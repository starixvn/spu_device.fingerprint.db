/*<info serverAlias="xxxx" databaseType="2" executers="fpsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `FPS_FP_UpdateTransaction`;
DELIMITER $$

CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `FPS_FP_UpdateTransaction`(
		ip_BatchSize INT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20220218@Terry.Nguyen
		Task :		
		DB:			FPS_FingerPrint
		Original:

		Revisions:
            
		Param's Explanation (filtered by):	

		Example:
			- CALL FPS_FP_UpdateTransaction(ip_BatchSize);
			
	*/
    DECLARE lv_retryTimes BIGINT DEFAULT 2;
    DECLARE lv_currentDate DATETIME DEFAULT NOW();
    
	DROP TEMPORARY TABLE IF EXISTS Temp_Transaction;  
    
	-- Create Temporary table
	CREATE TEMPORARY TABLE Temp_Transaction(
		`Id` 				BIGINT SIGNED PRIMARY KEY,          
		`SessionKey` 		VARCHAR(200) NOT NULL,
		`CustId` 			BIGINT DEFAULT NULL,
		`SubAccId` 			BIGINT DEFAULT NULL,
		`LoginName` 		VARCHAR(100) DEFAULT NULL,
		`SubscriberId` 		INT DEFAULT NULL,
		`Transtime` 		DATETIME DEFAULT NULL,
		`ClientIP` 			VARCHAR(45) DEFAULT NULL,
		`UserAgent` 		VARCHAR(500) DEFAULT NULL,
		`Url` 				VARCHAR(100) DEFAULT NULL,
		`Action` 			VARCHAR(100) DEFAULT NULL,
		`ModifiedDate` 		DATETIME DEFAULT NULL,
		`CreatedDate` 		DATETIME DEFAULT NULL,
		`TransKey` 			VARCHAR(200) DEFAULT NULL,
		`Flagged` 			VARCHAR(50) DEFAULT NULL,
		`Status` 			TINYINT DEFAULT '0',
		`Retry` 			TINYINT DEFAULT '0',
		`FingerPrintCode` 	VARCHAR(200) DEFAULT NULL,
		`CookieId` 			BIGINT DEFAULT NULL,
        INDEX Temp_Transaction_FingerPrintCode_Index (FingerPrintCode)
    ) ENGINE = MEMORY;  
    
	-- insert data into Temp_Transaction
    INSERT INTO Temp_Transaction(
		Id
		, SessionKey
		, CustId
		, SubAccId
		, LoginName
		, SubscriberId
		, Transtime
		, ClientIP
		, UserAgent
		, Url
		, Action
		, ModifiedDate
		, CreatedDate
		, TransKey
		, Status
		, Retry
	)
    SELECT Id
		, SessionKey
        , CustId
        , SubAccId
        , LoginName
        , SubscriberId
        , Transtime
		, ClientIP
        , UserAgent
        , Url
        , Action
        , ModifiedDate
        , CreatedDate
        , TransKey
		, Status
        , Retry
    FROM FPS_FingerPrint.RawTransaction
    WHERE Status = 0 
    AND Retry < lv_retryTimes
    ORDER BY Id ASC
    LIMIT ip_BatchSize;  
    
    UPDATE Temp_Transaction trans
    LEFT JOIN FPS_FingerPrint.FingerPrint fp ON fp.SessionKey = trans.SessionKey
    SET trans.FingerPrintCode = fp.FingerPrintCode
		, trans.CookieId = fp.CookieId
		, trans.Flagged = fp.Flagged
        , trans.retry = trans.retry + 1
        , trans.Url = IFNULL(trans.Url, fp.Url);
    
	-- Insert data completed
    INSERT INTO FPS_FingerPrint.Transaction(
		Id
		, CustId
		, SubAccId
		, LoginName
		, SubscriberId
		, FingerPrintCode
		, CookieId
		, Transtime
		, ClientIP
		, UserAgent
		, Url
		, Action
		, ModifiedDate
		, CreatedDate
		, TransKey
		, Flagged
	)
    SELECT Id
		, CustId
        , SubAccId
        , LoginName
        , SubscriberId
        , FingerPrintCode
		, CookieId
        , Transtime
        , ClientIP
        , UserAgent
        , Url
        , Action
        , lv_currentDate as ModifiedDate
        , CreatedDate
        , TransKey
        , Flagged
    FROM Temp_Transaction
    WHERE FingerPrintCode IS NOT NULL;
    
    UPDATE FPS_FingerPrint.RawTransaction rawTrans
    INNER JOIN Temp_Transaction tmp ON tmp.Id = rawTrans.Id 
    SET rawTrans.status = 1,
		rawTrans.ModifiedDate = lv_currentDate 
    WHERE tmp.FingerPrintCode IS NOT NULL;
    
    UPDATE FPS_FingerPrint.FingerPrint fp
    INNER JOIN Temp_Transaction tmp ON tmp.SessionKey = fp.SessionKey
    SET fp.MergedStatus = 1;
    
	-- Processing data error    
    UPDATE FPS_FingerPrint.RawTransaction rawTrans
    INNER JOIN Temp_Transaction tmp ON tmp.Id = rawTrans.Id
    SET rawTrans.Retry = tmp.Retry,
        rawTrans.status = IF(tmp.Retry < lv_retryTimes, 0, -1),
		rawTrans.ModifiedDate = lv_currentDate,
        tmp.status = IF(tmp.Retry < lv_retryTimes, 0, -1)
	WHERE tmp.FingerPrintCode IS NULL;	
    
    INSERT INTO FPS_FingerPrint.Transaction24(
		Id
		, SessionKey
		, ModifiedDate
		, CreatedDate
	)
    SELECT Id
		, SessionKey
        , lv_currentDate AS ModifiedDate
        , lv_currentDate AS CreatedDate
    FROM Temp_Transaction
    WHERE status = -1;    
	-- End Processing data error
        
	DROP TEMPORARY TABLE IF EXISTS Temp_Transaction;
END$$
DELIMITER ;

GRANT EXECUTE ON PROCEDURE FPS_FingerPrint.FPS_FP_UpdateTransaction TO 'fpsServiceAdmin'@'%';