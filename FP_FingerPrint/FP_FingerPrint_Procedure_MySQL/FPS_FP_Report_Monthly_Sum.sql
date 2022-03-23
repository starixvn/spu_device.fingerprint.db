/*<info serverAlias="FPSDC-FPS_FingerPrint" databaseType="2" executers="fpsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `FPS_FP_Report_Monthly_Sum`;
DELIMITER $$

CREATE DEFINER=`fpsOwner`@`%` PROCEDURE `FPS_FP_Report_Monthly_Sum`(
		ip_Month VARCHAR(7)
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20220323@Jonathan.Doan
		Task :		
		DB:			FPS_FingerPrint
		Original:

		Revisions: 
			- 20220323@Jonathan.Doan: Created [Redmine ID: #170284]
            
		Param's Explanation (filtered by):	

		Example:
			- CALL FPS_FP_Report_Monthly_Sum('03/2022');
			
	*/
   
	DECLARE lv_FirstDate DATE;
	DECLARE lv_LastDate DATE;
    
    SET lv_FirstDate = STR_TO_DATE(CONCAT('01/',ip_Month), '%d/%m/%Y');
    SET lv_LastDate = LAST_DAY(STR_TO_DATE(CONCAT('01/',ip_Month), '%d/%m/%Y'));
    
    INSERT INTO FPS_FingerPrint.ClientTransactionMonthlySum(TransMonth, SubscriberId, TotalTrans, TotalValidTrans, CreateDate)
    WITH CTE_DailySum as (
		SELECT 	sum.SubscriberId
				, SUM(sum.TotalTrans) as TotalTrans
				, SUM(sum.TotalValidTrans) as TotalValidTrans
		FROM FPS_FingerPrint.ClientTransactionDailySum sum
		WHERE TransDate BETWEEN lv_FirstDate AND lv_LastDate
		GROUP BY sum.SubscriberId
    )
    SELECT 	lv_FirstDate
			, cte.SubscriberId
			, cte.TotalTrans
			, cte.TotalValidTrans
			, NOW() as CreateDate
    FROM CTE_DailySum cte
    ON DUPLICATE KEY UPDATE TotalTrans = cte.TotalTrans
							, TotalValidTrans = cte.TotalValidTrans
							, ModifiedDate = NOW();
                            
    
    INSERT INTO FPS_FingerPrint.ServerTransactionMonthlySum(TransMonth, SubscriberId, TotalTrans, TotalValidTrans, CreateDate)
    WITH CTE_DailySum as (
		SELECT 	sum.SubscriberId
				, SUM(sum.TotalTrans) as TotalTrans
				, SUM(sum.TotalValidTrans) as TotalValidTrans
		FROM FPS_FingerPrint.ServerTransactionDailySum sum
		WHERE TransDate BETWEEN lv_FirstDate AND lv_LastDate
		GROUP BY sum.SubscriberId
    )
    SELECT 	lv_FirstDate
			, cte.SubscriberId
			, cte.TotalTrans
			, cte.TotalValidTrans
			, NOW() as CreateDate
    FROM CTE_DailySum cte
    ON DUPLICATE KEY UPDATE TotalTrans = cte.TotalTrans
							, TotalValidTrans = cte.TotalValidTrans
							, ModifiedDate = NOW();
    
END$$
DELIMITER ;
