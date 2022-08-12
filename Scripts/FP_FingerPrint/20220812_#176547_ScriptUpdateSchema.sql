/*<info serverAlias="FPSDC-FPS_FingerPrint" databaseType="2"></info>*/
/*
	Created: 20220812@Jonathan.Doan [Redmine ID: #176547]
	Task: Srcipt update Schema
	DB: FPS_FingerPrint
*/
USE FPS_FingerPrint;

ALTER TABLE `FPS_FingerPrint`.`BrowserInfo` 
DROP COLUMN `IsMobileDevice`,
DROP COLUMN `Vendor`,
DROP COLUMN `Platform`;

ALTER TABLE `FPS_FingerPrint`.`BrowserInfoCompleted` 
DROP COLUMN `IsMobileDevice`,
DROP COLUMN `Vendor`,
DROP COLUMN `Platform`;

ALTER TABLE `FPS_FingerPrint`.`BrowserInfoAttribute` 
DROP COLUMN `BrowserInfoJs`,
ADD COLUMN `JsBrowserName` VARCHAR(100) NULL AFTER `SecChUaMobile`,
ADD COLUMN `JsOSName` VARCHAR(100) NULL AFTER `JsBrowserName`;
