/*<info serverAlias="FPSDC-FPS_FingerPrint" databaseType="2" executers="fpsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `FPS_FP_Transform_DeviceIdentify_NoFingerPrint`;
DELIMITER $$

CREATE DEFINER=`fpsOwner`@`%` PROCEDURE `FPS_FP_Transform_DeviceIdentify_NoFingerPrint`(		
        ip_TransList	LONGTEXT
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
            - 20220808@Jonathan.Doan: Add AddonId [Redmine ID: #175155]
			- 20221123@Jonathan.Doan: Remove field SeverTransId, ClientTransId, AddonId [Redmine ID: #180406]
			- 20231017@Teddy.Le: Detect real ip and fake ip via x-real-ip [Redmine ID: #195602]
		Param's Explanation (filtered by):	

		Example:
			- CALL FPS_FP_Transform_DeviceIdentify_NoFingerPrint('1,2,3');
			
	*/
    
    /*******LOG TEST********************/
    IF (SELECT ofs.OffsetValue FROM FPS_FingerPrint.Offset AS ofs WHERE Id = 7) = 1 THEN		
		INSERT INTO CTS_Log.FPSLog(SpName, JsonString, OtherText, InsertTime)
		SELECT 'FPS_FP_Transform_DeviceIdentify_NoFingerPrint', NULL,ip_TransList, CURRENT_TIMESTAMP();
	END IF;
    /*******LOG TEST********************/
    
	DROP TEMPORARY TABLE IF EXISTS Temp_InputTrans;    
	CREATE TEMPORARY TABLE Temp_InputTrans(
		Id	BIGINT UNSIGNED PRIMARY KEY
	);
    
    SET @sql = CONCAT("INSERT INTO Temp_InputTrans (Id) VALUES ('", REPLACE(ip_TransList, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;
    
    INSERT INTO FPS_FingerPrint.TransactionDevice(CustId , SubAccId, AccountId, LoginName, SubscriberId, RawFingerPrintId, BrowserInstanceId, TransTime, ClientIP, FakeIP, UserAgentId, Url, Action, CreatedDate, TransKey)
    SELECT  ts.CustId
		, 	ts.SubAccId
		, 	ts.AccountId
		, 	ts.LoginName
		, 	ts.SubscriberId
		, 	ts.RawFingerPrintId
		, 	ts.BrowserInstanceId
		, 	ts.TransTime
		, 	ts.ClientIP
        ,	ts.FakeIP
		, 	ts.BrowserInfoId
		, 	ts.UserAgentId
		, 	ts.Url
		, 	ts.Action
		, 	CURRENT_TIMESTAMP(4)
		, 	ts.TransKey
	FROM Temp_InputTrans AS tmpTs
		INNER JOIN FPS_FingerPrint.Transaction AS ts ON tmpTs.Id = ts.Id;
    
    DELETE ts 
    FROM FPS_FingerPrint.Transaction AS ts
		INNER JOIN Temp_InputTrans tmpTs ON tmpTs.Id = ts.Id;    
    
END$$
DELIMITER ;