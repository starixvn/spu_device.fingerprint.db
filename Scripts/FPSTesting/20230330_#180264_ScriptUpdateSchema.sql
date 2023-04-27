/*<info serverAlias="FPSDC-FPSTesting" databaseType="2"></info>*/
/*
	Created: 20230330@Jonathan.Doan [Redmine ID: #180264]
	Task: Update Schema
	DB: FPSTesting
*/

USE FPSTesting;

TRUNCATE TABLE `FPSTesting`.`FP_Account`;
TRUNCATE TABLE `FPSTesting`.`FP_ActionResult`;
TRUNCATE TABLE `FPSTesting`.`FP_Device`;
TRUNCATE TABLE `FPSTesting`.`FP_DeviceCode`;
TRUNCATE TABLE `FPSTesting`.`FP_DeviceFingerprint`;
TRUNCATE TABLE `FPSTesting`.`FP_MappingDevice`;
TRUNCATE TABLE `FPSTesting`.`FP_ProcessedTransaction`;
TRUNCATE TABLE `FPSTesting`.`FP_RawTransaction`;
TRUNCATE TABLE `FPSTesting`.`FP_RawTransaction_Old`;
TRUNCATE TABLE `FPSTesting`.`FP_Transaction`;
TRUNCATE TABLE `FPSTesting`.`FP_Transaction07`;
TRUNCATE TABLE `FPSTesting`.`FP_UserAgent`;

DROP TABLE IF EXISTS FPSTesting.FP_Association;
DROP TABLE IF EXISTS FPSTesting.FP_AssociationNew;
DROP TABLE IF EXISTS FPSTesting.FP_Association_Old;
DROP TABLE IF EXISTS FPSTesting.FP_RawTransaction_Old_Completed;

CREATE TABLE `FP_Association` (
  `AssociationID` bigint unsigned NOT NULL AUTO_INCREMENT,
  `AccountID` bigint unsigned NOT NULL,
  `FPDeviceID` bigint unsigned NOT NULL,
  `CreatedTime` datetime(4) NOT NULL,
  `CreatedDate` datetime(4) NOT NULL,
  `InsertTime` datetime(4) NOT NULL,
  `IsCTSTransformed` tinyint NOT NULL DEFAULT '0',
  PRIMARY KEY (`AssociationID`),
  UNIQUE KEY `UX_FP_Association_AccountIDFPDeviceID` (`AccountID`,`FPDeviceID`),
  KEY `IX_FP_Association_IsCTSTransformed` (`IsCTSTransformed`),
  KEY `IX_FP_Association_FPDeviceIDAccountID` (`FPDeviceID`,`AccountID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `FP_Association_Old` (
  `AssociationID` bigint unsigned NOT NULL AUTO_INCREMENT,
  `DeviceID` bigint unsigned NOT NULL,
  `AccountID` bigint unsigned NOT NULL,
  `SubscriberID` int NOT NULL,
  `CreatedTime` timestamp(4) NOT NULL,
  `CreatedDate` timestamp(4) NOT NULL,
  `InsertTime` timestamp(4) NOT NULL,
  `IsCTSTransformed` tinyint NOT NULL DEFAULT '0',
  PRIMARY KEY (`AccountID`,`DeviceID`),
  KEY `IX_FP_Association_Old_SubscriberID_AccountID_DeviceID` (`SubscriberID`,`AccountID`,`DeviceID`),
  KEY `IX_FP_Association_Old_IsCTSTransformed` (`IsCTSTransformed`),
  KEY `IX_FP_Association_Old_DeviceID_AccountID` (`DeviceID`,`AccountID`),
  KEY `IX_FP_Association_Old_AssociationID` (`AssociationID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `FP_RawTransaction_Old_Completed` (
  `LoginName` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `SubscriberName` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `TransTime` timestamp(4) NOT NULL,
  `CreatedDate` datetime NOT NULL COMMENT 'Date Only',
  `DeviceCode` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `FingerprintCode` varchar(620) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `FingerprintMoreInfo` varchar(250) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `UserAgent` varchar(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `IP` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `IPID` decimal(50,0) DEFAULT NULL,
  `PluginID` bigint DEFAULT NULL,
  `URL` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `Action` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `ActionResult` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `InvalidDevice` varchar(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `TransStatus` bit(16) DEFAULT NULL COMMENT 'Refer Table TransStatus',
  `FPSTransID` bigint unsigned DEFAULT NULL,
  `Flagged` smallint DEFAULT NULL,
  `IsProcessed` tinyint NOT NULL DEFAULT '0',
  `TransID` bigint unsigned NOT NULL AUTO_INCREMENT,
  `TransKey` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  PRIMARY KEY (`TransID`,`CreatedDate`),
  KEY `IX_RawTransaction_IsProcessed` (`IsProcessed`,`TransKey`),
  KEY `IX_RawTransaction_SubscriberName` (`SubscriberName`,`CreatedDate`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
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

UPDATE FPSTesting.FP_SystemSetting 
SET VValue = 0 
WHERE VName IN ('MinTransId', 'MinRawTransId');

UPDATE FPSTesting.FP_SystemSetting 
SET VValue = '2023-01-01' 
WHERE VName IN ('MinCreatedDate');
