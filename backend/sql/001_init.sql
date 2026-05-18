CREATE DATABASE IF NOT EXISTS prism CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE prism;

CREATE TABLE IF NOT EXISTS person_profile (
  person_id VARCHAR(32) PRIMARY KEY,
  name_masked VARCHAR(64) NOT NULL,
  id_no_masked VARCHAR(64) DEFAULT NULL,
  region_code VARCHAR(12) NOT NULL,
  tags_json JSON DEFAULT NULL,
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS clue_event (
  clue_id VARCHAR(32) PRIMARY KEY,
  person_id VARCHAR(32) NOT NULL,
  source_system VARCHAR(64) NOT NULL,
  event_type VARCHAR(64) NOT NULL,
  event_time DATETIME(3) NOT NULL,
  risk_level ENUM('high','medium','low') NOT NULL,
  payload_ref VARCHAR(256) DEFAULT NULL,
  INDEX idx_clue_person_time (person_id, event_time),
  CONSTRAINT fk_clue_person FOREIGN KEY (person_id) REFERENCES person_profile(person_id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS risk_snapshot (
  snapshot_id BIGINT UNSIGNED PRIMARY KEY,
  person_id VARCHAR(32) NOT NULL,
  rule_score DECIMAL(6,2) NOT NULL,
  model_score DECIMAL(6,2) NOT NULL,
  final_level ENUM('high','medium','low') NOT NULL,
  explain_json JSON DEFAULT NULL,
  ts DATETIME(3) NOT NULL,
  INDEX idx_risk_person_ts (person_id, ts),
  CONSTRAINT fk_risk_person FOREIGN KEY (person_id) REFERENCES person_profile(person_id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS clue_task (
  task_id VARCHAR(32) PRIMARY KEY,
  clue_id VARCHAR(32) NOT NULL,
  status ENUM('pending','in_progress','reported','closed') NOT NULL,
  assignee VARCHAR(32) NOT NULL,
  due_at DATETIME(3) DEFAULT NULL,
  decision VARCHAR(64) DEFAULT NULL,
  decision_reason VARCHAR(255) DEFAULT NULL,
  closed_at DATETIME(3) DEFAULT NULL,
  INDEX idx_task_status_assignee_due (status, assignee, due_at),
  CONSTRAINT fk_task_clue FOREIGN KEY (clue_id) REFERENCES clue_event(clue_id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS dialogue_session (
  session_id VARCHAR(32) PRIMARY KEY,
  operator_id VARCHAR(32) NOT NULL,
  scope_json JSON DEFAULT NULL,
  started_at DATETIME(3) NOT NULL,
  ended_at DATETIME(3) DEFAULT NULL
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS dialogue_message (
  msg_id BIGINT UNSIGNED PRIMARY KEY,
  session_id VARCHAR(32) NOT NULL,
  role ENUM('user','assistant','system') NOT NULL,
  content TEXT NOT NULL,
  citations_json JSON DEFAULT NULL,
  safety_flags JSON DEFAULT NULL,
  created_at DATETIME(3) NOT NULL,
  INDEX idx_msg_session_time (session_id, created_at),
  CONSTRAINT fk_msg_session FOREIGN KEY (session_id) REFERENCES dialogue_session(session_id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS report_doc (
  report_id VARCHAR(32) PRIMARY KEY,
  report_type ENUM('daily','weekly','case') NOT NULL,
  period_start DATETIME(3) NOT NULL,
  period_end DATETIME(3) NOT NULL,
  content_ref VARCHAR(256) NOT NULL,
  creator_id VARCHAR(32) NOT NULL,
  status ENUM('generating','ready','failed') NOT NULL,
  archived_at DATETIME(3) DEFAULT NULL
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS audit_log (
  log_id BIGINT UNSIGNED PRIMARY KEY,
  operator_id VARCHAR(32) NOT NULL,
  action VARCHAR(64) NOT NULL,
  resource_type VARCHAR(64) NOT NULL,
  resource_id VARCHAR(64) NOT NULL,
  ip VARCHAR(45) NOT NULL,
  ts DATETIME(3) NOT NULL,
  INDEX idx_audit_operator_ts (operator_id, ts)
) ENGINE=InnoDB;
