/*<info serverAlias="FPSDC-FPS_FingerPrint" databaseType="2"></info>*/
/*
	Created: 20231023@Jonathan.Doan [Redmine id: #195880]
	Task: Srcipt update Schema
	DB: FPS_FingerPrint
*/
USE FPS_FingerPrint;

ALTER TABLE `FPS_FingerPrint`.`Transaction` 
ADD COLUMN `Flagged` SMALLINT DEFAULT NULL,
ADD COLUMN `BotDetectionValue` BIT(32) DEFAULT NULL,
ADD COLUMN `BotComponentId` BIGINT UNSIGNED DEFAULT NULL,
DROP COLUMN `BrowserInfoId`;

ALTER TABLE `FPS_FingerPrint`.`TransactionCompleted` 
ADD COLUMN `Flagged` SMALLINT DEFAULT NULL,
ADD COLUMN `BotDetectionValue` BIT(32) DEFAULT NULL,
ADD COLUMN `BotComponentId` BIGINT UNSIGNED DEFAULT NULL,
DROP COLUMN `BrowserInfoId`;

ALTER TABLE `FPS_FingerPrint`.`TransactionDevice`
ADD COLUMN `Flagged` SMALLINT DEFAULT NULL,
ADD COLUMN `BotDetectionValue` BIT(32) DEFAULT NULL,
ADD COLUMN `BotComponentId` BIGINT UNSIGNED DEFAULT NULL,
DROP COLUMN `BrowserInfoId`;

ALTER TABLE `FPS_FingerPrint`.`TransactionEvolution`
ADD COLUMN `Flagged` SMALLINT DEFAULT NULL,
ADD COLUMN `BotDetectionValue` BIT(32) DEFAULT NULL,
ADD COLUMN `BotComponentId` BIGINT UNSIGNED DEFAULT NULL,
DROP COLUMN `BrowserInfoId`;

CREATE TABLE `BotDetection` (
  `Value` BIT(32) NOT NULL,
  `Name` VARCHAR(100) NOT NULL,
  `CreatedDate` DATETIME NULL,
  PRIMARY KEY (`Value`),
  KEY `IX_BotDetection_Name` (`Name`)
) ENGINE=InnoDB;

INSERT INTO FPS_FingerPrint.BotDetection(Value, Name, CreatedDate)
VALUES 	(1,'detectAppVersion', NOW())
	,	(2,'detectDocumentAttributes', NOW())
	,	(4,'detectErrorTrace', NOW())
	,	(8,'detectEvalLengthInconsistency', NOW())
	,	(16,'detectFunctionBind', NOW())
	,	(32,'detectLanguagesLengthInconsistency', NOW())
	,	(64,'detectNotificationPermissions', NOW())
	,	(128,'detectPluginsArray', NOW())
	,	(256,'detectPluginsLengthInconsistency', NOW())
	,	(512,'detectProcess', NOW())
	,	(1024,'detectUserAgent', NOW())
	,	(2048,'detectWebDriver', NOW())
	,	(4096,'detectWebGL', NOW())
	,	(8192,'detectWindowExternal', NOW())
	,	(16384,'detectWindowSize', NOW())
	,	(32768,'detectMimeTypesConsistent', NOW())
	,	(65536,'detectProductSub', NOW())
	,	(131072,'detectDistinctiveProperties', NOW())
	,	(262144,'detectPlatform', NOW())
	,	(524288,'detectVmFromMemoryScreenDimensions', NOW())
;

