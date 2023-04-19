/*<info serverAlias="FPSDC-FPS_FingerPrint" databaseType="2"></info>*/
/*
	Created: 20230419@Jonathan.Doan [Redmine ID: #180264]
	Task: Srcipt update Schema
	DB: FPS_FingerPrint
*/
USE FPS_FingerPrint;

TRUNCATE TABLE `FPS_FingerPrint`.`Account`;
TRUNCATE TABLE `FPS_FingerPrint`.`BrowserInfoAttribute`;
TRUNCATE TABLE `FPS_FingerPrint`.`BrowserInfoCompleted`;
TRUNCATE TABLE `FPS_FingerPrint`.`Cookie`;
TRUNCATE TABLE `FPS_FingerPrint`.`Device`;
TRUNCATE TABLE `FPS_FingerPrint`.`RawFingerPrint`;
TRUNCATE TABLE `FPS_FingerPrint`.`RawUserAgent`;
TRUNCATE TABLE `FPS_FingerPrint`.`TransactionDailySum`;
TRUNCATE TABLE `FPS_FingerPrint`.`TransactionMonthlySum`;

DROP TABLE IF EXISTS FPS_FingerPrint.AccountFingerprint;
DROP TABLE IF EXISTS FPS_FingerPrint.Addon;
DROP TABLE IF EXISTS FPS_FingerPrint.BrowserInfo;
DROP TABLE IF EXISTS FPS_FingerPrint.BrowserInstance;
DROP TABLE IF EXISTS FPS_FingerPrint.BrowserInstanceAttribute;
DROP TABLE IF EXISTS FPS_FingerPrint.BrowserInstanceRawFingerPrint;
DROP TABLE IF EXISTS FPS_FingerPrint.ClientTransaction;
DROP TABLE IF EXISTS FPS_FingerPrint.ClientTransactionCompleted;
DROP TABLE IF EXISTS FPS_FingerPrint.ClientTransactionDailySum;
DROP TABLE IF EXISTS FPS_FingerPrint.ClientTransaction_Logs;
DROP TABLE IF EXISTS FPS_FingerPrint.DeviceCookie;
DROP TABLE IF EXISTS FPS_FingerPrint.DeviceFingerPrint;
DROP TABLE IF EXISTS FPS_FingerPrint.FingerPrintAttribute;
DROP TABLE IF EXISTS FPS_FingerPrint.RecoverDailySum;
DROP TABLE IF EXISTS FPS_FingerPrint.ServerTransaction;
DROP TABLE IF EXISTS FPS_FingerPrint.ServerTransactionCompleted;
DROP TABLE IF EXISTS FPS_FingerPrint.ServerTransactionDailySum;
DROP TABLE IF EXISTS FPS_FingerPrint.ServerTransactionN;
DROP TABLE IF EXISTS FPS_FingerPrint.Transaction;
DROP TABLE IF EXISTS FPS_FingerPrint.TransactionCompleted;
DROP TABLE IF EXISTS FPS_FingerPrint.TransactionDevice;
DROP TABLE IF EXISTS FPS_FingerPrint.TransactionEvolution;
DROP TABLE IF EXISTS FPS_FingerPrint.TransactionEvolutionCompleted;

