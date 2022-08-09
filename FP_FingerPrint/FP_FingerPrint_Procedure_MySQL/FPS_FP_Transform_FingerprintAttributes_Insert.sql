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
			FingerPrintCode				VARCHAR(200) 		NULL
		,	Attribute					LONGTEXT	 		NULL
        , 	INDEX IX_Temp_FingerPrintAttributes_FingerPrintCode(FingerPrintCode)
    );
    
    INSERT INTO Temp_FingerPrintAttributes(FingerPrintCode, Attribute)
	SELECT	tmp.FingerPrintCode
		,	tmp.Attribute
	FROM	JSON_TABLE(
			ip_FingerprintAttributes,
			 "$[*]" COLUMNS(
						FingerPrintCode				VARCHAR(64)	PATH "$.FingerPrintCode"
					,	Attribute					LONGTEXT	PATH "$.Attribute"
				)
		   ) AS tmp; 
    
    INSERT IGNORE INTO FPS_FingerPrint.FingerPrintAttribute(FingerPrintCode, Attribute)
    SELECT	tmp.FingerPrintCode
		,	tmp.Attribute
	FROM Temp_FingerPrintAttributes AS tmp;
    
END$$
DELIMITER ;