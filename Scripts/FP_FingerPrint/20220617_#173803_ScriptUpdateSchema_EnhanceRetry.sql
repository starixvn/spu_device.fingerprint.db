/*<info serverAlias="FPSDC-FPS_FingerPrint" databaseType="2"></info>*/
/*
	Created: 20220609@terry.nugyen [Redmine ID: #173803]
	Task: Srcipt update Schema
	DB: FPS_FingerPrint
*/

ALTER TABLE `FPS_FingerPrint`.`ServerTransactionN` 
ADD COLUMN `Retry` INT NULL DEFAULT 0 AFTER `CreatedDate`,
ADD UNIQUE INDEX `UX_ServerTransactionN_ServerTransId` (`ServerTransId` ASC) VISIBLE;