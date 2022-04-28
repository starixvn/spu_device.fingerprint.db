/*<info serverAlias="FPSDC-FPS_FingerPrint" databaseType="2" executers="fpsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `FPS_FP_Transform_ServerTransactionN_Update`;
DELIMITER $$

CREATE DEFINER=`fpsOwner`@`%` PROCEDURE `FPS_FP_Transform_ServerTransactionN_Update`(
			ip_RawTransJson	LONGTEXT
	,       ip_OffsetId		INT
	,       ip_OffsetValue	BIGINT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20220221@Terry.Nguyen
		Task :		
		DB:			FPS_FingerPrint
		Original:

		Revisions:
			- 20220307@Terry.Nguyen: Created [Redmine ID: #162668]
            
		Param's Explanation (filtered by):	

		Example:
			- CALL FPS_FP_Transform_ServerTransactionN_Update({});
			
	*/
   
    DECLARE lv_currentDate DATETIME DEFAULT NOW();   
    
    /*******LOG TEST********************/
    IF (SELECT ofs.OffsetValue FROM FPS_FingerPrint.Offset AS ofs WHERE Id = 7) = 1 THEN		
		INSERT INTO CTS_Log.FPSLog(SpName, JsonString, OtherText, InsertTime)
		SELECT 'FPS_FP_Transform_ServerTransactionN_Update', ip_RawTransJson,CONCAT('ip_OffsetId:',ip_OffsetId,'; ip_OffsetValue:',ip_OffsetValue), CURRENT_TIMESTAMP();
	END IF;
    /*******LOG TEST********************/
    
	-- Create Temporary table
    DROP TEMPORARY TABLE IF EXISTS Temp_RawTransaction; 
	CREATE TEMPORARY TABLE Temp_RawTransaction(
			Id 					BIGINT UNSIGNED PRIMARY KEY    
		,	SessionKey 			VARCHAR(200) NOT NULL
		,	CustId 				BIGINT UNSIGNED DEFAULT NULL
		,	SubAccId 			BIGINT UNSIGNED DEFAULT NULL
		,	LoginName 			VARCHAR(100) DEFAULT NULL
		,	SubscriberId 		INT UNSIGNED DEFAULT NULL
		,	TransTime 			DATETIME(4) DEFAULT NULL
		,	ClientIP 			VARCHAR(45) DEFAULT NULL
		,	UserAgentId 		BIGINT UNSIGNED DEFAULT NULL
		,	Url 				VARCHAR(100) DEFAULT NULL
		,	Action 				VARCHAR(100) DEFAULT NULL
		,	ModifiedDate 		DATETIME DEFAULT NULL
		,	CreatedDate 		DATETIME DEFAULT NULL
		,	TransKey 			VARCHAR(200) DEFAULT NULL
		,	Flagged 			VARCHAR(50) DEFAULT NULL		
		,	Retry 				TINYINT DEFAULT '0'
		,	RawFingerPrintId 	BIGINT UNSIGNED DEFAULT NULL
		,	CookieId 			BIGINT UNSIGNED DEFAULT NULL
        
        ,	INDEX IX_Temp_RawTransaction_RawFingerPrintId(RawFingerPrintId)
    );  
    
    DROP TEMPORARY TABLE IF EXISTS Temp_RawTransaction2;
    CREATE TEMPORARY TABLE Temp_RawTransaction2(
			Id 					BIGINT UNSIGNED PRIMARY KEY        
		,	SessionKey 			VARCHAR(200) NOT NULL
		,	CustId 				BIGINT UNSIGNED DEFAULT NULL
		,	SubAccId 			BIGINT UNSIGNED DEFAULT NULL
		,	LoginName 			VARCHAR(100) DEFAULT NULL
		,	SubscriberId 		INT UNSIGNED DEFAULT NULL
		,	TransTime 			DATETIME(4) DEFAULT NULL
		,	ClientIP 			VARCHAR(45) DEFAULT NULL
		,	UserAgentId 		BIGINT UNSIGNED DEFAULT NULL
		,	Url 				VARCHAR(100) DEFAULT NULL
		,	Action 				VARCHAR(100) DEFAULT NULL
		,	ModifiedDate 		DATETIME DEFAULT NULL
		,	CreatedDate 		DATETIME DEFAULT NULL
		,	TransKey 			VARCHAR(200) DEFAULT NULL
		,	Flagged 			VARCHAR(50) DEFAULT NULL		
		,	Retry 				TINYINT DEFAULT 0
		,	RawFingerPrintId 	BIGINT UNSIGNED DEFAULT NULL
		,	CookieId 			BIGINT UNSIGNED DEFAULT NULL
        
        ,	INDEX IX_Temp_RawTransaction2_RawFingerPrintId(RawFingerPrintId)
        ,	INDEX IX_Temp_RawTransaction2_SessionKey(SessionKey)
    );  
    
   INSERT INTO Temp_RawTransaction(Id, SessionKey, CustId, SubAccId, LoginName, SubscriberId, TransTime, ClientIP, UserAgentId, Url, TransKey, Retry, Action)
	SELECT	rt.Id
		,	rt.SessionKey
		,	rt.CustId
		,	rt.SubAccId
		,	rt.LoginName
		,	rt.SubscriberId
		,	rt.TransTime
		,	rt.ClientIP
		,	rt.UserAgentId
		,	rt.Url	
        ,	rt.TransKey	
        ,	rt.Retry	
        ,	rt.Action
	FROM	JSON_TABLE(
			ip_RawTransJson,
			 "$[*]" COLUMNS(
								Id						BIGINT			PATH "$.Id"       
							,	SessionKey				VARCHAR(200) 	PATH "$.SessionKey"   
							,	CustId					BIGINT 			PATH "$.CustId"
							,	SubAccId				BIGINT			PATH "$.SubAccId"
							,	LoginName				VARCHAR(100)	PATH "$.LoginName"
							,	SubscriberId			INT 			PATH "$.SubscriberId"
							,	TransTime				DATETIME(4)	 	PATH "$.TransTime"
                            ,	ClientIP				VARCHAR(45)		PATH "$.ClientIP"
                            ,	UserAgentId				BIGINT			PATH "$.UserAgentId"
							,	Url						VARCHAR(100) 	PATH "$.Url"
							,	TransKey				VARCHAR(200) 	PATH "$.TransKey"
                            ,	Retry					TINYINT			PATH "$.Retry"
							,	Action					VARCHAR(100) 	PATH "$.Action"                           
				)
		   ) AS  rt; 
           
    INSERT INTO Temp_RawTransaction2(Id, SessionKey, CustId, SubAccId, LoginName, SubscriberId, TransTime, ClientIP, UserAgentId, Url, TransKey, Retry, Action, RawFingerPrintId, CookieId, Flagged)
	SELECT	tmpRt.Id
		,	tmpRt.SessionKey
		,	tmpRt.CustId
		,	tmpRt.SubAccId
		,	tmpRt.LoginName
		,	tmpRt.SubscriberId
		,	tmpRt.TransTime
		,	tmpRt.ClientIP
		,	tmpRt.UserAgentId
		,	IFNULL(tmpRt.Url, fp.Url)
		,	tmpRt.TransKey
		,	tmpRt.Retry
		,	tmpRt.Action
		,	fp.RawFingerPrintId
		,	fp.CookieId
		,	(CASE WHEN fp.Flagged is NULL THEN 'undefined'		
			ELSE fp.Flagged END) 
    FROM Temp_RawTransaction AS tmpRt
		LEFT JOIN FPS_FingerPrint.ClientTransaction fp ON fp.SessionKey = tmpRt.SessionKey;
      
	-- Insert data completed
    INSERT INTO FPS_FingerPrint.Transaction(ServerTransId, CustId, SubAccId, LoginName, SubscriberId, RawFingerPrintId, CookieId, TransTime, ClientIP, UserAgentId, Url, Action, CreatedDate, TransKey, Flagged)
    SELECT 	tmpRt2.Id
		,	tmpRt2.CustId
        ,	tmpRt2.SubAccId
        ,	tmpRt2.LoginName
        ,	tmpRt2.SubscriberId
        ,	tmpRt2.RawFingerPrintId
		,	tmpRt2.CookieId
        ,	tmpRt2.TransTime
        ,	tmpRt2.ClientIP
        ,	tmpRt2.UserAgentId
        ,	tmpRt2.Url
        ,	tmpRt2.Action
        ,	tmpRt2.CreatedDate
        ,	tmpRt2.TransKey
        ,	tmpRt2.Flagged
    FROM Temp_RawTransaction2 AS tmpRt2;

	INSERT INTO FPS_FingerPrint.ServerTransactionCompleted(Id, SessionKey, CustId, SubAccId, LoginName, SubscriberId, TransTime, ClientIP, UserAgentId, Url, ModifiedDate, CreatedDate, TransKey, Retry, Action)
    SELECT 	ts.Id
		, 	ts.SessionKey
		, 	ts.CustId
		, 	ts.SubAccId
		, 	ts.LoginName
		, 	ts.SubscriberId
		, 	ts.TransTime
		, 	ts.ClientIP
		, 	ts.UserAgentId
		, 	ts.Url
		, 	ts.ModifiedDate
		, 	ts.CreatedDate
		, 	ts.TransKey
		, 	ts.Retry
		, 	ts.Action
    FROM FPS_FingerPrint.ServerTransaction AS ts 
		INNER JOIN Temp_RawTransaction2 AS tmpRt2 ON ts.Id = tmpRt2.Id;
    
    INSERT INTO FPS_FingerPrint.ClientTransactionCompleted(Id, RawFingerPrintId, CookieId, SubscriberId, SessionKey, Flagged, Url, CreatedDate)
    SELECT 	fp.Id
		,	fp.RawFingerPrintId
		,	fp.CookieId
		,	fp.SubscriberId
		,	fp.SessionKey
		,	fp.Flagged
		,	fp.Url
		,	fp.CreatedDate
    FROM FPS_FingerPrint.ClientTransaction AS fp
		INNER JOIN Temp_RawTransaction2 AS tmpRt2 ON tmpRt2.SessionKey = fp.SessionKey;
    
    DELETE fp FROM FPS_FingerPrint.ClientTransaction AS fp
		INNER JOIN Temp_RawTransaction2 AS tmpRt2 ON tmpRt2.SessionKey = fp.SessionKey;   
    
    DELETE rt 
    FROM FPS_FingerPrint.ServerTransaction AS rt 
		INNER JOIN Temp_RawTransaction2 AS tmpRt2 ON rt.Id = tmpRt2.Id;
    
    DELETE rtn 
    FROM FPS_FingerPrint.ServerTransactionN AS rtn
		INNER JOIN Temp_RawTransaction2 AS tmpRt2 ON rtn.ServerTransId = tmpRt2.Id;
    
    UPDATE FPS_FingerPrint.Offset AS fs
	SET fs.OffsetValue = ip_OffsetValue
    WHERE fs.Id = ip_OffsetId;

END$$
DELIMITER ;