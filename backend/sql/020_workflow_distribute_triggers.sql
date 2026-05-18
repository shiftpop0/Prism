-- Prism: grjd_distribute -> nb_tab_grjd_workflow_state trigger sync script
-- Usage:
-- 1) USE wxzdb;
-- 2) SOURCE backend/sql/020_workflow_distribute_triggers.sql;

-- One-time backfill to align historical data.
INSERT INTO nb_tab_grjd_workflow_state (id, status, level, distribute)
SELECT clue_id, '待核查', level, tag
FROM grjd_distribute
ON DUPLICATE KEY UPDATE
  level = VALUES(level),
  distribute = VALUES(distribute);

UPDATE nb_tab_grjd_workflow_state w
LEFT JOIN grjd_distribute d ON w.id = d.clue_id
SET w.distribute = COALESCE(d.tag, '');

UPDATE nb_tab_grjd_workflow_state w
JOIN grjd_distribute d ON w.id = d.clue_id
SET w.level = d.level;

DROP TRIGGER IF EXISTS trg_grjd_distribute_ai;
DROP TRIGGER IF EXISTS trg_grjd_distribute_au;
DROP TRIGGER IF EXISTS trg_grjd_distribute_ad;

DELIMITER $$

CREATE TRIGGER trg_grjd_distribute_ai
AFTER INSERT ON grjd_distribute
FOR EACH ROW
BEGIN
  INSERT INTO nb_tab_grjd_workflow_state (id, status, level, distribute)
  VALUES (NEW.clue_id, '待核查', NEW.level, COALESCE(NEW.tag, ''))
  ON DUPLICATE KEY UPDATE
    level = NEW.level,
    distribute = COALESCE(NEW.tag, '');
END $$

CREATE TRIGGER trg_grjd_distribute_au
AFTER UPDATE ON grjd_distribute
FOR EACH ROW
BEGIN
  IF OLD.clue_id <> NEW.clue_id THEN
    UPDATE nb_tab_grjd_workflow_state
    SET distribute = ''
    WHERE id = OLD.clue_id;
  END IF;

  INSERT INTO nb_tab_grjd_workflow_state (id, status, level, distribute)
  VALUES (NEW.clue_id, '待核查', NEW.level, COALESCE(NEW.tag, ''))
  ON DUPLICATE KEY UPDATE
    level = NEW.level,
    distribute = COALESCE(NEW.tag, '');
END $$

CREATE TRIGGER trg_grjd_distribute_ad
AFTER DELETE ON grjd_distribute
FOR EACH ROW
BEGIN
  UPDATE nb_tab_grjd_workflow_state
  SET distribute = ''
  WHERE id = OLD.clue_id;
END $$

DELIMITER ;

-- Health check:
-- SHOW TRIGGERS LIKE 'grjd_distribute';
