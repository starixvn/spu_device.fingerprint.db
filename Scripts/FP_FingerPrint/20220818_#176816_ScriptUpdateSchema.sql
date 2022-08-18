/*<info serverAlias="FPSDC-FPS_FingerPrint" databaseType="2"></info>*/
/*
	Created: 20220818@Jonathan.Doan [Redmine ID: #176816]
	Task: Srcipt update Schema
	DB: FPS_FingerPrint
*/
USE FPS_FingerPrint;

ALTER TABLE `FPS_FingerPrint`.`RawUserAgent` 
ADD INDEX `IX_RawUserAgent_Brand` (`Brand`) ;