CREATE TABLE `BotComponent` (
  `Id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `Code` VARCHAR(100) NOT NULL,
  `Component` LONGTEXT NOT NULL,
  `CreatedDate` DATETIME DEFAULT NULL,
  `IsHuman` BOOL DEFAULT NULL,
  `ModifiedDate` DATETIME DEFAULT NULL,
  PRIMARY KEY (`Id`),
  UNIQUE KEY `UX_BotComponent_Code` (`Code`),
  KEY `IX_BotComponent_ModifiedDate` (`ModifiedDate`)
) ENGINE=InnoDB;

CREATE TABLE `StaticList` (
  `ListId` INT NOT NULL,
  `ItemId` SMALLINT NOT NULL,
  `ListCode` VARCHAR(100) DEFAULT NULL,
  `ListName` VARCHAR(200) DEFAULT NULL,
  `ItemCode` VARCHAR(100) DEFAULT NULL,
  `ItemName` VARCHAR(200) DEFAULT NULL,
  `Status` TINYINT DEFAULT NULL,
  `Description` VARCHAR(200) DEFAULT NULL,
  `CreatedDate` DATETIME DEFAULT NULL,
  `GroupId` TINYINT DEFAULT NULL,
  `GroupName` TINYINT DEFAULT NULL,
  PRIMARY KEY (`Listid`,`Itemid`),
  UNIQUE KEY `UX_StaticList_ListCode_ItemCode` (`ListCode`,`ItemCode`)
) ENGINE=InnoDB;

INSERT INTO FPS_FingerPrint.StaticList (Listid, Itemid, ListCode, ListName, ItemCode, ItemName, Status, Description, CreatedDate, Groupid) VALUES
(1, 1, 'Flagged', 'Flagged','Human', 'Human',1,'', current_timestamp(), 1)
,(1, 2, 'Flagged', 'Flagged','EmptyToken', 'Invalid Browser Info',1,'Empty Token', current_timestamp(), 2)
,(1, 3, 'Flagged', 'Flagged','InvalidToken', 'Invalid Browser Info',1,'Invalid Token', current_timestamp(), 2)
,(1, 4, 'Flagged', 'Flagged','EmptyAnalysis', 'Invalid Browser Info',1,'Empty Analysis', current_timestamp(), 2)
,(1, 5, 'Flagged', 'Flagged','InvalidAnalysis', 'Invalid Browser Info',1,'Invalid Analysis', current_timestamp(), 2)
,(1, 6, 'Flagged', 'Flagged','EmptyDevice', 'Invalid Browser Info',1,'Empty Device', current_timestamp(), 2)
,(1, 7, 'Flagged', 'Flagged','InvalidDevice', 'Invalid Browser Info',1,'Invalid Device', current_timestamp(), 2)
,(1, 8, 'Flagged', 'Flagged','EmptyUserAgent', 'Invalid Browser Info',1,'Empty UserAgent', current_timestamp(), 2)
,(1, 9, 'Flagged', 'Flagged','Headless', 'Bot',1,'Bot - Headless Chrome', current_timestamp(), 3)
,(1, 10, 'Flagged', 'Flagged','awesomium', 'Bot',1,'Bot - Awesomium', current_timestamp(), 3)
,(1, 11, 'Flagged', 'Flagged','cef', 'Bot',1,'Bot - Cef', current_timestamp(), 3)
,(1, 12, 'Flagged', 'Flagged','cefsharp', 'Bot',1,'Bot - CefSharp', current_timestamp(), 3)
,(1, 13, 'Flagged', 'Flagged','coachjs', 'Bot',1,'Bot - CoachJS', current_timestamp(), 3)
,(1, 14, 'Flagged', 'Flagged','electron', 'Bot',1,'Bot - Electron', current_timestamp(), 3)
,(1, 15, 'Flagged', 'Flagged','fminer', 'Bot',1,'Bot - FMiner', current_timestamp(), 3)
,(1, 16, 'Flagged', 'Flagged','geb', 'Bot',1,'Bot - Geb', current_timestamp(), 3)
,(1, 17, 'Flagged', 'Flagged','nightmarejs', 'Bot',1,'Bot - NightmareJS', current_timestamp(), 3)
,(1, 18, 'Flagged', 'Flagged','phantomas', 'Bot',1,'Bot - Phantomas', current_timestamp(), 3)
,(1, 19, 'Flagged', 'Flagged','phantomjs', 'Bot',1,'Bot - PhantomJS', current_timestamp(), 3)
,(1, 20, 'Flagged', 'Flagged','rhino', 'Bot',1,'Bot - Rhino', current_timestamp(), 3)
,(1, 21, 'Flagged', 'Flagged','selenium', 'Bot',1,'Bot - Selenium', current_timestamp(), 3)
,(1, 22, 'Flagged', 'Flagged','sequentum', 'Bot',1,'Bot - Sequentum', current_timestamp(), 3)
,(1, 23, 'Flagged', 'Flagged','slimerjs', 'Bot',1,'Bot - SlimerJS', current_timestamp(), 3)
,(1, 24, 'Flagged', 'Flagged','webdriverio', 'Bot',1,'Bot - WebDriverIO', current_timestamp(), 3)
,(1, 25, 'Flagged', 'Flagged','webdriver', 'Bot',1,'Bot - WebDriver', current_timestamp(), 3)
,(1, 26, 'Flagged', 'Flagged','headless_chrome', 'Bot',1,'Bot - Headless Chrome', current_timestamp(), 3)
,(1, 27, 'Flagged', 'Flagged','unknown', 'Bot',1,'Bot - Unknown', current_timestamp(), 3);
