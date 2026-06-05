package main

import (
	"bytes"
	"database/sql"
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"sync"
	"time"

	_ "github.com/go-sql-driver/mysql"
	"github.com/xuri/excelize/v2"
)

// ------- config -------

type appConfig struct {
	MySQL struct {
		DSN string `json:"dsn"`
	} `json:"mysql"`
	ExternalMySQL struct {
		Database string `json:"database"`
		DSN      string `json:"dsn"`
	} `json:"external_mysql"`
}

type dbConfig struct {
	SdataDSN string
	WxzdbDSN string
}

func loadDBConfig() (*dbConfig, error) {
	paths := []string{}
	if p := strings.TrimSpace(os.Getenv("PRISM_CONFIG_PATH")); p != "" {
		paths = append(paths, p)
	}
	paths = append(paths,
		filepath.Join("..", "..", "config", "prism-config.json"),
		filepath.Join("..", "config", "prism-config.json"),
		filepath.Join("config", "prism-config.json"),
	)
	for _, p := range paths {
		b, err := os.ReadFile(p)
		if err != nil {
			continue
		}
		var cfg appConfig
		b = bytes.TrimPrefix(b, []byte{0xEF, 0xBB, 0xBF})
		if err := json.Unmarshal(b, &cfg); err != nil {
			continue
		}
		sdataDSN := strings.TrimSpace(cfg.MySQL.DSN)
		wxzdbDSN := strings.TrimSpace(cfg.ExternalMySQL.DSN)
		if sdataDSN == "" {
			continue
		}
		if wxzdbDSN == "" {
			wxzdbDSN = sdataDSN // fallback: single DB
		}
		log.Printf("config loaded from: %s", p)
		return &dbConfig{SdataDSN: sdataDSN, WxzdbDSN: wxzdbDSN}, nil
	}
	return nil, fmt.Errorf("mysql.dsn is required in prism-config.json")
}

// ------- data types -------

type phoneTask struct {
	idx   int
	phone string
}

type phoneResult struct {
	idx   int
	ids   []string
	err   error
}

type summaryRow struct {
	ID         string
	Type       string
	Msisdn1    string
	Msisdn2    string
	Cnt        int
	CntDt      int
	Message    string
	Summary    string
	Region     sql.NullString
	Info       sql.NullString
	AssignTo   sql.NullString
	Score      float64
	Qklx       sql.NullString
	Label2     sql.NullString
	UserID     sql.NullString
	UserName   sql.NullString
	Status     string
	UpdateTime string
	DataDate   string
}

type workflowState struct {
	ID         string
	Status     string
	Level      sql.NullString
	Remark     sql.NullString
	MarkTag    sql.NullString
	Distribute sql.NullString
}

type distributeRow struct {
	ClueID   string
	Level    sql.NullString
	Tag      sql.NullString
	AssignTo sql.NullString
}

type feedbackRow struct {
	ClueID           string
	Feedback         string
	FeedbackTime     string
	FeedbackUserID   sql.NullString
	FeedbackUserName sql.NullString
}

// ------- helpers -------

func canonicalID(id string) string {
	parts := strings.Split(id, "-")
	if len(parts) != 3 {
		return id
	}
	a, b, dt := parts[0], parts[1], parts[2]
	if lessOrEqualNumericString(a, b) {
		return a + "-" + b + "-" + dt
	}
	return b + "-" + a + "-" + dt
}

func reverseID(id string) string {
	parts := strings.Split(id, "-")
	if len(parts) != 3 {
		return id
	}
	return parts[1] + "-" + parts[0] + "-" + parts[2]
}

func lessOrEqualNumericString(a, b string) bool {
	aTrim := strings.TrimLeft(a, "0")
	bTrim := strings.TrimLeft(b, "0")
	if aTrim == "" {
		aTrim = "0"
	}
	if bTrim == "" {
		bTrim = "0"
	}
	if len(aTrim) != len(bTrim) {
		return len(aTrim) < len(bTrim)
	}
	return aTrim <= bTrim
}

func csvEscape(s string) string {
	if strings.ContainsAny(s, ",\"\n\r") {
		return `"` + strings.ReplaceAll(s, `"`, `""`) + `"`
	}
	return s
}

