/*<info serverAlias="FPSDC-FPS_FingerPrint" databaseType="2" executers="fpsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `FPS_FP_Transform_DeviceIdentify_Get`;
DELIMITER $$

CREATE DEFINER=`fpsOwner`@`%` PROCEDURE `FPS_FP_Transform_DeviceIdentify_Get`(
		ip_BatchSize 	INT
	,	ip_NoOfBatch	INT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20220228@Casey.Huynh
		Task :		
		DB:			FPS_FingerPrint
		Original:

		Revisions:
			- 20220307@Terry.Nguyen: Created [Redmine ID: #162668]
            
		Param's Explanation (filtered by):	

		Example:
			- CALL FPS_FP_Transform_DeviceIdentify_Get(100,10);
			
	*/
    DECLARE lv_Size INT;
    DECLARE lv_preRawFingerPrintId BIGINT UNSIGNED;
    DECLARE lv_preCookieId BIGINT UNSIGNED;
    DECLARE lv_groupId BIGINT UNSIGNED DEFAULT 0;
	
    /*******LOG TEST********************/
    IF (SELECT ofs.OffsetValue FROM FPS_FingerPrint.Offset AS ofs WHERE Id = 7) = 1 THEN		
		INSERT INTO CTS_Log.FPSLog(SpName, JsonString, OtherText, InsertTime)
		SELECT 'FPS_FP_Transform_DeviceIdentify_Get', NULL,CONCAT('ip_BatchSize:',ip_BatchSize,'ip_NoOfBatch:',ip_NoOfBatch), CURRENT_TIMESTAMP();
    END IF;
    /*******LOG TEST********************/
    
    SET lv_Size = ip_BatchSize * ip_NoOfBatch;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Transaction;  
    CREATE TEMPORARY TABLE Temp_Transaction(
			Id					BIGINT UNSIGNED PRIMARY KEY		
		,	RawFingerPrintId	BIGINT UNSIGNED
        ,	CookieId			BIGINT UNSIGNED
        ,	TransTime			DATETIME(4)
        ,	SubscriberId		BIGINT UNSIGNED
        ,	LoginName			VARCHAR(100)
        ,	UserAgentId			BIGINT UNSIGNED
        ,	GroupId				BIGINT UNSIGNED DEFAULT 0
        
        , 	INDEX IX_Temp_Transaction_RawFingerPrintId(RawFingerPrintId)
        ,	INDEX IX_Temp_Transaction_CookieId(CookieId)
    );
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Transaction2;  
    CREATE TEMPORARY TABLE Temp_Transaction2(
			Id					BIGINT UNSIGNED PRIMARY KEY
		,	RawFingerPrintId	BIGINT UNSIGNED
        ,	CookieId			BIGINT UNSIGNED
        ,	GroupFp				BIGINT UNSIGNED DEFAULT 0
        ,	GroupCk				BIGINT UNSIGNED DEFAULT 0
        ,	GroupId				BIGINT UNSIGNED DEFAULT 0
        
        , 	INDEX IX_Temp_Transaction_RawFingerPrintId(RawFingerPrintId)
        ,	INDEX IX_Temp_Transaction_CookieId(CookieId)
        ,	INDEX IX_Temp_Transaction_GroupFp(GroupFp,GroupCk)
    );
    
    DROP TEMPORARY TABLE IF EXISTS Temp_TransGroup;        
	CREATE TEMPORARY TABLE Temp_TransGroup(
			Id 		BIGINT UNSIGNED PRIMARY KEY
        ,	GroupId	BIGINT UNSIGNED           
    );
    
    INSERT INTO Temp_Transaction(Id, RawFingerPrintId, CookieId, TransTime, SubscriberId, LoginName, UserAgentId)
    SELECT	Id
		,	RawFingerPrintId
        ,	CookieId
        ,	TransTime
        ,	SubscriberId
        ,	LoginName
        ,	UserAgentId
    FROM FPS_FingerPrint.Transaction AS ts
    ORDER BY Id
    LIMIT lv_Size;
	
    INSERT INTO Temp_Transaction2(Id, RawFingerPrintId, CookieId)
    SELECT	Id
		,	RawFingerPrintId
        ,	CookieId
	FROM Temp_Transaction AS tmpTs 
    WHERE tmpTs.RawFingerPrintId IS NOT NULL;
    
    UPDATE Temp_Transaction2 AS tmpTs
		INNER JOIN (SELECT tmpTg.RawFingerPrintId, Min(tmpTg.Id) AS GroupFp 
					FROM Temp_Transaction tmpTg 
                    GROUP BY tmpTg.RawFingerPrintId
                    HAVING COUNT(1) > 1) AS tmp ON tmpTs.RawFingerPrintId = tmp.RawFingerPrintId
	SET tmpTs.GroupFp = tmp.GroupFp;
    
    UPDATE Temp_Transaction2 AS tmpTs
		INNER JOIN (SELECT tmpTg.CookieId, Min(tmpTg.Id) AS GroupCk 
					FROM Temp_Transaction tmpTg 
                    GROUP BY tmpTg.CookieId
                    HAVING COUNT(1) > 1) AS tmp ON tmpTs.CookieId = tmp.CookieId
	SET tmpTs.GroupCk = tmp.GroupCk;
  
    DELETE tmpTs
    FROM Temp_Transaction2 AS tmpTs
    WHERE GroupFp = 0 AND GroupCk = 0;    
    
    SELECT tmpTs2.RawFingerPrintId, tmpTs2.CookieId, tmpTs2.Id
	INTO lv_preRawFingerPrintId, lv_preCookieId, lv_groupId        
	FROM Temp_Transaction2 AS tmpTs2
	WHERE tmpTs2.GroupId = 0
	ORDER BY Id LIMIT 1;
    
    WHILE lv_groupId > 0 DO
    
		TRUNCATE TABLE Temp_TransGroup;
        
		INSERT INTO Temp_TransGroup(Id, GroupId)
		WITH RECURSIVE CTE_Group AS ( 
			SELECT lv_groupId AS Id, lv_preRawFingerPrintId AS RawFingerPrintId, lv_preCookieId AS CookieId
			UNION
			SELECT tmpCa.Id, tmpCa.RawFingerPrintId, tmpCa.CookieId
			FROM Temp_Transaction2  AS tmpCa
			  JOIN CTE_Group ON CTE_Group.RawFingerPrintId = tmpCa.RawFingerPrintId OR  CTE_Group.CookieId = tmpCa.CookieId
		) 
		SELECT	CTE_Group.Id, lv_groupId 
		FROM CTE_Group;	
        
        UPDATE Temp_Transaction2 AS tmpTs
			INNER JOIN Temp_TransGroup AS tmpTg ON tmpTs.Id = tmpTg.Id
		SET tmpTs.GroupId = tmpTg.GroupId;
        
        SET  lv_groupId   = 0;
        
		SELECT tmpTs2.RawFingerPrintId, tmpTs2.CookieId, tmpTs2.Id
		INTO lv_preRawFingerPrintId, lv_preCookieId, lv_groupId        
		FROM Temp_Transaction2 AS tmpTs2
        WHERE GroupId = 0
        ORDER BY Id LIMIT 1;        
        
    END WHILE;
	
    UPDATE Temp_Transaction AS tmpTs
		INNER JOIN Temp_Transaction2 AS tmpTs2 ON tmpTs.Id = tmpTs2.Id
    SET tmpTs.GroupId = tmpTs2.GroupId;
    
    #====1. RawFingerPrintId IS NOT NULL===========================
    SET @rowNo = 0; 
    SET @BatchNo = 1; 
    SET @GroupId = (SELECT tmpTs.GroupID FROM Temp_Transaction AS tmpTs WHERE tmpTs.GroupId > 0 ORDER BY tmpTs.GroupId ASC LIMIT 1) ;
    SET @packSize = ip_BatchSize;
    
    SELECT tmpTs.Id, tmpTs.GroupID 
    INTO @preId, @preGroupId 
    FROM Temp_Transaction AS tmpTs 
    WHERE tmpTs.GroupId > 0 
    ORDER BY tmpTs.GroupId ASC 
    LIMIT 1;
    
    #====RETURN 1.1: Group By (RawFingerPrintId OR CookieId)*/ ---> CALL FPS_FP_Transform_DeviceIdentify WITH ip_GroupType = 1
    SELECT	tmpTs.Id
		,	tmpTs.TransTime
		,	tmpTs.RawFingerPrintId
        ,	tmpTs.CookieId
        ,	tmpTs.SubscriberId
        ,	tmpTs.LoginName
        ,	tmpTs.UserAgentId
		,	tmpTs.GroupId
        ,	(CASE WHEN @rowNo >= @packSize AND GroupId !=  @preGroupId THEN @BatchNo := @BatchNo + 1 ELSE @BatchNo END) AS BatchNumber
        ,	(CASE WHEN @rowNo >= @packSize AND GroupId !=  @preGroupId THEN @rowNo:= 1 ELSE @rowNo:= @rowNo + 1 END) AS RowNo
        ,	(CASE WHEN tmpTs.GroupId !=  @preGroupId THEN @preGroupId:= tmpTs.GroupId ELSE @preGroupId  END) AS PreGroup
	FROM Temp_Transaction AS tmpTs
    WHERE tmpTs.RawFingerPrintId IS NOT NULL AND tmpTs.GroupId > 0
    ORDER BY tmpTs.GroupId ASC;
    
    #====RETURN 1.2: Trans: NOT Group By (RawFingerPrintId OR CookieId)*/ --> CALL FPS_FP_Transform_DeviceIdentify WITH ip_GroupType = 0
    SET @rowNo = 0;
    SET @BatchNo = @BatchNo + 1;  
    SELECT	tmpTs.Id
		,	tmpTs.TransTime
		,	tmpTs.RawFingerPrintId
        ,	tmpTs.CookieId
        ,	tmpTs.SubscriberId
        ,	tmpTs.LoginName
        ,	tmpTs.UserAgentId
		,	tmpTs.GroupId
        ,	(CASE WHEN @rowNo >= @packSize THEN @BatchNo := @BatchNo +1 ELSE @BatchNo END) AS BatchNumber
        ,	(CASE WHEN @rowNo >= @packSize THEN @rowNo:= 1 ELSE @rowNo:= @rowNo + 1 END) AS RowNo
	FROM Temp_Transaction AS tmpTs
    WHERE tmpTs.RawFingerPrintId IS NOT NULL AND tmpTs.GroupId = 0
    ORDER BY tmpTs.GroupId ASC;    
    
	#====RETUNR 2. RawFingerPrintId IS NULL===========================
    SELECT	tmpTs.Id
	FROM Temp_Transaction AS tmpTs
    WHERE tmpTs.RawFingerPrintId IS NULL;   
      
END$$
DELIMITER ;
