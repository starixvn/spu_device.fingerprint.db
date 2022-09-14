/*<info serverAlias="FPSDC-FPS_FingerPrint" databaseType="2"></info>*/
/*
	Created: 20220825@Jonathan.Doan [Redmine ID: #176820]
	Task: Srcipt update Schema
	DB: FPS_FingerPrint
*/
USE FPS_FingerPrint;

INSERT INTO `FPS_FingerPrint`.`Offset` (`Id`, `OffsetName`, `OffsetValue`, `CreatedDate`) VALUES ('12', 'UpdateEvolution', '0', NOW());

CREATE TABLE `Account` (
  `Id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `SubscriberId` INT DEFAULT NULL,
  `LoginName` VARCHAR(100) DEFAULT NULL,
  `CreatedDate` DATETIME DEFAULT NULL,
  `ModifiedDate` DATETIME DEFAULT NULL,
  PRIMARY KEY (`Id`),
  KEY `IX_Account_SubscriberId_LoginName` (`SubscriberId`,`LoginName`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `BrowserInstance` (
  `Id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `OSName` VARCHAR(100) DEFAULT NULL,
  `Platform` VARCHAR(15) DEFAULT NULL,
  `BrowserName` VARCHAR(100) DEFAULT NULL,
  `CreatedDate` DATETIME DEFAULT NULL,
  `ModifiedDate` DATETIME DEFAULT NULL,
  PRIMARY KEY (`Id`),
  UNIQUE KEY `UX_BrowserInstance_OSName_Platform_BrowserName` (`OSName`,`Platform`,`BrowserName`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `AccountFingerprint` (
  `Id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `AccountId` BIGINT UNSIGNED DEFAULT NULL,
  `BrowserInstanceId` BIGINT UNSIGNED DEFAULT NULL,
  `FingerPrintId` BIGINT UNSIGNED DEFAULT NULL,
  `IsEvolution` BOOLEAN DEFAULT NULL,
  `CreatedDate` DATETIME DEFAULT NULL,
  `ModifiedDate` DATETIME DEFAULT NULL,
  PRIMARY KEY (`Id`),
  UNIQUE KEY `UX_AccountFingerprint_AccountId_BrowserInstanceId_FingerPrintId` (`AccountId`,`BrowserInstanceId`,`FingerPrintId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `FingerPrintEvolution` (
  `Id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `ServerTransId` bigint unsigned DEFAULT NULL,
  `CustId` bigint unsigned DEFAULT NULL,
  `SubAccId` bigint unsigned DEFAULT NULL,
  `LoginName` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `SubscriberId` int DEFAULT NULL,
  `RawFingerPrintId` bigint unsigned DEFAULT NULL,
  `CookieId` bigint unsigned DEFAULT NULL,
  `TransTime` datetime(4) DEFAULT NULL,
  `ClientIP` varchar(45) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `BrowserInfoId` bigint unsigned DEFAULT NULL,
  `UserAgentId` bigint unsigned DEFAULT NULL,
  `Url` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `Action` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `CreatedDate` datetime DEFAULT NULL,
  `TransKey` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `AddonId` bigint unsigned DEFAULT NULL,
  PRIMARY KEY (`Id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `RecoverDailySum` (
  `TransDate` DATE NOT NULL,
  `SubscriberId` INT UNSIGNED NOT NULL,
  `TotalRecoverTrans` BIGINT UNSIGNED DEFAULT NULL,
  `TotalEvolutionTrans` BIGINT UNSIGNED DEFAULT NULL,
  `CreatedDate` DATETIME DEFAULT NULL,
  `ModifiedDate` DATETIME DEFAULT NULL,
  PRIMARY KEY (`TransDate`,`SubscriberId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

ALTER TABLE `FPS_FingerPrint`.`FingerPrintAttribute` 
ADD COLUMN `OSName` VARCHAR(100) NULL,
ADD COLUMN `BrowserName` VARCHAR(100) NULL,
ADD COLUMN `BrowserVersion` VARCHAR(50) NULL,
ADD COLUMN `DoNotTrack` VARCHAR(15) NULL,
ADD COLUMN `GLRenderer` VARCHAR(200) NULL,
ADD COLUMN `HeaderAccept` VARCHAR(100) NULL,
ADD COLUMN `HeaderAcceptEncoding` VARCHAR(200) NULL,
ADD COLUMN `Headers` VARCHAR(500) NULL,
ADD COLUMN `Audio` VARCHAR(25) NULL,
ADD COLUMN `CanvasPrint` LONGTEXT NULL,
ADD COLUMN `ColorDepth` SMALLINT NULL,
ADD COLUMN `ColorGamut` VARCHAR(10) NULL,
ADD COLUMN `Contrast` SMALLINT NULL,
ADD COLUMN `CookiesEnabled` BOOLEAN NULL,
ADD COLUMN `CpuClass` VARCHAR(45) NULL,
ADD COLUMN `DeviceMemory` TINYINT NULL,
ADD COLUMN `DomBlockers` VARCHAR(45) NULL,
ADD COLUMN `FontPreferencePrint` VARCHAR(500) NULL,
ADD COLUMN `Fonts` VARCHAR(500) NULL,
ADD COLUMN `ForcedColors` BOOLEAN NULL,
ADD COLUMN `HardwareConcurrency` TINYINT NULL,
ADD COLUMN `HDR` BOOLEAN NULL,
ADD COLUMN `IndexedDB` BOOLEAN NULL,
ADD COLUMN `InvertedColors` BOOLEAN NULL,
ADD COLUMN `LanguagesPrint` VARCHAR(500) NULL,
ADD COLUMN `LocalStorage` BOOLEAN NULL,
ADD COLUMN `Math` VARCHAR(1000) NULL,
ADD COLUMN `Monochrome` TINYINT NULL,
ADD COLUMN `OpenDatabase` BOOLEAN NULL,
ADD COLUMN `OsCpu` VARCHAR(45) NULL,
ADD COLUMN `Platform` VARCHAR(45) NULL,
ADD COLUMN `Plugins` LONGTEXT NULL,
ADD COLUMN `ReducedMotion` BOOLEAN NULL,
ADD COLUMN `ScreenPrint` VARCHAR(200) NULL,
ADD COLUMN `SessionStorage` BOOLEAN NULL,
ADD COLUMN `Timezone` VARCHAR(45) NULL,
ADD COLUMN `TouchSupport` VARCHAR(200) NULL,
ADD COLUMN `Vendor` VARCHAR(45) NULL,
ADD COLUMN `VendorFlavors` VARCHAR(45) NULL,
ADD COLUMN `WebglPrint` VARCHAR(200) NULL;


