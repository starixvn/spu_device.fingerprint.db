/*<info serverAlias="xxxx" databaseType="2" executers="fpsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `FPS_FP_UpdateTransactionN`;
DELIMITER $$

CREATE DEFINER=`jonathan.vn`@`%` PROCEDURE `FPS_FP_UpdateTransactionN`(
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
			- CALL FPS_FP_UpdateTransaction24(ip_BatchSize);
			
	*/
    DECLARE lv_currentDate DATETIME DEFAULT NOW();
    DECLARE lv_expiredDate DATETIME DEFAULT DATE_ADD(NOW(), INTERVAL -15 MINUTE);
    
	DROP TEMPORARY TABLE IF EXISTS Temp_TransactionN;    
    
    -- Move data fail to Transaction
    UPDATE FPS_FingerPrint.TransactionN
    SET Status = -1
    WHERE CreatedDate < lv_expiredDate;
    
    -- Get Data into Temp
    CREATE TEMPORARY TABLE Temp_TransactionN (PRIMARY KEY Temp_TransactionN_PR (Id), INDEX Temp_TransactionN_Index (FingerPrintCode, SessionKey, Status))
    SELECT trans.Id
		, trans.Status
		, fp.SessionKey
		, fp.FingerPrintCode
        , fp.CookieId
        , fp.Flagged
        , fp.Url
    FROM FPS_FingerPrint.TransactionN trans
    LEFT JOIN FPS_FingerPrint.FingerPrint fp ON fp.SessionKey = trans.SessionKey;
        
	-- Insert data completed
    INSERT INTO FPS_FingerPrint.Transaction(
		RawTransId
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
    FROM Temp_TransactionN tmp
    INNER JOIN FPS_FingerPrint.RawTransaction rawTrans on rawTrans.Id = tmp.Id
    WHERE tmp.FingerPrintCode IS NOT NULL
    OR tmp.Status = -1;
    
    UPDATE FPS_FingerPrint.RawTransaction rawTrans
    INNER JOIN Temp_TransactionN tmp on tmp.Id = rawTrans.Id
    SET rawTrans.status = 1,
		rawTrans.ModifiedDate = lv_currentDate
    WHERE tmp.FingerPrintCode IS NOT NULL;
    
    UPDATE FPS_FingerPrint.FingerPrint fp
    INNER JOIN Temp_TransactionN tmp ON tmp.SessionKey = fp.SessionKey
    SET fp.MergedStatus = 1;
        
    DELETE trans, tmp
    FROM FPS_FingerPrint.TransactionN trans
    INNER JOIN Temp_TransactionN tmp on tmp.Id = trans.Id
    WHERE tmp.FingerPrintCode IS NOT NULL
    OR tmp.Status = -1;  
    
	-- Processing data error    
    UPDATE FPS_FingerPrint.TransactionN trans
    INNER JOIN Temp_TransactionN tmp ON tmp.Id = trans.Id
    SET trans.ModifiedDate = lv_currentDate;
  
	DROP TEMPORARY TABLE IF EXISTS Temp_TransactionN;  
    
END$$
DELIMITER ;
