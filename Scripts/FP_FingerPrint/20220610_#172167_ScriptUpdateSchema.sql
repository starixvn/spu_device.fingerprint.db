/*<info serverAlias="FPSDC-FPS_FingerPrint" databaseType="2"></info>*/
/*
	Created: 20220610@Jonathan.Doan [Redmine ID: #172167]
	Task: Srcipt update Schema
	DB: FPS_FingerPrint
*/

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
