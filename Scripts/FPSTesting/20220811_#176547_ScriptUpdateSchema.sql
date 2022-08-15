/*<info serverAlias="FPSDC-FPSTesting" databaseType="2"></info>*/
/*
	Created: 20220811@Jonathan.Doan [Redmine ID: #176547]
	Task: Srcipt update Schema
	DB: FPSTesting
*/
USE FPSTesting;

ALTER TABLE `FPSTesting`.`FP_RawTransaction` 
ADD COLUMN `BrowserInfoId` BIGINT NULL;

ALTER TABLE `FPSTesting`.`FP_RawTransaction` 
ADD INDEX `IX_RawTransaction_BrowserInfoId` (`BrowserInfoId` ASC);
