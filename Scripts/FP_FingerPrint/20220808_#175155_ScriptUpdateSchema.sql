/*<info serverAlias="FPSDC-FPS_FingerPrint" databaseType="2"></info>*/
/*
	Created: 20220808@Jonathan.Doan [Redmine ID: #175155]
	Task: Srcipt update Schema
	DB: FPS_FingerPrint
*/
USE FPS_FingerPrint;

CREATE TABLE `Addon` (
  `Id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `AddonCode` VARCHAR(45) DEFAULT NULL,
  `CanvasDefender` BOOLEAN DEFAULT NULL,
  `WebGLDefender` BOOLEAN DEFAULT NULL,
  `AudioContextDefender` BOOLEAN DEFAULT NULL,
  `FontDefender` BOOLEAN DEFAULT NULL,
  PRIMARY KEY (`Id`),
  UNIQUE KEY `UX_Addon_AddonCode` (`AddonCode`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

ALTER TABLE `FPS_FingerPrint`.`ClientTransaction`
ADD COLUMN `AddonId` BIGINT UNSIGNED NULL;

ALTER TABLE `FPS_FingerPrint`.`ClientTransactionCompleted`
ADD COLUMN `AddonId` BIGINT UNSIGNED NULL;

ALTER TABLE `FPS_FingerPrint`.`Transaction`
ADD COLUMN `AddonId` BIGINT UNSIGNED NULL;

ALTER TABLE `FPS_FingerPrint`.`TransactionCompleted`
ADD COLUMN `AddonId` BIGINT UNSIGNED NULL;

ALTER TABLE `FPS_FingerPrint`.`TransactionDevice`
ADD COLUMN `AddonId` BIGINT UNSIGNED NULL;