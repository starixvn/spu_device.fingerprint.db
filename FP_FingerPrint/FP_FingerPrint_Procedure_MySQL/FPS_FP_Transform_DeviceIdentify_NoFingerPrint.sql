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
            
		Param's Explanation (filtered by):	

		Example:
			- CALL FPS_FP_Transform_DeviceIdentify_NoFingerPrint('1,2,3');
			
	*/
    
    /*******LOG TEST********************/
    INSERT INTO FPS_FingerPrint.Test_LOG(SpName, JsonString, OtherText, InsertTime)
    SELECT 'FPS_FP_Transform_DeviceIdentify_NoFingerPrint', NULL,ip_TransList, CURRENT_TIMESTAMP();
    /*******LOG TEST********************/
    
	DROP TEMPORARY TABLE IF EXISTS Temp_InputTrans;    
	CREATE TEMPORARY TABLE Temp_InputTrans(
		Id	BIGINT UNSIGNED PRIMARY KEY
	);
    
    SET @sql = CONCAT("INSERT INTO Temp_InputTrans (Id) VALUES ('", REPLACE(ip_TransList, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;
    
    INSERT INTO FPS_FingerPrint.TransactionDevice(ServerTransId, CustId , SubAccId, LoginName, SubscriberId, TransTime,  ClientIP, UserAgentId, UserAgent, Url, Action, CreatedDate, TransKey, Flagged)
    SELECT  ts.ServerTransId
			, 	ts.CustId
			, 	ts.SubAccId
			, 	ts.LoginName
			, 	ts.SubscriberId			
			, 	ts.TransTime
			, 	ts.ClientIP
			, 	ts.UserAgentId
			, 	ts.UserAgent
			, 	ts.Url
			, 	ts.Action
			, 	CURRENT_TIMESTAMP(4)
			, 	ts.TransKey
			, 	ts.Flagged    
	FROM Temp_InputTrans AS tmpTs
		INNER JOIN FPS_FingerPrint.Transaction AS ts ON tmpTs.Id = ts.Id;
    
    DELETE ts 
    FROM FPS_FingerPrint.Transaction AS ts
		INNER JOIN Temp_InputTrans tmpTs ON tmpTs.Id = ts.Id;    
    
END$$
DELIMITER ;