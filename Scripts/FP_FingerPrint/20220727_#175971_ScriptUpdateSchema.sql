/*<info serverAlias="FPSDC-FPS_FingerPrint" databaseType="2"></info>*/
/*
	Created: 20220728@Jonathan.Doan [Redmine ID: #175971]
	Task: Srcipt update Schema
	DB: FPS_FingerPrint
*/
USE FPS_FingerPrint;

ALTER TABLE `FPS_FingerPrint`.`ServerTransaction` 
ADD COLUMN `UserAgentId` BIGINT UNSIGNED NULL AFTER `ClientIP`;

ALTER TABLE `FPS_FingerPrint`.`ServerTransactionCompleted` 
ADD COLUMN `UserAgentId` BIGINT UNSIGNED NULL AFTER `ClientIP`;


ALTER TABLE `FPS_FingerPrint`.`BrowserInfo` 
DROP COLUMN `ClientIPDNS`;

ALTER TABLE `FPS_FingerPrint`.`BrowserInfoCompleted` 
DROP COLUMN `ClientIPDNS`;

ALTER TABLE `FPS_FingerPrint`.`BrowserInfoAttribute` 
DROP COLUMN `UserAgentData`;