// ------- worker pool -------

func runWorkerPool(db *sql.DB, phones []string, workers int) []phoneResult {
	tasks := make(chan phoneTask, len(phones))
	results := make(chan phoneResult, len(phones))

	var wg sync.WaitGroup
	for w := 0; w < workers; w++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			for t := range tasks {
				r := phoneResult{idx: t.idx}
				rows, err := db.Query(
					`SELECT id FROM nb_tab_grjd_summary WHERE msisdn_1 = ? OR msisdn_2 = ?`,
					t.phone, t.phone,
				)
				if err != nil {
					r.err = err
					results <- r
					continue
				}
				for rows.Next() {
					var id string
					if scanErr := rows.Scan(&id); scanErr == nil {
						r.ids = append(r.ids, canonicalID(id))
					}
				}
				rows.Close()
				if rows.Err() != nil {
					r.err = rows.Err()
				}
				results <- r
			}
		}()
	}

	for i, p := range phones {
		tasks <- phoneTask{idx: i, phone: p}
	}
	close(tasks)

	go func() {
		wg.Wait()
		close(results)
	}()

	var out []phoneResult
	for r := range results {
		out = append(out, r)
	}
	sort.Slice(out, func(i, j int) bool { return out[i].idx < out[j].idx })
	return out
}

// ------- main -------

