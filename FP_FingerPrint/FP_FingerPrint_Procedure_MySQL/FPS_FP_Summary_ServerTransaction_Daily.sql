/*<info serverAlias="FPSDC-FPS_FingerPrint" databaseType="2" executers="fpsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `FPS_FP_Summary_ServerTransaction_Daily`;
DELIMITER $$

CREATE DEFINER=`fpsOwner`@`%` PROCEDURE `FPS_FP_Summary_ServerTransaction_Daily`(
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
			- CALL FPS_FP_Summary_ServerTransaction_Daily(10);
			
	*/
    
    
    DECLARE lv_ServerTransId BIGINT DEFAULT 0;    
    DECLARE lv_MaxTransId BIGINT DEFAULT 0;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_SumTransaction;  
    
    CREATE TEMPORARY TABLE Temp_SumTransaction(
			Id 					BIGINT UNSIGNED PRIMARY KEY        	
		,	SubscriberId 		INT DEFAULT NULL
		,	TransDate 			DATETIME(4) DEFAULT NULL		
    ); 
    
    /*******LOG TEST********************/
    INSERT INTO FPS_FingerPrint.Test_LOG(SpName, JsonString, OtherText, InsertTime)
    SELECT 'FPS_FP_Summary_ServerTransaction_Daily', NULL, NULL, CURRENT_TIMESTAMP();
    /*******LOG TEST********************/
    
   SELECT off.OffsetValue INTO lv_ServerTransId 
    FROM FPS_FingerPrint.Offset off 
    WHERE off.OffsetName = 'SummaryServerTransaction';
    
    INSERT INTO Temp_SumTransaction(Id, SubscriberId, TransDate)
    SELECT cl.Id, cl.SubscriberId, DATE(cl.TransTime) as TransDate
    FROM FPS_FingerPrint.ServerTransactionCompleted cl 
    WHERE cl.Id > lv_ServerTransId     
    LIMIT ip_batchSize;
    
    IF EXISTS(SELECT 1 FROM Temp_SumTransaction) THEN
    BEGIN    
		UPDATE FPS_FingerPrint.ServerTransactionDailySum cls 
		INNER JOIN (SELECT tmp.SubscriberId, DATE(tmp.TransDate) as TransDate, COUNT(1) as Total 
					FROM Temp_SumTransaction tmp 
					GROUP BY  tmp.SubscriberId, DATE(tmp.TransDate)) tmp2 ON cls.SubscriberId = tmp2.SubscriberId AND cls.TransDate = tmp2.TransDate
		SET cls.TotalValidTrans = cls.TotalValidTrans + tmp2.Total
		,	cls.ModifiedDate = NOW();
		
		SELECT MAX(Id) INTO lv_MaxTransId 
			FROM Temp_SumTransaction;
		
		UPDATE FPS_FingerPrint.Offset off 
			SET off.OffsetValue = lv_MaxTransId
		WHERE off.OffsetName = 'SummaryServerTransaction'; 
    END;
    END IF;
END$$
DELIMITER ;