/*<info serverAlias="FPSDC-FPS_FingerPrint" databaseType="2"></info>*/
/*
	Created: 20231017@Teddy.Le [Redmine ID: #195602]
	Task: Detect real ip and fake ip via x-real-ip
	DB: FPS_FingerPrint
*/
USE FPS_FingerPrint;

ALTER TABLE `FPS_FingerPrint`.`Transaction` 
ADD COLUMN `FakeIP` VARCHAR(45) CHARACTER SET 'utf8mb4' COLLATE 'utf8mb4_0900_ai_ci' NULL DEFAULT NULL AFTER `ClientIP`;

ALTER TABLE `FPS_FingerPrint`.`TransactionEvolution` 
ADD COLUMN `FakeIP` VARCHAR(45) CHARACTER SET 'utf8mb4' COLLATE 'utf8mb4_0900_ai_ci' NULL DEFAULT NULL AFTER `ClientIP`;
