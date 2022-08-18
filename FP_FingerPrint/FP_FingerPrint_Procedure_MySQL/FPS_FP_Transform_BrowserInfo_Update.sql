/*<info serverAlias="FPSDC-FPS_FingerPrint" databaseType="2" executers="fpsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `FPS_FP_Transform_BrowserInfo_Update`;
DELIMITER $$

CREATE DEFINER=`fpsOwner`@`%` PROCEDURE `FPS_FP_Transform_BrowserInfo_Update`(
		ip_BrowserInfo LONGTEXT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20220525@Jonathan.Doan
		Task :		
		DB:			FPS_FingerPrint
		Original:

		Revisions:
			- 20220602@Jonathan.Doan: Created [Redmine ID: #172167]
            
		Param's Explanation (filtered by):	

		Example:
			- CALL FPS_FP_Transform_BrowserInfo_Update('[{"Id": 3, "Flagged": 1}]');
			
	*/
    
    DECLARE lv_CurrentDate DATETIME DEFAULT NOW();
    
    /*******LOG TEST********************/
    IF (SELECT ofs.OffsetValue FROM FPS_FingerPrint.Offset AS ofs WHERE Id = 7) = 1 THEN		
		INSERT INTO CTS_Log.FPSLog(SpName, JsonString, OtherText, InsertTime)
		SELECT 'FPS_FP_Transform_BrowserInfo_Update', ip_BrowserInfo , NULL, CURRENT_TIMESTAMP();
	END IF;
    /*******LOG TEST********************/
    
    DROP TEMPORARY TABLE IF EXISTS Temp_BrowserInfo;
    
	CREATE TEMPORARY TABLE Temp_BrowserInfo(
			Id 				BIGINT UNSIGNED PRIMARY KEY
		,	Flagged 		SMALLINT 		NULL
    );   
    
    
    INSERT IGNORE INTO Temp_BrowserInfo(Id, Flagged)
    SELECT 	tmp.Id
		,	tmp.Flagged
	FROM	JSON_TABLE(
			ip_BrowserInfo,
			 "$[*]" COLUMNS(
							Id			BIGINT UNSIGNED		PATH "$.Id"   
						,	Flagged		SMALLINT			PATH "$.Flagged"
				)
		   ) AS tmp; 
        
	INSERT INTO FPS_FingerPrint.BrowserInfoCompleted(Id, SessionKey, UserAgentId, BrowserInfoAttributeId, HeadlessScore, BrowserName, OSName, Flagged, CreatedDate)
    SELECT 	bi.Id
		, 	bi.SessionKey
        , 	bi.UserAgentId
        , 	bi.BrowserInfoAttributeId
        , 	bi.HeadlessScore
        , 	bi.BrowserName
        , 	bi.OSName
        , 	tmp.Flagged
        , 	bi.CreatedDate
    FROM FPS_FingerPrint.BrowserInfo AS bi
		INNER JOIN Temp_BrowserInfo AS tmp ON tmp.Id = bi.Id;
        
	DELETE bi FROM FPS_FingerPrint.BrowserInfo AS bi
		INNER JOIN Temp_BrowserInfo AS tmp ON tmp.Id = bi.Id;
    
END$$
DELIMITER ;
