/*<info serverAlias="FPSDC-FPS_FingerPrint" databaseType="2"></info>*/
/*
	Created: 20220912@Terry.Nguyen [Redmine ID: #176816]
	Task: Srcipt update Schema
	DB: FPS_FingerPrint
*/
USE FPS_FingerPrint;

CREATE TABLE `ClientTransaction_Logs` (
  `Id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `SessionKey` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,    
  `SubscriberId` int DEFAULT NULL,
  `Url` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `TransTime` datetime(4) DEFAULT NULL,
  `UserAgent` varchar(300) DEFAULT NULL,
  `CreatedDate` datetime NOT NULL,    
  PRIMARY KEY (`Id`),
  UNIQUE KEY `UX_ClientTransaction_Logs_SessionKey` (`SessionKey`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
