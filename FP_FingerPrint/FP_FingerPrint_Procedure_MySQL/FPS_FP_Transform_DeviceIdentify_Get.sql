/*<info serverAlias="xxxx" databaseType="2" executers="fpsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `FPS_FP_Transform_DeviceIdentify_Get`;
DELIMITER $$

CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `FPS_FP_Transform_DeviceIdentify_Get`(
		ip_BatchSize 	INT
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
			- CALL FPS_FP_Transform_DeviceIdentify_Get(1000);
			
	*/
    
    DECLARE lv_preFingerPrintCode VARCHAR(64);	
    DECLARE lv_preCookieId BIGINT;	
    DECLARE lv_groupId INT DEFAULT 0;	
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Transaction;  
    CREATE TEMPORARY TABLE Temp_Transaction(
			Id				BIGINT UNSIGNED PRIMARY KEY		
		,	FingerPrintCode	VARCHAR(64)
        ,	CookieId		BIGINT UNSIGNED
        ,	Transtime		DATETIME(4)
        ,	GroupId			BIGINT UNSIGNED DEFAULT 0
        
        , 	INDEX IX_Temp_Transaction(FingerPrintCode)
        ,	INDEX IX_Temp_Transaction_CookieId(CookieId)
    )ENGINE = MEMORY;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Transaction2;  
    CREATE TEMPORARY TABLE Temp_Transaction2(
			Id				BIGINT UNSIGNED PRIMARY KEY
		,	FingerPrintCode	VARCHAR(64)
        ,	CookieId		BIGINT UNSIGNED
        ,	GroupFp			BIGINT UNSIGNED DEFAULT 0
        ,	GroupCk			BIGINT UNSIGNED DEFAULT 0
        ,	GroupId			BIGINT UNSIGNED DEFAULT 0
        
        , 	INDEX IX_Temp_Transaction(FingerPrintCode)
        ,	INDEX IX_Temp_Transaction_CookieId(CookieId)
        ,	INDEX IX_Temp_Transaction_GroupFp(GroupFp,GroupCk)
    )ENGINE = MEMORY;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_TransGroup;        
	CREATE TEMPORARY TABLE Temp_TransGroup(
			Id 		BIGINT UNSIGNED PRIMARY KEY
        ,	GroupId	INT        
    );
    
    INSERT INTO Temp_Transaction(Id, FingerPrintCode, CookieId,TransTime)
    SELECT	Id
		,	FingerPrintCode
        ,	CookieId
        ,	TransTime
	FROM FPS_FingerPrint.Transaction AS ts
    ORDER BY Id
    LIMIT ip_BatchSize;

    INSERT INTO Temp_Transaction2(Id, FingerPrintCode, CookieId)
    SELECT	Id
		,	FingerPrintCode
        ,	CookieId
	FROM Temp_Transaction AS tmpTs 
    WHERE tmpTs.FingerPrintCode IS NOT NULL;
    
    UPDATE Temp_Transaction2 AS tmpTs
		INNER JOIN (SELECT tmpTg.FingerPrintCode, Min(tmpTg.Id) AS GroupFp 
					FROM Temp_Transaction tmpTg 
                    GROUP BY tmpTg.FingerPrintCode
                    HAVING Count(1) > 1) AS tmp ON tmpTs.FingerPrintCode = tmp.FingerPrintCode
	SET tmpTs.GroupFp = tmp.GroupFp;
    
    UPDATE Temp_Transaction2 AS tmpTs
		INNER JOIN (SELECT tmpTg.CookieId, Min(tmpTg.Id) AS GroupCk 
					FROM Temp_Transaction tmpTg 
                    GROUP BY tmpTg.CookieId
                    HAVING Count(1) > 1) AS tmp ON tmpTs.CookieId = tmp.CookieId
	SET tmpTs.GroupCk = tmp.GroupCk;
    
    DELETE tmpTs
    FROM Temp_Transaction2 AS tmpTs
    WHERE GroupFp = 0 AND GroupCk = 0;    
    
    SELECT tmpTs2.FingerPrintCode, tmpTs2.CookieId, tmpTs2.Id
	INTO lv_preFingerPrintCode, lv_preCookieId, lv_groupId        
	FROM Temp_Transaction2 AS tmpTs2
	WHERE tmpTs2.GroupId = 0
	ORDER BY Id LIMIT 1;
    
    WHILE lv_groupId > 0 DO
    
		TRUNCATE TABLE Temp_TransGroup;
        
		INSERT INTO Temp_TransGroup(Id, GroupId)
		WITH RECURSIVE CTE_Group AS ( 
			SELECT lv_groupId AS Id, lv_preFingerPrintCode AS FingerPrintCode, lv_preCookieId AS CookieId
			UNION
			SELECT tmpCa.Id, tmpCa.FingerPrintCode, tmpCa.CookieId
			FROM Temp_Transaction2  AS tmpCa
			  JOIN CTE_Group ON CTE_Group.FingerPrintCode = tmpCa.FingerPrintCode OR  CTE_Group.CookieId = tmpCa.CookieId
		) 
		SELECT	CTE_Group.Id, lv_groupId 
		FROM CTE_Group;	
        
        UPDATE Temp_Transaction2 AS tmpTs
			INNER JOIN Temp_TransGroup AS tmpTg ON tmpTs.Id = tmpTg.Id
		SET tmpTs.GroupId = tmpTg.GroupId;
        
        SET  lv_groupId   = 0;
        
		SELECT tmpTs2.FingerPrintCode, tmpTs2.CookieId, tmpTs2.Id
		INTO lv_preFingerPrintCode, lv_preCookieId, lv_groupId        
		FROM Temp_Transaction2 AS tmpTs2
        WHERE GroupId = 0
        ORDER BY Id LIMIT 1;        
        
    END WHILE;
	
    UPDATE Temp_Transaction AS tmpTs
		INNER JOIN Temp_Transaction2 AS tmpTs2 ON tmpTs.Id = tmpTs2.Id
    SET tmpTs.GroupId = tmpTs2.GroupId;
    
    #====RETURN 1: FingerPrintCode IS NOT NULL===========================
    SELECT	tmpTs.Id
		,	tmpTs.Transtime
		,	tmpTs.FingerPrintCode
        ,	tmpTs.CookieId
		,	tmpTs.GroupId
	FROM Temp_Transaction AS tmpTs
    WHERE tmpTs.FingerPrintCode IS NOT NULL
    ORDER BY GroupId ASC;    
    
	#====RETURN 2: FingerPrintCode IS NULL===========================
    SELECT	tmpTs.Id
	FROM Temp_Transaction AS tmpTs
    WHERE tmpTs.FingerPrintCode IS NULL;    
    
      
END$$
DELIMITER ;
