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
    DROP TEMPORARY TABLE IF EXISTS Temp_BrowserInfoJs;
    DROP TEMPORARY TABLE IF EXISTS Temp_BrowserInfoAttribute;
    
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
		,	OSName						VARCHAR(100)	 	NULL
		,	BrowserName					VARCHAR(100)		NULL
        ,	PRIMARY KEY (BrowserInfoAttributeCode)
    );
    
	CREATE TEMPORARY TABLE Temp_BrowserInfoJs(	
			BrowserInfoAttributeCode	VARCHAR(64) 		NOT NULL
		,	OSName						VARCHAR(100)	 	NULL
		,	BrowserName					VARCHAR(100)		NULL
		,	Platform					VARCHAR(100)		NULL
		,	Vendor						VARCHAR(100)		NULL
		,	IsMobileDevice				VARCHAR(15)			NULL
        ,	PRIMARY KEY (BrowserInfoAttributeCode)
    );
    
	CREATE TEMPORARY TABLE Temp_BrowserInfoAttribute(	
			BrowserInfoAttributeCode	VARCHAR(64) 		NOT NULL
		,	SecChUa						VARCHAR(100)	 	NULL
		,	SecChUaPlatform				VARCHAR(100)		NULL
		,	SecChUaMobile				VARCHAR(100) 		NULL
		,	BrowserInfoJs				VARCHAR(500)		NULL
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

    /*******BrowserInfo********************/
	SELECT CONCAT('[', BrowserInfo, ']'), CONCAT('[', BrowserInfoAttribute, ']'), BrowserInfoAttributeCode
    INTO lv_BrowserInfo, lv_BrowserInfoAttribute, lv_BrowserInfoAttributeCode
    FROM Temp_MainTable;
    
    INSERT IGNORE INTO Temp_BrowserInfo(BrowserInfoAttributeCode, OSName, BrowserName)
    SELECT 	lv_BrowserInfoAttributeCode
		,	tmp.OSName
		,	tmp.BrowserName
	FROM	JSON_TABLE(
			lv_BrowserInfo,
			 "$[*]" COLUMNS(
								BrowserInfoAttributeCode	VARCHAR(64) 	PATH "$.BrowserInfoAttributeCode"
							,	OSName						VARCHAR(100)	PATH "$.OSName"
							,	BrowserName					VARCHAR(100) 	PATH "$.BrowserName"
				)
		   ) AS tmp;

    /*******BrowserInfoAttribute********************/
    INSERT IGNORE INTO Temp_BrowserInfoAttribute(BrowserInfoAttributeCode, SecChUa, SecChUaPlatform, SecChUaMobile, BrowserInfoJs)
    SELECT 	lv_BrowserInfoAttributeCode
		,	tmp.SecChUa
		,	tmp.SecChUaPlatform
		,	tmp.SecChUaMobile
		,	tmp.BrowserInfoJs
	FROM	JSON_TABLE(
			lv_BrowserInfoAttribute,
			 "$[*]" COLUMNS(
								BrowserInfoAttributeCode	VARCHAR(64) 	PATH "$.BrowserInfoAttributeCode"
							,	SecChUa						VARCHAR(100)	PATH "$.SecChUa"
							,	SecChUaPlatform				VARCHAR(100)	PATH "$.SecChUaPlatform"
							,	SecChUaMobile				VARCHAR(100)	PATH "$.SecChUaMobile"
							,	BrowserInfoJs				VARCHAR(500)	PATH "$.BrowserInfoJs"
				)
		   ) AS tmp;
    
    /*******BrowserInfoJs********************/    
	SELECT CONCAT('[', BrowserInfoJs, ']')
    INTO lv_BrowserInfoJs
    FROM Temp_BrowserInfoAttribute;
    
    INSERT IGNORE INTO Temp_BrowserInfoJs(BrowserInfoAttributeCode, OSName, BrowserName, Platform, Vendor, IsMobileDevice)
    SELECT 	lv_BrowserInfoAttributeCode
		,	tmp.OSName
		,	tmp.BrowserName
		,	tmp.Platform
		,	tmp.Vendor
		,	tmp.IsMobileDevice
	FROM	JSON_TABLE(
			lv_BrowserInfoJs,
			 "$[*]" COLUMNS(
								BrowserInfoAttributeCode	VARCHAR(64) 	PATH "$.BrowserInfoAttributeCode"
							,	OSName						VARCHAR(100)	PATH "$.OSName"
							,	BrowserName					VARCHAR(100)	PATH "$.BrowserName"
							,	Platform					VARCHAR(100)	PATH "$.Platform"
							,	Vendor						VARCHAR(100)	PATH "$.Vendor"
							,	IsMobileDevice				VARCHAR(15)		PATH "$.IsMobileDevice"
				)
		   ) AS tmp;

    /*******BrowserInfo********************/
    INSERT IGNORE INTO FPS_FingerPrint.BrowserInfoAttribute(BrowserInfoAttributeCode, SecChUa, SecChUaPlatform, SecChUaMobile, BrowserInfoJs)
    SELECT 	tmp.BrowserInfoAttributeCode
		,	tmp.SecChUa
		,	tmp.SecChUaPlatform
		,	tmp.SecChUaMobile
		,	tmp.BrowserInfoJs
    FROM Temp_BrowserInfoAttribute tmp;
        
    UPDATE Temp_MainTable tmp
    INNER JOIN FPS_FingerPrint.BrowserInfoAttribute bia ON bia.BrowserInfoAttributeCode = tmp.BrowserInfoAttributeCode
    SET tmp.BrowserInfoAttributeId = bia.Id;
	
    INSERT IGNORE INTO FPS_FingerPrint.BrowserInfo(SessionKey, BrowserInfoAttributeId, HeadlessScore, BrowserName, OSName, Platform, Vendor, IsMobileDevice, CreatedDate, ModifiedDate)
    SELECT 	tmp.SessionKey
		, 	tmp.BrowserInfoAttributeId
		, 	tmp.HeadlessScore
		, 	tmpBI.BrowserName
        , 	tmpBI.OSName
        , 	tmpJs.Platform
        , 	tmpJs.Vendor
        , 	(tmpAtt.SecChUaMobile OR tmpJs.IsMobileDevice) AS IsMobileDevice
        ,	lv_CurrentDate AS CreatedDate
        ,	lv_CurrentDate AS ModifiedDate
    FROM Temp_MainTable AS tmp
		INNER JOIN Temp_BrowserInfo AS tmpBI ON tmpBI.BrowserInfoAttributeCode = tmp.BrowserInfoAttributeCode
		INNER JOIN Temp_BrowserInfoAttribute AS tmpAtt ON tmpAtt.BrowserInfoAttributeCode = tmp.BrowserInfoAttributeCode
		INNER JOIN Temp_BrowserInfoJs tmpJs ON tmpJs.BrowserInfoAttributeCode = tmp.BrowserInfoAttributeCode;
	
END$$
DELIMITER ;
