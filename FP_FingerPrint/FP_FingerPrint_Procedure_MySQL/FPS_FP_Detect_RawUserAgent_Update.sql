/*<info serverAlias="FPSDC-FPS_FingerPrint" databaseType="2" executers="fpsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `FPS_FP_Detect_RawUserAgent_Update`;
DELIMITER $$

CREATE DEFINER=`fpsOwner`@`%` PROCEDURE `FPS_FP_Detect_RawUserAgent_Update`(
		ip_RawUserAgentJson	LONGTEXT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20220406@Jonathan.Doan
		Task :		
		DB:			FPS_FingerPrint
		Original:

		Revisions:
			- 20220406@Jonathan.Doan: Created [Redmine ID: #162668]
            
		Param's Explanation (filtered by):	

		Example:
			- CALL FPS_FP_Detect_RawUserAgent_Update(100,4);
			
	*/
    
    /*******LOG TEST********************/
    IF (SELECT ofs.OffsetValue FROM FPS_FingerPrint.Offset AS ofs WHERE Id = 7) = 1 THEN		
		INSERT INTO CTS_Log.FPSLog(SpName, JsonString, OtherText, InsertTime)
		SELECT 'FPS_FP_Detect_RawUserAgent_Update', ip_RawUserAgentJson, NULL, CURRENT_TIMESTAMP();
	END IF;
    /*******LOG TEST********************/
    
    
	DROP TEMPORARY TABLE IF EXISTS Temp_RawUserAgent; 
    
	/* Create Temporary table */
	CREATE TEMPORARY TABLE Temp_RawUserAgent(
			Id 					BIGINT UNSIGNED PRIMARY KEY        
		,	ClientType 			VARCHAR(15) NULL
		,	ClientName 			VARCHAR(100) NULL
		,	ClientVersion 		VARCHAR(50) NULL
		,	OSName 				VARCHAR(100) NULL
		,	OSShortName 		VARCHAR(50) NULL
		,	OSVersion 			VARCHAR(50) NULL
		,	OSPlatform 			VARCHAR(15) NULL
		,	Device 				VARCHAR(50) NULL
		,	Brand 				VARCHAR(50) NULL
		,	Model 				VARCHAR(15) NULL
		,	BotName 			VARCHAR(100) NULL
		,	BotCategory 		VARCHAR(50) NULL
    );
    
   INSERT IGNORE INTO Temp_RawUserAgent(Id, ClientType, ClientName, ClientVersion, OSName, OSShortName, OSVersion, OSPlatform, Device, Brand, Model, BotName, BotCategory)
	SELECT	rt.Id
		,	rt.ClientType
		,	rt.ClientName
		,	rt.ClientVersion
		,	rt.OSName
		,	rt.OSShortName
		,	rt.OSVersion
		,	rt.OSPlatform
		,	rt.Device
		,	rt.Brand
		,	rt.Model	
        ,	rt.BotName	
        ,	rt.BotCategory
	FROM	JSON_TABLE(
			ip_RawUserAgentJson,
			 "$[*]" COLUMNS(
								Id					BIGINT			PATH "$.Id"       
							,	ClientType			VARCHAR(15) 	PATH "$.ClientType"                        
							,	ClientName			VARCHAR(100) 	PATH "$.ClientName"                        
							,	ClientVersion		VARCHAR(50) 	PATH "$.ClientVersion"                        
							,	OSName				VARCHAR(100) 	PATH "$.OSName"                        
							,	OSShortName			VARCHAR(50) 	PATH "$.OSShortName"                        
							,	OSVersion			VARCHAR(50) 	PATH "$.OSVersion"                        
							,	OSPlatform			VARCHAR(15) 	PATH "$.OSPlatform"                        
							,	Device				VARCHAR(50) 	PATH "$.Device"                        
							,	Brand				VARCHAR(50) 	PATH "$.Brand"                        
							,	Model				VARCHAR(15) 	PATH "$.Model"                        
							,	BotName				VARCHAR(100) 	PATH "$.BotName"                        
							,	BotCategory			VARCHAR(50) 	PATH "$.BotCategory"                        
				)
		   ) AS  rt;    
    
    
	/* Process data */
    UPDATE FPS_FingerPrint.RawUserAgent ua
		INNER JOIN Temp_RawUserAgent AS tmp ON ua.Id = tmp.Id
    SET ua.ClientType = tmp.ClientType,
		ua.ClientName = tmp.ClientName,
		ua.ClientVersion = tmp.ClientVersion,
		ua.OSName = tmp.OSName,
		ua.OSShortName = tmp.OSShortName,
		ua.OSVersion = tmp.OSVersion,
		ua.OSPlatform = tmp.OSPlatform,
		ua.Device = tmp.Device,
		ua.Brand = tmp.Brand,
		ua.Model = tmp.Model,
		ua.BotName = tmp.BotName,
		ua.BotCategory = tmp.BotCategory;
          
END$$
DELIMITER ;
