/*<info serverAlias="xxxx" databaseType="2" executers="fpsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `FPS_FP_Transform_DeviceIdentify_Get`;
DELIMITER $$

CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `FPS_FP_Transform_DeviceIdentify_Get`(
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
            
		Param's Explanation (filtered by):	

		Example:
			- CALL FPS_FP_Transform_DeviceIdentify_Get(100,10);
			
	*/
    DECLARE lv_Size INT;
    DECLARE lv_preFingerPrintCode VARCHAR(64);	
    DECLARE lv_preCookieCode VARCHAR(64);	
    DECLARE lv_groupId BIGINT UNSIGNED DEFAULT 0;
	
    SET lv_Size = ip_BatchSize * ip_NoOfBatch;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Transaction;  
    CREATE TEMPORARY TABLE Temp_Transaction(
			Id				BIGINT UNSIGNED PRIMARY KEY		
		,	FingerPrintCode	VARCHAR(64)
        ,	CookieCode		VARCHAR(64)
        ,	Transtime		DATETIME(4)
        ,	GroupId			BIGINT UNSIGNED DEFAULT 0
        
        , 	INDEX IX_Temp_Transaction(FingerPrintCode)
        ,	INDEX IX_Temp_Transaction_CookieCode(CookieCode)
    )ENGINE = MEMORY;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Transaction2;  
    CREATE TEMPORARY TABLE Temp_Transaction2(
			Id				BIGINT UNSIGNED PRIMARY KEY
		,	FingerPrintCode	VARCHAR(64)
        ,	CookieCode		VARCHAR(64)
        ,	GroupFp			BIGINT UNSIGNED DEFAULT 0
        ,	GroupCk			BIGINT UNSIGNED DEFAULT 0
        ,	GroupId			BIGINT UNSIGNED DEFAULT 0
        
        , 	INDEX IX_Temp_Transaction(FingerPrintCode)
        ,	INDEX IX_Temp_Transaction_CookieCode(CookieCode)
        ,	INDEX IX_Temp_Transaction_GroupFp(GroupFp,GroupCk)
    )ENGINE = MEMORY;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_TransGroup;        
	CREATE TEMPORARY TABLE Temp_TransGroup(
			Id 		BIGINT UNSIGNED PRIMARY KEY
        ,	GroupId	BIGINT UNSIGNED           
    );
    
    INSERT INTO Temp_Transaction(Id, FingerPrintCode, CookieCode,TransTime)
    SELECT	Id
		,	FingerPrintCode
        ,	CookieCode
        ,	TransTime
    FROM FPS_FingerPrint.Transaction AS ts
    ORDER BY Id
    LIMIT lv_Size;
	
    INSERT INTO Temp_Transaction2(Id, FingerPrintCode, CookieCode)
    SELECT	Id
		,	FingerPrintCode
        ,	CookieCode
	FROM Temp_Transaction AS tmpTs 
    WHERE tmpTs.FingerPrintCode IS NOT NULL;
    
    UPDATE Temp_Transaction2 AS tmpTs
		INNER JOIN (SELECT tmpTg.FingerPrintCode, Min(tmpTg.Id) AS GroupFp 
					FROM Temp_Transaction tmpTg 
                    GROUP BY tmpTg.FingerPrintCode
                    HAVING COUNT(1) > 1) AS tmp ON tmpTs.FingerPrintCode = tmp.FingerPrintCode
	SET tmpTs.GroupFp = tmp.GroupFp;
    
    UPDATE Temp_Transaction2 AS tmpTs
		INNER JOIN (SELECT tmpTg.CookieCode, Min(tmpTg.Id) AS GroupCk 
					FROM Temp_Transaction tmpTg 
                    GROUP BY tmpTg.CookieCode
                    HAVING COUNT(1) > 1) AS tmp ON tmpTs.CookieCode = tmp.CookieCode
	SET tmpTs.GroupCk = tmp.GroupCk;
    
    DELETE tmpTs
    FROM Temp_Transaction2 AS tmpTs
    WHERE GroupFp = 0 AND GroupCk = 0;    
    
    SELECT tmpTs2.FingerPrintCode, tmpTs2.CookieCode, tmpTs2.Id
	INTO lv_preFingerPrintCode, lv_preCookieCode, lv_groupId        
	FROM Temp_Transaction2 AS tmpTs2
	WHERE tmpTs2.GroupId = 0
	ORDER BY Id LIMIT 1;
    
    WHILE lv_groupId > 0 DO
    
		TRUNCATE TABLE Temp_TransGroup;
        
		INSERT INTO Temp_TransGroup(Id, GroupId)
		WITH RECURSIVE CTE_Group AS ( 
			SELECT lv_groupId AS Id, lv_preFingerPrintCode AS FingerPrintCode, lv_preCookieCode AS CookieCode
			UNION
			SELECT tmpCa.Id, tmpCa.FingerPrintCode, tmpCa.CookieCode
			FROM Temp_Transaction2  AS tmpCa
			  JOIN CTE_Group ON CTE_Group.FingerPrintCode = tmpCa.FingerPrintCode OR  CTE_Group.CookieCode = tmpCa.CookieCode
		) 
		SELECT	CTE_Group.Id, lv_groupId 
		FROM CTE_Group;	
        
        UPDATE Temp_Transaction2 AS tmpTs
			INNER JOIN Temp_TransGroup AS tmpTg ON tmpTs.Id = tmpTg.Id
		SET tmpTs.GroupId = tmpTg.GroupId;
        
        SET  lv_groupId   = 0;
        
		SELECT tmpTs2.FingerPrintCode, tmpTs2.CookieCode, tmpTs2.Id
		INTO lv_preFingerPrintCode, lv_preCookieCode, lv_groupId        
		FROM Temp_Transaction2 AS tmpTs2
        WHERE GroupId = 0
        ORDER BY Id LIMIT 1;        
        
    END WHILE;
	
    UPDATE Temp_Transaction AS tmpTs
		INNER JOIN Temp_Transaction2 AS tmpTs2 ON tmpTs.Id = tmpTs2.Id
    SET tmpTs.GroupId = tmpTs2.GroupId;
    
    #====RETURN 1: FingerPrintCode IS NOT NULL===========================
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
    
    #====RETURN 1: Group By (FingerPrintCode OR CookieCode)*/
    SELECT	tmpTs.Id
		,	tmpTs.Transtime
		,	tmpTs.FingerPrintCode
        ,	tmpTs.CookieCode
		,	tmpTs.GroupId
        ,	(CASE WHEN @rowNo >= @packSize AND GroupId !=  @preGroupId THEN @BatchNo := @BatchNo + 1 ELSE @BatchNo END) AS BatchNumber
        ,	(CASE WHEN @rowNo >= @packSize AND GroupId !=  @preGroupId THEN @rowNo:= 1 ELSE @rowNo:= @rowNo + 1 END) AS RowNo
        ,	(CASE WHEN tmpTs.GroupId !=  @preGroupId THEN @preGroupId:= tmpTs.GroupId ELSE @preGroupId  END) AS PreGroup
	FROM Temp_Transaction AS tmpTs
    WHERE tmpTs.FingerPrintCode IS NOT NULL AND tmpTs.GroupId > 0
    ORDER BY tmpTs.GroupId ASC;
    
    #====RETURN 2: Trans: NOT Group By (FingerPrintCode OR CookieCode)*/
    SET @rowNo = 0;
    SET @BatchNo = @BatchNo + 1;  
    SELECT	tmpTs.Id
		,	tmpTs.Transtime
		,	tmpTs.FingerPrintCode
        ,	tmpTs.CookieCode
		,	tmpTs.GroupId
        ,	(CASE WHEN @rowNo >= @packSize THEN @BatchNo := @BatchNo +1 ELSE @BatchNo END) AS BatchNumber
        ,	(CASE WHEN @rowNo >= @packSize THEN @rowNo:= 1 ELSE @rowNo:= @rowNo + 1 END) AS RowNo
	FROM Temp_Transaction AS tmpTs
    WHERE tmpTs.FingerPrintCode IS NOT NULL AND tmpTs.GroupId = 0
    ORDER BY tmpTs.GroupId ASC;    
    
	#====RETURN 3: FingerPrintCode IS NULL===========================
    SELECT	tmpTs.Id
	FROM Temp_Transaction AS tmpTs
    WHERE tmpTs.FingerPrintCode IS NULL;   

      
END$$
DELIMITER ;
