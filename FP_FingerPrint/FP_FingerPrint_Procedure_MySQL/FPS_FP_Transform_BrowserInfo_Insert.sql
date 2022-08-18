/*<info serverAlias="FPSDC-FPS_FingerPrint" databaseType="2" executers="fpsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `FPS_FP_Transform_BrowserInfo_Insert`;
DELIMITER $$

CREATE DEFINER=`fpsOwner`@`%` PROCEDURE `FPS_FP_Transform_BrowserInfo_Insert`(
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
			- 20220525@Jonathan.Doan: Created [Redmine ID: #172167]
			- 20220811@Jonathan.Doan: tuning performance [Redmine ID: #172167]
            
		Param's Explanation (filtered by):	

		Example:
			- CALL FPS_FP_Transform_BrowserInfo_Insert('[{"SessionKey":"123", "BrowserInfo":"{}", "HeadlessScore":"{}"}]');
			
	*/
    
    DECLARE lv_CurrentDate DATETIME DEFAULT NOW();
    DECLARE lv_BrowserInfoAttributeCode VARCHAR(64);
    DECLARE lv_BrowserInfo LONGTEXT;
    DECLARE lv_BrowserInfoAttribute LONGTEXT;
    DECLARE lv_BrowserInfoJs LONGTEXT;
    
    /*******LOG TEST********************/
    IF (SELECT ofs.OffsetValue FROM FPS_FingerPrint.Offset AS ofs WHERE Id = 7) = 1 THEN		
		INSERT INTO CTS_Log.FPSLog(SpName, JsonString, OtherText, InsertTime)
		SELECT 'FPS_FP_Transform_BrowserInfo_Insert', ip_BrowserInfo , NULL, CURRENT_TIMESTAMP();
	END IF;
    /*******LOG TEST********************/
    
    DROP TEMPORARY TABLE IF EXISTS Temp_MainTable;
    DROP TEMPORARY TABLE IF EXISTS Temp_BrowserInfo;
    
	CREATE TEMPORARY TABLE Temp_MainTable(	
			SessionKey					VARCHAR(100) 		NOT NULL
		,	BrowserInfo					LONGTEXT			NULL
		,	BrowserInfoAttributeId		BIGINT UNSIGNED		NULL
		,	BrowserInfoAttribute		LONGTEXT			NULL
		,	BrowserInfoAttributeCode	VARCHAR(64)			NULL
		,	HeadlessScore				VARCHAR(300)		NULL
        ,	PRIMARY KEY (SessionKey)
    );
    
	CREATE TEMPORARY TABLE Temp_BrowserInfo(	
			BrowserInfoAttributeCode	VARCHAR(64) 		NOT NULL
		,	OSName						VARCHAR(50)	 		NULL
		,	BrowserName					VARCHAR(100)		NULL
		,	SecChUa						VARCHAR(100)	 	NULL
		,	SecChUaPlatform				VARCHAR(100)		NULL
		,	SecChUaMobile				VARCHAR(50) 		NULL
		,	JsBrowserName				VARCHAR(100)		NULL
		,	JsOSName					VARCHAR(50)			NULL
        ,	PRIMARY KEY (BrowserInfoAttributeCode)
    );
    
    INSERT IGNORE INTO Temp_MainTable(SessionKey, BrowserInfo, BrowserInfoAttribute, BrowserInfoAttributeCode, HeadlessScore)
    SELECT 	tmp.SessionKey
		,	tmp.BrowserInfo
		,	tmp.BrowserInfoAttribute
		,	tmp.BrowserInfoAttributeCode
		,	tmp.HeadlessScore
	FROM	JSON_TABLE(
			ip_BrowserInfo,
			 "$[*]" COLUMNS(
							SessionKey					VARCHAR(100) 	PATH "$.SessionKey"
						,	BrowserInfo					LONGTEXT		PATH "$.BrowserInfo"
						,	BrowserInfoAttribute		LONGTEXT		PATH "$.BrowserInfoAttribute"
						,	BrowserInfoAttributeCode	VARCHAR(64)		PATH "$.BrowserInfoAttributeCode"
						,	HeadlessScore				VARCHAR(300) 	PATH "$.HeadlessScore"
				)
		   ) AS tmp;
    
    INSERT IGNORE INTO Temp_BrowserInfo(BrowserInfoAttributeCode, OSName, BrowserName, SecChUa, SecChUaPlatform, SecChUaMobile, JsBrowserName, JsOSName)
    SELECT 	tmp.BrowserInfoAttributeCode
		,	tmp.BrowserInfo->>'$.OSName'
		,	tmp.BrowserInfo->>'$.BrowserName'
		,	tmp.BrowserInfoAttribute->>'$.SecChUa'
		,	tmp.BrowserInfoAttribute->>'$.SecChUaPlatform'
		,	tmp.BrowserInfoAttribute->>'$.SecChUaMobile'
		,	tmp.BrowserInfoAttribute->>'$.JsBrowserName'
		,	tmp.BrowserInfoAttribute->>'$.JsOSName'
    FROM Temp_MainTable AS tmp;
    
    /*******BrowserInfo********************/
    INSERT IGNORE INTO FPS_FingerPrint.BrowserInfoAttribute(BrowserInfoAttributeCode, SecChUa, SecChUaPlatform, SecChUaMobile, JsBrowserName, JsOSName)
    SELECT 	tmp.BrowserInfoAttributeCode
		,	tmp.SecChUa
		,	tmp.SecChUaPlatform
		,	tmp.SecChUaMobile
		,	tmp.JsBrowserName
		,	tmp.JsOSName
    FROM Temp_BrowserInfo tmp
    WHERE NOT EXISTS (SELECT 1 FROM FPS_FingerPrint.BrowserInfoAttribute bia WHERE bia.BrowserInfoAttributeCode = tmp.BrowserInfoAttributeCode);
        
    UPDATE Temp_MainTable tmp
		INNER JOIN FPS_FingerPrint.BrowserInfoAttribute bia ON bia.BrowserInfoAttributeCode = tmp.BrowserInfoAttributeCode
    SET tmp.BrowserInfoAttributeId = bia.Id;
	
    INSERT IGNORE INTO FPS_FingerPrint.BrowserInfo(SessionKey, BrowserInfoAttributeId, HeadlessScore, BrowserName, OSName, CreatedDate, ModifiedDate)
    SELECT 	tmp.SessionKey
		, 	tmp.BrowserInfoAttributeId
		, 	tmp.HeadlessScore
		, 	tmpBI.BrowserName
        , 	tmpBI.OSName
        ,	lv_CurrentDate AS CreatedDate
        ,	lv_CurrentDate AS ModifiedDate
    FROM Temp_MainTable AS tmp
		INNER JOIN Temp_BrowserInfo AS tmpBI ON tmpBI.BrowserInfoAttributeCode = tmp.BrowserInfoAttributeCode;
	
END$$
DELIMITER ;
