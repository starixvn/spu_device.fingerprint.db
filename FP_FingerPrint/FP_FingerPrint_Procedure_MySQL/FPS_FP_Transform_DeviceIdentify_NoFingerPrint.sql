/*<info serverAlias="xxxx" databaseType="2" executers="fpsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `FPS_FP_Transform_DeviceIdentify_NoFingerPrint`;
DELIMITER $$

CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `FPS_FP_Transform_DeviceIdentify_NoFingerPrint`(		
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
            
		Param's Explanation (filtered by):	

		Example:
			- CALL FPS_FP_Transform_DeviceIdentify_NoFingerPrint('1,2,3');
			
	*/
   
	DROP TEMPORARY TABLE IF EXISTS Temp_InputTrans;    
	CREATE TEMPORARY TABLE Temp_InputTrans(
		Id	BIGINT UNSIGNED PRIMARY KEY
	);
    
    SET @sql = CONCAT("INSERT INTO Temp_InputTrans (Id) VALUES ('", REPLACE(ip_TransList, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;
    
    INSERT INTO FPS_FingerPrint.TransactionCompleted(Id, RawTransId, CustId , SubAccId, LoginName, SubscriberId, Transtime,  ClientIP, UserAgent, Url, Action, ModifiedDate, CreatedDate, TransKey, Flagged)
    SELECT  	ts.Id
			, 	ts.RawTransId
			, 	ts.CustId
			, 	ts.SubAccId
			, 	ts.LoginName
			, 	ts.SubscriberId			
			, 	ts.Transtime
			, 	ts.ClientIP
			, 	ts.UserAgent
			, 	ts.Url
			, 	ts.Action
			, 	ts.ModifiedDate
			, 	CURRENT_TIMESTAMP(4)
			, 	ts.TransKey
			, 	ts.Flagged    
	FROM Temp_Transaction AS tmpTs
		INNER JOIN FPS_FingerPrint.Transaction AS ts ON tmpTs.Id = ts.Id;
    
    DELETE ts 
    FROM FPS_FingerPrint.Transaction AS ts
		INNER JOIN Temp_Transaction tmpTs ON tmpTs.Id = ts.Id;    
    
END$$
DELIMITER ;