/*<info serverAlias="FPSDC-FPS_FingerPrint" databaseType="2"></info>*/
/*
	Created: 20230529@Jonathan.Doan [Redmine ID: #188882]
	Task: Srcipt update Schema
	DB: FPS_FingerPrint
*/
USE FPS_FingerPrint;

ALTER TABLE `FPS_FingerPrint`.`BrowserInstance` 
CHANGE COLUMN `Accept` `Accept` VARCHAR(200) NULL DEFAULT NULL ;


