/*<info serverAlias="FPSDC-FPS_FingerPrint" databaseType="2" executers="fpsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `FPS_FP_Summary_ClientServerTransaction_Monthly`;
DELIMITER $$

CREATE DEFINER=`fpsOwner`@`%` PROCEDURE `FPS_FP_Summary_ClientServerTransaction_Monthly`(
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
			- CALL FPS_FP_Summary_ClientServerTransaction_Monthly();
			
	*/
    DECLARE lv_CurrentDate DATETIME DEFAULT NULL;
    DECLARE lv_FirstDate DATETIME DEFAULT NULL;
    DECLARE lv_LastDate DATETIME DEFAULT NULL;
    
    /*******LOG TEST********************/
    INSERT INTO FPS_FingerPrint.Test_LOG(SpName, JsonString, OtherText, InsertTime)
    SELECT 'FPS_FP_Summary_ClientServerTransaction_Monthly', NULL, NULL, CURRENT_TIMESTAMP();
    /*******LOG TEST********************/
    
    SET lv_CurrentDate = NOW();
    SET lv_FirstDate = CAST(DATE_FORMAT(lv_CurrentDate, '%Y-%m-01') AS DATE);
    SET lv_LastDate = DATE_ADD(lv_FirstDate, INTERVAL 1 MONTH);
	
    INSERT INTO FPS_FingerPrint.ClientTransactionMonthlySum(TransMonth, SubscriberId, TotalTrans, TotalValidTrans, CreateDate, ModifiedDate)
    WITH tmp_SumDaily AS
    (
		SELECT 	DATE_FORMAT(cl.TransDate,'%Y-%m-01') as TransMonth
			, 	cl.SubscriberId
			, 	SUM(cl.TotalTrans) as TotalTrans
			, 	SUM(cl.TotalValidTrans) as TotalValidTrans
			, 	lv_CurrentDate as CreatedDate
			, 	lv_CurrentDate as ModifiedDate
		FROM FPS_FingerPrint.ClientTransactionDailySum cl 
		WHERE cl.TransDate BETWEEN lv_FirstDate AND lv_LastDate
		GROUP BY cl.SubscriberId, TransMonth
	)
    SELECT 		tmp.TransMonth
			,	tmp.SubscriberId	
            ,	tmp.TotalTrans	
            ,	tmp.TotalValidTrans	
            ,	tmp.CreatedDate	
            ,	tmp.ModifiedDate
    FROM tmp_SumDaily tmp
    ON DUPLICATE KEY UPDATE TotalTrans = tmp.TotalTrans, 
							TotalValidTrans = tmp.TotalValidTrans, 
							ModifiedDate = lv_CurrentDate;
    
    #==================================
    
    INSERT INTO FPS_FingerPrint.ServerTransactionMonthlySum(TransMonth, SubscriberId, TotalTrans, TotalValidTrans, CreateDate, ModifiedDate)
    WITH tmp_SumDaily AS
    (
		SELECT 	DATE_FORMAT(cl.TransDate,'%Y-%m-01') as TransMonth
			, 	cl.SubscriberId
			, 	SUM(cl.TotalTrans) as TotalTrans
			, 	SUM(cl.TotalValidTrans) as TotalValidTrans
			, 	lv_CurrentDate as CreatedDate
			, 	lv_CurrentDate as ModifiedDate
		FROM FPS_FingerPrint.ServerTransactionDailySum cl 
		WHERE cl.TransDate BETWEEN lv_FirstDate AND lv_LastDate
		GROUP BY cl.SubscriberId, TransMonth
	)
    SELECT 		tmp.TransMonth
			,	tmp.SubscriberId	
            ,	tmp.TotalTrans	
            ,	tmp.TotalValidTrans	
            ,	tmp.CreatedDate	
            ,	tmp.ModifiedDate
    FROM tmp_SumDaily tmp
    ON DUPLICATE KEY UPDATE TotalTrans = tmp.TotalTrans, 
							TotalValidTrans = tmp.TotalValidTrans, 
							ModifiedDate = lv_CurrentDate;
    
    #==================================
    
    INSERT INTO FPS_FingerPrint.TransactionMonthlySum(TransMonth, SubscriberId, TotalTrans, CreateDate, ModifiedDate)
    WITH tmp_SumDaily AS
    (
		SELECT 	DATE_FORMAT(cl.TransDate,'%Y-%m-01') as TransMonth
			, 	cl.SubscriberId
			, 	SUM(cl.TotalTrans) as TotalTrans       
			, 	lv_CurrentDate as CreatedDate
			, 	lv_CurrentDate as ModifiedDate
		FROM FPS_FingerPrint.TransactionDailySum cl 
		WHERE cl.TransDate BETWEEN lv_FirstDate AND lv_LastDate
		GROUP BY cl.SubscriberId, TransMonth
	)
    SELECT 		tmp.TransMonth
			,	tmp.SubscriberId	
            ,	tmp.TotalTrans	           
            ,	tmp.CreatedDate	
            ,	tmp.ModifiedDate
    FROM tmp_SumDaily tmp
    ON DUPLICATE KEY UPDATE TotalTrans = tmp.TotalTrans,     
							ModifiedDate = lv_CurrentDate;
    
END$$
DELIMITER ;