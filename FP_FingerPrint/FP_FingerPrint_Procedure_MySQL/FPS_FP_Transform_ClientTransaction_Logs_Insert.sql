/*<info serverAlias="FPSDC-FPS_FingerPrint" databaseType="2" executers="fpsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `FPS_FP_Transform_ClientTransaction_Logs_Insert`;
DELIMITER $$

CREATE DEFINER=`fpsOwner`@`%` PROCEDURE `FPS_FP_Transform_ClientTransaction_Logs_Insert`(
		ip_FingerPrint LONGTEXT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20220912@Terry.Nguyen
		Task :		
		DB:			FPS_FingerPrint
		Original:

		Revisions:
			- 20220307@Terry.Nguyen: Created [Redmine ID: #162668]			
            - 20221020@Terry.Nguyen: Log more information [Redmine ID: #178913]
            
		Param's Explanation (filtered by):	

		Example:
			- CALL FPS_FP_Transform_ClientTransaction_Logs_Insert('[{"FingerPrintCode":"53b9f5d0e59645d09cfb56690a7b0916","SessionKey":"ddddd","SubscriberId":2,"CookieId":1,"Url":"fdsafdsaf"}]');
			
	*/
    
    DECLARE lv_CurrentDate DATETIME DEFAULT NOW();
    DECLARE lv_RawFingerPrintId BIGINT;
    
    /*******LOG TEST********************/
    IF (SELECT ofs.OffsetValue FROM FPS_FingerPrint.Offset AS ofs WHERE Id = 7) = 1 THEN		
		INSERT INTO CTS_Log.FPSLog(SpName, JsonString, OtherText, InsertTime)
		SELECT 'FPS_FP_Transform_ClientTransaction_Logs_Insert', ip_FingerPrint , NULL, CURRENT_TIMESTAMP();
	END IF;
    /*******LOG TEST********************/
    
    DROP TEMPORARY TABLE IF EXISTS Temp_FingerPrint;
    
	CREATE TEMPORARY TABLE Temp_FingerPrint(	
			SessionKey					VARCHAR(100) 		NULL
		,	SubscriberId				INT	UNSIGNED		NULL		
        ,	Url							VARCHAR(100)		NULL
		,	TransTime					DATETIME(4)	 		NULL			
		,	UserAgent					VARCHAR(300)	 	NULL
        ,	Information					TEXT			 	NULL        
    );
    
    INSERT INTO Temp_FingerPrint(SessionKey, SubscriberId, Url, TransTime, UserAgent, Information)
	SELECT	tmp.SessionKey
		,	tmp.SubscriberId        
        ,	tmp.Url
        ,	tmp.TransTime
        ,	tmp.UserAgent
        ,	tmp.Information
	FROM	JSON_TABLE(
			ip_FingerPrint,
			 "$[*]" COLUMNS(
								SessionKey				VARCHAR(100) 	PATH "$.SessionKey"   
							,	SubscriberId			INT 			PATH "$.SubscriberId"							
                            ,	Url						VARCHAR(100) 	PATH "$.Url"
                            ,	TransTime				DATETIME(4)		PATH "$.TransTime"
                            ,	UserAgent				VARCHAR(300)	PATH "$.UserAgent"
                            ,	Information				VARCHAR(300)	PATH "$.Information"
				)
		   ) AS tmp;     
   
    
    /*******ClientTransaction********************/
    INSERT IGNORE INTO FPS_FingerPrint.ClientTransaction_Logs(SubscriberId, SessionKey, Url, TransTime, UserAgent, CreatedDate, Information)
	SELECT	tmp.SubscriberId		
		,	tmp.SessionKey
		,	tmp.Url
		,	tmp.TransTime
		,	tmp.UserAgent
		,	lv_CurrentDate AS CreatedDate
        ,	tmp.Information
	FROM Temp_FingerPrint AS tmp;
    
END$$
DELIMITER ;