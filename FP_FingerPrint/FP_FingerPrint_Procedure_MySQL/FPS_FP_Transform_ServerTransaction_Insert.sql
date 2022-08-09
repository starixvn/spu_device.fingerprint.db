/*<info serverAlias="FPSDC-FPS_FingerPrint" databaseType="2" executers="fpsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `FPS_FP_Transform_ServerTransaction_Insert`;
DELIMITER $$

CREATE DEFINER=`fpsOwner`@`%` PROCEDURE `FPS_FP_Transform_ServerTransaction_Insert`(
		ip_Transaction LONGTEXT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20220218@Terry.Nguyen
		Task :		
		DB:			FPS_FingerPrint
		Original:

		Revisions: 
			- 20220307@Terry.Nguyen: Created [Redmine ID: #162668]
			- 20220318@Jonathan.Doan: Insert ServerTransactionDailySum [Redmine ID: #162668]
			- 20220608@Jonathan.Doan: Remove ServerTransactionDailySum [Redmine ID: #173803]
			- 20220728@Jonathan.Doan: Hotfix UA [Redmine ID: #175971]
            
		Param's Explanation (filtered by):	

		Example:
			- CALL FPS_FP_Transform_ServerTransaction_Insert(100);
			
	*/
    DECLARE lv_CurrentDate DATETIME DEFAULT NOW();
    
    /*******LOG TEST********************/
    IF (SELECT ofs.OffsetValue FROM FPS_FingerPrint.Offset AS ofs WHERE Id = 7) = 1 THEN		
		INSERT INTO CTS_Log.FPSLog(SpName, JsonString, OtherText, InsertTime)
		SELECT 'FPS_FP_Transform_ServerTransaction_Insert', ip_Transaction, NULL, CURRENT_TIMESTAMP();
	END IF;
    /*******LOG TEST********************/
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Transactions;
    DROP TEMPORARY TABLE IF EXISTS Temp_RawUserAgent;
    
	CREATE TEMPORARY TABLE Temp_Transactions(
			Id 							BIGINT UNSIGNED 		NOT NULL AUTO_INCREMENT
		,	LoginName					VARCHAR(100) 			NOT NULL	
		,	SubscriberId				INT						NOT NULL
		,	SessionKey					VARCHAR(100)	 		NOT NULL
		,	TransTime					DATETIME(4)	 			NULL
		,	ClientIp					VARCHAR(45)				NULL	
		,	UserAgentId					BIGINT UNSIGNED			NULL
		,	UserAgent					LONGTEXT				NULL
		,	UserAgentCode				VARCHAR(100)			NULL
		,	Url							VARCHAR(100)			NULL
		,	Action						VARCHAR(100)			NULL
		,	TransKey					VARCHAR(500)			NULL
        ,	CustId						BIGINT UNSIGNED			NULL
        ,	SubAccId					BIGINT UNSIGNED			NULL
        ,	PRIMARY KEY (Id)
		,	INDEX IX_Temp_Transactions_UserAgentCode(UserAgentCode)
    );     
    
	CREATE TEMPORARY TABLE Temp_RawUserAgent(
			TransactionsId 				BIGINT UNSIGNED			NOT NULL 
		,	UserAgentId					BIGINT UNSIGNED			NOT NULL
        ,	PRIMARY KEY (TransactionsId)
    );  
    
    INSERT INTO Temp_Transactions(
			LoginName
        ,	SubscriberId
        ,	SessionKey
        ,	TransTime
        ,	ClientIp
        ,	UserAgent
        ,	UserAgentCode
        ,	Url
        ,	Action
        ,	TransKey
        ,	CustId
        ,	SubAccId)
	SELECT	tmp.LoginName
		,	tmp.SubscriberId
		,	tmp.SessionKey
		,	tmp.TransTime
        ,	tmp.ClientIp
        ,	tmp.UserAgent
        ,	tmp.UserAgentCode
        ,	tmp.Url
        ,	tmp.Action
        ,	tmp.TransKey
        ,	tmp.CustId
        ,	tmp.SubAccId
	FROM	JSON_TABLE(
			ip_Transaction,
			 "$[*]" COLUMNS(
					LoginName				VARCHAR(100)	PATH "$.LoginName"       
				,	SubscriberId			INT 			PATH "$.SubscriberId"   
				,	SessionKey				VARCHAR(100) 	PATH "$.SessionKey"
				,	TransTime				DATETIME(4)		PATH "$.TransTime"
				,	ClientIp				VARCHAR(45)		PATH "$.ClientIp"
				,	UserAgent				LONGTEXT		PATH "$.UserAgent"
				,	UserAgentCode			VARCHAR(100)	PATH "$.UserAgentCode"
				,	Url						VARCHAR(100) 	PATH "$.Url"
				,	Action					VARCHAR(100) 	PATH "$.Action"
				,	TransKey				VARCHAR(200) 	PATH "$.TransKey"
				,	CustId					BIGINT		 	PATH "$.CustId"
				,	SubAccId				BIGINT		 	PATH "$.SubAccId"
				)
		   ) AS tmp;            
    
	/*******RawUserAgent********************/
    INSERT IGNORE INTO FPS_FingerPrint.RawUserAgent (UserAgentCode, UserAgent, CreatedDate, ModifiedDate)
	SELECT	DISTINCT 
			tmp.UserAgentCode
		,	tmp.UserAgent
        ,	lv_CurrentDate AS CreatedDate
        ,	lv_CurrentDate AS ModifiedDate
	FROM Temp_Transactions AS tmp
    WHERE NOT EXISTS (SELECT 1 FROM FPS_FingerPrint.RawUserAgent ua WHERE ua.UserAgentCode = tmp.UserAgentCode);
        
    INSERT IGNORE INTO Temp_RawUserAgent(TransactionsId, UserAgentId)
    SELECT 	tmp.Id AS TransactionsId
		, 	ua.Id AS UserAgentId
    FROM Temp_Transactions AS tmp
		INNER JOIN FPS_FingerPrint.RawUserAgent AS ua ON tmp.UserAgentCode = ua.UserAgentCode;

    UPDATE Temp_Transactions AS tmp
		INNER JOIN Temp_RawUserAgent AS ua ON ua.TransactionsId = tmp.Id
	SET tmp.UserAgentId = ua.UserAgentId;

    /*******ServerTransaction********************/
    INSERT INTO FPS_FingerPrint.ServerTransaction(
						LoginName
					,	SubscriberId
                    ,	SessionKey
					,	TransTime
					,	ClientIp
					,	UserAgentId
                    ,	Url
                    ,	Action
					,	ModifiedDate
					,	CreatedDate
                    ,	TransKey
                    ,	CustId
                    ,	SubAccId
	)
	SELECT			tmp.LoginName
					,	tmp.SubscriberId
					,	tmp.SessionKey
					,	tmp.TransTime
					,	tmp.ClientIp
					,	tmp.UserAgentId
                    ,	tmp.Url
                    ,	tmp.Action
					, 	lv_CurrentDate
					, 	lv_CurrentDate
                    ,	tmp.TransKey
                    ,	tmp.CustId
                    ,	tmp.SubAccId
	FROM Temp_Transactions AS tmp;
    
END$$
DELIMITER ;