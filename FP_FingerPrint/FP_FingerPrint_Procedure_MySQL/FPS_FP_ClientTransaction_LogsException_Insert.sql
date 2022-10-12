/*<info serverAlias="FPSDC-FPS_FingerPrint" databaseType="2" executers="fpsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `FPS_FP_ClientTransaction_LogsException_Insert`;
DELIMITER $$

CREATE DEFINER=`fpsOwner`@`%` PROCEDURE `FPS_FP_ClientTransaction_LogsException_Insert`(
		ip_Function 	VARCHAR(100),
        ip_Exception 	TEXT,
        ip_UserAgent	VARCHAR(500)
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20220929@Terry.Nguyen
		Task :		
		DB:			FPS_FingerPrint
		Original:

		Revisions: 
			- 20220307@Terry.Nguyen: Created [Redmine ID: #162668]			
            
		Param's Explanation (filtered by):	

		Example:
			- CALL FPS_FP_ClientTransaction_LogsException_Insert('FingerPrint', 'abc');
			
	*/
    
    INSERT INTO CTS_Log.FPSClientTransaction_Exception(FunctionName, Exception, UserAgent, CreatedDate)
	VALUES(ip_Function, ip_Exception, ip_UserAgent, NOW());
    
END$$
DELIMITER ;