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
            
		Param's Explanation (filtered by):	

		Example:
			- CALL FPS_FP_Transform_BrowserInfo_Insert('[{"UserAgent":"Mozilla/5.0", "SessionKey":"123", "BrowserInfo":"{}", "HeadlessScore":"{}"}]');
			
	*/
    
    DECLARE lv_CurrentDate DATETIME DEFAULT NOW();
    
    /*******LOG TEST********************/
    IF (SELECT ofs.OffsetValue FROM FPS_FingerPrint.Offset AS ofs WHERE Id = 7) = 1 THEN		
		INSERT INTO CTS_Log.FPSLog(SpName, JsonString, OtherText, InsertTime)
		SELECT 'FPS_FP_Transform_BrowserInfo_Insert', ip_BrowserInfo , NULL, CURRENT_TIMESTAMP();
	END IF;
    /*******LOG TEST********************/
    
    DROP TEMPORARY TABLE IF EXISTS Temp_BrowserInfo;
    DROP TEMPORARY TABLE IF EXISTS Temp_RawUserAgent;
    
	CREATE TEMPORARY TABLE Temp_BrowserInfo(	
			SessionKey					VARCHAR(100) 		NOT NULL
		,	UserAgentId					BIGINT	 			NULL
		,	UserAgentCode				VARCHAR(100)		NULL
		,	UserAgent					LONGTEXT 			NULL
		,	BrowserInfo					LONGTEXT			NULL
		,	browserInfoAttribute		LONGTEXT			NULL
		,	browserInfoAttributeCode	VARCHAR(64)			NULL
		,	HeadlessScore				VARCHAR(300)		NULL
        ,	PRIMARY KEY (SessionKey)
    );      
    
	CREATE TEMPORARY TABLE Temp_RawUserAgent(
			SessionKey 					VARCHAR(100) 			NOT NULL 
		,	UserAgentId					BIGINT UNSIGNED			NOT NULL
        ,	PRIMARY KEY (SessionKey)
    );  
    
    INSERT IGNORE INTO Temp_BrowserInfo(SessionKey, UserAgent, UserAgentCode, BrowserInfo, browserInfoAttribute, browserInfoAttributeCode, HeadlessScore)
    SELECT 	tmp.SessionKey
		,	tmp.UserAgent
		,	tmp.UserAgentCode
		,	tmp.BrowserInfo
		,	tmp.browserInfoAttribute
		,	tmp.browserInfoAttributeCode
		,	tmp.HeadlessScore
	FROM	JSON_TABLE(
			ip_BrowserInfo,
			 "$[*]" COLUMNS(
								SessionKey					VARCHAR(100) 	PATH "$.SessionKey"   
							,	UserAgent					LONGTEXT		PATH "$.UserAgent"
							,	UserAgentCode				VARCHAR(100) 	PATH "$.UserAgentCode"
							,	BrowserInfo					LONGTEXT		PATH "$.BrowserInfo"
							,	browserInfoAttribute		LONGTEXT		PATH "$.browserInfoAttribute"
							,	browserInfoAttributeCode	VARCHAR(64)		PATH "$.browserInfoAttributeCode"
							,	HeadlessScore				VARCHAR(300) 	PATH "$.HeadlessScore"
				)
		   ) AS tmp; 
    
    
     
	/*******RawUserAgent********************/
    INSERT IGNORE INTO FPS_FingerPrint.RawUserAgent (UserAgentCode, UserAgent, CreatedDate, ModifiedDate)	
	SELECT	tmp.UserAgentCode
		,	tmp.UserAgent
        ,	lv_CurrentDate AS CreatedDate
        ,	lv_CurrentDate AS ModifiedDate
	FROM Temp_BrowserInfo AS tmp;
        
    INSERT INTO Temp_RawUserAgent(SessionKey, UserAgentId)
    SELECT 	tmp.SessionKey
		, 	ua.Id AS UserAgentId
    FROM Temp_BrowserInfo AS tmp
		INNER JOIN FPS_FingerPrint.RawUserAgent AS ua ON tmp.UserAgentCode = ua.UserAgentCode;
    
    UPDATE Temp_BrowserInfo AS tmp
		INNER JOIN Temp_RawUserAgent AS ua ON ua.SessionKey = tmp.SessionKey
	SET tmp.UserAgentId = ua.UserAgentId;
     
     
    /*******BrowserInfo********************/
    
    INSERT IGNORE INTO FPS_FingerPrint.BrowserInfoAttribute(BrowserInfoAttributeCode, SecChUa, SecChUaPlatform, SecChUaMobile, BrowserInfoJs, UserAgentData)
    SELECT 	tmp.browserInfoAttributeCode
		,	JSON_UNQUOTE(JSON_EXTRACT(tmp.browserInfoAttribute, '$.SecChUa')) AS SecChUa
		,	JSON_UNQUOTE(JSON_EXTRACT(tmp.browserInfoAttribute, '$.SecChUaPlatform')) AS SecChUaPlatform
		,	JSON_UNQUOTE(JSON_EXTRACT(tmp.browserInfoAttribute, '$.SecChUaMobile')) AS SecChUaMobile
		,	JSON_UNQUOTE(JSON_EXTRACT(tmp.browserInfoAttribute, '$.BrowserInfoJs')) AS BrowserInfoJs
		,	JSON_UNQUOTE(JSON_EXTRACT(tmp.browserInfoAttribute, '$.UserAgentData')) AS UserAgentData
    FROM Temp_BrowserInfo tmp;
        
    INSERT IGNORE INTO FPS_FingerPrint.BrowserInfo(SessionKey, UserAgentId, BrowserInfoAttributeId, HeadlessScore, BrowserName, OSName, Platform, Vendor, IsMobileDevice, ClientIPDNS, CreatedDate, ModifiedDate)
    SELECT 	tmp.SessionKey
		, 	tmp.UserAgentId
		, 	bia.Id AS BrowserInfoAttributeId
		, 	tmp.HeadlessScore
		, 	JSON_UNQUOTE(JSON_EXTRACT(tmp.BrowserInfo, '$.BrowserName')) AS BrowserName
        , 	JSON_UNQUOTE(JSON_EXTRACT(tmp.BrowserInfo, '$.OSName')) AS OSName
        , 	JSON_UNQUOTE(JSON_EXTRACT(bia.BrowserInfoJs, '$.Platform')) AS Platform
        , 	JSON_UNQUOTE(JSON_EXTRACT(bia.BrowserInfoJs, '$.Vendor')) AS Vendor
        , 	JSON_UNQUOTE(JSON_EXTRACT(tmp.browserInfoAttribute, '$.SecChUaMobile')) || JSON_UNQUOTE(JSON_EXTRACT(bia.BrowserInfoJs, '$.IsMobileDevice')) AS IsMobileDevice
        , 	JSON_UNQUOTE(JSON_EXTRACT(tmp.BrowserInfo, '$.ClientIPDNS')) AS ClientIPDNS
        ,	lv_CurrentDate AS CreatedDate
        ,	lv_CurrentDate AS ModifiedDate
    FROM Temp_BrowserInfo AS tmp
		LEFT JOIN FPS_FingerPrint.BrowserInfoAttribute bia ON bia.BrowserInfoAttributeCode = tmp.browserInfoAttributeCode;
	
END$$
DELIMITER ;
