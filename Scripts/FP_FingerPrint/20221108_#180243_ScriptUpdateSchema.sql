/*<info serverAlias="FPSDC-FPS_FingerPrint" databaseType="2"></info>*/
/*
	Created: 20221108@Jonathan.Doan [Redmine ID: #180243]
	Task: Srcipt update Schema
	DB: FPS_FingerPrint
*/
USE FPS_FingerPrint;

CREATE TABLE `BrowserInstanceAttribute` (
  `Id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `FingerPrintAttributeId` BIGINT UNSIGNED NOT NULL,
  `BrowserInstanceId` BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY (`Id`),
  UNIQUE KEY `UX_BrowserInstanceAttribute_FPAId_BrowserInstanceId` (`FingerPrintAttributeId`, `BrowserInstanceId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- drop table `BrowserInstance`;
CREATE TABLE `BrowserInstance` (
  `Id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `BrowserInstanceCode` varchar(64) DEFAULT NULL COMMENT 'hash ALL',
  `UserAgent` longtext,
  `BrowserFamilyCode` varchar(64) DEFAULT NULL COMMENT 'hash: OSName, BrowserName, Platform',
  `OSName` varchar(100) DEFAULT NULL,
  `Platform` varchar(45) DEFAULT NULL,
  `BrowserName` varchar(100) DEFAULT NULL,
  `BrowserVersion` varchar(50) DEFAULT NULL,
  `Accept` varchar(100) DEFAULT NULL,
  `Encoding` varchar(200) DEFAULT NULL,
  `Headers` longtext,
  PRIMARY KEY (`Id`),
  UNIQUE KEY `UX_BrowserInstance_BrowserInstanceCode` (`BrowserInstanceCode`),
  KEY `IX_BrowserInstance_BrowserFamilyCode` (`BrowserFamilyCode`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

ALTER TABLE `FPS_FingerPrint`.`FingerPrintAttribute` 
DROP COLUMN `BrowserVersion`,
DROP COLUMN `BrowserName`,
DROP COLUMN `OSName`,
DROP COLUMN `BrowserInstanceCode`,
DROP COLUMN `UserAgent`,
DROP COLUMN `Attribute`,
DROP COLUMN `Headers`,
DROP COLUMN `Encoding`,
DROP COLUMN `Accept`,
DROP INDEX `IX_FingerPrintAttribute_BrowserInstanceCode` ;
