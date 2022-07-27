/*<info serverAlias="FPSDC-FPS_FingerPrint" databaseType="2"></info>*/
/*
	Created: 20220727@Jonathan.Doan [Redmine ID: #172167]
	Task: Srcipt update Schema
	DB: FPS_FingerPrint
*/
USE FPS_FingerPrint;

ALTER TABLE `FPS_FingerPrint`.`BrowserInfo` 
ADD COLUMN `IsMobileDevice` TINYINT(1) NULL AFTER `Vendor`;

ALTER TABLE `FPS_FingerPrint`.`BrowserInfoCompleted` 
ADD COLUMN `IsMobileDevice` TINYINT(1) NULL AFTER `Vendor`;