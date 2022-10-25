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
  `RecoverType` smallint unsigned NOT NULL COMMENT '0: New device\\n1: Recover By FP\\n2: Recover By Cookies\\n3: Recover By FP & Cookies\\n4: Recover By Evolution',
  `SubscriberId` int unsigned NOT NULL,
  `TransDate` date NOT NULL,
  `Total` bigint unsigned DEFAULT NULL,
  `CreatedDate` datetime DEFAULT NULL,
  `ModifiedDate` datetime DEFAULT NULL,
  PRIMARY KEY (`Id`),
  UNIQUE KEY `UX_RecoverDailySum_RecoverType_SubscriberId_TransDate` (`RecoverType`,`SubscriberId`,`TransDate`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `TransactionEvolutionCompleted` (
  `Id` bigint unsigned NOT NULL,
  `ServerTransId` bigint unsigned  NOT NULL,
  `ClientTransId` bigint unsigned  NOT NULL,
  `AccountId` bigint unsigned NOT NULL,
  `IsEvolution` tinyint(1),
  `CreatedDate` datetime DEFAULT NULL,
  `ModifiedDate` datetime DEFAULT NULL,
  PRIMARY KEY (`Id`),
  INDEX `IX_TransactionEvolutionCompleted_ServerTransId` (`ServerTransId`),
  INDEX `IX_TransactionEvolutionCompleted_AccountId` (`AccountId`),
  INDEX `IX_TransactionEvolutionCompleted_IsEvolution` (`IsEvolution`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


CREATE INDEX IX_AccountFingerprint_IsEvolution ON FPS_FingerPrint.AccountFingerprint(IsEvolution);

ALTER TABLE `FPS_FingerPrint`.`AccountFingerprint` 
ADD INDEX `IX_AccountFingerprint_IsEvolution` (`IsEvolution`);
