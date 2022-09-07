/*<info serverAlias="FPSDC-FPS_FingerPrint" databaseType="2" executers="fpsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `FPS_FP_Transform_FingerprintAttributes_Insert`;
DELIMITER $$

CREATE DEFINER=`fpsOwner`@`%` PROCEDURE `FPS_FP_Transform_FingerprintAttributes_Insert`(
		ip_FingerprintAttributes LONGTEXT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20220607@Jonathan.Doan
		Task :		
		DB:			FPS_FingerPrint
		Original:

		Revisions:
			- 20220607@Jonathan.Doan: Created [Redmine ID: #173803]
			- 20220711@Jonathan.Doan: Update Canvas & WebGL Defender [Redmine ID: #175155]
			- 20220907@Jonathan.Doan: FPS Evolution [Redmine ID: #176820]
            
		Param's Explanation (filtered by):	

		Example:
			- CALL FPS_FP_Transform_FingerprintAttributes_Insert('[{"FingerPrintCode":"53b9f5d0e59645d09cfb56690a7b0916"}]');
			
	*/
    
    DECLARE lv_CurrentDate DATETIME DEFAULT NOW();
    
    /*******LOG TEST********************/
    IF (SELECT ofs.OffsetValue FROM FPS_FingerPrint.Offset AS ofs WHERE Id = 7) = 1 THEN		
		INSERT INTO CTS_Log.FPSLog(SpName, JsonString, OtherText, InsertTime)
		SELECT 'FPS_FP_Transform_FingerprintAttributes_Insert', ip_FingerprintAttributes , NULL, CURRENT_TIMESTAMP();
	END IF;
    /*******LOG TEST********************/
    
    DROP TEMPORARY TABLE IF EXISTS Temp_FingerPrintAttributes;
    
	CREATE TEMPORARY TABLE Temp_FingerPrintAttributes(
			Attribute					LONGTEXT	 		NULL
		,	FingerPrintCode				VARCHAR(200) 		NULL
		,	DoNotTrack					VARCHAR(15)	 		NULL
		,	GLRenderer					VARCHAR(200)	 	NULL
        , 	INDEX IX_Temp_FingerPrintAttributes_FingerPrintCode(FingerPrintCode)
    );
    
    INSERT INTO Temp_FingerPrintAttributes(Attribute, FingerPrintCode, DoNotTrack, GLRenderer)
	SELECT	tmp.Attribute
		,	tmp.FingerPrintCode
		,	tmp.DoNotTrack
		,	tmp.GLRenderer
	FROM	JSON_TABLE(
			ip_FingerprintAttributes,
			 "$[*]" COLUMNS(
						Attribute					LONGTEXT		PATH "$.Attribute"
					,	FingerPrintCode				VARCHAR(64)		PATH "$.FingerPrintCode"
					,	DoNotTrack					VARCHAR(15)		PATH "$.DoNotTrack"
					,	GLRenderer					VARCHAR(200)	PATH "$.GLRenderer"
				)
		   ) AS tmp;
    
    INSERT IGNORE INTO FPS_FingerPrint.FingerPrintAttribute(FingerPrintCode, DoNotTrack, GLRenderer, Audio, CanvasPrint, ColorDepth, ColorGamut, Contrast, CookiesEnabled, CpuClass, DeviceMemory, DomBlockers, FontPreferencePrint
						, Fonts, ForcedColors, HardwareConcurrency, HDR, IndexedDB, InvertedColors, LanguagesPrint, LocalStorage, Math, Monochrome, OpenDatabase, OsCpu, Platform, Plugins, ReducedMotion
                        , ScreenPrint, SessionStorage, Timezone, TouchSupport, Vendor, VendorFlavors, WebglPrint)
    SELECT	tmp.FingerPrintCode
		,	tmp.DoNotTrack
		,	tmp.GLRenderer
		,	tmp.Attribute->>'$.audio'
		,	tmp.Attribute->>'$.canvasPrint'
		,	tmp.Attribute->>'$.colorDepth'
		,	tmp.Attribute->>'$.colorGamut'
		,	tmp.Attribute->>'$.contrast'
		,	CASE 	tmp.Attribute->>'$.cookiesEnabled'
					WHEN 'true' THEN 1
                    WHEN 'false' THEN 0
                    ELSE NULL END AS cookiesEnabled
		,	tmp.Attribute->>'$.cpuClass'
		,	tmp.Attribute->>'$.deviceMemory'
		,	tmp.Attribute->>'$.domBlockers'
		,	tmp.Attribute->>'$.fontPreferencePrint'
		,	tmp.Attribute->>'$.fonts'
		,	CASE 	tmp.Attribute->>'$.forcedColors'
					WHEN 'true' THEN 1
                    WHEN 'false' THEN 0
                    ELSE NULL END AS forcedColors
		,	CASE 	tmp.Attribute->>'$.hardwareConcurrency'
					WHEN 'undefined' THEN NULL
                    ELSE tmp.Attribute->>'$.hardwareConcurrency' END AS hardwareConcurrency
		,	CASE 	tmp.Attribute->>'$.hdr'
					WHEN 'true' THEN 1
                    WHEN 'false' THEN 0
                    ELSE NULL END AS hdr
		,	CASE 	tmp.Attribute->>'$.indexedDB'
					WHEN 'true' THEN 1
                    WHEN 'false' THEN 0
                    ELSE NULL END AS indexedDB
		,	CASE 	tmp.Attribute->>'$.invertedColors'
					WHEN 'true' THEN 1
                    WHEN 'false' THEN 0
                    ELSE NULL END AS invertedColors
		,	tmp.Attribute->>'$.languagesPrint'
		,	CASE 	tmp.Attribute->>'$.localStorage'
					WHEN 'true' THEN 1
                    WHEN 'false' THEN 0
                    ELSE NULL END AS localStorage
		,	tmp.Attribute->>'$.math'
		,	CASE 	tmp.Attribute->>'$.monochrome'
					WHEN 'undefined' THEN NULL
                    ELSE tmp.Attribute->>'$.monochrome' END AS monochrome
		,	CASE 	tmp.Attribute->>'$.openDatabase'
					WHEN 'true' THEN 1
                    WHEN 'false' THEN 0
                    ELSE -1 END AS openDatabase
		,	tmp.Attribute->>'$.osCpu'
		,	tmp.Attribute->>'$.platform'
		,	tmp.Attribute->>'$.plugins'
		,	CASE 	tmp.Attribute->>'$.reducedMotion'
					WHEN 'true' THEN 1
                    WHEN 'false' THEN 0
                    ELSE -1 END AS reducedMotion
		,	tmp.Attribute->>'$.screenPrint'
		,	CASE 	tmp.Attribute->>'$.sessionStorage'
					WHEN 'true' THEN 1
                    WHEN 'false' THEN 0
                    ELSE -1 END AS sessionStorage
		,	tmp.Attribute->>'$.timezone'
		,	tmp.Attribute->>'$.touchSupport'
		,	tmp.Attribute->>'$.vendor'
		,	tmp.Attribute->>'$.vendorFlavors'
		,	tmp.Attribute->>'$.webglPrint'
	FROM Temp_FingerPrintAttributes AS tmp;
    
END$$
DELIMITER ;