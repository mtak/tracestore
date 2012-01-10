-- MySQL dump 10.13  Distrib 5.1.49, for debian-linux-gnu (i486)
--
-- Host: localhost    Database: traceroute
-- ------------------------------------------------------
-- Server version	5.1.49-3

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `traceresults`
--

DROP TABLE IF EXISTS `traceresults`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `traceresults` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'ID',
  `traceroutes_id` int(11) NOT NULL COMMENT 'Traceroutes ID',
  `hop` int(11) NOT NULL COMMENT 'Hop number',
  `ip` int(11) unsigned NOT NULL COMMENT 'IP address of host',
  `hostname` varchar(128) DEFAULT NULL COMMENT 'Hostname of destination IP',
  `rtt` float NOT NULL COMMENT 'Roundtrip time',
  `as` int(6) DEFAULT NULL COMMENT 'AS Number',
  PRIMARY KEY (`id`),
  KEY `ip` (`ip`),
  KEY `traceroutes_id` (`traceroutes_id`)
) ENGINE=MyISAM AUTO_INCREMENT=9230465 DEFAULT CHARSET=latin1 COMMENT='Results of traceroute';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `traceroutes`
--

DROP TABLE IF EXISTS `traceroutes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `traceroutes` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'ID',
  `src` int(11) unsigned NOT NULL COMMENT 'Source (ip2long)',
  `dest` int(11) unsigned NOT NULL COMMENT 'Destination (ip2long)',
  `hostname` varchar(64) CHARACTER SET ascii COLLATE ascii_bin DEFAULT NULL COMMENT 'Destination hostname',
  `tcp_trace` tinyint(1) NOT NULL DEFAULT '0' COMMENT 'Is this a tcp trace',
  `time` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `dest` (`dest`)
) ENGINE=MyISAM AUTO_INCREMENT=374936 DEFAULT CHARSET=latin1 COMMENT='Traceroute metadata';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Temporary table structure for view `view_top_traceresults`
--

DROP TABLE IF EXISTS `view_top_traceresults`;
/*!50001 DROP VIEW IF EXISTS `view_top_traceresults`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE TABLE `view_top_traceresults` (
  `INET_NTOA(ip)` varbinary(31),
  `COUNT(ip)` bigint(21)
) ENGINE=MyISAM */;
SET character_set_client = @saved_cs_client;

--
-- Temporary table structure for view `view_traceresults`
--

DROP TABLE IF EXISTS `view_traceresults`;
/*!50001 DROP VIEW IF EXISTS `view_traceresults`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE TABLE `view_traceresults` (
  `id` int(11),
  `traceroutes_id` int(11),
  `hop` int(11),
  `INET_NTOA(ip)` varbinary(31),
  `rtt` float,
  `hostname` varchar(128),
  `as` int(6)
) ENGINE=MyISAM */;
SET character_set_client = @saved_cs_client;

--
-- Temporary table structure for view `view_traceroutes`
--

DROP TABLE IF EXISTS `view_traceroutes`;
/*!50001 DROP VIEW IF EXISTS `view_traceroutes`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE TABLE `view_traceroutes` (
  `id` int(11),
  `INET_NTOA(src)` varbinary(31),
  `INET_NTOA(dest)` varbinary(31),
  `tcp_trace` tinyint(1),
  `time` datetime
) ENGINE=MyISAM */;
SET character_set_client = @saved_cs_client;

--
-- Final view structure for view `view_top_traceresults`
--

/*!50001 DROP TABLE IF EXISTS `view_top_traceresults`*/;
/*!50001 DROP VIEW IF EXISTS `view_top_traceresults`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = latin1 */;
/*!50001 SET character_set_results     = latin1 */;
/*!50001 SET collation_connection      = latin1_swedish_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `view_top_traceresults` AS select inet_ntoa(`traceresults`.`ip`) AS `INET_NTOA(ip)`,count(`traceresults`.`ip`) AS `COUNT(ip)` from `traceresults` group by inet_ntoa(`traceresults`.`ip`) order by count(inet_ntoa(`traceresults`.`ip`)) desc */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `view_traceresults`
--

/*!50001 DROP TABLE IF EXISTS `view_traceresults`*/;
/*!50001 DROP VIEW IF EXISTS `view_traceresults`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = latin1 */;
/*!50001 SET character_set_results     = latin1 */;
/*!50001 SET collation_connection      = latin1_swedish_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `view_traceresults` AS select `traceresults`.`id` AS `id`,`traceresults`.`traceroutes_id` AS `traceroutes_id`,`traceresults`.`hop` AS `hop`,inet_ntoa(`traceresults`.`ip`) AS `INET_NTOA(ip)`,`traceresults`.`rtt` AS `rtt`,`traceresults`.`hostname` AS `hostname`,`traceresults`.`as` AS `as` from `traceresults` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `view_traceroutes`
--

/*!50001 DROP TABLE IF EXISTS `view_traceroutes`*/;
/*!50001 DROP VIEW IF EXISTS `view_traceroutes`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = latin1 */;
/*!50001 SET character_set_results     = latin1 */;
/*!50001 SET collation_connection      = latin1_swedish_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `view_traceroutes` AS select `traceroutes`.`id` AS `id`,inet_ntoa(`traceroutes`.`src`) AS `INET_NTOA(src)`,inet_ntoa(`traceroutes`.`dest`) AS `INET_NTOA(dest)`,`traceroutes`.`tcp_trace` AS `tcp_trace`,`traceroutes`.`time` AS `time` from `traceroutes` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2012-01-10 11:35:29
