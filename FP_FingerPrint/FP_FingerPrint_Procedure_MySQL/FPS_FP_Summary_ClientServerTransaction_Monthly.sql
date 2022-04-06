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
    DECLARE lv_SumDate DATETIME DEFAULT NULL;
    
    /*******LOG TEST********************/
    INSERT INTO FPS_FingerPrint.Test_LOG(SpName, JsonString, OtherText, InsertTime)
    SELECT 'FPS_FP_Summary_ClientServerTransaction_Monthly', NULL, NULL, CURRENT_TIMESTAMP();
    /*******LOG TEST********************/
    SET lv_CurrentDate = NOW();
    SET lv_SumDate = DATE_SUB(lv_CurrentDate, INTERVAL 1 DAY);
	
    INSERT INTO FPS_FingerPrint.ClientTransactionMonthlySum(TransMonth, SubscriberId, TotalTrans, TotalValidTrans, CreateDate, ModifiedDate)
    WITH tmp_SumDaily AS
    (SELECT 
		DATE_FORMAT(cl.TransDate,'%Y-%m-01') as TransDate
        , cl.SubscriberId
        , SUM(cl.TotalTrans) as TotalTrans
        , SUM(cl.TotalValidTrans) as TotalValidTrans
        , lv_CurrentDate as CreatedDate
        , lv_CurrentDate as ModifiedDate
    FROM FPS_FingerPrint.ClientTransactionDailySum cl 
    WHERE DATE(cl.TransDate) = DATE(lv_SumDate)
    GROUP BY cl.SubscriberId, DATE_FORMAT(cl.TransDate,'%Y-%m-01'))
    SELECT 		tmp.TransDate
			,	tmp.SubscriberId	
            ,	tmp.TotalTrans	
            ,	tmp.TotalValidTrans	
            ,	tmp.CreatedDate	
            ,	tmp.ModifiedDate
    FROM tmp_SumDaily tmp
    ON DUPLICATE KEY UPDATE 
    TotalTrans = tmp.TotalTrans, 
    TotalValidTrans = tmp.TotalValidTrans, 
    ModifiedDate = lv_CurrentDate;
    
    #==================================
    
    INSERT INTO FPS_FingerPrint.ServerTransactionMonthlySum(TransMonth, SubscriberId, TotalTrans, TotalValidTrans, CreateDate, ModifiedDate)
    WITH tmp_SumDaily AS
    (SELECT 
		DATE_FORMAT(cl.TransDate,'%Y-%m-01') as TransDate
        , cl.SubscriberId
        , SUM(cl.TotalTrans) as TotalTrans
        , SUM(cl.TotalValidTrans) as TotalValidTrans
        , lv_CurrentDate as CreatedDate
        , lv_CurrentDate as ModifiedDate
    FROM FPS_FingerPrint.ServerTransactionDailySum cl 
    WHERE DATE(cl.TransDate) = DATE(lv_SumDate)
    GROUP BY cl.SubscriberId, DATE_FORMAT(cl.TransDate,'%Y-%m-01'))
    SELECT 		tmp.TransDate
			,	tmp.SubscriberId	
            ,	tmp.TotalTrans	
            ,	tmp.TotalValidTrans	
            ,	tmp.CreatedDate	
            ,	tmp.ModifiedDate
    FROM tmp_SumDaily tmp
    ON DUPLICATE KEY UPDATE 
    TotalTrans = tmp.TotalTrans, 
    TotalValidTrans = tmp.TotalValidTrans, 
    ModifiedDate = lv_CurrentDate;
    
END$$
DELIMITER ;