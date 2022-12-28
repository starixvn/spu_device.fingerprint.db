/*<info serverAlias="FPSDC-FPS_FingerPrint" databaseType="2"></info>*/
/*
	Created: 20221115@Jonathan.Doan [Redmine ID: #180264]
	Task: Srcipt update Schema
	DB: FPS_FingerPrint
*/
USE FPS_FingerPrint;

DROP TABLE IF EXISTS FPS_FingerPrint.BrowserInfo;
DROP TABLE IF EXISTS FPS_FingerPrint.ServerTransaction;
DROP TABLE IF EXISTS FPS_FingerPrint.ServerTransactionCompleted;
DROP TABLE IF EXISTS FPS_FingerPrint.ServerTransactionDailySum;
DROP TABLE IF EXISTS FPS_FingerPrint.ServerTransactionN;
DROP TABLE IF EXISTS FPS_FingerPrint.ClientTransaction;
DROP TABLE IF EXISTS FPS_FingerPrint.ClientTransactionCompleted;
DROP TABLE IF EXISTS FPS_FingerPrint.ClientTransactionDailySum;
DROP TABLE IF EXISTS FPS_FingerPrint.ClientTransaction_Logs;
DROP TABLE IF EXISTS FPS_FingerPrint.BrowserInstanceAttribute;
DROP TABLE IF EXISTS FPS_FingerPrint.TransactionEvolutionCompleted;
DROP TABLE IF EXISTS FPS_FingerPrint.Addon;
DROP TABLE IF EXISTS FPS_FingerPrint.ClientTransaction_Logs;

TRUNCATE TABLE `FPS_FingerPrint`.`Transaction`;
TRUNCATE TABLE `FPS_FingerPrint`.`TransactionCompleted`;
TRUNCATE TABLE `FPS_FingerPrint`.`TransactionDailySum`;
TRUNCATE TABLE `FPS_FingerPrint`.`TransactionDevice`;
TRUNCATE TABLE `FPS_FingerPrint`.`TransactionEvolution`;
TRUNCATE TABLE `FPS_FingerPrint`.`RecoverDailySum`;
TRUNCATE TABLE `FPS_FingerPrint`.`RawUserAgent`;
TRUNCATE TABLE `FPS_FingerPrint`.`RawFingerPrint`;
TRUNCATE TABLE `FPS_FingerPrint`.`FingerPrintAttribute`;
TRUNCATE TABLE `FPS_FingerPrint`.`DeviceFingerPrint`;
TRUNCATE TABLE `FPS_FingerPrint`.`DeviceCookie`;
TRUNCATE TABLE `FPS_FingerPrint`.`Device`;
TRUNCATE TABLE `FPS_FingerPrint`.`Cookie`;
TRUNCATE TABLE `FPS_FingerPrint`.`BrowserInstance`;
TRUNCATE TABLE `FPS_FingerPrint`.`BrowserInfoCompleted`;
TRUNCATE TABLE `FPS_FingerPrint`.`BrowserInfoAttribute`;
TRUNCATE TABLE `FPS_FingerPrint`.`BrowserInfo`;
TRUNCATE TABLE `FPS_FingerPrint`.`AccountFingerprint`;

ALTER TABLE `FPS_FingerPrint`.`FingerPrintAttribute` 
CHANGE COLUMN `FingerPrintCode` `RawFingerPrintId` BIGINT UNSIGNED NOT NULL ,
DROP INDEX `UX_FingerPrintAttribute_FingerPrintCode` ,
ADD UNIQUE INDEX `UX_FingerPrintAttribute_RawFingerPrintId` (`RawFingerPrintId`);

ALTER TABLE `FPS_FingerPrint`.`Cookie` 
CHANGE COLUMN `CookieCode` `CookieCode` VARCHAR(64) NOT NULL ;

ALTER TABLE `FPS_FingerPrint`.`RawFingerPrint` 
CHANGE COLUMN `FingerPrintCode` `FingerPrintCode` VARCHAR(64) NOT NULL ;

ALTER TABLE `FPS_FingerPrint`.`BrowserInstance` 
CHANGE COLUMN `BrowserInstanceCode` `BrowserInstanceCode` VARCHAR(64) NOT NULL COMMENT 'hash ALL',
ADD COLUMN `CreatedDate` DATETIME(4) NULL,
ADD COLUMN `ModifiedDate` DATETIME(4) NULL;

CREATE TABLE `BrowserInstanceRawFingerPrint` (
  `Id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `RawFingerPrintId` bigint unsigned NOT NULL,
  `BrowserInstanceId` bigint unsigned NOT NULL,
  PRIMARY KEY (`Id`),
  UNIQUE KEY `UX_BrowserInstanceRawFingerPrint_FPId_BrowserInstanceId` (`RawFingerPrintId`,`BrowserInstanceId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `TransactionEvolutionCompleted` (
  `Id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `RawFingerPrintId` bigint unsigned NOT NULL,
  `RecoverFingerPrintId` bigint unsigned NOT NULL,
  `DeviceId` bigint unsigned NOT NULL,
  `CreatedDate` datetime DEFAULT NULL,
  `ModifiedDate` datetime DEFAULT NULL,
  PRIMARY KEY (`Id`),
  KEY `IX_TransactionEvolutionCompleted_DeviceId` (`DeviceId`)
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


ALTER TABLE `FPS_FingerPrint`.`Transaction` 
DROP COLUMN `ClientTransId`,
DROP COLUMN `ServerTransId`,
DROP COLUMN `AddonId`,
ADD COLUMN `BrowserInstanceId` BIGINT UNSIGNED NULL AFTER `RawFingerPrintId`,
ADD INDEX `IX_Transaction_CustId` (`CustId`);

ALTER TABLE `FPS_FingerPrint`.`TransactionDevice` 
DROP COLUMN `ClientTransId`,
DROP COLUMN `ServerTransId`,
DROP COLUMN `AddonId`,
ADD COLUMN `BrowserInstanceId` BIGINT UNSIGNED NULL AFTER `RawFingerPrintId`,
ADD INDEX `IX_TransactionDevice_CustId` (`CustId`);

ALTER TABLE `FPS_FingerPrint`.`TransactionEvolution`
DROP COLUMN `ClientTransId`,
DROP COLUMN `ServerTransId`,
DROP COLUMN `AddonId`,
ADD COLUMN `BrowserInstanceId` BIGINT UNSIGNED NULL AFTER `RawFingerPrintId`,
ADD INDEX `IX_TransactionEvolution_CustId` (`CustId`);

ALTER TABLE `FPS_FingerPrint`.`TransactionCompleted`
DROP COLUMN `ClientTransId`,
DROP COLUMN `ServerTransId`,
DROP COLUMN `AddonId`,
ADD COLUMN `BrowserInstanceId` BIGINT UNSIGNED NULL AFTER `RawFingerPrintId`,
ADD INDEX `IX_TransactionCompleted_CustId` (`CustId`);

ALTER TABLE `FPS_FingerPrint`.`DeviceCookie`
DROP COLUMN `ModifiedDate`;

ALTER TABLE `FPS_FingerPrint`.`DeviceFingerPrint`
DROP COLUMN `ModifiedDate`;


