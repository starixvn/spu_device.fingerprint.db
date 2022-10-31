/*<info serverAlias="FPSDC-FPS_FingerPrint" databaseType="2" executers="fpsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `FPS_FP_Summary_RecoverType_Daily`;
DELIMITER $$

CREATE DEFINER=`fpsOwner`@`%` PROCEDURE `FPS_FP_Summary_RecoverType_Daily`(
		ip_batchSize INT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20221026@Jonathan.Doan
		Task :		
		DB:			FPS_FingerPrint
		Original:

		Revisions: 
			- 20221026@Jonathan.Doan: Created [Redmine ID: #179603]			
            
		Param's Explanation (filtered by):	

		Example:
			- CALL FPS_FP_Summary_RecoverType_Daily(10);
			
	*/
    
    DECLARE lv_TransId BIGINT DEFAULT 0;   
    DECLARE lv_MaxTransId BIGINT DEFAULT 0;
    DECLARE lv_CreatedDate DATETIME(4) DEFAULT CURRENT_TIMESTAMP(4);
    DECLARE lv_OffsetName VARCHAR(20) DEFAULT 'SummaryRecoverType';
    
    /*******LOG TEST********************/
    IF (SELECT ofs.OffsetValue FROM FPS_FingerPrint.Offset AS ofs WHERE Id = 7) = 1 THEN		
		INSERT INTO CTS_Log.FPSLog(SpName, JsonString, OtherText, InsertTime)
		SELECT 'FPS_FP_Summary_RecoverType_Daily', NULL, NULL, CURRENT_TIMESTAMP();
	END IF;
    /*******LOG TEST********************/
    
    SELECT off.OffsetValue INTO lv_TransId 
    FROM FPS_FingerPrint.Offset AS off
    WHERE off.OffsetName = lv_OffsetName;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Transaction;  
    DROP TEMPORARY TABLE IF EXISTS Temp_SumTransaction;  
    
    CREATE TEMPORARY TABLE Temp_Transaction(
			Id			 		BIGINT UNSIGNED PRIMARY KEY
		,	SubscriberId 		INT DEFAULT NULL
		,	TransDate 			DATE DEFAULT NULL
		,	RecoverType			TINYINT DEFAULT NULL
        
        ,	INDEX IX_Temp_Transaction_RecoverType(RecoverType)
    ); 
    
    CREATE TEMPORARY TABLE Temp_SumTransaction(
			Id			 			BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY
		,	SubscriberId 			INT DEFAULT NULL
		,	TransDate 				DATE DEFAULT NULL
		,	TmpTotal				INT UNSIGNED DEFAULT 0
		,	TmpNullDevice			INT UNSIGNED DEFAULT 0
		,	TmpNewDevice			INT UNSIGNED DEFAULT 0
		,	TmpRecoverByFP			INT UNSIGNED DEFAULT 0
		,	TmpRecoverByCookies		INT UNSIGNED DEFAULT 0
		,	TmpRecoverByFPnCookies	INT UNSIGNED DEFAULT 0
		,	TmpRecoverByEvolution	INT UNSIGNED DEFAULT 0
    ); 
    
    INSERT INTO Temp_Transaction(Id, SubscriberId, TransDate, RecoverType)
    SELECT 	Id
		,	SubscriberId
        ,	DATE(TransTime) AS TransDate
        ,	RecoverType
	FROM FPS_FingerPrint.TransactionCompleted
    WHERE Id > lv_TransId
    LIMIT ip_batchSize;
        
    IF EXISTS(SELECT 1 FROM Temp_Transaction) THEN
		INSERT INTO Temp_SumTransaction(SubscriberId, TransDate, TmpTotal, TmpNullDevice, TmpNewDevice, TmpRecoverByFP, TmpRecoverByCookies, TmpRecoverByFPnCookies, TmpRecoverByEvolution)
		SELECT 	SubscriberId
			,	TransDate
			,	COUNT(Id) AS Total
			,	SUM(IF(RecoverType IS NULL, 1, 0)) AS NullDevice
			,	SUM(IF(RecoverType = 0, 1, 0)) AS NewDevice
			,	SUM(IF(RecoverType = 1, 1, 0)) AS RecoverByFP
			,	SUM(IF(RecoverType = 2, 1, 0)) AS RecoverByCookies
			,	SUM(IF(RecoverType = 3, 1, 0)) AS RecoverByFPnCookies
			,	SUM(IF(RecoverType = 4, 1, 0)) AS RecoverByEvolution
		FROM Temp_Transaction
		GROUP BY SubscriberId, TransDate;
         
        INSERT INTO FPS_FingerPrint.RecoverDailySum(SubscriberId, TransDate, Total, NullDevice, NewDevice, RecoverByFP, RecoverByCookies, RecoverByFPnCookies, RecoverByEvolution, CreatedDate)
        SELECT 	tmp.SubscriberId
			,	tmp.TransDate
            ,	tmp.TmpTotal
            ,	tmp.TmpNullDevice
            ,	tmp.TmpNewDevice
            ,	tmp.TmpRecoverByFP
            ,	tmp.TmpRecoverByCookies
            ,	tmp.TmpRecoverByFPnCookies
            ,	tmp.TmpRecoverByEvolution
            ,	lv_CreatedDate AS CreatedDate
        FROM Temp_SumTransaction AS tmp
			ON DUPLICATE KEY UPDATE ModifiedDate 			= lv_CreatedDate
								,	Total 					= Total + tmp.TmpTotal
								,	NullDevice 				= NullDevice + tmp.TmpNullDevice
								,	NewDevice 				= NewDevice + tmp.TmpNewDevice
								,	RecoverByFP 			= RecoverByFP + tmp.TmpRecoverByFP
								,	RecoverByCookies 		= RecoverByCookies + tmp.TmpRecoverByCookies
								,	RecoverByFPnCookies 	= RecoverByFPnCookies + tmp.TmpRecoverByFPnCookies
								,	RecoverByEvolution 		= RecoverByEvolution + tmp.TmpRecoverByEvolution;
        
		SELECT MAX(tmp.Id) INTO lv_MaxTransId 
			FROM Temp_Transaction AS tmp;
		
		UPDATE FPS_FingerPrint.Offset AS off 
			SET off.OffsetValue = lv_MaxTransId
		WHERE off.OffsetName = lv_OffsetName;
    END IF;
    
END$$
DELIMITER ;