func main() {
	log.SetOutput(os.Stdout)

	xlsxPath := flag.String("xlsx", "msisdn_score.xlsx", "Path to input xlsx file (column A = phone numbers)")
	workers := flag.Int("workers", 8, "Number of concurrent query workers")
	flag.Parse()

	dbCfg, err := loadDBConfig()
	if err != nil {
		log.Fatalf("load config: %v", err)
	}

	db, err := sql.Open("mysql", dbCfg.SdataDSN)
	if err != nil {
		log.Fatalf("open sdata mysql: %v", err)
	}
	defer db.Close()
	db.SetMaxOpenConns(*workers + 4)
	db.SetMaxIdleConns(*workers)
	db.SetConnMaxLifetime(5 * time.Minute)

	if err := db.Ping(); err != nil {
		log.Fatalf("sdata ping: %v", err)
	}
	log.Println("sdata connected")

	var wxzdb *sql.DB
	if dbCfg.WxzdbDSN != dbCfg.SdataDSN {
		wxzdb, err = sql.Open("mysql", dbCfg.WxzdbDSN)
		if err != nil {
			log.Fatalf("open wxzdb mysql: %v", err)
		}
		defer wxzdb.Close()
		wxzdb.SetMaxOpenConns(8)
		wxzdb.SetMaxIdleConns(4)
		wxzdb.SetConnMaxLifetime(5 * time.Minute)
		if err := wxzdb.Ping(); err != nil {
			log.Printf("wxzdb ping failed, fallback to sdata: %v", err)
			wxzdb = db
		} else {
			log.Println("wxzdb connected")
		}
	} else {
		wxzdb = db
		log.Println("using single database for both sdata and wxzdb")
	}

	// ---- Phase 1: Read input Excel ----
	log.Printf("reading input: %s", *xlsxPath)
	f, err := excelize.OpenFile(*xlsxPath)
	if err != nil {
		log.Fatalf("open xlsx: %v", err)
	}
	defer f.Close()

	sheet := f.GetSheetName(0)
	allRows, err := f.GetRows(sheet)
	if err != nil {
		log.Fatalf("read rows: %v", err)
	}
	if len(allRows) < 2 {
		log.Fatal("xlsx must have header + at least one data row")
	}

	// Preserve existing columns; column A = phone, B/C/D = preserved data
	phones := make([]string, 0, len(allRows)-1)
	colB := make([]string, len(allRows)-1)
	colC := make([]string, len(allRows)-1)
	colD := make([]string, len(allRows)-1)

	for i := 1; i < len(allRows); i++ {
		row := allRows[i]
		phone := strings.TrimSpace(getCell(row, 0))
		phones = append(phones, phone)
		colB[i-1] = getCell(row, 1)
		colC[i-1] = getCell(row, 2)
		colD[i-1] = getCell(row, 3)
	}
	total := len(phones)
	log.Printf("loaded %d phone numbers", total)

	// ---- Phase 2: Concurrent phone lookups ----
	log.Printf("starting %d workers for phone matching...", *workers)
	startTime := time.Now()
	results := runWorkerPool(db, phones, *workers)
	elapsed := time.Since(startTime)
	log.Printf("phone matching completed in %s", elapsed.Round(time.Millisecond))

	// Collect all matched IDs
	allIDs := make(map[string]bool)
	matchCounts := make([]int, total)
	matchIDs := make([]string, total)
	failures := 0
	for _, r := range results {
		if r.err != nil {
			log.Printf("WARN: phone[%d]=%s query error: %v", r.idx, phones[r.idx], r.err)
			failures++
			continue
		}
		// Deduplicate IDs for this phone
		seen := make(map[string]bool)
		var unique []string
		for _, id := range r.ids {
			if !seen[id] {
				seen[id] = true
				unique = append(unique, id)
				allIDs[id] = true
			}
		}
		matchCounts[r.idx] = len(unique)
		matchIDs[r.idx] = strings.Join(unique, ",")
	}
	log.Printf("unique matched IDs: %d (query failures: %d)", len(allIDs), failures)

	// ---- Phase 3: Write back to msisdn_score.xlsx with E/F columns ----
	log.Printf("writing match results back to input xlsx...")
	f.SetCellValue(sheet, "E1", "匹配数")
	f.SetCellValue(sheet, "F1", "匹配线索ID(逗号分隔)")
	for i := 0; i < total; i++ {
		rowIdx := i + 2 // 1-based, +1 for header
		f.SetCellValue(sheet, fmt.Sprintf("E%d", rowIdx), matchCounts[i])
		f.SetCellValue(sheet, fmt.Sprintf("F%d", rowIdx), matchIDs[i])
	}
	// Widen E/F columns
	f.SetColWidth(sheet, "E", "E", 10)
	f.SetColWidth(sheet, "F", "F", 40)

	outXlsx := strings.TrimSuffix(*xlsxPath, ".xlsx") + "_matched.xlsx"
	if err := f.SaveAs(outXlsx); err != nil {
		log.Fatalf("save matched xlsx: %v", err)
	}
	log.Printf("saved: %s", outXlsx)

	// ---- Phase 4: Export full matching data to id-export.xlsx ----
	if len(allIDs) == 0 {
		log.Println("no matching IDs — skipping id-export.xlsx")
		return
	}

	idList := make([]string, 0, len(allIDs))
	for id := range allIDs {
		idList = append(idList, id)
	}
	log.Printf("exporting %d matching clues to id-export.xlsx...", len(idList))

	ef := excelize.NewFile()
	defer ef.Close()
	esheet := ef.GetSheetName(0)

	// Header row (same as batch export CSV)
	exportHeaders := []string{
		"线索ID", "类型", "线索等级", "号码1", "号码2", "分数", "状态", "分配",
		"分配负责人", "标记", "前科类型", "属地", "短信全文", "AI总结", "备注",
		"额外信息", "数据日期", "更新时间", "最新反馈", "最新反馈时间", "最新反馈人",
		"详情压缩", "历史反馈压缩", "上下文短信压缩",
	}
	for i, h := range exportHeaders {
		col, _ := excelize.CoordinatesToCellName(i+1, 1)
		ef.SetCellValue(esheet, col, h)
	}
	headerStyle, _ := ef.NewStyle(&excelize.Style{Font: &excelize.Font{Bold: true}})
	ef.SetRowStyle(esheet, 1, 1, headerStyle)

	// Batch load all data
	summaries := loadAllSummaries(db, idList)
	workflows := loadAllWorkflows(wxzdb, idList)
	distributes := loadAllDistributes(wxzdb, idList)
	feedbacks := loadLatestFeedbacks(wxzdb, idList)

	rowIdx := 2
	for _, id := range idList {
		canon := canonicalID(id)
		item := summaries[canon]
		if item == nil {
			continue
		}
		wf := workflows[canon]
		dist := distributes[canon]
		fb := feedbacks[canon]

		level := ""
		distributeVal := ""
		if wf != nil {
			level = wf.Level.String
			distributeVal = wf.Distribute.String
		}
		if strings.TrimSpace(level) == "" && dist != nil {
			level = dist.Level.String
		}
		if strings.TrimSpace(distributeVal) == "" && dist != nil {
			distributeVal = dist.Tag.String
		}

		status := ""
		if wf != nil {
			status = wf.Status
		}
		if fb != nil && fb.Feedback != "" && status != "已处置" {
			status = "已反馈"
		}
		if status == "" {
			status = "待核查"
		}

		feedbackText := ""
		feedbackTime := ""
		feedbackUser := ""
		if fb != nil {
			feedbackText = fb.Feedback
			feedbackTime = fb.FeedbackTime
			feedbackUser = fb.FeedbackUserName.String
		}

		remark := ""
		markTag := ""
		if wf != nil {
			remark = wf.Remark.String
			markTag = wf.MarkTag.String
		}

		assignTo := ""
		if item.AssignTo.Valid {
			assignTo = item.AssignTo.String
		} else if dist != nil {
			assignTo = dist.AssignTo.String
		}

		row := []string{
			canon, item.Type, level, item.Msisdn1, item.Msisdn2,
			fmt.Sprintf("%.2f", item.Score), status, distributeVal,
			assignTo, markTag,
			item.Qklx.String, item.Region.String, item.Message, item.Summary, remark,
			item.Info.String, item.DataDate, item.UpdateTime,
			feedbackText, feedbackTime, feedbackUser,
			buildDetailText(item, wf, fb),
			buildFeedbackHistoryText(wxzdb, canon),
			buildMessagesText(db, canon),
		}

		for i, v := range row {
			col, _ := excelize.CoordinatesToCellName(i+1, rowIdx)
			ef.SetCellValue(esheet, col, v)
		}
		rowIdx++
	}

	// Set column widths
	widths := map[string]float64{
		"A": 32, "B": 14, "C": 16, "D": 16, "E": 16, "F": 10, "G": 10, "H": 14,
		"I": 14, "J": 12, "K": 16, "L": 14, "M": 40, "N": 40, "O": 20,
		"P": 20, "Q": 14, "R": 20, "S": 30, "T": 20, "U": 14,
		"V": 50, "W": 50, "X": 50,
	}
	for col, w := range widths {
		ef.SetColWidth(esheet, col, col, w)
	}

	exportPath := "id-export.xlsx"
	if err := ef.SaveAs(exportPath); err != nil {
		log.Fatalf("save export xlsx: %v", err)
	}
	log.Printf("saved: %s (%d rows)", exportPath, rowIdx-2)
	log.Println("done")
}

