/*<info serverAlias="FPSDC-FPS_FingerPrint" databaseType="2"></info>*/
/*
	Created: 20220622@Jonathan.Doan [Redmine ID: #174020]
	Task: Srcipt update Schema
	DB: FPS_FingerPrint
*/

ALTER TABLE `FPS_FingerPrint`.`ClientTransaction` 
ADD UNIQUE INDEX `UX_ClientTransaction_SessionKey` (`SessionKey` ASC);