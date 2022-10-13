/*<info serverAlias="FPSDC-FPS_FingerPrint" databaseType="2" executers="fpsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `FPS_FP_Transform_CookieSessionKey_Insert`;
DELIMITER $$

CREATE DEFINER=`fpsOwner`@`%` PROCEDURE `FPS_FP_Transform_CookieSessionKey_Insert`(
		ip_TransJson LONGTEXT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20221012@Jonathan.Doan
		Task :		
		DB:			FPS_FingerPrint
		Original:

		Revisions:
			- 20221012@Jonathan.Doan: Created [Redmine ID: #176820]			
            
		Param's Explanation (filtered by):	

		Example:
			- CALL FPS_FP_Transform_CookieSessionKey_Insert('[{"SessionKey":"ddddd","Cookie":"12321"}]');
			
	*/
    
    DECLARE lv_CurrentDate DATETIME DEFAULT NOW();
    
    /*******LOG TEST********************/
    IF (SELECT ofs.OffsetValue FROM FPS_FingerPrint.Offset AS ofs WHERE Id = 7) = 1 THEN		
		INSERT INTO CTS_Log.FPSLog(SpName, JsonString, OtherText, InsertTime)
		SELECT 'FPS_FP_Transform_CookieSessionKey_Insert', ip_TransJson , NULL, CURRENT_TIMESTAMP();
	END IF;
    /*******LOG TEST********************/
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Table;
    DROP TEMPORARY TABLE IF EXISTS Temp_Cookie;
    
	CREATE TEMPORARY TABLE Temp_Table(	
			SessionKey					VARCHAR(100) 		NULL
		,	CookieId					BIGINT UNSIGNED		NULL
		,	CookieCode					VARCHAR(64)			NULL
        , 	INDEX IX_Temp_Table_SessionKey(SessionKey)
    );
    
	CREATE TEMPORARY TABLE Temp_Cookie(
			CookieId					BIGINT UNSIGNED 	NOT NULL	
		,	CookieCode					VARCHAR(64) 		NOT NULL
        ,	PRIMARY KEY (CookieId)	
        , 	INDEX IX_Temp_Cookie_CookieCode(CookieCode)
    );
    
    INSERT INTO Temp_Table(SessionKey, CookieCode)
	SELECT	tmp.SessionKey
		,	tmp.CookieCode
	FROM	JSON_TABLE(
			ip_TransJson,
			 "$[*]" COLUMNS(
						SessionKey				VARCHAR(100) 	PATH "$.SessionKey"
					,	CookieCode				VARCHAR(64) 	PATH "$.CookieCode"
				)
		   ) AS tmp;
   
    
    INSERT IGNORE INTO FPS_FingerPrint.Cookie(CookieCode, CreatedDate, ModifiedDate)
	SELECT	tmp.CookieCode
        ,	lv_CurrentDate AS CreatedDate
        ,	lv_CurrentDate AS ModifiedDate
	FROM Temp_Table AS tmp
    WHERE NOT EXISTS (SELECT 1 FROM FPS_FingerPrint.Cookie c WHERE c.CookieCode = tmp.CookieCode);
    
    INSERT INTO Temp_Cookie(CookieId, CookieCode)
    SELECT DISTINCT c.Id AS CookieId
				, 	tmp.CookieCode
    FROM Temp_Table AS tmp
		INNER JOIN FPS_FingerPrint.Cookie AS c ON c.CookieCode = tmp.CookieCode;
        
    UPDATE Temp_Table AS tmp
		INNER JOIN Temp_Cookie AS c ON c.CookieCode = tmp.CookieCode
    SET tmp.CookieId = c.CookieId;
    
    /*******ClientTransaction********************/
    INSERT IGNORE INTO FPS_FingerPrint.CookieSessionKey(SessionKey, CookieId, CreatedDate)
	SELECT	tmp.SessionKey
		,	tmp.CookieId
		,	lv_CurrentDate AS CreatedDate
	FROM Temp_Table AS tmp;
    
END$$
DELIMITER ;