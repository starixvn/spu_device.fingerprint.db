/*<info serverAlias="FPSDC-FPS_FingerPrint" databaseType="2" executers="fpsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `FPS_FP_Monitor_TransactionMonthlySum_Get`;
DELIMITER $$

CREATE DEFINER=`fpsOwner`@`%` PROCEDURE `FPS_FP_Monitor_TransactionMonthlySum_Get`(
		ip_Month VARCHAR(7)
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20220324@Jonathan.Doan
		Task :		
		DB:			FPS_FingerPrint
		Original:

		Revisions: 
			- 20220323@Jonathan.Doan: Created [Redmine ID: #170284]
            
		Param's Explanation (filtered by):	

		Example:
			- CALL FPS_FP_Monitor_TransactionMonthlySum_Get('03/2022');
			
	*/
   
	DECLARE lv_FirstDate DATE;
    SET lv_FirstDate = STR_TO_DATE(CONCAT('01/',ip_Month), '%d/%m/%Y');

   -- Server monthly sum
    SELECT daily.TransMonth AS TransDate
		, daily.SubscriberId
		, sub.Name AS SubscriberName
        , daily.TotalTrans
        , daily.TotalValidTrans
	FROM FPS_FingerPrint.ServerTransactionMonthlySum AS daily
		INNER JOIN FPS_FingerPrint.Subscribers AS sub ON sub.Id = daily.SubscriberId
	WHERE daily.TransMonth = lv_FirstDate;

   -- Client monthly sum
    SELECT daily.TransMonth
		, daily.SubscriberId
		, sub.Name AS SubscriberName
        , daily.TotalTrans
        , daily.TotalValidTrans
	FROM FPS_FingerPrint.ClientTransactionMonthlySum AS daily
		INNER JOIN FPS_FingerPrint.Subscribers AS sub ON sub.Id = daily.SubscriberId
	WHERE daily.TransMonth = lv_FirstDate;
    
END$$
DELIMITER ;
