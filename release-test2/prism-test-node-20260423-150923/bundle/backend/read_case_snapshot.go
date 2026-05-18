package main

import (
	"database/sql"
	"encoding/json"
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"strings"

	_ "github.com/go-sql-driver/mysql"
)

type output struct {
	Type    string  `json:"type"`
	Level   string  `json:"level"`
	Score   float64 `json:"score"`
	Summary string  `json:"summary"`
}

type appConfig struct {
	MySQL struct {
		DSN string `json:"dsn"`
	} `json:"mysql"`
	ExternalMySQL struct {
		Database string `json:"database"`
	} `json:"external_mysql"`
}

func canonicalID(id string) string {
	parts := strings.Split(id, "-")
	if len(parts) != 3 {
		return id
	}
	a := parts[0]
	b := parts[1]
	dt := parts[2]
	if a <= b {
		return a + "-" + b + "-" + dt
	}
	return b + "-" + a + "-" + dt
}

func main() {
	clueID := flag.String("clue-id", "", "clue id")
	flag.Parse()

	if strings.TrimSpace(*clueID) == "" {
		fmt.Fprintln(os.Stderr, "clue-id is required")
		os.Exit(2)
	}

	dsn := os.Getenv("MYSQL_DSN")
	workflowSchema := strings.TrimSpace(os.Getenv("EXTERNAL_MYSQL_DATABASE"))
	if strings.TrimSpace(dsn) == "" {
		cfgDSN, cfgSchema := loadDSNFromConfig()
		if strings.TrimSpace(cfgDSN) != "" {
			dsn = cfgDSN
			if workflowSchema == "" {
				workflowSchema = cfgSchema
			}
		} else {
			dsn = "root@tcp(127.0.0.1:3306)/sdata?charset=utf8mb4&parseTime=True&loc=Local"
		}
	}
	if workflowSchema == "" {
		workflowSchema = "wxzdb"
	}

	db, err := sql.Open("mysql", dsn)
	if err != nil {
		fmt.Fprintln(os.Stderr, err.Error())
		os.Exit(1)
	}
	defer db.Close()

	canonical := canonicalID(*clueID)
	reversed := canonical
	parts := strings.Split(canonical, "-")
	if len(parts) == 3 {
		reversed = parts[1] + "-" + parts[0] + "-" + parts[2]
	}

	var out output
	query := `SELECT type, score, summary FROM nb_tab_grjd_summary WHERE id IN (?, ?) ORDER BY update_time DESC LIMIT 1`
	if err := db.QueryRow(query, canonical, reversed).Scan(&out.Type, &out.Score, &out.Summary); err != nil {
		fmt.Fprintln(os.Stderr, err.Error())
		os.Exit(1)
	}

	levelQuery := fmt.Sprintf("SELECT level FROM `%s`.`nb_tab_grjd_workflow_state` WHERE id IN (?, ?) LIMIT 1", workflowSchema)
	_ = db.QueryRow(levelQuery, canonical, reversed).Scan(&out.Level)

	enc := json.NewEncoder(os.Stdout)
	enc.SetEscapeHTML(false)
	_ = enc.Encode(out)
}

func loadDSNFromConfig() (string, string) {
	paths := []string{}
	if p := strings.TrimSpace(os.Getenv("PRISM_CONFIG_PATH")); p != "" {
		paths = append(paths, p)
	}
	paths = append(paths, filepath.Join("..", "config", "prism-config.json"), filepath.Join("config", "prism-config.json"))

	for _, p := range paths {
		content, err := os.ReadFile(p)
		if err != nil {
			continue
		}
		var cfg appConfig
		if err := json.Unmarshal(content, &cfg); err == nil {
			if strings.TrimSpace(cfg.MySQL.DSN) != "" {
				schema := strings.TrimSpace(cfg.ExternalMySQL.Database)
				if schema == "" {
					schema = "wxzdb"
				}
				return cfg.MySQL.DSN, schema
			}
		}
	}

	return "", "wxzdb"
}
