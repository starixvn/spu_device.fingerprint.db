/*<info serverAlias="FPSDC-FPS_FingerPrint" databaseType="2"></info>*/
/*
	Created: 20220418@Jonathan.Doan [Redmine ID: #166727]
	Task: Init Data
	DB: FPS_FingerPrint
*/
INSERT IGNORE INTO FPS_FingerPrint.Offset(Id, OffsetName, OffsetValue, CreatedDate)
SELECT 1, 'UpdateServerTransaction', 0, NOW()
UNION ALL
SELECT 2, 'UpdateServerTransactionN', 0, NOW()
UNION ALL
SELECT 3, 'DetectRawUserAgent', 0, NOW()
UNION ALL
SELECT 4, 'SummaryClientTransaction', 0, NOW()
UNION ALL
SELECT 5, 'SummaryServerTransaction', 0, NOW()
UNION ALL
SELECT 6, 'SummaryTransaction', 0, NOW()
UNION ALL
SELECT 7, 'TurnOnSPLog_FPS_Fingerpring', 0, NOW()
UNION ALL
SELECT 8, 'TurnOnSPLog_FPS_Testing', 0, NOW();


INSERT INTO FPS_FingerPrint.Subscribers(Id, Name, IsActive, CreatedDate, ModifiedDate) 
VALUES (2,'Alpha',1,NULL,NULL),(5,'Demo',1,NULL,NULL);
