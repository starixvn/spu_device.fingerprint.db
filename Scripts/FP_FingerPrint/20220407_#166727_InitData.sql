
INSERT IGNORE INTO FPS_FingerPrint.Offset(Id, OffsetName, OffsetValue, CreatedDate)
SELECT 1, 'UpdateServerTransaction', 0, NOW()
UNION ALL
SELECT 2, 'UpdateServerTransactionN', 0, NOW()
UNION ALL
SELECT 3, 'DetectRawUserAgent', 0
UNION ALL
SELECT 4, 'SummaryClientTransaction', 0, NOW()
UNION ALL
SELECT 5, 'SummaryServerTransaction', 0, NOW()
UNION ALL
SELECT 6, 'SummaryTransaction', 0, NOW()
UNION ALL
SELECT 7, 'TurnOnSPLog_FPS_Fingerpring', 0, NOW()
UNION ALL
SELECT 8, 'TurnOnSPLog_FPS_Testing', 0, NOW()