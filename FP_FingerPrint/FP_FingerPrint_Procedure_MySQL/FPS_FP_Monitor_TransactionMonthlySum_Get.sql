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
   
    DECLARE lv_FirstDate DATETIME DEFAULT NULL;
    DECLARE lv_LastDate DATETIME DEFAULT NULL;
    
    SET lv_FirstDate = STR_TO_DATE(CONCAT('01/',ip_Month), '%d/%m/%Y');
    SET lv_LastDate = DATE_ADD(lv_FirstDate, INTERVAL 1 MONTH);

   -- Server monthly sum
    WITH tmp_SumDaily AS
    (
		SELECT 	DATE_FORMAT(cl.TransDate,'%Y-%m-01') AS TransMonth
			, 	cl.SubscriberId
			, 	SUM(cl.TotalTrans) AS TotalTrans
			, 	SUM(cl.TotalValidTrans) AS TotalValidTrans
		FROM FPS_FingerPrint.ClientTransactionDailySum AS cl 
		WHERE cl.TransDate BETWEEN lv_FirstDate AND lv_LastDate
		GROUP BY cl.SubscriberId, TransMonth
	)
    SELECT 		tmp.TransMonth
			,	tmp.SubscriberId	
            ,	tmp.TotalTrans	
            ,	tmp.TotalValidTrans	
    FROM tmp_SumDaily AS tmp;

   -- Client monthly sum
    WITH tmp_SumDaily AS
    (
		SELECT 	DATE_FORMAT(cl.TransDate,'%Y-%m-01') AS TransMonth
			, 	cl.SubscriberId
			, 	SUM(cl.TotalTrans) AS TotalTrans
			, 	SUM(cl.TotalValidTrans) AS TotalValidTrans
		FROM FPS_FingerPrint.ServerTransactionDailySum AS cl 
		WHERE cl.TransDate BETWEEN lv_FirstDate AND lv_LastDate
		GROUP BY cl.SubscriberId, TransMonth
	)
    SELECT 		tmp.TransMonth
			,	tmp.SubscriberId	
            ,	tmp.TotalTrans	
            ,	tmp.TotalValidTrans	
    FROM tmp_SumDaily AS tmp;
    
END$$
DELIMITER ;
