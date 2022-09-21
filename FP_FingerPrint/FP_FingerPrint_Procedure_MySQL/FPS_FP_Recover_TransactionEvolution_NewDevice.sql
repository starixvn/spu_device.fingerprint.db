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

	INSERT INTO FPS_FingerPrint.Transaction(ServerTransId, CustId, SubAccId, AccountId, LoginName, SubscriberId, RawFingerPrintId, CookieId, TransTime, ClientIP, UserAgentId, Url, Action, CreatedDate, TransKey, BrowserInfoId, AddonId)
	SELECT	fpe.ServerTransId
		,	fpe.CustId
		,	fpe.SubAccId
		,	fpe.AccountId
		,	fpe.LoginName
		,	fpe.SubscriberId
		,	fpe.RawFingerPrintId
		,	fpe.CookieId
		,	fpe.TransTime
		,	fpe.ClientIP
		,	fpe.UserAgentId
		,	fpe.Url
		,	fpe.Action
		,	fpe.CreatedDate
		,	fpe.TransKey
		,	fpe.BrowserInfoId
		,	fpe.AddonId
	FROM Temp_InputTrans AS tmp
		INNER JOIN FPS_FingerPrint.TransactionEvolution AS fpe ON tmp.Id = fpe.Id;
	
	DELETE fpe
	FROM Temp_InputTrans AS tmp
		INNER JOIN FPS_FingerPrint.TransactionEvolution AS fpe ON tmp.Id = fpe.Id;

END$$
DELIMITER ;
