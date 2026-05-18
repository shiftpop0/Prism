package main

import (
  "bytes"
  "database/sql"
  "encoding/json"
  "fmt"
  "os"
  "path/filepath"
  "strings"

  _ "github.com/go-sql-driver/mysql"
)

type appConfig struct {
  MySQL struct {
    DSN string `json:"dsn"`
  } `json:"mysql"`
}

func loadCoreDSN() (string, error) {
  paths := []string{}
  if p := strings.TrimSpace(os.Getenv("PRISM_CONFIG_PATH")); p != "" {
    paths = append(paths, p)
  }
  paths = append(paths, filepath.Join("..", "config", "prism-config.json"), filepath.Join("config", "prism-config.json"))
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

func main() {
  dsn, err := loadCoreDSN()
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

  // Keep only nb_tab_grjd_message and nb_tab_grjd_summary in core database.
  statements := []string{
    "DROP TABLE IF EXISTS feedback2nb_tab_grjd_feedback_history",
    "DROP TABLE IF EXISTS feedback",
    "DROP TABLE IF EXISTS grjdmxjg_za",
    "DROP TABLE IF EXISTS nb_tab_grjd_feedback_history",
    "DROP TABLE IF EXISTS nb_tab_grjd_workflow_state",
  }

  for _, s := range statements {
    if _, err := db.Exec(s); err != nil {
      panic(err)
    }
  }

  fmt.Println("core cleanup done")
}
