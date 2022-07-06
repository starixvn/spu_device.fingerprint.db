/*<info serverAlias="FPSDC-FPS_FingerPrint" databaseType="2"></info>*/
/*
	Created: 20220609@Jonathan.Doan [Redmine ID: #173803]
	Task: Srcipt update Schema
	DB: FPS_FingerPrint
*/

ALTER TABLE `FPS_FingerPrint`.`FingerPrintAttribute` 
CHANGE COLUMN `RawFingerPrintId` `FingerPrintCode` VARCHAR(64) NOT NULL ;

ALTER TABLE `FPS_FingerPrint`.`FingerPrintAttribute` ;
ALTER TABLE `FPS_FingerPrint`.`FingerPrintAttribute` RENAME INDEX `UX_FingerPrintAttribute_RawFingerPrintId` TO `UX_FingerPrintAttribute_FingerPrintCode`;
ALTER TABLE `FPS_FingerPrint`.`FingerPrintAttribute` ALTER INDEX `UX_FingerPrintAttribute_FingerPrintCode` VISIBLE;