// ------- batch data loaders -------

func loadAllSummaries(db *sql.DB, ids []string) map[string]*summaryRow {
	result := make(map[string]*summaryRow)
	if len(ids) == 0 {
		return result
	}

	// Build parameterized query with all canonical + reversed IDs
	idSet := make(map[string]bool)
	for _, id := range ids {
		canon := canonicalID(id)
		idSet[canon] = true
		idSet[reverseID(canon)] = true
	}
	idForms := make([]string, 0, len(idSet))
	placeholders := make([]string, 0, len(idSet))
	args := make([]interface{}, 0, len(idSet))
	for id := range idSet {
		placeholders = append(placeholders, "?")
		args = append(args, id)
		idForms = append(idForms, id)
	}

	query := fmt.Sprintf(`
		SELECT id, COALESCE(type,''), COALESCE(msisdn_1,''), COALESCE(msisdn_2,''),
		       cnt, cnt_dt, COALESCE(message,''), COALESCE(summary,''),
		       region, info, score, qklx, label2, user_id, user_name, status,
		       COALESCE(DATE_FORMAT(update_time,'%%Y-%%m-%%d %%H:%%i:%%s'),''),
		       COALESCE(DATE_FORMAT(dt,'%%Y-%%m-%%d'),'')
		FROM nb_tab_grjd_summary
		WHERE id IN (%s)`, strings.Join(placeholders, ","))

	rows, err := db.Query(query, args...)
	if err != nil {
		log.Printf("load summaries error: %v", err)
		return result
	}
	defer rows.Close()

	for rows.Next() {
		var s summaryRow
		if err := rows.Scan(&s.ID, &s.Type, &s.Msisdn1, &s.Msisdn2,
			&s.Cnt, &s.CntDt, &s.Message, &s.Summary,
			&s.Region, &s.Info, &s.Score, &s.Qklx, &s.Label2, &s.UserID, &s.UserName, &s.Status,
			&s.UpdateTime, &s.DataDate); err != nil {
			log.Printf("scan summary error: %v", err)
			continue
		}
		canon := canonicalID(s.ID)
		if _, exists := result[canon]; !exists {
			s.ID = canon
			result[canon] = &s
		}
	}
	if rows.Err() != nil {
		log.Printf("rows err: %v", rows.Err())
	}
	_ = idForms
	return result
}

