/*<info serverAlias="FPSDC-FPS_FingerPrint" databaseType="2" executers="fpsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `FPS_FP_Transform_ClientTransaction_Insert`;
DELIMITER $$

CREATE DEFINER=`fpsOwner`@`%` PROCEDURE `FPS_FP_Transform_ClientTransaction_Insert`(
		ip_FingerPrint LONGTEXT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20220218@Terry.Nguyen
		Task :		
		DB:			FPS_FingerPrint
		Original:

		Revisions:
			- 20220307@Terry.Nguyen: Created [Redmine ID: #162668]
			- 20220318@Jonathan.Doan: Add TransTime for ClientTransaction and Insert ClientTransactionDailySum [Redmine ID: #162668]
            
		Param's Explanation (filtered by):	

		Example:
			- CALL FPS_FP_Transform_ClientTransaction_Insert('[{"FingerPrintCode":"53b9f5d0e59645d09cfb56690a7b0916","SessionKey":"ddddd","SubscriberId":2,"Attribute":"dfsfsafsaf","CookieId":1,"Flagged":"Human","Url":"fdsafdsaf"}]');
			
	*/
    
    DECLARE lv_CurrentDate DATETIME DEFAULT NOW();
    DECLARE lv_RawFingerPrintId BIGINT;
    
    /*******LOG TEST********************/
    IF (SELECT ofs.OffsetValue FROM FPS_FingerPrint.Offset AS ofs WHERE Id = 7) = 1 THEN		
		INSERT INTO CTS_Log.FPSLog(SpName, JsonString, OtherText, InsertTime)
		SELECT 'FPS_FP_Transform_ClientTransaction_Insert', ip_FingerPrint , NULL, CURRENT_TIMESTAMP();
	END IF;
    /*******LOG TEST********************/
    
    DROP TEMPORARY TABLE IF EXISTS Temp_FingerPrint;
    DROP TEMPORARY TABLE IF EXISTS Temp_RawFingerPrint;
    DROP TEMPORARY TABLE IF EXISTS Temp_Cookie;
    
	CREATE TEMPORARY TABLE Temp_FingerPrint(
			RawFingerPrintId			BIGINT UNSIGNED 	NULL	
		,	FingerPrintCode				VARCHAR(200) 		NULL	
		,	SessionKey					VARCHAR(100) 		NULL
		,	SubscriberId				INT	UNSIGNED		NULL
		,	Attribute					LONGTEXT	 		NULL
		,	CookieId 					BIGINT UNSIGNED 	NULL
		,	CookieCode 					VARCHAR(64)			NULL		
        ,	Flagged						VARCHAR(50)			NULL
		,	RobotDetail					VARCHAR(300)		NULL	
        ,	Url							VARCHAR(100)		NULL
		,	TransTime					DATETIME(4)	 		NULL	
        , 	INDEX IX_Temp_FingerPrint_FingerPrintCode(FingerPrintCode)
    );     
    
	CREATE TEMPORARY TABLE Temp_RawFingerPrint(
			RawFingerPrintId			BIGINT UNSIGNED 	NOT NULL	
		,	FingerPrintCode				VARCHAR(64) 		NOT NULL
        ,	PRIMARY KEY (RawFingerPrintId)	
        , 	INDEX IX_Temp_RawFingerPrint_FingerPrintCode(FingerPrintCode)
    );   
    
	CREATE TEMPORARY TABLE Temp_Cookie(
			CookieId					BIGINT UNSIGNED 	NOT NULL	
		,	CookieCode					VARCHAR(64) 		NOT NULL
        ,	PRIMARY KEY (CookieId)	
        , 	INDEX IX_Temp_Cookie_CookieCode(CookieCode)
    );   

    
    INSERT INTO Temp_FingerPrint(FingerPrintCode, SessionKey, SubscriberId, Attribute, CookieCode, Flagged, RobotDetail, Url, TransTime)
	SELECT	tmp.FingerPrintCode
		,	tmp.SessionKey
		,	tmp.SubscriberId
		,	tmp.Attribute
        ,	tmp.CookieCode
        ,	tmp.Flagged
        ,	tmp.RobotDetail
        ,	tmp.Url
        ,	tmp.TransTime
	FROM	JSON_TABLE(
			ip_FingerPrint,
			 "$[*]" COLUMNS(
								FingerPrintCode			VARCHAR(64)	PATH "$.FingerPrintCode"       
							,	SessionKey				VARCHAR(100) 	PATH "$.SessionKey"   
							,	SubscriberId			INT 			PATH "$.SubscriberId"
							,	Attribute				LONGTEXT		PATH "$.Attribute"
							,	CookieCode				VARCHAR(64) 	PATH "$.CookieCode"							
                            ,	Flagged					VARCHAR(50) 	PATH "$.Flagged"
                            ,	RobotDetail				VARCHAR(300) 	PATH "$.RobotDetail"
                            ,	Url						VARCHAR(100) 	PATH "$.Url"
                            ,	TransTime				DATETIME(4)		PATH "$.TransTime"
				)
		   ) AS tmp; 
    
    /*******RawFingerPrint********************/
    INSERT IGNORE INTO FPS_FingerPrint.RawFingerPrint(FingerPrintCode, CreatedDate, ModifiedDate)
	SELECT	tmp.FingerPrintCode		
        ,	lv_CurrentDate AS CreatedDate
        ,	lv_CurrentDate AS ModifiedDate
	FROM Temp_FingerPrint AS tmp;
    
    INSERT INTO Temp_RawFingerPrint(RawFingerPrintId, FingerPrintCode)
    SELECT DISTINCT rfp.Id AS RawFingerPrintId, tmp.FingerPrintCode
    FROM Temp_FingerPrint AS tmp
		INNER JOIN FPS_FingerPrint.RawFingerPrint AS rfp ON rfp.FingerPrintCode = tmp.FingerPrintCode;
    
    UPDATE Temp_FingerPrint AS tmp
		INNER JOIN Temp_RawFingerPrint AS rfp ON rfp.FingerPrintCode = tmp.FingerPrintCode
    SET tmp.RawFingerPrintId = rfp.RawFingerPrintId;
    
    INSERT IGNORE INTO FPS_FingerPrint.FingerPrintAttribute(RawFingerPrintId, Attribute)
    SELECT	tmp.RawFingerPrintId
		,	tmp.Attribute
	FROM Temp_FingerPrint AS tmp;
    
    
    /*******Cookie********************/
    INSERT IGNORE INTO FPS_FingerPrint.Cookie(CookieCode, CreatedDate, ModifiedDate)
	SELECT	tmp.CookieCode		
        ,	lv_CurrentDate AS CreatedDate
        ,	lv_CurrentDate AS ModifiedDate
	FROM Temp_FingerPrint AS tmp;
    
    INSERT INTO Temp_Cookie(CookieId, CookieCode)
    SELECT DISTINCT c.Id AS CookieId, tmp.CookieCode
    FROM Temp_FingerPrint AS tmp
		INNER JOIN FPS_FingerPrint.Cookie AS c ON c.CookieCode = tmp.CookieCode;
        
    UPDATE Temp_FingerPrint AS tmp
		INNER JOIN Temp_Cookie AS c ON c.CookieCode = tmp.CookieCode
    SET tmp.CookieId = c.CookieId;
    
    
    /*******ClientTransaction********************/
    INSERT IGNORE INTO FPS_FingerPrint.ClientTransaction(RawFingerPrintId, SubscriberId, CookieId, SessionKey, Flagged, RobotDetail, Url, TransTime, CreatedDate, ModifiedDate)
	SELECT	tmp.RawFingerPrintId
		,	tmp.SubscriberId
		,	tmp.CookieId
		,	tmp.SessionKey
		,	tmp.Flagged
        ,	tmp.RobotDetail
		,	tmp.Url
		,	tmp.TransTime
		,	lv_CurrentDate AS CreatedDate
		,	lv_CurrentDate AS CreatedDate
	FROM Temp_FingerPrint AS tmp;
    
	INSERT INTO FPS_FingerPrint.ClientTransactionDailySum(
			TransDate
		,	SubscriberId
		,	TotalTrans
		,	TotalValidTrans
		,	CreateDate
		,	ModifiedDate
    )
    WITH group_data AS (
		SELECT CAST(tmp.TransTime AS DATE) AS TransDate
				,	tmp.SubscriberId
				,	COUNT(tmp.SubscriberId) AS CountTrans
		FROM Temp_FingerPrint AS tmp
		GROUP BY TransDate, tmp.SubscriberId
	)
    SELECT 	gd.TransDate
			,	gd.SubscriberId
			,	gd.CountTrans AS TotalTrans
			,	0 AS TotalValidTrans
			,	lv_CurrentDate AS CreatedDate
			,	lv_CurrentDate AS ModifiedDate
	FROM group_data AS gd
    ON DUPLICATE KEY UPDATE TotalTrans = TotalTrans + gd.CountTrans,
							ModifiedDate = lv_CurrentDate;
END$$
DELIMITER ;