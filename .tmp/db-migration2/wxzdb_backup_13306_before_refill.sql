
/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;
DROP TABLE IF EXISTS `feedback`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `feedback` (
  `id` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `feedback_content` varchar(2000) COLLATE utf8mb4_unicode_ci NOT NULL,
  `feedback_userId` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `feedback_time` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `mid` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `feedback_username` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `appEname` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `feedback` WRITE;
/*!40000 ALTER TABLE `feedback` DISABLE KEYS */;
/*!40000 ALTER TABLE `feedback` ENABLE KEYS */;
UNLOCK TABLES;
DROP TABLE IF EXISTS `feedback2nb_tab_grjd_feedback_history`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `feedback2nb_tab_grjd_feedback_history` (
  `source_feedback_id` varchar(100) NOT NULL,
  `feedback_id` bigint(20) unsigned NOT NULL,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`source_feedback_id`),
  KEY `idx_feedback_id` (`feedback_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `feedback2nb_tab_grjd_feedback_history` WRITE;
/*!40000 ALTER TABLE `feedback2nb_tab_grjd_feedback_history` DISABLE KEYS */;
INSERT INTO `feedback2nb_tab_grjd_feedback_history` VALUES ('5328cc296dd40317ca0955445bc3a4da',1,'2026-04-28 15:34:09'),('d2750ef93abe166fe220384e23f9618a',2,'2026-04-28 15:34:09'),('dd45b8bc88aa59196090fbd2bb728fe7',3,'2026-04-28 15:34:09');
/*!40000 ALTER TABLE `feedback2nb_tab_grjd_feedback_history` ENABLE KEYS */;
UNLOCK TABLES;
DROP TABLE IF EXISTS `grjd_distribute`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `grjd_distribute` (
  `clue_id` varchar(64) NOT NULL,
  `level` varchar(128) NOT NULL,
  `assign_to` varchar(64) NOT NULL,
  `model_name` varchar(128) NOT NULL,
  `tag` varchar(64) NOT NULL,
  `assigned_time` datetime NOT NULL,
  `dt` date DEFAULT NULL,
  `remark` text,
  PRIMARY KEY (`clue_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `grjd_distribute` WRITE;
/*!40000 ALTER TABLE `grjd_distribute` DISABLE KEYS */;
INSERT INTO `grjd_distribute` VALUES ('12330964780-12358909038-20260401','??????test','GCL','model1','????','2026-05-17 20:17:05',NULL,NULL);
/*!40000 ALTER TABLE `grjd_distribute` ENABLE KEYS */;
UNLOCK TABLES;
DROP TABLE IF EXISTS `nb_tab_grjd_feedback_history`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `nb_tab_grjd_feedback_history` (
  `feedback_id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `clue_id` varchar(64) NOT NULL,
  `feedback_content` text NOT NULL,
  `feedback_userId` varchar(64) DEFAULT NULL,
  `feedback_username` varchar(64) DEFAULT NULL,
  `remark` text,
  `feedback_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`feedback_id`),
  KEY `idx_feedback_id_time` (`clue_id`,`feedback_time`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `nb_tab_grjd_feedback_history` WRITE;
/*!40000 ALTER TABLE `nb_tab_grjd_feedback_history` DISABLE KEYS */;
INSERT INTO `nb_tab_grjd_feedback_history` VALUES (1,'12331646331-12354130649-20260412','?????????????????????2026?4?11??????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????','2381','???','','2026-04-14 18:06:15'),(2,'12333692288-12347615159-20260413','??????????????????????????????????2026?4?14???????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????','2381','???','','2026-04-14 22:24:32'),(3,'12325514755-12329146438-20260410','?????????????????664458880766894696?12308982121???????1???????????????????????????????????????????????????????????????????????????????????????????????????????????????','2381','???','','2026-04-14 18:04:16'),(4,'12335309795-12379558908-20260401','test123','system','??','','2026-05-17 20:12:41');
/*!40000 ALTER TABLE `nb_tab_grjd_feedback_history` ENABLE KEYS */;
UNLOCK TABLES;
DROP TABLE IF EXISTS `nb_tab_grjd_workflow_state`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `nb_tab_grjd_workflow_state` (
  `id` varchar(64) NOT NULL,
  `status` varchar(16) NOT NULL DEFAULT '待核查',
  `level` varchar(32) DEFAULT NULL,
  `remark` text,
  `mark_tag` varchar(64) DEFAULT NULL,
  `distribute` varchar(64) NOT NULL DEFAULT '',
  `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `nb_tab_grjd_workflow_state` WRITE;
/*!40000 ALTER TABLE `nb_tab_grjd_workflow_state` DISABLE KEYS */;
INSERT INTO `nb_tab_grjd_workflow_state` VALUES ('12300704351-12396919584-20260401','???',NULL,NULL,NULL,'','2026-05-17 20:21:05'),('12325514755-12329146438-20260410','已反馈',NULL,NULL,NULL,'','2026-05-18 00:39:11'),('12330964780-12358909038-20260401','???','??????test',NULL,NULL,'????','2026-05-17 20:21:05'),('12331646331-12354130649-20260412','已反馈',NULL,NULL,NULL,'','2026-05-18 00:39:11'),('12331661479-12379472013-20260401','???',NULL,NULL,NULL,'','2026-05-17 20:21:05'),('12333692288-12347615159-20260413','已反馈',NULL,NULL,NULL,'','2026-05-18 00:39:11'),('12335309795-12379558908-20260401','已反馈',NULL,NULL,NULL,'','2026-05-18 00:39:11');
/*!40000 ALTER TABLE `nb_tab_grjd_workflow_state` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

