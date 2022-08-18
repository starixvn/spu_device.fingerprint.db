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


UPDATE `FPS_FingerPrint`.`BrowserInfoCompleted` 
SET Flagged = '1'
where Flagged = 'human';

UPDATE `FPS_FingerPrint`.`BrowserInfoCompleted` 
SET Flagged = '9'
where Flagged = 'bot';

UPDATE `FPS_FingerPrint`.`BrowserInfoCompleted` 
SET Flagged = '6'
where Flagged = 'undefined';

ALTER TABLE `FPS_FingerPrint`.`BrowserInfoCompleted` 
DROP COLUMN `IsMobileDevice`,
DROP COLUMN `Vendor`,
DROP COLUMN `Platform`,
DROP COLUMN `Reason`,
CHANGE COLUMN `Flagged` `Flagged` SMALLINT NULL DEFAULT NULL;


ALTER TABLE `FPS_FingerPrint`.`BrowserInfoAttribute` 
DROP COLUMN `BrowserInfoJs`,
ADD COLUMN `JsBrowserName` VARCHAR(100) NULL,
ADD COLUMN `JsOSName` VARCHAR(100) NULL;
