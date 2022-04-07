/*<info serverAlias="FPSDC-FPS_FingerPrint" databaseType="2" executers="fpsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `FPS_FP_Summary_Transaction_Daily`;
DELIMITER $$

CREATE DEFINER=`fpsOwner`@`%` PROCEDURE `FPS_FP_Summary_Transaction_Daily`(
		ip_batchSize INT
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
			- CALL FPS_FP_Summary_Transaction_Daily(10);
			
	*/
    
    DECLARE lv_TransId BIGINT DEFAULT 0;   
    DECLARE lv_MaxTransId BIGINT DEFAULT 0;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_SumTransaction;  
    
    CREATE TEMPORARY TABLE Temp_SumTransaction(
			Id 					BIGINT UNSIGNED PRIMARY KEY        	
		,	SubscriberId 		INT DEFAULT NULL
		,	TransDate 			DATETIME(4) DEFAULT NULL
    ); 
    
    /*******LOG TEST********************/
    INSERT INTO FPS_FingerPrint.Test_LOG(SpName, JsonString, OtherText, InsertTime)
    SELECT 'FPS_FP_Summary_Transaction_Daily', NULL, NULL, CURRENT_TIMESTAMP();
    /*******LOG TEST********************/
    
    SELECT off.OffsetValue INTO lv_TransId 
    FROM FPS_FingerPrint.Offset off 
    WHERE off.OffsetName = 'SummaryTransaction';
    
    INSERT INTO Temp_SumTransaction(Id, SubscriberId, TransDate)
    SELECT cl.Id, cl.SubscriberId, DATE(cl.TransTime) as TransDate
    FROM FPS_FingerPrint.TransactionCompleted cl 
    WHERE cl.Id > lv_TransId     
    LIMIT ip_batchSize;
    
    INSERT INTO FPS_FingerPrint.TransactionDailySum(TransDate, SubscriberId, TotalTrans, CreateDate, ModifiedDate)
    WITH dailySum AS(
				SELECT DATE(tmp.TransDate) as TransDate, tmp.SubscriberId, COUNT(1) as Total 
				FROM Temp_SumTransaction tmp 
                GROUP BY  tmp.SubscriberId, DATE(tmp.TransDate)) 
    SELECT tmp.TransDate, tmp.SubscriberId, tmp.Total, NOW(), NOW() FROM dailySum tmp
    ON DUPLICATE KEY UPDATE 
		TotalTrans = TotalTrans + tmp.Total,
        ModifiedDate = NOW();    
    
    SELECT MAX(Id) INTO lv_MaxTransId 
		FROM Temp_SumTransaction;
    
    UPDATE FPS_FingerPrint.Offset off 
		SET off.OffsetValue = lv_MaxTransId
    WHERE off.OffsetName = 'SummaryTransaction';
    
END$$
DELIMITER ;