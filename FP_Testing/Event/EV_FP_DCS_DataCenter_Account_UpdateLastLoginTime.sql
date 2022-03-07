DELIMITER //
DROP EVENT IF EXISTS EV_FP_DCS_DataCenter_Account_UpdateLastLoginTime;
/*
	Created: 202107050@Aries.Nguyen
	Task : Update Account.LastLoginTime
	DB: FPTesting
	Original:

	Revisions:
	Param's Explanation (filtered by):
*/    
CREATE DEFINER=`aries.vn`@`%` 
EVENT `EV_FP_DCS_DataCenter_Account_UpdateLastLoginTime` 
	ON SCHEDULE 
		EVERY 10 SECOND 
		DO BEGIN
 			IF EXISTS(SELECT 1 FROM FPTesting.FP_SystemEventStatus WHERE EventName = 'EV_FP_DCS_DataCenter_Account_UpdateLastLoginTime' AND Status = 'Stop') THEN
 				UPDATE CTS_DataCenter.SystemEventStatus 
 				SET Status = 'Start' 
 				WHERE EventName = 'EV_FP_DCS_DataCenter_Account_UpdateLastLoginTime' ;
 
 				CALL FPTesting.FP_DCS_DC_Transform_Account_UpdateLastLoginTime(500); 
 
 				UPDATE FPTesting.FP_SystemEventStatus 
 				SET Status = 'Stop' 
 				WHERE EventName = 'EV_FP_DCS_DataCenter_Account_UpdateLastLoginTime' ;
 
 			END IF; 			
       END //
DELIMITER ;
