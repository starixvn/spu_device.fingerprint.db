/*<info serverAlias="FPSDC-FPS_FingerPrint" databaseType="2" executers="fpsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `FPS_FP_Monitor_ClientTransactionDailySum_Get`;
DELIMITER $$

CREATE DEFINER=`fpsOwner`@`%` PROCEDURE `FPS_FP_Monitor_ClientTransactionDailySum_Get`(
		ip_dmyDate VARCHAR(10)
)
    SQL SECURITY INVOKER
BEGIN
	DECLARE lv_Date DATE;
    SET lv_Date = CAST(STR_TO_DATE(ip_dmyDate, '%d/%m/%Y') as DATE);
	/*
		Created:	20220322@Jonathan.Doan
		Task :		
		DB:			FPS_FingerPrint
		Original:

		Revisions: 
			- 20220322@Jonathan.Doan: Created [Redmine ID: #170284]
            
		Param's Explanation (filtered by):	

		Example:
			- CALL FPS_FP_Monitor_ClientTransactionDailySum_Get('22/03/2022');
			
	*/
   
    SELECT daily.TransDate
		, daily.SubscriberId
		, sub.Name as SubscriberName
        , daily.TotalTrans
        , daily.TotalValidTrans
	FROM FPS_FingerPrint.ClientTransactionDailySum daily
		INNER JOIN FPS_FingerPrint.Subscribers sub on sub.Id = daily.SubscriberId
	WHERE daily.TransDate = lv_Date;
    
END$$
DELIMITER ;