func loadAllWorkflows(db *sql.DB, ids []string) map[string]*workflowState {
	result := make(map[string]*workflowState)
	if len(ids) == 0 {
		return result
	}
	placeholders := make([]string, len(ids))
	args := make([]interface{}, len(ids))
	for i, id := range ids {
		placeholders[i] = "?"
		args[i] = id
	}
	query := fmt.Sprintf(`
		SELECT id, status, level, remark, mark_tag, distribute
		FROM nb_tab_grjd_workflow_state
		WHERE id IN (%s)`, strings.Join(placeholders, ","))

	rows, err := db.Query(query, args...)
	if err != nil {
		log.Printf("load workflows error: %v", err)
		return result
	}
	defer rows.Close()

	for rows.Next() {
		var w workflowState
		if err := rows.Scan(&w.ID, &w.Status, &w.Level, &w.Remark, &w.MarkTag, &w.Distribute); err != nil {
			continue
		}
		canon := canonicalID(w.ID)
		if _, exists := result[canon]; !exists {
			w.ID = canon
			result[canon] = &w
		}
	}
	return result
}

func loadAllDistributes(db *sql.DB, ids []string) map[string]*distributeRow {
	result := make(map[string]*distributeRow)
	if len(ids) == 0 {
		return result
	}
	placeholders := make([]string, len(ids))
	args := make([]interface{}, len(ids))
	for i, id := range ids {
		placeholders[i] = "?"
		args[i] = id
	}
	query := fmt.Sprintf(`
		SELECT clue_id, level, tag, assign_to
		FROM grjd_distribute
		WHERE clue_id IN (%s)`, strings.Join(placeholders, ","))

	rows, err := db.Query(query, args...)
	if err != nil {
		log.Printf("load distributes error: %v", err)
		return result
	}
	defer rows.Close()

	for rows.Next() {
		var d distributeRow
		if err := rows.Scan(&d.ClueID, &d.Level, &d.Tag, &d.AssignTo); err != nil {
			continue
		}
		canon := canonicalID(d.ClueID)
		if _, exists := result[canon]; !exists {
			d.ClueID = canon
			result[canon] = &d
		}
	}
	return result
}

func loadLatestFeedbacks(db *sql.DB, ids []string) map[string]*feedbackRow {
	result := make(map[string]*feedbackRow)
	if len(ids) == 0 {
		return result
	}
	idSet := make(map[string]bool)
	for _, id := range ids {
		idSet[canonicalID(id)] = true
		idSet[reverseID(canonicalID(id))] = true
	}
	idForms := make([]string, 0, len(idSet))
	placeholders := make([]string, 0, len(idSet))
	args := make([]interface{}, 0, len(idSet))
	for id := range idSet {
		placeholders = append(placeholders, "?")
		args = append(args, id)
		idForms = append(idForms, id)
	}

	query := fmt.Sprintf(`
		SELECT clue_id, feedback_content, DATE_FORMAT(feedback_time,'%%Y-%%m-%%d %%H:%%i:%%s'), feedback_userId, feedback_username
		FROM nb_tab_grjd_feedback_history
		WHERE clue_id IN (%s)
		ORDER BY feedback_time DESC`, strings.Join(placeholders, ","))

	rows, err := db.Query(query, args...)
	if err != nil {
		log.Printf("load feedbacks error: %v", err)
		return result
	}
	defer rows.Close()

	for rows.Next() {
		var f feedbackRow
		if err := rows.Scan(&f.ClueID, &f.Feedback, &f.FeedbackTime, &f.FeedbackUserID, &f.FeedbackUserName); err != nil {
			continue
		}
		canon := canonicalID(f.ClueID)
		if _, exists := result[canon]; !exists {
			f.ClueID = canon
			result[canon] = &f
		}
	}
	_ = idForms
	return result
}

