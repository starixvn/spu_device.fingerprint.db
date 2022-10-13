/*<info serverAlias="FPSDC-FPS_FingerPrint" databaseType="2"></info>*/
/*
	Created: 20221012@Jonathan.Doan [Redmine ID: #176820]
	Task: Srcipt update Schema
	DB: FPS_FingerPrint
*/
USE FPS_FingerPrint;

CREATE TABLE `CookieSessionKey` (
  `Id` INT NOT NULL AUTO_INCREMENT,
  `SessionKey` VARCHAR(100) DEFAULT NULL,
  `CookieCode` VARCHAR(64) DEFAULT NULL,
  `CreatedDate` DATETIME DEFAULT NULL,
  PRIMARY KEY (`Id`),
  KEY `IX_CookieSessionKey_SessionKey` (`SessionKey`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8_unicode_ci;

