package main

import (
	"bytes"
	"context"
	"database/sql"
	"encoding/json"
	"flag"
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
}

func main() {
	dsnFlag := flag.String("dsn", "", "mysql dsn, e.g. user:pass@tcp(host:3306)/db?charset=utf8mb4&parseTime=True&loc=Local")
	timeoutSec := flag.Int("timeout", 5, "connect timeout in seconds")
	flag.Parse()

	dsn := strings.TrimSpace(*dsnFlag)
	source := "flag --dsn"
	if dsn == "" {
		cfgDSN, ok := loadDSNFromConfig()
		if ok {
			dsn = cfgDSN
			source = "config/prism-config.json mysql.dsn"
		}
	}

	if dsn == "" {
		fmt.Fprintln(os.Stderr, "no dsn provided")
		fmt.Fprintln(os.Stderr, "use --dsn or configure prism-config.json mysql.dsn")
		os.Exit(2)
	}

	fmt.Printf("[INFO] DSN source: %s\n", source)
	fmt.Printf("[INFO] DSN (masked): %s\n", maskDSN(dsn))

	db, err := sql.Open("mysql", dsn)
	if err != nil {
		fmt.Fprintf(os.Stderr, "[ERROR] sql.Open failed: %v\n", err)
		os.Exit(1)
	}
	defer db.Close()

	db.SetConnMaxLifetime(30 * time.Second)
	db.SetMaxIdleConns(1)
	db.SetMaxOpenConns(1)

	pingTimeout := time.Duration(*timeoutSec) * time.Second
	deadlineCtx, cancel := context.WithTimeout(context.Background(), pingTimeout)
	defer cancel()

	if err := db.PingContext(deadlineCtx); err != nil {
		fmt.Fprintf(os.Stderr, "[ERROR] ping failed: %v\n", err)
		os.Exit(1)
	}

	var now string
	if err := db.QueryRow("SELECT NOW()").Scan(&now); err != nil {
		fmt.Fprintf(os.Stderr, "[ERROR] query failed after ping: %v\n", err)
		os.Exit(1)
	}

	fmt.Printf("[OK] mysql connected, server time: %s\n", now)
}

func loadDSNFromConfig() (string, bool) {
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
		content = bytes.TrimPrefix(content, []byte{0xEF, 0xBB, 0xBF})
		var cfg appConfig
		if err := json.Unmarshal(content, &cfg); err != nil {
			continue
		}
		dsn := strings.TrimSpace(cfg.MySQL.DSN)
		if dsn != "" {
			return dsn, true
		}
	}
	return "", false
}

func maskDSN(dsn string) string {
	at := strings.Index(dsn, "@")
	if at <= 0 {
		return dsn
	}
	left := dsn[:at]
	colon := strings.Index(left, ":")
	if colon < 0 {
		return dsn
	}
	return left[:colon+1] + "******" + dsn[at:]
}