CREATE TABLE `AccountFingerprint` (
  `Id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `AccountId` bigint unsigned DEFAULT NULL,
  `RawFingerPrintId` bigint unsigned DEFAULT NULL,
  `IsEvolution` tinyint(1) DEFAULT NULL,
  `CreatedDate` datetime DEFAULT NULL,
  `ModifiedDate` datetime(4) DEFAULT NULL,
  PRIMARY KEY (`Id`),
  UNIQUE KEY `UX_AccountFingerprint_AccountId_RawFingerPrintId` (`AccountId`,`RawFingerPrintId`) /*!80000 INVISIBLE */,
  KEY `IX_AccountFingerprint_IsEvolution` (`IsEvolution`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `BrowserInfo` (
  `Id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `UserAgentId` bigint unsigned DEFAULT NULL,
  `BrowserInfoAttributeId` bigint unsigned DEFAULT NULL,
  `HeadlessDetail` longtext,
  `BrowserName` varchar(100) DEFAULT NULL,
  `OSName` varchar(100) DEFAULT NULL,
  `CreatedDate` datetime(4) DEFAULT NULL,
  `ModifiedDate` datetime(4) DEFAULT NULL,
  `HeadlessScore` decimal(3,1) DEFAULT NULL,
  `BrowserInfoCode` varchar(64) DEFAULT NULL,
  `Flagged` smallint DEFAULT NULL,
  PRIMARY KEY (`Id`),
  UNIQUE KEY `UX_BrowserInfo_UserAgentId_BIAId_BICode` (`UserAgentId`,`BrowserInfoAttributeId`,`BrowserInfoCode`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `BrowserInstance` (
  `Id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `BrowserInstanceCode` varchar(64) NOT NULL COMMENT 'hash ALL',
  `UserAgent` longtext,
  `BrowserFamilyCode` varchar(64) DEFAULT NULL COMMENT 'hash: OSName, BrowserName, Platform',
  `OSName` varchar(100) DEFAULT NULL,
  `Platform` varchar(45) DEFAULT NULL,
  `BrowserName` varchar(100) DEFAULT NULL,
  `BrowserVersion` varchar(50) DEFAULT NULL,
  `Accept` varchar(100) DEFAULT NULL,
  `Encoding` varchar(200) DEFAULT NULL,
  `Headers` longtext,
  `CreatedDate` datetime(4) DEFAULT NULL,
  `ModifiedDate` datetime(4) DEFAULT NULL,
  PRIMARY KEY (`Id`),
  UNIQUE KEY `UX_BrowserInstance_BrowserInstanceCode` (`BrowserInstanceCode`),
  KEY `IX_BrowserInstance_BrowserFamilyCode` (`BrowserFamilyCode`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `BrowserInstanceRawFingerPrint` (
  `Id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `RawFingerPrintId` bigint unsigned NOT NULL,
  `BrowserInstanceId` bigint unsigned NOT NULL,
  PRIMARY KEY (`Id`),
  UNIQUE KEY `UX_BrowserInstanceRawFingerPrint_FPId_BrowserInstanceId` (`RawFingerPrintId`,`BrowserInstanceId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `DeviceCookie` (
  `Id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `CookieId` bigint unsigned NOT NULL,
  `DeviceId` bigint unsigned DEFAULT NULL,
  `CreatedDate` datetime DEFAULT NULL,
  PRIMARY KEY (`Id`),
  UNIQUE KEY `UX_DeviceCookie_CookieId` (`CookieId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `DeviceFingerPrint` (
  `Id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `RawFingerPrintId` bigint unsigned DEFAULT NULL,
  `DeviceId` bigint unsigned DEFAULT NULL,
  `CreatedDate` datetime DEFAULT NULL,
  PRIMARY KEY (`Id`),
  UNIQUE KEY `UX_DeviceFingerPrint_RawFingerPrintId` (`RawFingerPrintId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `FingerPrintAttribute` (
  `Id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `RawFingerPrintId` bigint unsigned NOT NULL,
  `Platform` varchar(45) DEFAULT NULL,
  `LocalStorage` tinyint(1) DEFAULT NULL,
  `DoNotTrack` varchar(15) DEFAULT NULL,
  `Cookies` tinyint(1) DEFAULT NULL,
  `Canvas` longtext,
  `GLRenderer` varchar(200) DEFAULT NULL,
  `Audio` varchar(25) DEFAULT NULL,
  `ColorDepth` smallint DEFAULT NULL,
  `ColorGamut` varchar(10) DEFAULT NULL,
  `Contrast` smallint DEFAULT NULL,
  `CpuClass` varchar(45) DEFAULT NULL,
  `DeviceMemory` tinyint DEFAULT NULL,
  `DomBlockers` varchar(45) DEFAULT NULL,
  `FontPreferencePrint` longtext,
  `Fonts` longtext,
  `ForcedColors` tinyint(1) DEFAULT NULL,
  `HardwareConcurrency` tinyint DEFAULT NULL,
  `HDR` tinyint(1) DEFAULT NULL,
  `IndexedDB` tinyint(1) DEFAULT NULL,
  `InvertedColors` tinyint(1) DEFAULT NULL,
  `Languages` longtext,
  `Math` longtext,
  `Monochrome` tinyint DEFAULT NULL,
  `OpenDatabase` tinyint(1) DEFAULT NULL,
  `OsCpu` varchar(45) DEFAULT NULL,
  `Plugins` longtext,
  `ReducedMotion` tinyint(1) DEFAULT NULL,
  `Resolution` varchar(200) DEFAULT NULL,
  `SessionStorage` tinyint(1) DEFAULT NULL,
  `Timezone` varchar(45) DEFAULT NULL,
  `TouchSupport` varchar(200) DEFAULT NULL,
  `Vendor` varchar(45) DEFAULT NULL,
  `VendorFlavors` varchar(45) DEFAULT NULL,
  `WebglPrint` varchar(200) DEFAULT NULL,
  PRIMARY KEY (`Id`),
  UNIQUE KEY `UX_FingerPrintAttribute_RawFingerPrintId` (`RawFingerPrintId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `RecoverDailySum` (
  `Id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `SubscriberId` int unsigned NOT NULL,
  `TransDate` date NOT NULL,
  `Total` BIGINT UNSIGNED DEFAULT NULL,
  `NullDevice` BIGINT UNSIGNED DEFAULT NULL,
  `NewDevice` BIGINT UNSIGNED DEFAULT NULL,
  `RecoverByFP` BIGINT UNSIGNED DEFAULT NULL,
  `RecoverByCookies` BIGINT UNSIGNED DEFAULT NULL,
  `RecoverByFPnCookies` BIGINT UNSIGNED DEFAULT NULL,
  `RecoverByEvolution` BIGINT UNSIGNED DEFAULT NULL,
  `CreatedDate` datetime DEFAULT NULL,
  `ModifiedDate` datetime DEFAULT NULL,
  PRIMARY KEY (`Id`),
  UNIQUE KEY `UX_RecoverDailySum_SubscriberId_TransDate` (`SubscriberId`,`TransDate`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `Transaction` (
  `Id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `CustId` bigint unsigned DEFAULT NULL,
  `SubAccId` bigint unsigned DEFAULT NULL,
  `AccountId` bigint unsigned DEFAULT NULL,
  `LoginName` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `SubscriberId` int DEFAULT NULL,
  `RawFingerPrintId` bigint unsigned DEFAULT NULL,
  `BrowserInstanceId` bigint unsigned DEFAULT NULL,
  `CookieId` bigint unsigned DEFAULT NULL,
  `TransTime` datetime(4) DEFAULT NULL,
  `ClientIP` varchar(45) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `BrowserInfoId` bigint unsigned DEFAULT NULL,
  `UserAgentId` bigint unsigned DEFAULT NULL,
  `Url` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `Action` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `CreatedDate` datetime DEFAULT NULL,
  `TransKey` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  PRIMARY KEY (`Id`),
  KEY `IX_Transaction_CustId` (`CustId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `TransactionCompleted` (
  `Id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `CustId` bigint unsigned DEFAULT NULL,
  `SubAccId` bigint unsigned DEFAULT NULL,
  `AccountId` bigint unsigned DEFAULT NULL,
  `LoginName` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `SubscriberId` int DEFAULT NULL,
  `RawFingerPrintId` bigint unsigned DEFAULT NULL,
  `BrowserInstanceId` bigint unsigned DEFAULT NULL,
  `CookieId` bigint unsigned DEFAULT NULL,
  `DeviceId` bigint unsigned DEFAULT NULL,
  `TransTime` datetime(4) DEFAULT NULL,
  `ClientIP` varchar(45) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `BrowserInfoId` bigint unsigned DEFAULT NULL,
  `UserAgentId` bigint unsigned DEFAULT NULL,
  `Url` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `Action` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `CreatedDate` datetime NOT NULL,
  `TransKey` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `Retry` tinyint DEFAULT '0',
  `RecoverType` tinyint DEFAULT NULL,
  PRIMARY KEY (`Id`,`CreatedDate`),
  KEY `UX_TransactionCompleted_AccountId` (`AccountId`),
  KEY `IX_TransactionCompleted_CustId` (`CustId`)
) ENGINE=InnoDB AUTO_INCREMENT=15 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
/*!50100 PARTITION BY RANGE (yearweek(`CreatedDate`,0))
 (PARTITION pw202315 VALUES LESS THAN (202316) ENGINE = InnoDB,
 PARTITION pw202316 VALUES LESS THAN (202317) ENGINE = InnoDB,
 PARTITION pw202317 VALUES LESS THAN (202318) ENGINE = InnoDB,
 PARTITION pw202318 VALUES LESS THAN (202319) ENGINE = InnoDB,
 PARTITION pw202319 VALUES LESS THAN (202320) ENGINE = InnoDB,
 PARTITION pw202320 VALUES LESS THAN (202321) ENGINE = InnoDB,
 PARTITION pw202321 VALUES LESS THAN (202322) ENGINE = InnoDB,
 PARTITION pw202322 VALUES LESS THAN (202323) ENGINE = InnoDB,
 PARTITION pw202323 VALUES LESS THAN (202324) ENGINE = InnoDB,
 PARTITION pw202324 VALUES LESS THAN (202325) ENGINE = InnoDB,
 PARTITION pw999999 VALUES LESS THAN MAXVALUE ENGINE = InnoDB) */;

CREATE TABLE `TransactionDevice` (
  `Id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `CustId` bigint unsigned DEFAULT NULL,
  `SubAccId` bigint unsigned DEFAULT NULL,
  `AccountId` bigint unsigned DEFAULT NULL,
  `LoginName` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `SubscriberId` int DEFAULT NULL,
  `RawFingerPrintId` bigint unsigned DEFAULT NULL,
  `BrowserInstanceId` bigint unsigned DEFAULT NULL,
  `CookieId` bigint unsigned DEFAULT NULL,
  `DeviceId` bigint unsigned DEFAULT NULL,
  `TransTime` datetime(4) DEFAULT NULL,
  `ClientIP` varchar(45) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `BrowserInfoId` bigint unsigned DEFAULT NULL,
  `UserAgentId` bigint unsigned DEFAULT NULL,
  `Url` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `Action` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `CreatedDate` datetime DEFAULT NULL,
  `TransKey` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `Retry` tinyint DEFAULT '0',
  `RecoverType` tinyint DEFAULT NULL,
  PRIMARY KEY (`Id`),
  KEY `IX_TransactionDevice_Retry` (`Retry`),
  KEY `IX_TransactionDevice_CustId` (`CustId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `TransactionEvolution` (
  `Id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `CustId` bigint unsigned DEFAULT NULL,
  `SubAccId` bigint unsigned DEFAULT NULL,
  `AccountId` bigint unsigned DEFAULT NULL,
  `LoginName` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `SubscriberId` int DEFAULT NULL,
  `RawFingerPrintId` bigint unsigned DEFAULT NULL,
  `BrowserInstanceId` bigint unsigned DEFAULT NULL,
  `CookieId` bigint unsigned DEFAULT NULL,
  `TransTime` datetime(4) DEFAULT NULL,
  `ClientIP` varchar(45) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `BrowserInfoId` bigint unsigned DEFAULT NULL,
  `UserAgentId` bigint unsigned DEFAULT NULL,
  `Url` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `Action` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `CreatedDate` datetime DEFAULT NULL,
  `TransKey` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  PRIMARY KEY (`Id`),
  KEY `IX_TransactionEvolution_CustId` (`CustId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `TransactionEvolutionCompleted` (
  `Id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `RawFingerPrintId` bigint unsigned NOT NULL,
  `RecoverFingerPrintId` bigint unsigned NOT NULL,
  `DeviceId` bigint unsigned NOT NULL,
  `CreatedDate` datetime DEFAULT NULL,
  PRIMARY KEY (`Id`),
  KEY `IX_TransactionEvolutionCompleted_DeviceId` (`DeviceId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


ALTER TABLE `FPS_FingerPrint`.`Cookie` 
CHANGE COLUMN `CookieCode` `CookieCode` VARCHAR(64) NOT NULL ;

ALTER TABLE `FPS_FingerPrint`.`RawFingerPrint` 
CHANGE COLUMN `FingerPrintCode` `FingerPrintCode` VARCHAR(64) NOT NULL ;

INSERT IGNORE INTO `FPS_FingerPrint`.`Offset`(Id, OffsetName, OffsetValue, CreatedDate)
VALUES ROW(12, 'UpdateEvolution', 0, '2022-09-12 05:35:49'), ROW(13,'SummaryRecoverType', 0, '2022-10-26');

SET sql_safe_updates = 0;
update FPS_FingerPrint.Offset set OffsetValue = 0 where Id not in (7,8);

DROP PROCEDURE IF EXISTS `FPS_FP_Transform_ServerTransaction_Insert`;
DROP PROCEDURE IF EXISTS `FPS_FP_Transform_ServerTransaction_Get`;
DROP PROCEDURE IF EXISTS `FPS_FP_Transform_ServerTransaction_Update`;
DROP PROCEDURE IF EXISTS `FPS_FP_Transform_ServerTransactionN_Get`;
DROP PROCEDURE IF EXISTS `FPS_FP_Transform_ServerTransactionN_Update`;
DROP PROCEDURE IF EXISTS `FPS_FP_Transform_ServerTransactionRetry_Get`;
DROP PROCEDURE IF EXISTS `FPS_FP_Transform_FingerprintAttributes_Insert`;
DROP PROCEDURE IF EXISTS `FPS_FP_Transform_ClientTransaction_Insert`;
DROP PROCEDURE IF EXISTS `FPS_FP_Summary_ServerTransaction_Daily`;
DROP PROCEDURE IF EXISTS `FPS_FP_Summary_ClientTransaction_Daily`;
DROP PROCEDURE IF EXISTS `FPS_FP_Summary_ClientServerTransaction_Monthly`;
DROP PROCEDURE IF EXISTS `FPS_FP_Monitor_ServerTransactionDailySum_Insert`;
DROP PROCEDURE IF EXISTS `FPS_FP_Monitor_ClientTransactionDailySum_Insert`;
DROP PROCEDURE IF EXISTS `FPS_FP_Transform_ClientTransaction_Logs_Insert`;
DROP PROCEDURE IF EXISTS `FPS_FP_Transform_BrowserInfo_Insert`;
DROP PROCEDURE IF EXISTS `FPS_FP_Transform_BrowserInfo_Get`;
DROP PROCEDURE IF EXISTS `FPS_FP_Transform_BrowserInfo_Update`;
DROP PROCEDURE IF EXISTS `FPS_FP_Transform_BrowserInfoFlaggedDCS_Get`;
DROP PROCEDURE IF EXISTS `FPS_FP_Transform_BrowserInfoFlaggedDCS_Update`;



