/*<info serverAlias="FPSDC-FPS_FingerPrint" databaseType="2" executers="fpsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `FPS_FP_Monitor_ServerTransactionDailySum_Insert`;
DELIMITER $$

CREATE DEFINER=`fpsOwner`@`%` PROCEDURE `FPS_FP_Monitor_ServerTransactionDailySum_Insert`(
		ip_Data LONGTEXT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20220608@Jonathan.Doan
		Task :		
		DB:			FPS_FingerPrint
		Original:

		Revisions:
			- 20220608@Jonathan.Doan: Created [Redmine ID: #173803]
            
		Param's Explanation (filtered by):	

		Example:
			- CALL FPS_FP_Monitor_ServerTransactionDailySum_Insert('[{"TransDate":"2022-06-07","SubscriberId":1,"CountTrans":2}]');
			
	*/
    
    DECLARE lv_CurrentDate DATETIME DEFAULT NOW();
    DECLARE lv_RawFingerPrintId BIGINT;
    
    /*******LOG TEST********************/
    IF (SELECT ofs.OffsetValue FROM FPS_FingerPrint.Offset AS ofs WHERE Id = 7) = 1 THEN		
		INSERT INTO CTS_Log.FPSLog(SpName, JsonString, OtherText, InsertTime)
		SELECT 'FPS_FP_Monitor_ServerTransactionDailySum_Insert', ip_Data , NULL, CURRENT_TIMESTAMP();
	END IF;
    /*******LOG TEST********************/
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Data;
    
	CREATE TEMPORARY TABLE Temp_Data(
			TransDate			DATE 		NULL	
		,	SubscriberId		INT	 		NULL	
		,	CountTrans			INT	 		NULL
        , 	INDEX IX_Temp_Data_TransDate(TransDate)
        , 	INDEX IX_Temp_Data_SubscriberId(SubscriberId)
    );
    
    INSERT INTO Temp_Data(TransDate, SubscriberId, CountTrans)
	SELECT	tmp.TransDate
		,	tmp.SubscriberId
		,	tmp.CountTrans
	FROM	JSON_TABLE(
			ip_Data,
			 "$[*]" COLUMNS(
							TransDate			DATE		PATH "$.TransDate"       
						,	SubscriberId		INT	 		PATH "$.SubscriberId"   
						,	CountTrans			INT	 		PATH "$.CountTrans"
				)
		   ) AS tmp; 
    
	INSERT INTO FPS_FingerPrint.ServerTransactionDailySum(
			TransDate
		,	SubscriberId
		,	TotalTrans
		,	TotalValidTrans
		,	CreateDate
		,	ModifiedDate
    )
    SELECT 	tmp.TransDate
		,	tmp.SubscriberId
		,	tmp.CountTrans AS TotalTrans
		,	0 AS TotalValidTrans
		,	lv_CurrentDate AS CreatedDate
		,	lv_CurrentDate AS ModifiedDate
	FROM Temp_Data AS tmp
    ON DUPLICATE KEY UPDATE TotalTrans = TotalTrans + tmp.CountTrans,
							ModifiedDate = lv_CurrentDate;
END$$
DELIMITER ;