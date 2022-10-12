/*<info serverAlias="FPSDC-CTS_Log" databaseType="2"></info>*/
/*
	Created: 20220912@Terry.Nguyen [Redmine ID: #176816]
	Task: Srcipt update Schema
	DB: CTS_Log
*/
USE CTS_Log;

CREATE TABLE `FPSClientTransaction_Exception` (
  `Id` int NOT NULL AUTO_INCREMENT,
  `FunctionName` varchar(100) COLLATE utf8_unicode_ci DEFAULT NULL,
  `Exception` text COLLATE utf8_unicode_ci,
  `UserAgent` varchar(500) COLLATE utf8_unicode_ci DEFAULT NULL,
  `CreatedDate` datetime DEFAULT NULL,
  PRIMARY KEY (`Id`),
  KEY `idx_FPSClientTransaction_Exception_FunctionName` (`FunctionName`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb3 COLLATE=utf8_unicode_ci;

