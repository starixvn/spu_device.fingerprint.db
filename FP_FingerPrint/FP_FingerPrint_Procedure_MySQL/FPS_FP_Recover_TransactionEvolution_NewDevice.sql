/*<info serverAlias="FPSDC-FPS_FingerPrint" databaseType="2" executers="fpsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `FPS_FP_Recover_TransactionEvolution_NewDevice`;
DELIMITER $$

CREATE DEFINER=`fpsOwner`@`%` PROCEDURE `FPS_FP_Recover_TransactionEvolution_NewDevice`(
		ip_TransJson LONGTEXT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20220913@Jonathan.Doan
		Task :		
		DB:			FPS_FingerPrint
		Original:

		Revisions:
			- 20220913@Jonathan.Doan: Created [Redmine ID: #176820]
            
		Param's Explanation (filtered by):	

		Example:
			- CALL FPS_FP_Recover_TransactionEvolution_NewDevice('1,2,3', 0);
			
	*/
    
    DECLARE lv_CurrentDate DATETIME DEFAULT NOW();
    DECLARE lv_CountTrans INT DEFAULT 0;
    
    /*******LOG TEST********************/
    IF (SELECT ofs.OffsetValue FROM FPS_FingerPrint.Offset AS ofs WHERE Id = 7) = 1 THEN		
		INSERT INTO CTS_Log.FPSLog(SpName, JsonString, OtherText, InsertTime)
		SELECT 'FPS_FP_Recover_TransactionEvolution_NewDevice', NULL, CONCAT('ip_TransJson: ', ip_TransJson), CURRENT_TIMESTAMP();
	END IF;
    /*******LOG TEST********************/
    
    DROP TEMPORARY TABLE IF EXISTS Temp_InputTrans;
    DROP TEMPORARY TABLE IF EXISTS Temp_Transaction;
    
    CREATE TEMPORARY TABLE Temp_InputTrans(
				Id 			BIGINT	NOT NULL PRIMARY KEY
    );
    
    CREATE TEMPORARY TABLE Temp_Transaction(
			 	ServerTransId			BIGINT UNSIGNED NOT NULL PRIMARY KEY
			, 	ClientTransId			BIGINT UNSIGNED
			, 	CustId					BIGINT UNSIGNED
			, 	SubAccId				BIGINT UNSIGNED
			, 	AccountId				BIGINT UNSIGNED
			, 	LoginName				VARCHAR(100)
			, 	SubscriberId			INT
			, 	RawFingerPrintId		BIGINT UNSIGNED
			, 	CookieId				BIGINT UNSIGNED
			, 	DeviceId				BIGINT UNSIGNED
			, 	RecoverFingerPrintId	BIGINT UNSIGNED
			, 	TransTime				DATETIME(4)
			, 	ClientIP				VARCHAR(45)
			, 	BrowserInfoId			BIGINT UNSIGNED
			, 	UserAgentId				BIGINT UNSIGNED
			, 	Url						VARCHAR(100)
			, 	Action					VARCHAR(100)
			, 	CreatedDate				DATETIME
			, 	TransKey				VARCHAR(200)
			, 	AddonId					BIGINT UNSIGNED
			, 	RecoverType				TINYINT DEFAULT 0
			, 	BrowserInstanceId		BIGINT UNSIGNED
    );
    
	SET @sql = CONCAT("INSERT INTO Temp_InputTrans (Id) VALUES ('", REPLACE(ip_TransJson, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;

	INSERT INTO Temp_Transaction(ServerTransId, ClientTransId, CustId, SubAccId, AccountId, LoginName, SubscriberId, RawFingerPrintId, CookieId, TransTime, ClientIP, UserAgentId, Url, Action, CreatedDate, TransKey, BrowserInfoId, AddonId)
	SELECT	te.ServerTransId
		,	te.ClientTransId
		,	te.CustId
		,	te.SubAccId
		,	te.AccountId
		,	te.LoginName
		,	te.SubscriberId
		,	te.RawFingerPrintId
		,	te.CookieId
		,	te.TransTime
		,	te.ClientIP
		,	te.UserAgentId
		,	te.Url
		,	te.Action
		,	te.CreatedDate
		,	te.TransKey
		,	te.BrowserInfoId
		,	te.AddonId
	FROM Temp_InputTrans AS tmp
		INNER JOIN FPS_FingerPrint.TransactionEvolution AS te ON tmp.Id = te.Id;
	
    INSERT INTO FPS_FingerPrint.Transaction(ServerTransId, ClientTransId, CustId, SubAccId, AccountId, LoginName, SubscriberId, RawFingerPrintId, CookieId, TransTime, ClientIP, UserAgentId, Url, Action, CreatedDate, TransKey, BrowserInfoId, AddonId)
	SELECT	tmp.ServerTransId
		,	tmp.ClientTransId
		,	tmp.CustId
		,	tmp.SubAccId
		,	tmp.AccountId
		,	tmp.LoginName
		,	tmp.SubscriberId
		,	tmp.RawFingerPrintId
		,	tmp.CookieId
		,	tmp.TransTime
		,	tmp.ClientIP
		,	tmp.UserAgentId
		,	tmp.Url
		,	tmp.Action
		,	tmp.CreatedDate
		,	tmp.TransKey
		,	tmp.BrowserInfoId
		,	tmp.AddonId
	FROM Temp_Transaction AS tmp;
    
    SELECT COUNT(1)
	INTO lv_CountTrans
	FROM Temp_Transaction;
    
    INSERT INTO FPS_FingerPrint.RecoverDailySum(RecoverType, SubscriberId, TransDate, Total, CreatedDate)
	SELECT 	0 AS RecoverType
		,	tmp.SubscriberId
		,	DATE_FORMAT(tmp.TransTime,'%Y-%m-%d') AS TransDate
		,	lv_CountTrans AS Total
		,	lv_CurrentDate AS CreatedDate
	FROM Temp_Recover AS tmp
	ON DUPLICATE KEY UPDATE Total = Total + lv_CountTrans,
							ModifiedDate = lv_CurrentDate;
    
	DELETE te
	FROM Temp_InputTrans AS tmp
		INNER JOIN FPS_FingerPrint.TransactionEvolution AS te ON tmp.Id = te.Id;

END$$
DELIMITER ;
