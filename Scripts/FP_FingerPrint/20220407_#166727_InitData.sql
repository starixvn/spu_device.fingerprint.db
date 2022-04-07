
INSERT IGNORE INTO FPS_FingerPrint.Offset(Id, OffsetName, OffsetValue)
SELECT 1, 'UpdateServerTransaction', 0
UNION ALL
SELECT 2, 'UpdateServerTransactionN', 0
UNION ALL
SELECT 3, 'DetectRawUserAgent', 0
UNION ALL
SELECT 4, 'SummaryClientTransaction', 0
UNION ALL
SELECT 5, 'SummaryServerTransaction', 0
UNION ALL
SELECT 6, 'SummaryTransaction', 0