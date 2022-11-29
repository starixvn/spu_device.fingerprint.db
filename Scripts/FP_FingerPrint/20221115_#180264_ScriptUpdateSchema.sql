/*<info serverAlias="FPSDC-FPS_FingerPrint" databaseType="2"></info>*/
/*
	Created: 20221115@Jonathan.Doan [Redmine ID: #180264]
	Task: Srcipt update Schema
	DB: FPS_FingerPrint
*/
USE FPS_FingerPrint;

DROP TABLE FPS_FingerPrint.ServerTransaction;
DROP TABLE FPS_FingerPrint.ServerTransactionCompleted;
DROP TABLE FPS_FingerPrint.ServerTransactionDailySum;
DROP TABLE FPS_FingerPrint.ServerTransactionN;
DROP TABLE FPS_FingerPrint.ClientTransaction;
DROP TABLE FPS_FingerPrint.ClientTransactionCompleted;
DROP TABLE FPS_FingerPrint.ClientTransactionDailySum;
DROP TABLE FPS_FingerPrint.ClientTransaction_Logs;

TRUNCATE TABLE `FPS_FingerPrint`.`Transaction`;
TRUNCATE TABLE `FPS_FingerPrint`.`TransactionCompleted`;
TRUNCATE TABLE `FPS_FingerPrint`.`TransactionDailySum`;
TRUNCATE TABLE `FPS_FingerPrint`.`TransactionDevice`;
TRUNCATE TABLE `FPS_FingerPrint`.`TransactionEvolution`;
TRUNCATE TABLE `FPS_FingerPrint`.`TransactionEvolutionCompleted`;
TRUNCATE TABLE `FPS_FingerPrint`.`TransactionMonthlySum`;
TRUNCATE TABLE `FPS_FingerPrint`.`RecoverDailySum`;
TRUNCATE TABLE `FPS_FingerPrint`.`RawUserAgent`;
TRUNCATE TABLE `FPS_FingerPrint`.`RawFingerPrint`;
TRUNCATE TABLE `FPS_FingerPrint`.`FingerPrintAttribute`;
TRUNCATE TABLE `FPS_FingerPrint`.`DeviceFingerPrint`;
TRUNCATE TABLE `FPS_FingerPrint`.`DeviceCookie`;
TRUNCATE TABLE `FPS_FingerPrint`.`Device`;
TRUNCATE TABLE `FPS_FingerPrint`.`Cookie`;
TRUNCATE TABLE `FPS_FingerPrint`.`BrowserInstanceAttribute`;
TRUNCATE TABLE `FPS_FingerPrint`.`BrowserInstance`;
TRUNCATE TABLE `FPS_FingerPrint`.`BrowserInfoCompleted`;
TRUNCATE TABLE `FPS_FingerPrint`.`BrowserInfoAttribute`;
TRUNCATE TABLE `FPS_FingerPrint`.`BrowserInfo`;
TRUNCATE TABLE `FPS_FingerPrint`.`AccountFingerprint`;

ALTER TABLE `FPS_FingerPrint`.`Cookie` 
CHANGE COLUMN `CookieCode` `CookieCode` VARCHAR(64) NOT NULL ;

ALTER TABLE `FPS_FingerPrint`.`RawFingerPrint` 
CHANGE COLUMN `FingerPrintCode` `FingerPrintCode` VARCHAR(64) NOT NULL ;

ALTER TABLE `FPS_FingerPrint`.`BrowserInstance` 
CHANGE COLUMN `BrowserInstanceCode` `BrowserInstanceCode` VARCHAR(64) NOT NULL COMMENT 'hash ALL' ;

SET sql_safe_updates = 0;
update FPS_FingerPrint.Offset set OffsetValue = 0 where Id not in (7,8);

DROP PROCEDURE IF EXISTS `FPS_FP_Transform_ServerTransaction_Insert`;
DROP PROCEDURE IF EXISTS `FPS_FP_Transform_ServerTransaction_Get`;
DROP PROCEDURE IF EXISTS `FPS_FP_Transform_ServerTransaction_Update`;
DROP PROCEDURE IF EXISTS `FPS_FP_Transform_ServerTransactionN_Get`;
DROP PROCEDURE IF EXISTS `FPS_FP_Transform_ServerTransactionN_Update`;
DROP PROCEDURE IF EXISTS `FPS_FP_Transform_ServerTransactionRetry_Get`;
DROP PROCEDURE IF EXISTS `FPS_FP_Summary_ServerTransaction_Daily`;
DROP PROCEDURE IF EXISTS `FPS_FP_Summary_ClientTransaction_Daily`;
DROP PROCEDURE IF EXISTS `FPS_FP_Summary_ClientServerTransaction_Monthly`;
DROP PROCEDURE IF EXISTS `FPS_FP_Transform_ClientTransaction_Insert`;
DROP PROCEDURE IF EXISTS `FPS_FP_Monitor_ServerTransactionDailySum_Insert`;
DROP PROCEDURE IF EXISTS `FPS_FP_Monitor_ClientTransactionDailySum_Insert`;


ALTER TABLE `FPS_FingerPrint`.`Transaction` 
DROP COLUMN `ClientTransId`,
DROP COLUMN `ServerTransId`,
DROP COLUMN `AddonId`;

ALTER TABLE `FPS_FingerPrint`.`TransactionDevice` 
DROP COLUMN `ClientTransId`,
DROP COLUMN `ServerTransId`,
DROP COLUMN `AddonId`;

ALTER TABLE `FPS_FingerPrint`.`TransactionEvolution` 
DROP COLUMN `ClientTransId`,
DROP COLUMN `ServerTransId`,
DROP COLUMN `AddonId`;

ALTER TABLE `FPS_FingerPrint`.`TransactionCompleted` 
DROP COLUMN `ClientTransId`,
DROP COLUMN `ServerTransId`,
DROP COLUMN `AddonId`;

ALTER TABLE `FPS_FingerPrint`.`BrowserInfo` 
DROP COLUMN `SessionKey`,
DROP INDEX `UX_BrowserInfo_SessionKey` ;

ALTER TABLE `FPS_FingerPrint`.`BrowserInfo` 
CHANGE COLUMN `HeadlessScore` `HeadlessDetail` LONGTEXT NULL DEFAULT NULL,
ADD COLUMN `HeadlessScore` DECIMAL(1) NULL;

ALTER TABLE `FPS_FingerPrint`.`BrowserInfo` 
ADD COLUMN `BrowserInfoCode` VARCHAR(64) NULL,
ADD COLUMN `Flagged` SMALLINT NULL,
ADD UNIQUE KEY `UX_BrowserInfo_BrowserInfoCode_UAId_BIAId` (`BrowserInfoCode`,`UserAgentId`,`BrowserInfoAttributeId`);

