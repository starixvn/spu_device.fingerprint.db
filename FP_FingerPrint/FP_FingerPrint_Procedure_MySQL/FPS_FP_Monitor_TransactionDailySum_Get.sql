/*<info serverAlias="FPSDC-FPS_FingerPrint" databaseType="2" executers="fpsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `FPS_FP_Monitor_TransactionDailySum_Get`;
DELIMITER $$

CREATE DEFINER=`fpsOwner`@`%` PROCEDURE `FPS_FP_Monitor_TransactionDailySum_Get`(
		ip_mdyDate VARCHAR(10)
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20220322@Jonathan.Doan
		Task :		
		DB:			FPS_FingerPrint
		Original:

		Revisions: 
			- 20220322@Jonathan.Doan: Created [Redmine ID: #170284]
            
		Param's Explanation (filtered by):	

		Example:
			- CALL FPS_FP_Monitor_TransactionDailySum_Get('22/03/2022');
			
	*/
    
	DECLARE lv_Date DATE;
    SET lv_Date = STR_TO_DATE(ip_mdyDate, '%m/%d/%Y');
   
   -- Server daily sum
    SELECT daily.TransDate
		, daily.SubscriberId
		, sub.Name AS SubscriberName
        , daily.TotalTrans
        , daily.TotalValidTrans
	FROM FPS_FingerPrint.ServerTransactionDailySum AS daily
		INNER JOIN FPS_FingerPrint.Subscribers AS sub ON sub.Id = daily.SubscriberId
	WHERE daily.TransDate = lv_Date;
   
   -- Client daily sum
    SELECT daily.TransDate
		, daily.SubscriberId
		, sub.Name AS SubscriberName
        , daily.TotalTrans
        , daily.TotalValidTrans
	FROM FPS_FingerPrint.ClientTransactionDailySum AS daily
		INNER JOIN FPS_FingerPrint.Subscribers AS sub ON sub.Id = daily.SubscriberId
	WHERE daily.TransDate = lv_Date;
    
END$$
DELIMITER ;
