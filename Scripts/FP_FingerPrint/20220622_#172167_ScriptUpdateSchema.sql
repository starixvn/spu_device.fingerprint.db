/*<info serverAlias="FPSDC-FPS_FingerPrint" databaseType="2"></info>*/
/*
	Created: 20220622@Jonathan.Doan [Redmine ID: #172167]
	Task: Srcipt update Schema
	DB: FPS_FingerPrint
*/

CREATE TABLE `BrowserInfo` (
  `Id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `SessionKey` varchar(100) DEFAULT NULL,
  `UserAgentId` bigint unsigned DEFAULT NULL,
  `BrowserInfoAttributeId` bigint unsigned DEFAULT NULL,
  `HeadlessScore` longtext,
  `ClientIp` varchar(45) DEFAULT NULL,
  `BrowserName` varchar(100) DEFAULT NULL,
  `OSName` varchar(100) DEFAULT NULL,
  `CreatedDate` datetime(4) DEFAULT NULL,
  `ModifiedDate` datetime(4) DEFAULT NULL,
  PRIMARY KEY (`Id`),
  UNIQUE KEY `UX_BrowserInfo_SessionKey` (`SessionKey`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `BrowserInfoAttribute` (
  `Id` bigint NOT NULL AUTO_INCREMENT,
  `Code` varchar(64) DEFAULT NULL,
  `SecChUa` varchar(100) DEFAULT NULL,
  `BrowserInfoJs` varchar(500) DEFAULT NULL,
  `UserAgentData` varchar(500) DEFAULT NULL,
  PRIMARY KEY (`Id`),
  UNIQUE KEY `UX_BrowserInfoAttribute_Code` (`Code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `BrowserInfoCompleted` (
  `Id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `SessionKey` varchar(100) NOT NULL,
  `UserAgentId` bigint unsigned DEFAULT NULL,
  `HeadlessScore` longtext,
  `ClientIp` varchar(45) DEFAULT NULL,
  `BrowserName` varchar(100) DEFAULT NULL,
  `OSName` varchar(100) DEFAULT NULL,
  `Flagged` varchar(50) DEFAULT NULL,
  `Reason` varchar(50) DEFAULT NULL,
  `CreatedDate` datetime(4) NOT NULL,
  PRIMARY KEY (`Id`,`CreatedDate`),
  KEY `IX_BrowserInfoCompleted_SessionKey` (`SessionKey`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
/*!50100 PARTITION BY RANGE (yearweek(`CreatedDate`,0))
(PARTITION pw202210 VALUES LESS THAN (202211) ENGINE = InnoDB,
 PARTITION pw999999 VALUES LESS THAN MAXVALUE ENGINE = InnoDB) */

ALTER TABLE `FPS_FingerPrint`.`ClientTransaction` 
DROP COLUMN `Flagged`,
DROP COLUMN `RobotDetail`;


ALTER TABLE `FPS_FingerPrint`.`ClientTransactionCompleted` 
DROP COLUMN `Flagged`,
DROP COLUMN `RobotDetail`;


ALTER TABLE `FPS_FingerPrint`.`ServerTransaction` 
DROP COLUMN `UserAgentId`;


ALTER TABLE `FPS_FingerPrint`.`ServerTransactionCompleted` 
DROP COLUMN `UserAgentId`;


ALTER TABLE `FPS_FingerPrint`.`Transaction` 
DROP COLUMN `Flagged`,
ADD COLUMN `BrowserInfoId` BIGINT UNSIGNED NULL AFTER `ClientIP`;


ALTER TABLE `FPS_FingerPrint`.`TransactionCompleted` 
DROP COLUMN `Flagged`,
ADD COLUMN `BrowserInfoId` BIGINT UNSIGNED NULL AFTER `ClientIP`;


ALTER TABLE `FPS_FingerPrint`.`TransactionDevice` 
DROP COLUMN `Flagged`,
ADD COLUMN `BrowserInfoId` BIGINT UNSIGNED NULL AFTER `ClientIP`;


INSERT IGNORE INTO `FPS_FingerPrint`.`Offset` (`Id`, `OffsetName`, `OffsetValue`) VALUES ('10', 'UpdateBrowserInfo', '0');


ALTER TABLE `FPS_FingerPrint`.`ServerTransaction` 
DROP INDEX `IX_ServerTransaction_SessionKey`,
ADD UNIQUE INDEX `UX_ServerTransaction_SessionKey` (`SessionKey` ASC);
;

ALTER TABLE `FPS_FingerPrint`.`ClientTransaction` 
DROP INDEX `IX_ClientTransaction_SessionKey`,
ADD UNIQUE INDEX `UX_ClientTransaction_SessionKey` (`SessionKey` ASC);
;
