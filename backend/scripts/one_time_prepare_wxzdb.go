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

	mustExec := func(sqlText string) {
		if _, err := db.Exec(sqlText); err != nil {
			panic(err)
		}
	}

	mustExec(`CREATE DATABASE IF NOT EXISTS wxzdb DEFAULT CHARSET=utf8mb4`)

	mustExec(`
    CREATE TABLE IF NOT EXISTS wxzdb.feedback (
      id VARCHAR(100) NOT NULL COMMENT 'id',
      feedback_content VARCHAR(2000) NOT NULL COMMENT '反馈内容',
      feedback_userId VARCHAR(100) NOT NULL COMMENT '反馈人',
      feedback_time VARCHAR(100) NOT NULL COMMENT '反馈时间',
      mid VARCHAR(100) NOT NULL COMMENT '与动态获得的表格id一致',
      feedback_username VARCHAR(100) NOT NULL COMMENT 'user名字',
      appEname VARCHAR(100) NOT NULL COMMENT 'appEname',
      PRIMARY KEY (id)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='反馈信息'`)

	mustExec(`
    CREATE TABLE IF NOT EXISTS wxzdb.grjdmxjg_za (
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

	mustExec(`
    CREATE TABLE IF NOT EXISTS wxzdb.nb_tab_grjd_feedback_history (
      feedback_id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
      clue_id VARCHAR(64) NOT NULL,
      feedback_content TEXT NOT NULL,
      feedback_userId VARCHAR(64) NULL,
      feedback_username VARCHAR(64) NULL,
      remark TEXT NULL,
      feedback_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
      KEY idx_feedback_id_time (clue_id, feedback_time)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4`)

	mustExec(`
    CREATE TABLE IF NOT EXISTS wxzdb.nb_tab_grjd_workflow_state (
      id VARCHAR(64) PRIMARY KEY,
      status VARCHAR(16) NOT NULL DEFAULT '待核查',
      level VARCHAR(32) NULL,
      remark TEXT NULL,
      mark_tag VARCHAR(64) NULL,
      distribute VARCHAR(64) NOT NULL DEFAULT '',
      updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4`)

	mustExec(`
    CREATE TABLE IF NOT EXISTS wxzdb.grjd_distribute (
      clue_id VARCHAR(64) PRIMARY KEY,
      level VARCHAR(128) NOT NULL,
      assign_to VARCHAR(64) NOT NULL,
      model_name VARCHAR(128) NOT NULL,
      tag VARCHAR(64) NOT NULL,
      assigned_time DATETIME NOT NULL,
      remark TEXT NULL
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4`)

	mustExec(`
    CREATE TABLE IF NOT EXISTS wxzdb.feedback2nb_tab_grjd_feedback_history (
      source_feedback_id VARCHAR(100) PRIMARY KEY,
      feedback_id BIGINT UNSIGNED NOT NULL,
      created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
      KEY idx_feedback_id (feedback_id)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4`)

	_, _ = db.Exec(`INSERT IGNORE INTO wxzdb.feedback (id, feedback_content, feedback_userId, feedback_time, mid, feedback_username, appEname) SELECT id, feedback_content, feedback_userId, feedback_time, mid, feedback_username, appEname FROM sdata.feedback`)
	_, _ = db.Exec(`INSERT IGNORE INTO wxzdb.grjdmxjg_za (id, is_feedback, create_time, appEname, jfhm, jfsfzh, jfzdrlx, ddhm, dfsfzh, dfzdrlx, zj, fz, jgrq, fxdj) SELECT id, is_feedback, create_time, appEname, jfhm, jfsfzh, jfzdrlx, ddhm, dfsfzh, dfzdrlx, zj, fz, jgrq, fxdj FROM sdata.grjdmxjg_za`)
	_, _ = db.Exec(`INSERT IGNORE INTO wxzdb.nb_tab_grjd_feedback_history (feedback_id, clue_id, feedback_content, feedback_userId, feedback_username, remark, feedback_time) SELECT feedback_id, clue_id, feedback_content, feedback_userId, feedback_username, remark, feedback_time FROM sdata.nb_tab_grjd_feedback_history`)
	_, _ = db.Exec(`
    INSERT INTO wxzdb.nb_tab_grjd_workflow_state (id, status, level, remark, mark_tag, distribute, updated_at)
    SELECT
      s.id,
      CASE WHEN fb.clue_id IS NULL THEN '待核查' ELSE '已反馈' END AS status,
      d.level,
      NULL AS remark,
      NULL AS mark_tag,
      COALESCE(d.tag, '') AS distribute,
      NOW() AS updated_at
    FROM sdata.nb_tab_grjd_summary s
    LEFT JOIN (SELECT clue_id FROM wxzdb.nb_tab_grjd_feedback_history GROUP BY clue_id) fb ON fb.clue_id = s.id
    LEFT JOIN wxzdb.grjd_distribute d ON d.clue_id = s.id
    ON DUPLICATE KEY UPDATE
      status = VALUES(status),
      level = VALUES(level),
      distribute = VALUES(distribute),
      updated_at = VALUES(updated_at)
  `)
	_, _ = db.Exec(`
    UPDATE wxzdb.nb_tab_grjd_workflow_state w
    LEFT JOIN wxzdb.grjd_distribute d ON w.id = d.clue_id
    SET w.distribute = COALESCE(d.tag, '')
  `)
	_, _ = db.Exec(`
    UPDATE wxzdb.nb_tab_grjd_workflow_state w
    JOIN wxzdb.grjd_distribute d ON w.id = d.clue_id
    SET w.level = d.level
  `)

	_, _ = db.Exec(`UPDATE wxzdb.grjdmxjg_za SET is_feedback = b'1'`)

	fmt.Println("wxzdb preparation done")
}
