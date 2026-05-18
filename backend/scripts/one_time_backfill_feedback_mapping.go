package main

import (
  "bytes"
  "database/sql"
  "encoding/json"
  "fmt"
  "os"
  "path/filepath"
  "strings"
  "time"

  _ "github.com/go-sql-driver/mysql"
)

type appConfig struct {
  MySQL struct {
    DSN string `json:"dsn"`
  } `json:"mysql"`
  ExternalMySQL struct {
    Database string `json:"database"`
    DSN      string `json:"dsn"`
  } `json:"external_mysql"`
}

func loadConfig() appConfig {
  candidates := []string{}
  if p := strings.TrimSpace(os.Getenv("PRISM_CONFIG_PATH")); p != "" {
    candidates = append(candidates, p)
  }
  candidates = append(candidates, filepath.Join("..", "config", "prism-config.json"), filepath.Join("config", "prism-config.json"))

  for _, p := range candidates {
    b, err := os.ReadFile(p)
    if err != nil {
      continue
    }
    var cfg appConfig
    b = bytes.TrimPrefix(b, []byte{0xEF, 0xBB, 0xBF})
    if err := json.Unmarshal(b, &cfg); err == nil {
      return cfg
    }
  }
  return appConfig{}
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

func normalizeDateToCompact(raw string) string {
  val := strings.TrimSpace(raw)
  if val == "" {
    return ""
  }
  if len(val) >= 8 && strings.Count(val, "-") == 0 {
    return val[0:8]
  }
  if t, err := time.Parse("2006-01-02", val); err == nil {
    return t.Format("20060102")
  }
  if len(val) >= 10 {
    if t, err := time.Parse("2006-01-02 15:04:05", val[0:19]); err == nil {
      return t.Format("20060102")
    }
  }
  return ""
}

func composeClueID(phoneA, phoneB, dateRaw string) string {
  a := strings.TrimSpace(phoneA)
  b := strings.TrimSpace(phoneB)
  if a == "" || b == "" {
    return ""
  }
  dt := normalizeDateToCompact(dateRaw)
  if dt == "" {
    return ""
  }
  if lessOrEqualNumericString(a, b) {
    return a + "-" + b + "-" + dt
  }
  return b + "-" + a + "-" + dt
}

func main() {
  cfg := loadConfig()

  externalDSN := strings.TrimSpace(cfg.ExternalMySQL.DSN)
  coreDSN := strings.TrimSpace(cfg.MySQL.DSN)
  schema := strings.TrimSpace(cfg.ExternalMySQL.Database)
  if schema == "" {
    schema = "wxzdb"
  }
  if coreDSN == "" {
    panic("mysql.dsn is required in prism-config.json")
  }

  dsn := coreDSN
  if externalDSN != "" {
    externalDB, err := sql.Open("mysql", externalDSN)
    if err == nil {
      if pingErr := externalDB.Ping(); pingErr == nil {
        dsn = externalDSN
      }
      _ = externalDB.Close()
    }
  }

  db, err := sql.Open("mysql", dsn)
  if err != nil {
    panic(err)
  }
  defer db.Close()
  if err := db.Ping(); err != nil {
    panic(err)
  }

  if _, err := db.Exec("USE `" + schema + "`"); err != nil {
    panic(err)
  }

  if _, err := db.Exec(`
    CREATE TABLE IF NOT EXISTS feedback2nb_tab_grjd_feedback_history (
      source_feedback_id VARCHAR(100) PRIMARY KEY,
      feedback_id BIGINT UNSIGNED NOT NULL,
      created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
      KEY idx_feedback_id (feedback_id)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4`); err != nil {
    panic(err)
  }

  rows, err := db.Query(`SELECT id, feedback_content, feedback_userId, feedback_time, mid, feedback_username FROM feedback`)
  if err != nil {
    panic(err)
  }
  defer rows.Close()

  imported := 0
  skipped := 0
  failed := 0

  for rows.Next() {
    var sourceID, content, userID, feedbackTimeRaw, mid, userName string
    if err := rows.Scan(&sourceID, &content, &userID, &feedbackTimeRaw, &mid, &userName); err != nil {
      failed++
      continue
    }

    var mapped int64
    if err := db.QueryRow(`SELECT feedback_id FROM feedback2nb_tab_grjd_feedback_history WHERE source_feedback_id = ?`, sourceID).Scan(&mapped); err == nil {
      skipped++
      continue
    }

    var jfhm, ddhm, jgrq sql.NullString
    if err := db.QueryRow(`SELECT jfhm, ddhm, jgrq FROM grjdmxjg_za WHERE id = ? LIMIT 1`, mid).Scan(&jfhm, &ddhm, &jgrq); err != nil {
      failed++
      continue
    }

    clueID := composeClueID(jfhm.String, ddhm.String, jgrq.String)
    if clueID == "" {
      skipped++
      continue
    }

    feedbackTime := time.Now()
    if parsed, err := time.Parse("2006-01-02 15:04:05", strings.TrimSpace(feedbackTimeRaw)); err == nil {
      feedbackTime = parsed
    }

    var historyID int64
    err = db.QueryRow(`
      SELECT id
      FROM nb_tab_grjd_feedback_history
      WHERE clue_id = ? AND feedback_content = ? AND feedback_userId = ? AND feedback_username = ?
      ORDER BY ABS(TIMESTAMPDIFF(SECOND, feedback_time, ?)) ASC, id DESC
      LIMIT 1`, clueID, content, userID, userName, feedbackTime).Scan(&historyID)
    if err != nil {
      err = db.QueryRow(`
        SELECT id
        FROM nb_tab_grjd_feedback_history
        WHERE clue_id = ? AND feedback_content = ?
        ORDER BY feedback_time DESC, id DESC
        LIMIT 1`, clueID, content).Scan(&historyID)
      if err != nil {
        result, insErr := db.Exec(`
          INSERT INTO nb_tab_grjd_feedback_history (clue_id, feedback_content, feedback_userId, feedback_username, remark, feedback_time)
          VALUES (?, ?, ?, ?, '', ?)`, clueID, content, userID, userName, feedbackTime)
        if insErr != nil {
          failed++
          continue
        }
        idVal, idErr := result.LastInsertId()
        if idErr != nil {
          failed++
          continue
        }
        historyID = idVal
      }
    }

    if _, err := db.Exec(`
      INSERT INTO feedback2nb_tab_grjd_feedback_history (source_feedback_id, feedback_id)
      VALUES (?, ?)
      ON DUPLICATE KEY UPDATE feedback_id = VALUES(feedback_id)`, sourceID, historyID); err != nil {
      failed++
      continue
    }

    imported++
  }

  if err := rows.Err(); err != nil {
    panic(err)
  }

  fmt.Printf("mapping backfill done: imported=%d skipped=%d failed=%d\n", imported, skipped, failed)
}
