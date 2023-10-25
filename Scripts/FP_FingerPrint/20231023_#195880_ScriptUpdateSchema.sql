/*<info serverAlias="FPSDC-FPS_FingerPrint" databaseType="2"></info>*/
/*
	Created: 20231023@Jonathan.Doan [Redmine id: #195880]
	Task: Srcipt update Schema
	DB: FPS_FingerPrint
*/
USE FPS_FingerPrint;

ALTER TABLE `FPS_FingerPrint`.`Transaction` 
ADD COLUMN `Flagged` SMALLINT DEFAULT NULL,
ADD COLUMN `BotDetectionValue` BIT(32) DEFAULT NULL,
ADD COLUMN `BotComponentId` BIGINT UNSIGNED DEFAULT NULL,
DROP COLUMN `BrowserInfoId`;

ALTER TABLE `FPS_FingerPrint`.`TransactionCompleted` 
ADD COLUMN `Flagged` SMALLINT DEFAULT NULL,
ADD COLUMN `BotDetectionValue` BIT(32) DEFAULT NULL,
ADD COLUMN `BotComponentId` BIGINT UNSIGNED DEFAULT NULL,
DROP COLUMN `BrowserInfoId`;

ALTER TABLE `FPS_FingerPrint`.`TransactionDevice`
ADD COLUMN `Flagged` SMALLINT DEFAULT NULL,
ADD COLUMN `BotDetectionValue` BIT(32) DEFAULT NULL,
ADD COLUMN `BotComponentId` BIGINT UNSIGNED DEFAULT NULL,
DROP COLUMN `BrowserInfoId`;

ALTER TABLE `FPS_FingerPrint`.`TransactionEvolution`
ADD COLUMN `Flagged` SMALLINT DEFAULT NULL,
ADD COLUMN `BotDetectionValue` BIT(32) DEFAULT NULL,
ADD COLUMN `BotComponentId` BIGINT UNSIGNED DEFAULT NULL,
DROP COLUMN `BrowserInfoId`;

CREATE TABLE `BotComponent` (
  `Id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `Code` VARCHAR(100) NOT NULL,
  `Component` LONGTEXT NOT NULL,
  `CreatedDate` DATETIME DEFAULT NULL,
  `IsHuman` BOOL DEFAULT NULL,
  `ModifiedDate` DATETIME DEFAULT NULL,
  PRIMARY KEY (`Id`),
  UNIQUE KEY `UX_BotComponent_Code` (`Code`),
  KEY `IX_BotComponent_ModifiedDate` (`ModifiedDate`)
) ENGINE=InnoDB;

ALTER TABLE `FPS_FingerPrint`.`AccountFingerprint` 
CHANGE COLUMN `IsEvolution` `IsEvolution` TINYINT(1) NULL DEFAULT 0 ;

UPDATE FPS_FingerPrint.AccountFingerprint
SET IsEvolution = 0
WHERE IsEvolution IS NULL;

