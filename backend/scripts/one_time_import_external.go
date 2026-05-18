package main

import (
  "bytes"
  "bufio"
  "database/sql"
  "encoding/json"
  "fmt"
  "os"
  "path/filepath"
  "strconv"
  "strings"
  "time"

  _ "github.com/go-sql-driver/mysql"
)

type appConfig struct {
  MySQL struct {
    DSN string `json:"dsn"`
  } `json:"mysql"`
}

type zaRow struct {
  ID         int64
  CreateTime sql.NullTime
  AppEname   sql.NullString
  Jfhm       sql.NullString
  Jfzdrlx    sql.NullString
  Ddhm       sql.NullString
  Dfzdrlx    sql.NullString
  Zj         sql.NullString
  Fz         sql.NullString
  Jgrq       sql.NullString
}

func loadDSN() (string, error) {
  paths := []string{}
  if p := strings.TrimSpace(os.Getenv("PRISM_CONFIG_PATH")); p != "" {
    paths = append(paths, p)
  }
  paths = append(paths,
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
    if err := json.Unmarshal(b, &cfg); err == nil && strings.TrimSpace(cfg.MySQL.DSN) != "" {
      return cfg.MySQL.DSN, nil
    }
  }
  return "", fmt.Errorf("mysql.dsn is required in prism-config.json")
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

func normalizeDate(raw string) string {
  v := strings.TrimSpace(raw)
  if len(v) >= 8 && strings.Count(v, "-") == 0 {
    return v[:8]
  }
  if t, err := time.Parse("2006-01-02", v); err == nil {
    return t.Format("20060102")
  }
  return ""
}

func composeClueID(a, b, dtRaw string) string {
  p1 := strings.TrimSpace(a)
  p2 := strings.TrimSpace(b)
  if p1 == "" || p2 == "" {
    return ""
  }
  dt := normalizeDate(dtRaw)
  if dt == "" {
    return ""
  }
  if lessOrEqualNumericString(p1, p2) {
    return p1 + "-" + p2 + "-" + dt
  }
  return p2 + "-" + p1 + "-" + dt
}

func parseDateToSQL(raw string) sql.NullString {
  d := normalizeDate(raw)
  if len(d) != 8 {
    return sql.NullString{}
  }
  return sql.NullString{String: d[:4] + "-" + d[4:6] + "-" + d[6:8], Valid: true}
}

func ensureTables(db *sql.DB) error {
  _, err := db.Exec(`
    CREATE TABLE IF NOT EXISTS feedback (
      id VARCHAR(100) NOT NULL COMMENT 'id',
      feedback_content VARCHAR(2000) NOT NULL COMMENT '反馈内容',
      feedback_userId VARCHAR(100) NOT NULL COMMENT '反馈人',
      feedback_time VARCHAR(100) NOT NULL COMMENT '反馈时间',
      mid VARCHAR(100) NOT NULL COMMENT '与动态获得的表格id一致',
      feedback_username VARCHAR(100) NOT NULL COMMENT 'user名字',
      appEname VARCHAR(100) NOT NULL COMMENT 'appEname',
      PRIMARY KEY (id)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='反馈信息'`)
  if err != nil {
    return err
  }

  _, err = db.Exec(`
    CREATE TABLE IF NOT EXISTS grjdmxjg_za (
      id BIGINT NOT NULL AUTO_INCREMENT COMMENT 'id',
      is_feedback BIT(1) DEFAULT b'0',
      create_time DATETIME NOT NULL,
      appEname VARCHAR(50) NOT NULL,
      jfhm VARCHAR(500) DEFAULT NULL,
      jfsfzh VARCHAR(500) DEFAULT NULL,
      jfzdrlx VARCHAR(500) DEFAULT NULL,
      ddhm VARCHAR(500) DEFAULT NULL,
      dfsfzh VARCHAR(500) DEFAULT NULL,
      dfzdrlx VARCHAR(500) DEFAULT NULL,
      zj VARCHAR(500) DEFAULT NULL,
      fz VARCHAR(500) DEFAULT NULL,
      jgrq VARCHAR(500) DEFAULT NULL,
      fxdj VARCHAR(500) DEFAULT NULL,
      PRIMARY KEY (id)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8`)
  return err
}

func importTxtSQL(db *sql.DB) (int, int, error) {
  paths := []string{
    filepath.Join("..", "..", "data", "数据例-脱敏 (1).txt"),
    filepath.Join("..", "data", "数据例-脱敏 (1).txt"),
  }

  var file *os.File
  var err error
  for _, p := range paths {
    file, err = os.Open(p)
    if err == nil {
      break
    }
  }
  if file == nil {
    return 0, 0, fmt.Errorf("cannot open data txt")
  }
  defer file.Close()

  success := 0
  skipped := 0
  ctrlBit := "'" + string(rune(1)) + "'"

  scanner := bufio.NewScanner(file)
  for scanner.Scan() {
    line := strings.TrimSpace(scanner.Text())
    if line == "" || strings.HasPrefix(line, "--") {
      continue
    }
    if !strings.HasPrefix(strings.ToUpper(line), "INSERT INTO") {
      continue
    }

    line = strings.ReplaceAll(line, "`information_centre`.`feedback`", "`feedback`")
    line = strings.ReplaceAll(line, "`information_centre`.`grjdmxjg_za`", "`grjdmxjg_za`")
    line = strings.ReplaceAll(line, "'\\x01'", "b'1'")
    line = strings.ReplaceAll(line, "'\\u0001'", "b'1'")
    line = strings.ReplaceAll(line, ctrlBit, "b'1'")

    if _, err := db.Exec(line); err != nil {
      skipped++
      continue
    }
    success++
  }
  if err := scanner.Err(); err != nil {
    return success, skipped, err
  }
  return success, skipped, nil
}

func importZaToSummary(db *sql.DB) (int, int, error) {
  rows, err := db.Query(`SELECT id, create_time, appEname, jfhm, jfzdrlx, ddhm, dfzdrlx, zj, fz, jgrq FROM grjdmxjg_za`)
  if err != nil {
    return 0, 0, err
  }
  defer rows.Close()

  imported := 0
  skipped := 0

  for rows.Next() {
    var r zaRow
    if err := rows.Scan(&r.ID, &r.CreateTime, &r.AppEname, &r.Jfhm, &r.Jfzdrlx, &r.Ddhm, &r.Dfzdrlx, &r.Zj, &r.Fz, &r.Jgrq); err != nil {
      skipped++
      continue
    }

    clueID := composeClueID(r.Jfhm.String, r.Ddhm.String, r.Jgrq.String)
    if clueID == "" {
      skipped++
      continue
    }

    ms1 := strings.TrimSpace(r.Jfhm.String)
    ms2 := strings.TrimSpace(r.Ddhm.String)
    if !lessOrEqualNumericString(ms1, ms2) {
      ms1, ms2 = ms2, ms1
    }

    score := 0.0
    if fv := strings.TrimSpace(r.Fz.String); fv != "" {
      if parsed, err := strconv.ParseFloat(fv, 64); err == nil {
        score = parsed
      }
    }

    dt := parseDateToSQL(r.Jgrq.String)
    updateTime := time.Now()
    if r.CreateTime.Valid {
      updateTime = r.CreateTime.Time
    }

    _, err := db.Exec(`
      INSERT INTO nb_tab_grjd_summary (
        id, type, msisdn_1, msisdn_2, cnt, cnt_dt, message, summary, score, qklx, label2,
        user_id, user_name, status, update_time, dt
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON DUPLICATE KEY UPDATE
        type = VALUES(type),
        msisdn_1 = VALUES(msisdn_1),
        msisdn_2 = VALUES(msisdn_2),
        summary = VALUES(summary),
        score = VALUES(score),
        qklx = VALUES(qklx),
        label2 = VALUES(label2),
        update_time = VALUES(update_time),
        dt = VALUES(dt)`,
      clueID,
      r.AppEname.String,
      ms1,
      ms2,
      1,
      1,
      r.Zj.String,
      r.Zj.String,
      score,
      r.Jfzdrlx.String,
      r.Dfzdrlx.String,
      "",
      "",
      0,
      updateTime,
      dt,
    )
    if err != nil {
      skipped++
      continue
    }
    imported++
  }

  if err := rows.Err(); err != nil {
    return imported, skipped, err
  }
  return imported, skipped, nil
}

func main() {
  dsn, err := loadDSN()
  if err != nil {
    panic(err)
  }
  db, err := sql.Open("mysql", dsn)
  if err != nil {
    panic(err)
  }
  defer db.Close()

  if err := db.Ping(); err != nil {
    panic(err)
  }
  if err := ensureTables(db); err != nil {
    panic(err)
  }

  txtOK, txtSkip, err := importTxtSQL(db)
  if err != nil {
    panic(err)
  }

  summaryOK, summarySkip, err := importZaToSummary(db)
  if err != nil {
    panic(err)
  }

  fmt.Printf("one-time import done: txt_success=%d txt_skipped=%d summary_imported=%d summary_skipped=%d\n", txtOK, txtSkip, summaryOK, summarySkip)
}
