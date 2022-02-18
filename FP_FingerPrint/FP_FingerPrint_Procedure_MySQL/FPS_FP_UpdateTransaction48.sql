/*<info serverAlias="xxxx" databaseType="2" executers="fpsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `FPS_FP_UpdateTransaction48`;
DELIMITER $$

CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `FPS_FP_UpdateTransaction48`(
		ip_BatchSize INT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20220218@jonathan
		Task :		
		DB:			FPS_FingerPrint
		Original:

		Revisions:
            
		Param's Explanation (filtered by):	

		Example:
			- CALL FPS_FP_UpdateTransaction48(ip_BatchSize);
			
	*/
     DECLARE lv_currentDate DATETIME DEFAULT NOW();
    DECLARE lv_lastDate DATETIME DEFAULT DATE_ADD(NOW(), INTERVAL -2 DAY);
	
	DROP TEMPORARY TABLE IF EXISTS Temp_Transaction;   
    
    -- Delete data to Transaction48
    DELETE FROM FPS_FingerPrint.Transaction48 WHERE CreatedDate < lv_lastDate;
    
    -- Get Data into Temp
    CREATE TEMPORARY TABLE Temp_Transaction
    SELECT trans48.Id
		, fp.SessionKey
		, fp.FingerPrintCode
        , fp.CookieId
        , fp.Flagged
        , fp.Url
        , trans48.retry + 1 as retry
    FROM FPS_FingerPrint.Transaction48 trans48
    LEFT JOIN FPS_FingerPrint.FingerPrint fp ON fp.SessionKey = trans48.SessionKey;
    
	-- Insert data completed
    INSERT INTO FPS_FingerPrint.Transaction(
		Id
		, CustId
		, SubAccId
		, LoginName
		, SubscriberId
		, Transtime
		, ClientIP
		, UserAgent
		, Url
		, Action
		, TransKey
		, CreatedDate
		, ModifiedDate
		, FingerPrintCode
		, CookieId
		, Flagged
	)
    SELECT rawTrans.Id
		, rawTrans.CustId
        , rawTrans.SubAccId
        , rawTrans.LoginName
        , rawTrans.SubscriberId
        , rawTrans.Transtime
        , rawTrans.ClientIP
        , rawTrans.UserAgent
        , IFNULL(rawTrans.Url, tmp.Url)
        , rawTrans.Action
        , rawTrans.TransKey
        , rawTrans.CreatedDate
        , lv_currentDate as ModifiedDate
        , tmp.FingerPrintCode
		, tmp.CookieId
        , tmp.Flagged
    FROM Temp_Transaction tmp
    INNER JOIN FPS_FingerPrint.RawTransaction rawTrans on rawTrans.Id = tmp.Id
    WHERE tmp.FingerPrintCode IS NOT NULL;
    
    UPDATE FPS_FingerPrint.RawTransaction rawTrans
    INNER JOIN Temp_Transaction tmp on tmp.Id = rawTrans.Id
    SET rawTrans.status = 1,
        rawTrans.retry = tmp.Retry,
		rawTrans.ModifiedDate = lv_currentDate
    WHERE tmp.FingerPrintCode IS NOT NULL;
    
    UPDATE FPS_FingerPrint.FingerPrint fp
    INNER JOIN Temp_Transaction tmp ON tmp.SessionKey = fp.SessionKey
    SET fp.MergedStatus = 1;
        
    DELETE trans48, tmp
    FROM FPS_FingerPrint.Transaction48 trans48
    INNER JOIN Temp_Transaction tmp on tmp.Id = trans48.Id
    WHERE tmp.FingerPrintCode IS NOT NULL;  
    
	-- Processing data error    
    UPDATE FPS_FingerPrint.Transaction48 trans48
    INNER JOIN Temp_Transaction tmp ON tmp.Id = trans48.Id
    SET trans48.Retry = tmp.Retry,
		trans48.ModifiedDate = lv_currentDate;
    
	DROP TEMPORARY TABLE IF EXISTS Temp_Transaction;   
END$$
DELIMITER ;

GRANT EXECUTE ON PROCEDURE FPS_FingerPrint.FPS_FP_UpdateTransaction48 TO 'fpsServiceAdmin'@'%';