/*<info serverAlias="FPSDC-FPSTesting" databaseType="2"></info>*/
/*
	Created: 20231018@Teddy.Le [Redmine ID: #195602]
	Task: Update Schema
	DB: FPSTesting
*/

USE FPSTesting;

ALTER TABLE `FPSTesting`.`FP_RawTransaction` 
ADD COLUMN `FakeIP` VARCHAR(45) CHARACTER SET 'utf8mb4' COLLATE 'utf8mb4_0900_ai_ci' NULL DEFAULT NULL AFTER `IP`;

ALTER TABLE `FPSTesting`.`FP_RawTransaction_Old_Completed` 
ADD COLUMN `FakeIP` VARCHAR(45) CHARACTER SET 'utf8mb4' COLLATE 'utf8mb4_0900_ai_ci' NULL DEFAULT NULL AFTER `IP`;

ALTER TABLE `FPSTesting`.`FP_ProcessedTransaction` 
ADD COLUMN `FakeIP` VARCHAR(45) CHARACTER SET 'utf8mb4' COLLATE 'utf8mb4_0900_ai_ci' NULL DEFAULT NULL AFTER `IP`;