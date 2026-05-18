
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
  `id` varchar(100) NOT NULL COMMENT 'id',
  `feedback_content` varchar(2000) NOT NULL COMMENT '鍙嶉鍐呭',
  `feedback_userId` varchar(100) NOT NULL COMMENT '鍙嶉浜?,
  `feedback_time` varchar(100) NOT NULL COMMENT '鍙嶉鏃堕棿',
  `mid` varchar(100) NOT NULL COMMENT '涓庡姩鎬佽幏寰楃殑琛ㄦ牸id涓€鑷?,
  `feedback_username` varchar(100) NOT NULL COMMENT 'user鍚嶅瓧',
  `appEname` varchar(100) NOT NULL COMMENT 'appEname',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='鍙嶉淇℃伅';
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `feedback` WRITE;
/*!40000 ALTER TABLE `feedback` DISABLE KEYS */;
INSERT INTO `feedback` VALUES ('5328cc296dd40317ca0955445bc3a4da','缁忔牳鏌ワ紝璇ュ嘲宄板拰涔愪箰绯荤濠氬か濡诲叧绯伙紝鍙屾柟浜?026骞?鏈?1鏃ョ粡骞胯タ浜烘皯娉曢櫌鍒ゅ喅绂诲锛屽瀛愬コ鎶氬吇銆佸搴€哄姟绛夊潎杩涜浜嗗垽鍐筹紝鐩墠宄板嘲鏆備綇澶╁彴甯傚ぇ婧晣锛屼箰涔愮幇浣忓箍瑗胯€佸锛屽弻鏂规湭鍐嶆寮曞彂绾犵悍锛屼粎鏄箰涔愬彂閫佷俊鎭粰宄板嘲璁╁叾涓嶈褰卞搷灏忓璇讳功骞跺敖蹇皢鎴峰彛杩佸嚭銆傚彟澶栵紝缁忔牳鏌ヨ宄板嘲鍦ㄥぉ鍙拌緰鍖哄唴鏃犵浉鍏崇煕鐩剧籂绾锋姤璀﹁褰曘€備笅涓€姝ワ紝鐢辫緰鍖哄ぇ婧墍灏嗗嘲宄颁綔涓虹煕鐩剧籂绾烽珮鍗变汉鍛樺綍鍏ュ叏缁寸郴缁熷姞寮哄叧娉紝閫傛椂寮€灞曞姖瀵笺€佸姖绂诲伐浣滐紝鍚屾椂瀵逛箰涔愯繘鍏ュぉ鍙拌繘琛屼复鎺э紝杩涗竴姝ョ伒閫氫俊鎭紝閬垮厤绾犵悍鍗囩骇銆佹縺鍖栥€?,'2381','2026-04-14 10:06:15','74','璋㈤亾寮?,'grjdmxjg'),('d2750ef93abe166fe220384e23f9618a','娌堝悍涓庤幉鑾插垎鎵嬪凡涓€涓鏈堬紝鑾茶幉宸查噸鏂版壘浜嗕竴涓柊鐨勭敺鏈嬪弸锛屼絾灏氭湭鍚屽眳銆?026骞?鏈?4鏃ュ噷鏅ㄦ矆搴烽厭鍚庯紝娆叉壘鑾茶幉澶嶅悎锛屽湪鑾茶幉浣忔墍闄勮繎閫楃暀銆傚悗姘戣鎵惧埌鍏跺悗鍔濇叞娌堝悍鏀惧純杩欐鎰熸儏锛屽洜娌堣瑷€琛ㄧ幇閰掕瘽锛屾晠閫佸叾閱掗厭銆傞啋閰掑悗锛屾皯璀﹀啀娆″姖瀵兼矆搴凤紝娌堣〃绀轰笉浼氬啀鍘绘墦鎵板紶锛屾槰鏅氱殑浜嬫儏姣旇緝涓㈣劯锛屼汉瀹舵湁鏂扮敺鏈嬪弸浜嗚繕鍘绘壘濂广€傚紶琛ㄧず涓轰簡涓嶈娌堝悍鍐嶆壘鍒帮紝鎹釜浣忔墍銆傚悗缁皢缁х画鍏虫敞涓や汉鍔ㄦ€併€?,'2381','2026-04-14 14:24:32','77','璋㈤亾寮?,'grjdmxjg'),('dd45b8bc88aa59196090fbd2bb728fe7','缁忔牳瀹烇紝璇ュ叞鍏帮紙浣忛粍宀╋級鍜屽江鏄ュ崕锛?64458880766894696锛?2308982121锛岄粍宀╂緞姹熻閬?鍙凤級涔嬪墠鏄敺濂虫湅鍙嬪叧绯伙紝鍥犲江涓庡鍚嶅コ瀛愪笉娓呬笉妤氾紝鑱婂ぉ姣旇緝鏆ф槯锛屽鑷村弻鏂瑰垎鎵嬨€傜洰鍓嶆宸茬粡涓嶆効鍜屽叾浜ゅ線锛屽鏂逛竴鐩寸籂缂犱笉娓咃紝鎬€鐤戞鏈夋柊鐢锋湅鍙嬶紝閫氳繃涓嶅悓閫斿緞鎵惧叾锛屽姹傜鍚堬紝鍋跺皵浼氭湁鏋佺瑷€璇紝搴滃墠鎵€鍚庣画杩涜鍏虫敞锛屾湜榛勫博鍒嗗眬浜堜互鍏虫敞銆?,'2381','2026-04-14 10:04:16','73','璋㈤亾寮?,'grjdmxjg');
/*!40000 ALTER TABLE `feedback` ENABLE KEYS */;
UNLOCK TABLES;
DROP TABLE IF EXISTS `feedback2nb_tab_grjd_feedback_history`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `feedback2nb_tab_grjd_feedback_history` (
  `source_feedback_id` varchar(100) NOT NULL,
  `feedback_id` bigint unsigned NOT NULL,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`source_feedback_id`),
  KEY `idx_feedback_id` (`feedback_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
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
  `remark` text,
  `dt` varchar(8) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  PRIMARY KEY (`clue_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `grjd_distribute` WRITE;
/*!40000 ALTER TABLE `grjd_distribute` DISABLE KEYS */;
INSERT INTO `grjd_distribute` VALUES ('12330964780-12358909038-20260401','銆愬鐢熺嚎绱€憈est','GCL','model1','鎺ㄩ€佹不瀹?,'2026-05-17 20:17:05',NULL,NULL);
/*!40000 ALTER TABLE `grjd_distribute` ENABLE KEYS */;
UNLOCK TABLES;
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
) ENGINE=InnoDB AUTO_INCREMENT=78 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `grjdmxjg_za` WRITE;
/*!40000 ALTER TABLE `grjdmxjg_za` DISABLE KEYS */;
INSERT INTO `grjdmxjg_za` VALUES (73,_binary '','2026-04-11 07:45:00','grjdmxjg','12325514755','鍘熻〃韬唤璇佸彿锛?36004616618113773|鍘熻〃濮撳悕锛氬叞鍏皘璁＄畻韬唤璇佸彿锛?36004616618113773|璁＄畻濮撳悕锛氬叞鍏皘杞︾墝鍙凤細娴橨5H26X|鏄ㄦ棩鐧藉ぉ鍖哄幙锛氭姹熷尯|鏄ㄦ棩鐧藉ぉgeohash6锛歸dd74b|鏄ㄦ棩鐧藉ぉ涓枃鍦板潃锛氭姹熺櫧浜戝伐鍟嗗眬|鏄ㄦ棩澶滈棿鍖哄幙锛氭姹熷尯|鏄ㄦ棩澶滈棿geohash6锛歸dd6fn|鏄ㄦ棩澶滈棿涓枃鍦板潃锛氬彴宸炲競妞掓睙鍖烘姹熻懎娌氭箹鐠熷悕閮藉簻澶栨墦SF|鐧藉ぉ甯搁┗鍖哄幙锛氭姹熷尯|鐧藉ぉ甯搁┗鐐筭eohash6锛歸dd74b|鐧藉ぉ甯搁┗鐐逛腑鏂囧湴鍧€锛氭姹熺櫧浜戝伐鍟嗗眬|澶滈棿甯搁┗鍖哄幙锛氭姹熷尯|澶滈棿甯搁┗鐐筭eohash6锛歸dd74m|澶滈棿甯搁┗鐐逛腑鏂囧湴鍧€锛氭姹熺櫧浜戝伐鍟嗗眬|甯哥敤瀵勪欢韬唤锛?|甯哥敤瀵勪欢濮撳悕锛?|甯哥敤瀵勪欢鍦板潃锛?|鏈€杩戜竴娆″瘎浠跺湴鍧€锛?|甯哥敤鏀朵欢韬唤锛?|甯哥敤鏀朵欢濮撳悕锛?|甯哥敤鏀朵欢鍦板潃锛?|鏈€杩戜竴娆℃敹浠跺湴鍧€锛?,'鍔濈浜哄憳','12329146438','韬唤璇佸彿A锛?|韬唤璇佸彿B锛?|濮撳悕锛?|杞︾墝鍙凤細 |鏄ㄦ棩鐧藉ぉ鍖哄幙锛氶粍宀╁尯|鏄ㄦ棩鐧藉ぉgeohash6锛歸dd4vu|鏄ㄦ棩鐧藉ぉ涓枃鍦板潃锛氬湡绠℃墍涓夋ゼ|鏄ㄦ棩澶滈棿鍖哄幙锛氶粍宀╁尯|鏄ㄦ棩澶滈棿geohash6锛歸dd4vu|鏄ㄦ棩澶滈棿涓枃鍦板潃锛氬湡绠℃墍涓夋ゼ|鐧藉ぉ甯搁┗鍖哄幙锛?|鐧藉ぉ甯搁┗鐐筭eohash6锛?|鐧藉ぉ甯搁┗鐐逛腑鏂囧湴鍧€锛?|澶滈棿甯搁┗鍖哄幙锛?|澶滈棿甯搁┗鐐筭eohash6锛?|澶滈棿甯搁┗鐐逛腑鏂囧湴鍧€锛?|甯哥敤瀵勪欢韬唤锛?|甯哥敤瀵勪欢濮撳悕锛?|甯哥敤瀵勪欢鍦板潃锛?|鏈€杩戜竴娆″瘎浠跺湴鍧€锛?|甯哥敤鏀朵欢韬唤锛?|甯哥敤鏀朵欢濮撳悕锛?|甯哥敤鏀朵欢鍦板潃锛?|鏈€杩戜竴娆℃敹浠跺湴鍧€锛?,'','鍙屾柟鍦ㄧ浜哄叧绯讳笂瀛樺湪涓ラ噸鍐茬獊锛屾儏缁縺鐑堛€俓n涓€鏂瑰洜瀵规柟琛屼负鎰熷埌涓嶆弧锛岃〃鐜板嚭鏋佺鎯呯华锛屽苟濞佽儊閲囧彇杩涗竴姝ヨ鍔ㄣ€俓n鍚庣画锛屼竴鏂规墦绠楅噰鍙栬繘涓€姝ヨ鍔ㄣ€?,'0.75','20260410','銆愪簩绾х嚎绱€戯紙鏈尮閰嶆潯浠讹級'),(74,_binary '','2026-04-13 07:44:00','grjdmxjg','12331646331','鍘熻〃韬唤璇佸彿锛?52646150043753880|鍘熻〃濮撳悕锛氬嘲宄皘璁＄畻韬唤璇佸彿锛?52646150043753880|璁＄畻濮撳悕锛氶攱閿媩杞︾墝鍙凤細 |鏄ㄦ棩鐧藉ぉ鍖哄幙锛氬ぉ鍙板競|鏄ㄦ棩鐧藉ぉgeohash6锛歸dd60p|鏄ㄦ棩鐧藉ぉ涓枃鍦板潃锛氬ぉ鍙板競澶ф邯闀囧ぇ婧縼宀欐潙鍚庡北|鏄ㄦ棩澶滈棿鍖哄幙锛氬ぉ鍙板競|鏄ㄦ棩澶滈棿geohash6锛歸dd60p|鏄ㄦ棩澶滈棿涓枃鍦板潃锛氬ぉ鍙板競澶ф邯闀囧ぇ婧縼宀欐潙鍚庡北|鐧藉ぉ甯搁┗鍖哄幙锛氬ぉ鍙板競|鐧藉ぉ甯搁┗鐐筭eohash6锛歸dd60p|鐧藉ぉ甯搁┗鐐逛腑鏂囧湴鍧€锛氬ぉ鍙板競澶ф邯闀囧ぇ婧縼宀欐潙鍚庡北|澶滈棿甯搁┗鍖哄幙锛氬ぉ鍙板競|澶滈棿甯搁┗鐐筭eohash6锛歸dd60p|澶滈棿甯搁┗鐐逛腑鏂囧湴鍧€锛氬ぉ鍙板競澶ф邯闀囧ぇ婧縼宀欐潙鍚庡北|甯哥敤瀵勪欢韬唤锛?|甯哥敤瀵勪欢濮撳悕锛?|甯哥敤瀵勪欢鍦板潃锛?|鏈€杩戜竴娆″瘎浠跺湴鍧€锛?|甯哥敤鏀朵欢韬唤锛?|甯哥敤鏀朵欢濮撳悕锛?|甯哥敤鏀朵欢鍦板潃锛?|鏈€杩戜竴娆℃敹浠跺湴鍧€锛?,'鍔濈浜哄憳','12354130649','鍘熻〃韬唤璇佸彿锛?37709001209304082|鍘熻〃濮撳悕锛氫箰涔恷璁＄畻韬唤璇佸彿锛?|璁＄畻濮撳悕锛?|杞︾墝鍙凤細 |鏄ㄦ棩鐧藉ぉ鍖哄幙锛?|鏄ㄦ棩鐧藉ぉgeohash6锛?|鏄ㄦ棩鐧藉ぉ涓枃鍦板潃锛?|鏄ㄦ棩澶滈棿鍖哄幙锛?|鏄ㄦ棩澶滈棿geohash6锛?|鏄ㄦ棩澶滈棿涓枃鍦板潃锛?|鐧藉ぉ甯搁┗鍖哄幙锛?|鐧藉ぉ甯搁┗鐐筭eohash6锛?|鐧藉ぉ甯搁┗鐐逛腑鏂囧湴鍧€锛?|澶滈棿甯搁┗鍖哄幙锛?|澶滈棿甯搁┗鐐筭eohash6锛?|澶滈棿甯搁┗鐐逛腑鏂囧湴鍧€锛?|甯哥敤瀵勪欢韬唤锛?|甯哥敤瀵勪欢濮撳悕锛?|甯哥敤瀵勪欢鍦板潃锛?|鏈€杩戜竴娆″瘎浠跺湴鍧€锛?|甯哥敤鏀朵欢韬唤锛?|甯哥敤鏀朵欢濮撳悕锛?|甯哥敤鏀朵欢鍦板潃锛?|鏈€杩戜竴娆℃敹浠跺湴鍧€锛?,'鍔濈浜哄憳','鍙屾柟鍦ㄥ瓙濂虫姎鍏汇€佸€哄姟澶勭悊鍜岃繃寰€鐭涚浘涓婂瓨鍦ㄤ弗閲嶅绔嬨€傚彟涓€鏂规槑纭嫆缁濋攱閿嬪弬涓庡瀛愮敓娲伙紝骞惰姹傚叾杩佸嚭鎴峰彛銆傞攱閿嬪垯鍚﹁閮ㄥ垎鍊哄姟璐ｄ换锛屽苟琛ㄧ幇鍑哄鎶楁儏缁€俓n\n鍙屾柟鏇惧洜濠氬Щ鍏崇郴浜х敓绾犵悍锛屽瓙濂虫姎鍏绘潈宸插垽褰掑彟涓€鏂癸紝閿嬮攱鐨勫瀛愬皢鍦ㄧ壒瀹氬鏍″氨璇汇€傞攱閿嬩笌鍙︿竴鏂逛箣闂存秹鍙婂绗斿€哄姟鏈竻鍋匡紝鐩稿叧娉曞緥绋嬪簭宸插惎鍔ㄣ€傞攱閿嬫浘鍥犲搴煕鐩句笌鍙︿竴鏂逛骇鐢熷啿绐侊紝骞舵秹鍙婄涓夋柟缁忔祹寰€鏉ャ€俓n\n閿嬮攱琛ㄧず浼氶€氳繃娉曞緥閫斿緞澶勭悊鍊哄姟闂锛屽彟涓€鏂硅〃绀哄皢閲囧彇娉曞緥鎵嬫搴斿閿嬮攱鐨勮涓恒€?,'0.88','20260412','銆愪竴绾х嚎绱€戯紙鏈垚骞翠汉濞佽儊锛?),(77,_binary '','2026-04-14 07:46:00','grjdmxjg','12347615159','鍘熻〃韬唤璇佸彿锛?11226016896854145|鍘熻〃濮撳悕锛氳幉鑾瞸璁＄畻韬唤璇佸彿锛?11226016896854145|璁＄畻濮撳悕锛氳幉鑾瞸杞︾墝鍙凤細 |鏄ㄦ棩鐧藉ぉ鍖哄幙锛氬ぉ鍙板競|鏄ㄦ棩鐧藉ぉgeohash6锛歸dd3cq|鏄ㄦ棩鐧藉ぉ涓枃鍦板潃锛氭俯宀墽灞夸笢鏂拌17鍙穦鏄ㄦ棩澶滈棿鍖哄幙锛氬ぉ鍙板競|鏄ㄦ棩澶滈棿geohash6锛歸dd39g|鏄ㄦ棩澶滈棿涓枃鍦板潃锛氫竾鏄屼腑璺笌涓囨槍鍖楄矾浜ゅ弶鍙ｈタ鍖?50绫硘鐧藉ぉ甯搁┗鍖哄幙锛氬ぉ鍙板競|鐧藉ぉ甯搁┗鐐筭eohash6锛歸dd3cq|鐧藉ぉ甯搁┗鐐逛腑鏂囧湴鍧€锛氭俯宀墽灞夸笢鏂拌17鍙穦澶滈棿甯搁┗鍖哄幙锛氬ぉ鍙板競|澶滈棿甯搁┗鐐筭eohash6锛歸dd3cq|澶滈棿甯搁┗鐐逛腑鏂囧湴鍧€锛氭俯宀墽灞夸笢鏂拌17鍙穦甯哥敤瀵勪欢韬唤锛?|甯哥敤瀵勪欢濮撳悕锛?|甯哥敤瀵勪欢鍦板潃锛?|鏈€杩戜竴娆″瘎浠跺湴鍧€锛?|甯哥敤鏀朵欢韬唤锛?|甯哥敤鏀朵欢濮撳悕锛?|甯哥敤鏀朵欢鍦板潃锛?|鏈€杩戜竴娆℃敹浠跺湴鍧€锛?,'鍔濈浜哄憳','12333692288','鍘熻〃韬唤璇佸彿锛?89661980484326243|鍘熻〃濮撳悕锛氭矆搴穦璁＄畻韬唤璇佸彿锛?89661980484326243|璁＄畻濮撳悕锛氭矆搴穦杞︾墝鍙凤細娴橨F02696|鏄ㄦ棩鐧藉ぉ鍖哄幙锛氬ぉ鍙板競|鏄ㄦ棩鐧藉ぉgeohash6锛歸dd3cn|鏄ㄦ棩鐧藉ぉ涓枃鍦板潃锛氱墽瑗挎潙|鏄ㄦ棩澶滈棿鍖哄幙锛氬ぉ鍙板競|鏄ㄦ棩澶滈棿geohash6锛歸dd3cn|鏄ㄦ棩澶滈棿涓枃鍦板潃锛氱墽瑗挎潙|鐧藉ぉ甯搁┗鍖哄幙锛氬ぉ鍙板競|鐧藉ぉ甯搁┗鐐筭eohash6锛歸dd3cn|鐧藉ぉ甯搁┗鐐逛腑鏂囧湴鍧€锛氱墽瑗挎潙|澶滈棿甯搁┗鍖哄幙锛氬ぉ鍙板競|澶滈棿甯搁┗鐐筭eohash6锛歸dd3cn|澶滈棿甯搁┗鐐逛腑鏂囧湴鍧€锛氱墽瑗挎潙|甯哥敤瀵勪欢韬唤锛?|甯哥敤瀵勪欢濮撳悕锛?|甯哥敤瀵勪欢鍦板潃锛?|鏈€杩戜竴娆″瘎浠跺湴鍧€锛?|甯哥敤鏀朵欢韬唤锛?|甯哥敤鏀朵欢濮撳悕锛?|甯哥敤鏀朵欢鍦板潃锛?|鏈€杩戜竴娆℃敹浠跺湴鍧€锛?,'鍔濈浜哄憳','鍙屾柟瀛樺湪婵€鐑堢殑鎯呯华鍐茬獊銆俓n娌堝悍鍦ㄨ幉鑾蹭綇鎵€闄勮繎閫楃暀锛岃幉鑾茶〃鐜板嚭鎶楁嫆鍜屽洶鎵般€俓n鍚庣画锛屾矆搴锋墦绠楃户缁湪鑾茶幉浣忔墍闄勮繎绛夊緟銆?,'0.75','20260413','銆愪竴绾х嚎绱€戯紙鍏蜂綋琛屽姩鍜屾鍣ㄥ▉鑳侊級');
/*!40000 ALTER TABLE `grjdmxjg_za` ENABLE KEYS */;
UNLOCK TABLES;
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
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `nb_tab_grjd_feedback_history` WRITE;
/*!40000 ALTER TABLE `nb_tab_grjd_feedback_history` DISABLE KEYS */;
INSERT INTO `nb_tab_grjd_feedback_history` VALUES (1,'12331646331-12354130649-20260412','缁忔牳鏌ワ紝璇ュ嘲宄板拰涔愪箰绯荤濠氬か濡诲叧绯伙紝鍙屾柟浜?026骞?鏈?1鏃ョ粡骞胯タ浜烘皯娉曢櫌鍒ゅ喅绂诲锛屽瀛愬コ鎶氬吇銆佸搴€哄姟绛夊潎杩涜浜嗗垽鍐筹紝鐩墠宄板嘲鏆備綇澶╁彴甯傚ぇ婧晣锛屼箰涔愮幇浣忓箍瑗胯€佸锛屽弻鏂规湭鍐嶆寮曞彂绾犵悍锛屼粎鏄箰涔愬彂閫佷俊鎭粰宄板嘲璁╁叾涓嶈褰卞搷灏忓璇讳功骞跺敖蹇皢鎴峰彛杩佸嚭銆傚彟澶栵紝缁忔牳鏌ヨ宄板嘲鍦ㄥぉ鍙拌緰鍖哄唴鏃犵浉鍏崇煕鐩剧籂绾锋姤璀﹁褰曘€備笅涓€姝ワ紝鐢辫緰鍖哄ぇ婧墍灏嗗嘲宄颁綔涓虹煕鐩剧籂绾烽珮鍗变汉鍛樺綍鍏ュ叏缁寸郴缁熷姞寮哄叧娉紝閫傛椂寮€灞曞姖瀵笺€佸姖绂诲伐浣滐紝鍚屾椂瀵逛箰涔愯繘鍏ュぉ鍙拌繘琛屼复鎺э紝杩涗竴姝ョ伒閫氫俊鎭紝閬垮厤绾犵悍鍗囩骇銆佹縺鍖栥€?,'2381','璋㈤亾寮?,'','2026-04-14 18:06:15'),(2,'12333692288-12347615159-20260413','娌堝悍涓庤幉鑾插垎鎵嬪凡涓€涓鏈堬紝鑾茶幉宸查噸鏂版壘浜嗕竴涓柊鐨勭敺鏈嬪弸锛屼絾灏氭湭鍚屽眳銆?026骞?鏈?4鏃ュ噷鏅ㄦ矆搴烽厭鍚庯紝娆叉壘鑾茶幉澶嶅悎锛屽湪鑾茶幉浣忔墍闄勮繎閫楃暀銆傚悗姘戣鎵惧埌鍏跺悗鍔濇叞娌堝悍鏀惧純杩欐鎰熸儏锛屽洜娌堣瑷€琛ㄧ幇閰掕瘽锛屾晠閫佸叾閱掗厭銆傞啋閰掑悗锛屾皯璀﹀啀娆″姖瀵兼矆搴凤紝娌堣〃绀轰笉浼氬啀鍘绘墦鎵板紶锛屾槰鏅氱殑浜嬫儏姣旇緝涓㈣劯锛屼汉瀹舵湁鏂扮敺鏈嬪弸浜嗚繕鍘绘壘濂广€傚紶琛ㄧず涓轰簡涓嶈娌堝悍鍐嶆壘鍒帮紝鎹釜浣忔墍銆傚悗缁皢缁х画鍏虫敞涓や汉鍔ㄦ€併€?,'2381','璋㈤亾寮?,'','2026-04-14 22:24:32'),(3,'12325514755-12329146438-20260410','缁忔牳瀹烇紝璇ュ叞鍏帮紙浣忛粍宀╋級鍜屽江鏄ュ崕锛?64458880766894696锛?2308982121锛岄粍宀╂緞姹熻閬?鍙凤級涔嬪墠鏄敺濂虫湅鍙嬪叧绯伙紝鍥犲江涓庡鍚嶅コ瀛愪笉娓呬笉妤氾紝鑱婂ぉ姣旇緝鏆ф槯锛屽鑷村弻鏂瑰垎鎵嬨€傜洰鍓嶆宸茬粡涓嶆効鍜屽叾浜ゅ線锛屽鏂逛竴鐩寸籂缂犱笉娓咃紝鎬€鐤戞鏈夋柊鐢锋湅鍙嬶紝閫氳繃涓嶅悓閫斿緞鎵惧叾锛屽姹傜鍚堬紝鍋跺皵浼氭湁鏋佺瑷€璇紝搴滃墠鎵€鍚庣画杩涜鍏虫敞锛屾湜榛勫博鍒嗗眬浜堜互鍏虫敞銆?,'2381','璋㈤亾寮?,'','2026-04-14 18:04:16'),(4,'12335309795-12379558908-20260401','test123','system','绯荤粺','','2026-05-17 20:12:41');
/*!40000 ALTER TABLE `nb_tab_grjd_feedback_history` ENABLE KEYS */;
UNLOCK TABLES;
DROP TABLE IF EXISTS `nb_tab_grjd_workflow_state`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `nb_tab_grjd_workflow_state` (
  `id` varchar(64) NOT NULL,
  `status` varchar(16) NOT NULL DEFAULT '寰呮牳鏌?,
  `level` varchar(32) DEFAULT NULL,
  `remark` text,
  `mark_tag` varchar(64) DEFAULT NULL,
  `distribute` varchar(64) NOT NULL DEFAULT '',
  `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `nb_tab_grjd_workflow_state` WRITE;
/*!40000 ALTER TABLE `nb_tab_grjd_workflow_state` DISABLE KEYS */;
INSERT INTO `nb_tab_grjd_workflow_state` VALUES ('12300704351-12396919584-20260401','寰呮牳鏌?,NULL,NULL,NULL,'','2026-05-17 20:21:05'),('12325514755-12329146438-20260410','宸插弽棣?,NULL,NULL,NULL,'','2026-05-14 10:31:05'),('12330964780-12358909038-20260401','寰呮牳鏌?,'銆愬鐢熺嚎绱€憈est',NULL,NULL,'鎺ㄩ€佹不瀹?,'2026-05-17 20:21:05'),('12331646331-12354130649-20260412','宸插弽棣?,NULL,NULL,NULL,'','2026-05-14 10:31:05'),('12331661479-12379472013-20260401','寰呮牳鏌?,NULL,NULL,NULL,'','2026-05-17 20:21:05'),('12333692288-12347615159-20260413','宸插弽棣?,NULL,NULL,NULL,'','2026-05-14 10:31:05'),('12335309795-12379558908-20260401','宸插弽棣?,NULL,NULL,NULL,'','2026-05-17 20:21:05');
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


