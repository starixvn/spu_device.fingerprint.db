/*<info serverAlias="FPSDC-FPS_FingerPrint" databaseType="2"></info>*/
/*
	Created: 20221115@Jonathan.Doan [Redmine ID: #180264]
	Task: Srcipt update Schema
	DB: FPS_FingerPrint
*/
USE FPS_FingerPrint;

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

ALTER TABLE `FPS_FingerPrint`.`TransactionEvolutionCompleted` 
DROP COLUMN `ClientTransId`,
DROP COLUMN `ServerTransId`;

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
ADD COLUMN `BrowserInfoCode` VARCHAR(64) NULL;

ALTER TABLE `FPS_FingerPrint`.`BrowserInfo` 
ADD UNIQUE INDEX `UX_BrowserInfo_BrowserInfoCode` (`BrowserInfoCode`);