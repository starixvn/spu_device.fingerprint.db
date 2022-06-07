ALTER TABLE `FPS_FingerPrint`.`FingerPrintAttribute` 
CHANGE COLUMN `RawFingerPrintId` `FingerPrintCode` VARCHAR(64) NOT NULL ;

ALTER TABLE `FPS_FingerPrint`.`FingerPrintAttribute` ;
ALTER TABLE `FPS_FingerPrint`.`FingerPrintAttribute` RENAME INDEX `FingerPrintCode_UNIQUE` TO `UX_FingerPrintAttribute_FingerPrintCode`;
ALTER TABLE `FPS_FingerPrint`.`FingerPrintAttribute` ALTER INDEX `UX_FingerPrintAttribute_FingerPrintCode` VISIBLE;
