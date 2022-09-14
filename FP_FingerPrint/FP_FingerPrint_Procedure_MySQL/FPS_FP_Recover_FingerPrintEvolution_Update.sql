/*<info serverAlias="FPSDC-FPS_FingerPrint" databaseType="2" executers="fpsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `FPS_FP_Recover_FingerPrintEvolution_Update`;
DELIMITER $$

CREATE DEFINER=`fpsOwner`@`%` PROCEDURE `FPS_FP_Recover_FingerPrintEvolution_Update`(
		ip_TransJson LONGTEXT,
		ip_Type TINYINT
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
			- CALL FPS_FP_Recover_FingerPrintEvolution_Update('[{"Id": 1}]');
			
	*/
    
    DECLARE lv_CurrentDate DATETIME DEFAULT NOW();
    
    /*******LOG TEST********************/
    IF (SELECT ofs.OffsetValue FROM FPS_FingerPrint.Offset AS ofs WHERE Id = 7) = 1 THEN		
		INSERT INTO CTS_Log.FPSLog(SpName, JsonString, OtherText, InsertTime)
		SELECT 'FPS_FP_Recover_FingerPrintEvolution_Update', ip_TransJson, CONCAT('ip_Type: ', ip_Type), CURRENT_TIMESTAMP();
	END IF;
    /*******LOG TEST********************/
    
    DROP TEMPORARY TABLE IF EXISTS Temp_InputTrans;
    DROP TEMPORARY TABLE IF EXISTS Temp_Recover;
    
    CREATE TEMPORARY TABLE Temp_InputTrans(
				Id 			BIGINT	NOT NULL PRIMARY KEY
    );
    
    CREATE TEMPORARY TABLE Temp_Recover(
				Id 					BIGINT UNSIGNED NOT NULL PRIMARY KEY
			, 	RawFingerPrintId	BIGINT UNSIGNED
			, 	CookieId			BIGINT UNSIGNED
			, 	TransTime			DATETIME(4)
			, 	DeviceId			BIGINT UNSIGNED
    );
    
    IF(ip_Type = 0) THEN
		SET @sql = CONCAT("INSERT INTO Temp_InputTrans (Id) VALUES ('", REPLACE(ip_TransJson, ",", "'),('"),"');");
		PREPARE stmt1 FROM @sql;
		EXECUTE stmt1;

		INSERT INTO FPS_FingerPrint.Transaction(ServerTransId, CustId, SubAccId, LoginName, SubscriberId, RawFingerPrintId, CookieId, TransTime, ClientIP, UserAgentId, Url, Action, CreatedDate, TransKey, BrowserInfoId, AddonId)
		SELECT	fpe.Id
			,	fpe.CustId
			,	fpe.SubAccId
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
			INNER JOIN FPS_FingerPrint.FingerPrintEvolution AS fpe ON tmp.Id = fpe.Id;
        
		DELETE fpe
		FROM Temp_InputTrans AS tmp
			INNER JOIN FPS_FingerPrint.FingerPrintEvolution AS fpe ON tmp.Id = fpe.Id;
            
	ELSE
		INSERT IGNORE INTO Temp_Recover(Id, RawFingerPrintId, CookieId, TransTime, DeviceId)
		SELECT	tmp.Id
			,	tmp.RawFingerPrintId
			,	tmp.CookieId
			,	tmp.TransTime
			,	tmp.DeviceId
		FROM	JSON_TABLE(
				ip_TransJson,
				 "$[*]" COLUMNS(
							Id					BIGINT UNSIGNED			PATH "$.Id",
							RawFingerPrintId	BIGINT UNSIGNED			PATH "$.RawFingerPrintId",
							CookieId			BIGINT UNSIGNED			PATH "$.CookieId",
							TransTime			DATETIME(4)				PATH "$.TransTime",
							DeviceId			BIGINT UNSIGNED			PATH "$.DeviceId"
					)
			   ) AS tmp;
               
		INSERT INTO FPS_FingerPrint.TransactionDevice(ServerTransId, TransTime, CustId , SubAccId, LoginName, SubscriberId, RawFingerPrintId, CookieId, DeviceId, ClientIP, BrowserInfoId, UserAgentId, Url, Action, CreatedDate, TransKey, AddonId)
        SELECT  fpe.ServerTransId
            ,	fpe.TransTime
			, 	fpe.CustId
			, 	fpe.SubAccId
			, 	fpe.LoginName
			, 	fpe.SubscriberId
			, 	fpe.RawFingerPrintId
			, 	fpe.CookieId
			, 	tmp.DeviceId
			, 	fpe.ClientIP
			, 	fpe.BrowserInfoId
			, 	fpe.UserAgentId
			, 	fpe.Url
			, 	fpe.Action
			, 	lv_CreatedDate
			, 	fpe.TransKey
			, 	fpe.AddonId
		FROM Temp_Recover AS tmp
			INNER JOIN FPS_FingerPrint.FingerPrintEvolution AS fpe ON tmp.Id = fpe.Id;

		INSERT IGNORE INTO FPS_FingerPrint.DeviceFingerPrint(RawFingerPrintId, DeviceId, CreatedDate, ModifiedDate)
		WITH cte (RawFingerPrintId, DeviceId, TransTime) AS
		(
			SELECT 	tmp.RawFingerPrintId
				,	tmp.DeviceId
				,	MAX(tmp.TransTime) AS TransTime
			FROM Temp_Recover AS tmp
			GROUP BY tmp.RawFingerPrintId, tmp.DeviceId
		)
		SELECT 	cte.RawFingerPrintId
			,	cte.DeviceId
			,	lv_CreatedDate
			,	cte.TransTime
		FROM cte
		WHERE NOT EXISTS (SELECT 1 FROM FPS_FingerPrint.DeviceFingerPrint df WHERE df.RawFingerPrintId = cte.RawFingerPrintId);
        
        INSERT IGNORE INTO FPS_FingerPrint.DeviceCookie(CookieId, DeviceId, CreatedDate, ModifiedDate)
		WITH cte (CookieId, DeviceId, TransTime) AS
		(
			SELECT 	tmp.CookieId
				,	tmp.DeviceId
				,	MAX(tmp.TransTime) AS TransTime
			FROM Temp_Recover AS tmp
			GROUP BY tmp.CookieId, tmp.DeviceId
		)
		SELECT 	cte.CookieId
			,	cte.DeviceId
			,	lv_CreatedDate
			,	cte.TransTime
		FROM cte
		WHERE NOT EXISTS (SELECT 1 FROM FPS_FingerPrint.DeviceCookie dc WHERE dc.CookieId = cte.CookieId);
        
		-- /*****AccountFingerprint******************/
-- 		UPDATE Temp_InputTrans AS tmp
-- 			INNER JOIN FPS_FingerPrint.Account AS acc ON acc.SubscriberId = tmp.SubscriberId AND acc.LoginName = tmp.LoginName
-- 		SET tmp.AccountId = acc.Id;
-- 		
-- 		UPDATE Temp_InputTrans AS tmp
-- 			INNER JOIN FPS_FingerPrint.RawUserAgent AS ua ON ua.Id = tmp.UserAgentId
-- 			INNER JOIN FPS_FingerPrint.BrowserInstance AS bi ON bi.BrowserName = ua.ClientName AND bi.OSName = ua.OSName
-- 		SET tmp.BrowserInstanceId = bi.Id;

-- 		INSERT IGNORE INTO FPS_FingerPrint.AccountFingerprint(AccountId, BrowserInstanceId, FingerPrintId)
-- 		SELECT	AccountId
-- 			,	BrowserInstanceId
-- 			,	RawFingerPrintId
-- 		FROM Temp_Recover;
        
		DELETE fpe
		FROM Temp_Recover AS tmp
			INNER JOIN FPS_FingerPrint.FingerPrintEvolution AS fpe ON tmp.Id = fpe.Id;

    END IF;
END$$
DELIMITER ;