// ------- compressed text builders (same format as server export) -------

func buildDetailText(item *summaryRow, wf *workflowState, fb *feedbackRow) string {
	if item == nil {
		return ""
	}
	level := ""
	status := ""
	remark := ""
	markTag := ""
	distribute := ""
	if wf != nil {
		level = wf.Level.String
		status = wf.Status
		remark = wf.Remark.String
		markTag = wf.MarkTag.String
		distribute = wf.Distribute.String
	}
	fbText, fbTime, fbUser := "", "", ""
	if fb != nil {
		fbText = fb.Feedback
		fbTime = fb.FeedbackTime
		fbUser = fb.FeedbackUserName.String
	}
	lines := []string{
		"type: " + item.Type,
		"level: " + level,
		"msisdn_1: " + item.Msisdn1,
		"msisdn_2: " + item.Msisdn2,
		fmt.Sprintf("cnt: %d", item.Cnt),
		fmt.Sprintf("cnt_dt: %d", item.CntDt),
		"message: " + item.Message,
		"summary: " + item.Summary,
		"region: " + item.Region.String,
		"info: " + item.Info.String,
		"score: " + fmt.Sprintf("%.2f", item.Score),
		"qklx: " + item.Qklx.String,
		"label2: " + item.Label2.String,
		"user_id: " + item.UserID.String,
		"user_name: " + item.UserName.String,
		"status: " + status,
		"feedback: " + fbText,
		"feedback_time: " + fbTime,
		"feedback_user: " + fbUser,
		"remark: " + remark,
		"mark_tag: " + markTag,
		"distribute: " + distribute,
		"update_time: " + item.UpdateTime,
		"data_date: " + item.DataDate,
	}
	return strings.Join(lines, "\n")
}

func buildFeedbackHistoryText(db *sql.DB, clueID string) string {
	canon := canonicalID(clueID)
	rev := reverseID(canon)
	rows, err := db.Query(`
		SELECT DATE_FORMAT(feedback_time,'%Y-%m-%d %H:%i:%s'), feedback_username, feedback_content
		FROM nb_tab_grjd_feedback_history
		WHERE clue_id IN (?,?)
		ORDER BY feedback_time DESC`, canon, rev)
	if err != nil {
		return ""
	}
	defer rows.Close()
	var lines []string
	for rows.Next() {
		var t, user, content string
		if err := rows.Scan(&t, &user, &content); err == nil {
			lines = append(lines, fmt.Sprintf("[%s] %s: %s", t, user, content))
		}
	}
	return strings.Join(lines, "\n")
}

func buildMessagesText(db *sql.DB, clueID string) string {
	canon := canonicalID(clueID)
	rev := reverseID(canon)
	rows, err := db.Query(`
		SELECT capture_time, msisdn, calltype, message
		FROM nb_tab_grjd_message
		WHERE id IN (?,?)
		ORDER BY capture_time ASC`, canon, rev)
	if err != nil {
		return ""
	}
	defer rows.Close()
	var lines []string
	for rows.Next() {
		var t, msisdn, callType, msg string
		if err := rows.Scan(&t, &msisdn, &callType, &msg); err == nil {
			lines = append(lines, fmt.Sprintf("[%s] %s(%s): %s", t, callType, msisdn, msg))
		}
	}
	return strings.Join(lines, "\n")
}

func getCell(row []string, idx int) string {
	if idx < len(row) {
		return row[idx]
	}
	return ""
}
