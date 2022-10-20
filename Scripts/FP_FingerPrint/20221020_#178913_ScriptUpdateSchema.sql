/*<info serverAlias="FPSDC-FPS_FingerPrint" databaseType="2"></info>*/
/*
	Created: 20221020@Terry.Nguyen [Redmine ID: #178913]
	Task: Logs Data
	DB: FPS_FingerPrint
*/

ALTER TABLE `FPS_FingerPrint`.`ClientTransaction_Logs` ADD COLUMN `Information` TEXT NULL AFTER `CreatedDate`;

DROP INDEX `UX_ClientTransaction_Logs_SessionKey` ON  `FPS_FingerPrint`.`ClientTransaction_Logs`;

CREATE INDEX `UX_ClientTransaction_Logs_SessionKey_SubscriberId` ON `FPS_FingerPrint`.`ClientTransaction_Logs`(`SubscriberId`,`SessionKey`);