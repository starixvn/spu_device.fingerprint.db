/*<info serverAlias="FPSDC-FPS_FingerPrint" databaseType="2"></info>*/
/*
	Created: 20221020@Jonathan.Doan [Redmine ID: #179362]
	Task: Srcipt update Schema
	DB: FPS_FingerPrint
*/
USE FPS_FingerPrint;

DROP TABLE `FPS_FingerPrint`.`RecoverDailySum`;

CREATE TABLE `RecoverDailySum` (
  `Id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `SubscriberId` int unsigned NOT NULL,
  `TransDate` date NOT NULL,
  `Total` BIGINT UNSIGNED DEFAULT NULL,
  `NullDevice` BIGINT UNSIGNED DEFAULT NULL,
  `NewDevice` BIGINT UNSIGNED DEFAULT NULL,
  `RecoverByFP` BIGINT UNSIGNED DEFAULT NULL,
  `RecoverByCookies` BIGINT UNSIGNED DEFAULT NULL,
  `RecoverByFPnCookies` BIGINT UNSIGNED DEFAULT NULL,
  `RecoverByEvolution` BIGINT UNSIGNED DEFAULT NULL,
  `CreatedDate` datetime DEFAULT NULL,
  `ModifiedDate` datetime DEFAULT NULL,
  PRIMARY KEY (`Id`),
  UNIQUE KEY `UX_RecoverDailySum_SubscriberId_TransDate` (`SubscriberId`,`TransDate`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `TransactionEvolutionCompleted` (
  `Id` bigint unsigned NOT NULL,
  `AccountId` bigint unsigned NOT NULL,
  `IsEvolution` tinyint(1),
  `CreatedDate` datetime DEFAULT NULL,
  `ModifiedDate` datetime DEFAULT NULL,
  PRIMARY KEY (`Id`),
  INDEX `IX_TransactionEvolutionCompleted_AccountId` (`AccountId`),
  INDEX `IX_TransactionEvolutionCompleted_IsEvolution` (`IsEvolution`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


ALTER TABLE `FPS_FingerPrint`.`AccountFingerprint` 
ADD INDEX `IX_AccountFingerprint_IsEvolution` (`IsEvolution`);

INSERT INTO `FPS_FingerPrint`.`Offset` (`Id`, `OffsetName`, `OffsetValue`, `CreatedDate`) VALUES ('13', 'SummaryRecoverType', '0', '2022-10-26 00:00:00');
