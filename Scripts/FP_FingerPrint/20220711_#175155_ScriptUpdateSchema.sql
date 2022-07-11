/*<info serverAlias="FPSDC-FPS_FingerPrint" databaseType="2"></info>*/
/*
	Created: 20220711@Jonathan.Doan [Redmine ID: #175155]
	Task: Srcipt update Schema
	DB: FPS_FingerPrint
*/

ALTER TABLE `FPS_FingerPrint`.`FingerPrintAttribute` 
CHANGE COLUMN `CanvasDefender` `CanvasDefender` BOOLEAN NULL DEFAULT NULL ,
CHANGE COLUMN `WebGLDefender` `WebGLDefender` BOOLEAN NULL DEFAULT NULL ;
