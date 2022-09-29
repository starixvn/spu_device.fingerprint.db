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
    
    /*******LOG TEST********************/
    IF (SELECT ofs.OffsetValue FROM FPS_FingerPrint.Offset AS ofs WHERE Id = 7) = 1 THEN		
		INSERT INTO CTS_Log.FPSLog(SpName, JsonString, OtherText, InsertTime)
		SELECT 'FPS_FP_Recover_TransactionEvolution_NewDevice', NULL, CONCAT('ip_TransJson: ', ip_TransJson), CURRENT_TIMESTAMP();
	END IF;
    /*******LOG TEST********************/
    
    DROP TEMPORARY TABLE IF EXISTS Temp_InputTrans;
    
    CREATE TEMPORARY TABLE Temp_InputTrans(
				Id 			BIGINT	NOT NULL PRIMARY KEY
    );
    
	SET @sql = CONCAT("INSERT INTO Temp_InputTrans (Id) VALUES ('", REPLACE(ip_TransJson, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;

	INSERT INTO FPS_FingerPrint.Transaction(ServerTransId, ClientTransId, CustId, SubAccId, AccountId, LoginName, SubscriberId, RawFingerPrintId, CookieId, TransTime, ClientIP, UserAgentId, Url, Action, CreatedDate, TransKey, BrowserInfoId, AddonId)
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
	
	DELETE te
	FROM Temp_InputTrans AS tmp
		INNER JOIN FPS_FingerPrint.TransactionEvolution AS te ON tmp.Id = te.Id;

END$$
DELIMITER ;
