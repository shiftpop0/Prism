-- MySQL dump 10.13  Distrib 8.4.8, for Win64 (x86_64)
--
-- Host: 127.0.0.1    Database: wxzdb
-- ------------------------------------------------------
-- Server version	8.4.8

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

--
-- Table structure for table `feedback`
--

DROP TABLE IF EXISTS `feedback`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `feedback` (
  `id` varchar(100) NOT NULL COMMENT 'id',
  `feedback_content` varchar(2000) NOT NULL COMMENT '反馈内容',
  `feedback_userId` varchar(100) NOT NULL COMMENT '反馈人',
  `feedback_time` varchar(100) NOT NULL COMMENT '反馈时间',
  `mid` varchar(100) NOT NULL COMMENT '与动态获得的表格id一致',
  `feedback_username` varchar(100) NOT NULL COMMENT 'user名字',
  `appEname` varchar(100) NOT NULL COMMENT 'appEname',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='反馈信息';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `feedback`
--

LOCK TABLES `feedback` WRITE;
/*!40000 ALTER TABLE `feedback` DISABLE KEYS */;
INSERT INTO `feedback` VALUES ('5328cc296dd40317ca0955445bc3a4da','经核查，该峰峰和乐乐系离婚夫妻关系，双方于2026年4月11日经广西人民法院判决离婚，对子女抚养、家庭债务等均进行了判决，目前峰峰暂住天台市大溪镇，乐乐现住广西老家，双方未再次引发纠纷，仅是乐乐发送信息给峰峰让其不要影响小孩读书并尽快将户口迁出。另外，经核查该峰峰在天台辖区内无相关矛盾纠纷报警记录。下一步，由辖区大溪所将峰峰作为矛盾纠纷高危人员录入全维系统加强关注，适时开展劝导、劝离工作，同时对乐乐进入天台进行临控，进一步灵通信息，避免纠纷升级、激化。','2381','2026-04-14 10:06:15','74','谢道强','grjdmxjg'),('d2750ef93abe166fe220384e23f9618a','沈康与莲莲分手已一个多月，莲莲已重新找了一个新的男朋友，但尚未同居。2026年4月14日凌晨沈康酒后，欲找莲莲复合，在莲莲住所附近逗留。后民警找到其后劝慰沈康放弃这段感情，因沈语言表现酒话，故送其醒酒。醒酒后，民警再次劝导沈康，沈表示不会再去打扰张，昨晚的事情比较丢脸，人家有新男朋友了还去找她。张表示为了不被沈康再找到，换个住所。后续将继续关注两人动态。','2381','2026-04-14 14:24:32','77','谢道强','grjdmxjg'),('dd45b8bc88aa59196090fbd2bb728fe7','经核实，该兰兰（住黄岩）和彭春华（664458880766894696，12308982121，黄岩澄江街道1号）之前是男女朋友关系，因彭与多名女子不清不楚，聊天比较暧昧，导致双方分手。目前欧已经不愿和其交往，对方一直纠缠不清，怀疑欧有新男朋友，通过不同途径找其，寻求符合，偶尔会有极端言语，府前所后续进行关注，望黄岩分局予以关注。','2381','2026-04-14 10:04:16','73','谢道强','grjdmxjg');
/*!40000 ALTER TABLE `feedback` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `feedback2nb_tab_grjd_feedback_history`
--

DROP TABLE IF EXISTS `feedback2nb_tab_grjd_feedback_history`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `feedback2nb_tab_grjd_feedback_history` (
  `source_feedback_id` varchar(100) NOT NULL,
  `feedback_id` bigint unsigned NOT NULL,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`source_feedback_id`),
  KEY `idx_feedback_id` (`feedback_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `feedback2nb_tab_grjd_feedback_history`
--

LOCK TABLES `feedback2nb_tab_grjd_feedback_history` WRITE;
/*!40000 ALTER TABLE `feedback2nb_tab_grjd_feedback_history` DISABLE KEYS */;
INSERT INTO `feedback2nb_tab_grjd_feedback_history` VALUES ('5328cc296dd40317ca0955445bc3a4da',1,'2026-04-28 15:34:09'),('d2750ef93abe166fe220384e23f9618a',2,'2026-04-28 15:34:09'),('dd45b8bc88aa59196090fbd2bb728fe7',3,'2026-04-28 15:34:09');
/*!40000 ALTER TABLE `feedback2nb_tab_grjd_feedback_history` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `grjd_distribute`
--

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
  `remark` text,
  `dt` varchar(8) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`clue_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `grjd_distribute`
--

LOCK TABLES `grjd_distribute` WRITE;
/*!40000 ALTER TABLE `grjd_distribute` DISABLE KEYS */;
INSERT INTO `grjd_distribute` VALUES ('12330964780-12358909038-20260401','【学生线索】test','GCL','model1','推送治安','2026-05-17 20:17:05',NULL,NULL);
/*!40000 ALTER TABLE `grjd_distribute` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `grjdmxjg_za`
--

DROP TABLE IF EXISTS `grjdmxjg_za`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `grjdmxjg_za` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT 'id',
  `is_feedback` bit(1) DEFAULT b'0',
  `create_time` datetime NOT NULL,
  `appEname` varchar(50) NOT NULL,
  `jfhm` varchar(500) DEFAULT NULL,
  `jfsfzh` varchar(500) DEFAULT NULL,
  `jfzdrlx` varchar(500) DEFAULT NULL,
  `ddhm` varchar(500) DEFAULT NULL,
  `dfsfzh` varchar(500) DEFAULT NULL,
  `dfzdrlx` varchar(500) DEFAULT NULL,
  `zj` varchar(500) DEFAULT NULL,
  `fz` varchar(500) DEFAULT NULL,
  `jgrq` varchar(500) DEFAULT NULL,
  `fxdj` varchar(500) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=78 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `grjdmxjg_za`
--

LOCK TABLES `grjdmxjg_za` WRITE;
/*!40000 ALTER TABLE `grjdmxjg_za` DISABLE KEYS */;
INSERT INTO `grjdmxjg_za` VALUES (73,_binary '','2026-04-11 07:45:00','grjdmxjg','12325514755','原表身份证号：336004616618113773|原表姓名：兰兰|计算身份证号：336004616618113773|计算姓名：兰兰|车牌号：浙J5H26X|昨日白天区县：椒江区|昨日白天geohash6：wdd74b|昨日白天中文地址：椒江白云工商局|昨日夜间区县：椒江区|昨日夜间geohash6：wdd6fn|昨日夜间中文地址：台州市椒江区椒江葭沚湖璟名都府外打SF|白天常驻区县：椒江区|白天常驻点geohash6：wdd74b|白天常驻点中文地址：椒江白云工商局|夜间常驻区县：椒江区|夜间常驻点geohash6：wdd74m|夜间常驻点中文地址：椒江白云工商局|常用寄件身份： |常用寄件姓名： |常用寄件地址： |最近一次寄件地址： |常用收件身份： |常用收件姓名： |常用收件地址： |最近一次收件地址：','劝离人员','12329146438','身份证号A： |身份证号B： |姓名： |车牌号： |昨日白天区县：黄岩区|昨日白天geohash6：wdd4vu|昨日白天中文地址：土管所三楼|昨日夜间区县：黄岩区|昨日夜间geohash6：wdd4vu|昨日夜间中文地址：土管所三楼|白天常驻区县： |白天常驻点geohash6： |白天常驻点中文地址： |夜间常驻区县： |夜间常驻点geohash6： |夜间常驻点中文地址： |常用寄件身份： |常用寄件姓名： |常用寄件地址： |最近一次寄件地址： |常用收件身份： |常用收件姓名： |常用收件地址： |最近一次收件地址：','','双方在私人关系上存在严重冲突，情绪激烈。\n一方因对方行为感到不满，表现出极端情绪，并威胁采取进一步行动。\n后续，一方打算采取进一步行动。','0.75','20260410','【二级线索】（未匹配条件）'),(74,_binary '','2026-04-13 07:44:00','grjdmxjg','12331646331','原表身份证号：352646150043753880|原表姓名：峰峰|计算身份证号：352646150043753880|计算姓名：锋锋|车牌号： |昨日白天区县：天台市|昨日白天geohash6：wdd60p|昨日白天中文地址：天台市大溪镇大溪翁岙村后山|昨日夜间区县：天台市|昨日夜间geohash6：wdd60p|昨日夜间中文地址：天台市大溪镇大溪翁岙村后山|白天常驻区县：天台市|白天常驻点geohash6：wdd60p|白天常驻点中文地址：天台市大溪镇大溪翁岙村后山|夜间常驻区县：天台市|夜间常驻点geohash6：wdd60p|夜间常驻点中文地址：天台市大溪镇大溪翁岙村后山|常用寄件身份： |常用寄件姓名： |常用寄件地址： |最近一次寄件地址： |常用收件身份： |常用收件姓名： |常用收件地址： |最近一次收件地址：','劝离人员','12354130649','原表身份证号：237709001209304082|原表姓名：乐乐|计算身份证号： |计算姓名： |车牌号： |昨日白天区县： |昨日白天geohash6： |昨日白天中文地址： |昨日夜间区县： |昨日夜间geohash6： |昨日夜间中文地址： |白天常驻区县： |白天常驻点geohash6： |白天常驻点中文地址： |夜间常驻区县： |夜间常驻点geohash6： |夜间常驻点中文地址： |常用寄件身份： |常用寄件姓名： |常用寄件地址： |最近一次寄件地址： |常用收件身份： |常用收件姓名： |常用收件地址： |最近一次收件地址：','劝离人员','双方在子女抚养、债务处理和过往矛盾上存在严重对立。另一方明确拒绝锋锋参与孩子生活，并要求其迁出户口。锋锋则否认部分债务责任，并表现出对抗情绪。\n\n双方曾因婚姻关系产生纠纷，子女抚养权已判归另一方，锋锋的孩子将在特定学校就读。锋锋与另一方之间涉及多笔债务未清偿，相关法律程序已启动。锋锋曾因家庭矛盾与另一方产生冲突，并涉及第三方经济往来。\n\n锋锋表示会通过法律途径处理债务问题，另一方表示将采取法律手段应对锋锋的行为。','0.88','20260412','【一级线索】（未成年人威胁）'),(77,_binary '','2026-04-14 07:46:00','grjdmxjg','12347615159','原表身份证号：411226016896854145|原表姓名：莲莲|计算身份证号：411226016896854145|计算姓名：莲莲|车牌号： |昨日白天区县：天台市|昨日白天geohash6：wdd3cq|昨日白天中文地址：温岭牧屿东新街17号|昨日夜间区县：天台市|昨日夜间geohash6：wdd39g|昨日夜间中文地址：万昌中路与万昌北路交叉口西北150米|白天常驻区县：天台市|白天常驻点geohash6：wdd3cq|白天常驻点中文地址：温岭牧屿东新街17号|夜间常驻区县：天台市|夜间常驻点geohash6：wdd3cq|夜间常驻点中文地址：温岭牧屿东新街17号|常用寄件身份： |常用寄件姓名： |常用寄件地址： |最近一次寄件地址： |常用收件身份： |常用收件姓名： |常用收件地址： |最近一次收件地址：','劝离人员','12333692288','原表身份证号：889661980484326243|原表姓名：沈康|计算身份证号：889661980484326243|计算姓名：沈康|车牌号：浙JF02696|昨日白天区县：天台市|昨日白天geohash6：wdd3cn|昨日白天中文地址：牧西村|昨日夜间区县：天台市|昨日夜间geohash6：wdd3cn|昨日夜间中文地址：牧西村|白天常驻区县：天台市|白天常驻点geohash6：wdd3cn|白天常驻点中文地址：牧西村|夜间常驻区县：天台市|夜间常驻点geohash6：wdd3cn|夜间常驻点中文地址：牧西村|常用寄件身份： |常用寄件姓名： |常用寄件地址： |最近一次寄件地址： |常用收件身份： |常用收件姓名： |常用收件地址： |最近一次收件地址：','劝离人员','双方存在激烈的情绪冲突。\n沈康在莲莲住所附近逗留，莲莲表现出抗拒和困扰。\n后续，沈康打算继续在莲莲住所附近等待。','0.75','20260413','【一级线索】（具体行动和武器威胁）');
/*!40000 ALTER TABLE `grjdmxjg_za` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `nb_tab_grjd_feedback_history`
--

DROP TABLE IF EXISTS `nb_tab_grjd_feedback_history`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `nb_tab_grjd_feedback_history` (
  `feedback_id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `clue_id` varchar(64) NOT NULL,
  `feedback_content` text NOT NULL,
  `feedback_userId` varchar(64) DEFAULT NULL,
  `feedback_username` varchar(64) DEFAULT NULL,
  `remark` text,
  `feedback_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`feedback_id`),
  KEY `idx_feedback_id_time` (`clue_id`,`feedback_time`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `nb_tab_grjd_feedback_history`
--

LOCK TABLES `nb_tab_grjd_feedback_history` WRITE;
/*!40000 ALTER TABLE `nb_tab_grjd_feedback_history` DISABLE KEYS */;
INSERT INTO `nb_tab_grjd_feedback_history` VALUES (1,'12331646331-12354130649-20260412','经核查，该峰峰和乐乐系离婚夫妻关系，双方于2026年4月11日经广西人民法院判决离婚，对子女抚养、家庭债务等均进行了判决，目前峰峰暂住天台市大溪镇，乐乐现住广西老家，双方未再次引发纠纷，仅是乐乐发送信息给峰峰让其不要影响小孩读书并尽快将户口迁出。另外，经核查该峰峰在天台辖区内无相关矛盾纠纷报警记录。下一步，由辖区大溪所将峰峰作为矛盾纠纷高危人员录入全维系统加强关注，适时开展劝导、劝离工作，同时对乐乐进入天台进行临控，进一步灵通信息，避免纠纷升级、激化。','2381','谢道强','','2026-04-14 18:06:15'),(2,'12333692288-12347615159-20260413','沈康与莲莲分手已一个多月，莲莲已重新找了一个新的男朋友，但尚未同居。2026年4月14日凌晨沈康酒后，欲找莲莲复合，在莲莲住所附近逗留。后民警找到其后劝慰沈康放弃这段感情，因沈语言表现酒话，故送其醒酒。醒酒后，民警再次劝导沈康，沈表示不会再去打扰张，昨晚的事情比较丢脸，人家有新男朋友了还去找她。张表示为了不被沈康再找到，换个住所。后续将继续关注两人动态。','2381','谢道强','','2026-04-14 22:24:32'),(3,'12325514755-12329146438-20260410','经核实，该兰兰（住黄岩）和彭春华（664458880766894696，12308982121，黄岩澄江街道1号）之前是男女朋友关系，因彭与多名女子不清不楚，聊天比较暧昧，导致双方分手。目前欧已经不愿和其交往，对方一直纠缠不清，怀疑欧有新男朋友，通过不同途径找其，寻求符合，偶尔会有极端言语，府前所后续进行关注，望黄岩分局予以关注。','2381','谢道强','','2026-04-14 18:04:16'),(4,'12335309795-12379558908-20260401','test123','system','系统','','2026-05-17 20:12:41');
/*!40000 ALTER TABLE `nb_tab_grjd_feedback_history` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `nb_tab_grjd_workflow_state`
--

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `nb_tab_grjd_workflow_state`
--

LOCK TABLES `nb_tab_grjd_workflow_state` WRITE;
/*!40000 ALTER TABLE `nb_tab_grjd_workflow_state` DISABLE KEYS */;
INSERT INTO `nb_tab_grjd_workflow_state` VALUES ('12300704351-12396919584-20260401','待核查',NULL,NULL,NULL,'','2026-05-17 20:21:05'),('12325514755-12329146438-20260410','已反馈',NULL,NULL,NULL,'','2026-05-14 10:31:05'),('12330964780-12358909038-20260401','待核查','【学生线索】test',NULL,NULL,'推送治安','2026-05-17 20:21:05'),('12331646331-12354130649-20260412','已反馈',NULL,NULL,NULL,'','2026-05-14 10:31:05'),('12331661479-12379472013-20260401','待核查',NULL,NULL,NULL,'','2026-05-17 20:21:05'),('12333692288-12347615159-20260413','已反馈',NULL,NULL,NULL,'','2026-05-14 10:31:05'),('12335309795-12379558908-20260401','已反馈',NULL,NULL,NULL,'','2026-05-17 20:21:05');
/*!40000 ALTER TABLE `nb_tab_grjd_workflow_state` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping routines for database 'wxzdb'
--
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-05-17 20:41:50

