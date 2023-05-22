/*<info serverAlias="FPSDC-FPS_FingerPrint" databaseType="2"></info>*/
/*
	Created: 20230522@Jonathan.Doan [Redmine ID: #188551]
	Task: Table Is Overread
	DB: FPS_FingerPrint
*/
USE FPS_FingerPrint;

UPDATE FPS_FingerPrint.AccountFingerprint
SET IsEvolution = 0
WHERE IsEvolution IS NULL;

ALTER TABLE FPS_FingerPrint.AccountFingerprint
MODIFY COLUMN ModifiedDate DATETIME;

ALTER TABLE FPS_FingerPrint.BrowserInstance
MODIFY COLUMN CreatedDate DATETIME,
MODIFY COLUMN ModifiedDate DATETIME;

ALTER TABLE FPS_FingerPrint.Cookie
MODIFY COLUMN CreatedDate DATETIME,
MODIFY COLUMN ModifiedDate DATETIME;

ALTER TABLE FPS_FingerPrint.RawFingerPrint
MODIFY COLUMN CreatedDate DATETIME,
MODIFY COLUMN ModifiedDate DATETIME;