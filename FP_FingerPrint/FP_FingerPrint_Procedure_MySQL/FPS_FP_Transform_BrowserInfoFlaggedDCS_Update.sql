/*<info serverAlias="FPSDC-FPS_FingerPrint" databaseType="2" executers="fpsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `FPS_FP_Transform_BrowserInfoFlaggedDCS_Update`;
DELIMITER $$

CREATE DEFINER=`fpsOwner`@`%` PROCEDURE `FPS_FP_Transform_BrowserInfoFlaggedDCS_Update`(
		ip_BrowserInfoIdJson	LONGTEXT
)
    SQL SECURITY INVOKER
BEGIN  
	/* 
		Created:	202200811@Jonathan.Doan
		Task :		
		DB:			FPS_FingerPrint
		Original:

		Revisions:
            - 20220811@Jonathan.Doan: Created [Redmine ID: #176547]
            
		Param's Explanation (filtered by):	

		Example:
			- CALL FPS_FP_Transform_BrowserInfoFlaggedDCS_Update('[{"Id": 1}]');
			
	*/
   
    DECLARE lv_currentDate DATETIME DEFAULT NOW();
    
    /*******LOG TEST********************/
    IF (SELECT ofs.OffsetValue FROM FPS_FingerPrint.Offset AS ofs WHERE Id = 7) = 1 THEN		
		INSERT INTO CTS_Log.FPSLog(SpName, JsonString, OtherText, InsertTime)
		SELECT 'FPS_FP_Transform_BrowserInfoFlaggedDCS_Update', ip_BrowserInfoIdJson, NULL, CURRENT_TIMESTAMP();
	END IF;
    /*******LOG TEST********************/
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Id;
    CREATE TEMPORARY TABLE Temp_Id(
			Id		BIGINT UNSIGNED PRIMARY KEY
     );
    
    DROP TEMPORARY TABLE IF EXISTS Temp_BrowserInfo;
    CREATE TEMPORARY TABLE Temp_BrowserInfo(
			Id			BIGINT UNSIGNED PRIMARY KEY,
			Flagged		SMALLINT
     );
     
    INSERT INTO Temp_Id(Id)
	SELECT	tmpJs.Id
    FROM JSON_TABLE(
			ip_BrowserInfoIdJson,
			 "$[*]" COLUMNS(
					Id	BIGINT UNSIGNED	PATH "$.Id"
			)
		) AS tmpJs;

    INSERT INTO Temp_BrowserInfo(Id, Flagged)
	SELECT 	tmp.Id
		,	bi.Flagged
    FROM Temp_Id AS tmp
    INNER JOIN FPS_FingerPrint.BrowserInfoCompleted AS bi ON bi.Id = tmp.Id;
    
    UPDATE FPSTesting.FP_RawTransaction AS trans
    INNER JOIN Temp_BrowserInfo AS tmp ON tmp.Id = trans.BrowserInfoId
    SET trans.Flagged = tmp.Flagged;
    
END$$
DELIMITER ;