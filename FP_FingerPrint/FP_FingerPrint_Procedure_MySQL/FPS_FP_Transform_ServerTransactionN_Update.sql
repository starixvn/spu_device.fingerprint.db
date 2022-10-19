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
			- 20220610@Jonathan.Doan: Update BrowserInfo [Redmine ID: #172167]
			- 20220614@Jonathan.Doan: Hot fix [Redmine ID: #174020]
            - 20220808@Jonathan.Doan: Add AddonId [Redmine ID: #175155]
            
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
    DROP TEMPORARY TABLE IF EXISTS Temp_RawTransaction2;
    DROP TEMPORARY TABLE IF EXISTS Temp_BrowserInfo;
    
	CREATE TEMPORARY TABLE Temp_RawTransaction(
			Id 					BIGINT UNSIGNED PRIMARY KEY    
		,	SessionKey 			VARCHAR(200) NOT NULL
		,	CustId 				BIGINT UNSIGNED DEFAULT NULL
		,	SubAccId 			BIGINT UNSIGNED DEFAULT NULL
		,	AccountId 			BIGINT UNSIGNED DEFAULT NULL
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
		,	Retry 				TINYINT DEFAULT '0'
		,	RawFingerPrintId 	BIGINT UNSIGNED DEFAULT NULL
		,	CookieId 			BIGINT UNSIGNED DEFAULT NULL
        
        ,	INDEX IX_Temp_RawTransaction_RawFingerPrintId(RawFingerPrintId)
    );  
    
    CREATE TEMPORARY TABLE Temp_RawTransaction2(
			Id 					BIGINT UNSIGNED PRIMARY KEY
		,	SessionKey 			VARCHAR(200) NOT NULL
		,	CustId 				BIGINT UNSIGNED DEFAULT NULL
		,	SubAccId 			BIGINT UNSIGNED DEFAULT NULL
		,	AccountId 			BIGINT UNSIGNED DEFAULT NULL
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
		,	Retry 				TINYINT DEFAULT 0
		,	ClientTransId	 	BIGINT UNSIGNED DEFAULT NULL
		,	RawFingerPrintId 	BIGINT UNSIGNED DEFAULT NULL
		,	CookieId 			BIGINT UNSIGNED DEFAULT NULL
		,	BrowserInfoId 		BIGINT UNSIGNED DEFAULT NULL
		,	AddonId		 		BIGINT UNSIGNED DEFAULT NULL
        
        ,	INDEX IX_Temp_RawTransaction2_RawFingerPrintId(RawFingerPrintId)
        ,	INDEX IX_Temp_RawTransaction2_SessionKey(SessionKey)
    );
    
    CREATE TEMPORARY TABLE Temp_BrowserInfo(
				Id 				BIGINT UNSIGNED NOT NULL PRIMARY KEY	
			, 	SessionKey 		VARCHAR(200)
			, 	UserAgentId 	BIGINT UNSIGNED
            , 	UNIQUE INDEX UX_Temp_BrowserInfo_SessionKey(SessionKey)   
    );
    
   INSERT INTO Temp_RawTransaction(Id, SessionKey, CustId, SubAccId, AccountId, LoginName, SubscriberId, TransTime, ClientIP, UserAgentId, Url, TransKey, Retry, Action)
	SELECT	rt.Id
		,	rt.SessionKey
		,	rt.CustId
		,	rt.SubAccId
		,	rt.AccountId
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
							,	AccountId				BIGINT UNSIGNED	PATH "$.AccountId"
							,	LoginName				VARCHAR(100)	PATH "$.LoginName"
							,	SubscriberId			INT 			PATH "$.SubscriberId"
							,	TransTime				DATETIME(4)	 	PATH "$.TransTime"
                            ,	ClientIP				VARCHAR(45)		PATH "$.ClientIP"
                            ,	UserAgentId				BIGINT UNSIGNED	PATH "$.UserAgentId"
							,	Url						VARCHAR(100) 	PATH "$.Url"
							,	TransKey				VARCHAR(200) 	PATH "$.TransKey"
                            ,	Retry					TINYINT			PATH "$.Retry"
							,	Action					VARCHAR(100) 	PATH "$.Action"
				)
		   ) AS  rt; 
           
    INSERT INTO Temp_RawTransaction2(Id, SessionKey, CustId, SubAccId, AccountId, LoginName, SubscriberId, TransTime, ClientIP, UserAgentId, Url, TransKey, Retry, Action, ClientTransId, RawFingerPrintId, CookieId, AddonId, CreatedDate)
	SELECT	tmpRt.Id
		,	tmpRt.SessionKey
		,	tmpRt.CustId
		,	tmpRt.SubAccId
		,	tmpRt.AccountId
		,	tmpRt.LoginName
		,	tmpRt.SubscriberId
		,	tmpRt.TransTime
		,	tmpRt.ClientIP
		,	tmpRt.UserAgentId
		,	IFNULL(tmpRt.Url, fp.Url)
		,	tmpRt.TransKey
		,	tmpRt.Retry
		,	tmpRt.Action
		,	fp.Id AS ClientTransId
		,	fp.RawFingerPrintId
		,	fp.CookieId
		,	fp.AddonId
		,	lv_currentDate
    FROM Temp_RawTransaction AS tmpRt
		LEFT JOIN FPS_FingerPrint.ClientTransaction fp ON fp.SessionKey = tmpRt.SessionKey;
      
	INSERT IGNORE INTO Temp_BrowserInfo(Id, SessionKey, UserAgentId)
    SELECT 	bi.Id
		,	bi.SessionKey
		,	tmp.UserAgentId
    FROM Temp_RawTransaction2 tmp
		INNER JOIN FPS_FingerPrint.BrowserInfo AS bi ON bi.SessionKey = tmp.SessionKey;
	
    /*******Update BrowserInfo.UserAgentId********************/
    UPDATE FPS_FingerPrint.BrowserInfo bi
		INNER JOIN Temp_BrowserInfo tmp ON tmp.Id = bi.Id
    SET bi.UserAgentId = tmp.UserAgentId
    WHERE bi.UserAgentId IS NULL;
	
    /*******Update Temp_RawTransaction2.BrowserInfoId********************/
	UPDATE Temp_RawTransaction2 tmp
		INNER JOIN Temp_BrowserInfo AS bi ON bi.SessionKey = tmp.SessionKey
    SET tmp.BrowserInfoId = bi.Id;
        
	-- Insert data completed
    INSERT INTO FPS_FingerPrint.Transaction(ServerTransId, ClientTransId, CustId, SubAccId, AccountId, LoginName, SubscriberId, RawFingerPrintId, CookieId, TransTime, ClientIP, UserAgentId, Url, Action, CreatedDate, TransKey, BrowserInfoId, AddonId)
    SELECT 	tmpRt2.Id
		,	tmpRt2.ClientTransId
		,	tmpRt2.CustId
        ,	tmpRt2.SubAccId
        ,	tmpRt2.AccountId
        ,	tmpRt2.LoginName
        ,	tmpRt2.SubscriberId
        ,	tmpRt2.RawFingerPrintId
		,	tmpRt2.CookieId
        ,	tmpRt2.TransTime
        ,	tmpRt2.ClientIP
        ,	tmpRt2.UserAgentId
        ,	tmpRt2.Url
        ,	tmpRt2.Action
        ,	lv_currentDate
        ,	tmpRt2.TransKey
        ,	tmpRt2.BrowserInfoId
        ,	tmpRt2.AddonId
    FROM Temp_RawTransaction2 AS tmpRt2;

	INSERT IGNORE INTO FPS_FingerPrint.ServerTransactionCompleted(Id, SessionKey, CustId, SubAccId, AccountId, LoginName, SubscriberId, TransTime, ClientIP, UserAgentId, Url, ModifiedDate, CreatedDate, TransKey, Retry, Action)
    SELECT	rt.Id
		,	rt.SessionKey
        ,	rt.CustId
        ,	rt.SubAccId
        ,	rt.AccountId
        ,	rt.LoginName
        ,	rt.SubscriberId
        ,	rt.TransTime
        ,	rt.ClientIP
        ,	rt.UserAgentId
        ,	rt.Url
        ,	rt.ModifiedDate
        ,	rt.CreatedDate
        ,	rt.TransKey
        ,	rt.Retry
        ,	rt.Action
    FROM Temp_RawTransaction2 AS tmpT2 
		INNER JOIN FPS_FingerPrint.ServerTransaction AS rt ON rt.Id = tmpT2.Id
	WHERE NOT EXISTS(SELECT 1 FROM FPS_FingerPrint.ServerTransactionCompleted sc WHERE sc.Id = tmpT2.Id);
    
    INSERT INTO FPS_FingerPrint.ClientTransactionCompleted(Id, RawFingerPrintId, CookieId, SubscriberId, SessionKey, Url, TransTime, AddonId, CreatedDate)
    SELECT	fp.Id
		,	fp.RawFingerPrintId
		,	fp.CookieId
		,	fp.SubscriberId
		,	fp.SessionKey
		,	fp.Url
		,	fp.TransTime
		,	fp.AddonId
		,	fp.CreatedDate
    FROM Temp_RawTransaction2 AS tmpT2
		INNER JOIN FPS_FingerPrint.ClientTransaction AS fp ON tmpT2.SessionKey = fp.SessionKey
	WHERE NOT EXISTS(SELECT 1 FROM FPS_FingerPrint.ClientTransactionCompleted cc WHERE cc.Id = tmpT2.Id);
    
    DELETE fp FROM FPS_FingerPrint.ClientTransaction AS fp
		INNER JOIN Temp_RawTransaction2 AS tmpRt2 ON tmpRt2.SessionKey = fp.SessionKey;   
    
    DELETE rt FROM FPS_FingerPrint.ServerTransaction AS rt 
		INNER JOIN Temp_RawTransaction2 AS tmpRt2 ON rt.Id = tmpRt2.Id;
    
    DELETE rtn FROM FPS_FingerPrint.ServerTransactionN AS rtn
		INNER JOIN Temp_RawTransaction2 AS tmpRt2 ON rtn.ServerTransId = tmpRt2.Id;
    
    UPDATE FPS_FingerPrint.Offset AS fs
	SET fs.OffsetValue = ip_OffsetValue
    WHERE fs.Id = ip_OffsetId;

END$$
DELIMITER ;