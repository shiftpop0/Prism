CREATE DATABASE IF NOT EXISTS sdata CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE sdata;

CREATE TABLE IF NOT EXISTS nb_tab_grjd_summary (
  id VARCHAR(64) NOT NULL,
  type VARCHAR(32) NOT NULL,
  msisdn_1 VARCHAR(32) NOT NULL,
  msisdn_2 VARCHAR(32) NOT NULL,
  cnt INT NOT NULL,
  cnt_dt INT NOT NULL,
  message LONGTEXT NULL,
  summary LONGTEXT NULL,
  score DECIMAL(8,4) NOT NULL,
  qklx VARCHAR(64) NULL,
  label2 VARCHAR(64) NULL,
  user_id VARCHAR(64) NULL,
  user_name VARCHAR(64) NULL,
  status VARCHAR(16) NULL,
  update_time DATETIME NULL,
  dt DATE NULL,
  PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS nb_tab_grjd_message (
  id VARCHAR(64) NOT NULL,
  capture_time DATETIME NOT NULL,
  msisdn VARCHAR(32) NOT NULL,
  calltype VARCHAR(8) NOT NULL,
  message LONGTEXT NULL,
  dt DATE NULL,
  KEY idx_message_id_time (id, capture_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Do not truncate production/offline data by default.
-- Load business data explicitly with your own SQL import file when needed.
