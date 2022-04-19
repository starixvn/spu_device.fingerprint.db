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
			- CALL FPS_FP_Transform_ClientTransaction_Insert('[{"FingerPrintCode":"53b9f5d0e59645d09cfb56690a7b0916","SessionKey":"ddddd","SubscriberId":2,"Attribute":"dfsfsafsaf","CookieCode":"cookief5d0e59645d09cfb56690a7b0916","Flagged":"Human","Url":"fdsafdsaf"}]');
			
	*/
    
    /*******LOG TEST********************/
    INSERT INTO FPS_FingerPrint.Test_LOG(SpName, JsonString, OtherText, InsertTime)
    SELECT 'FPS_FP_Transform_ClientTransaction_Insert', ip_FingerPrint , NULL, CURRENT_TIMESTAMP();
    /*******LOG TEST********************/
    
    DROP TEMPORARY TABLE IF EXISTS Temp_FingerPrint;    
	CREATE TEMPORARY TABLE Temp_FingerPrint(
			FingerPrintCode				VARCHAR(200) 	NULL	
		,	SessionKey					VARCHAR(100) 	NULL
		,	SubscriberId				INT	 			NULL
		,	Attribute					LONGTEXT	 	NULL
		,	CookieCode 					VARCHAR(64)		NULL		
        ,	Flagged						VARCHAR(50)		NULL
		,	RobotDetail					VARCHAR(300)	NULL	
        ,	Url							VARCHAR(100)	NULL
		,	TransTime					DATETIME(4)	 	NULL	
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
								FingerPrintCode			VARCHAR(200)	PATH "$.FingerPrintCode"       
							,	SessionKey				VARCHAR(100) 	PATH "$.SessionKey"   
							,	SubscriberId			INT 			PATH "$.SubscriberId"
							,	Attribute				LONGTEXT		PATH "$.Attribute"
							,	CookieCode				VARCHAR(64) 	PATH "$.CookieCode"							
                            ,	Flagged					VARCHAR(50) 	PATH "$.Flagged"
                            ,	RobotDetail				VARCHAR(300) 	PATH "$.RobotDetail"
                            ,	Url						VARCHAR(100) 	PATH "$.Url"
                            ,	TransTime				DATETIME(4)		PATH "$.TransTime"
				)
		   ) AS  tmp; 
    
    INSERT INTO FPS_FingerPrint.RawFingerPrint(FingerPrintCode, Attribute, CreatedDate, ModifiedDate)
	SELECT	tmp.FingerPrintCode
		,	tmp.Attribute
        ,	NOW() AS CreatedDate
        ,	NOW() AS ModifiedDate
	FROM Temp_FingerPrint tmp
	ON DUPLICATE KEY UPDATE ModifiedDate = NOW();
    
    
    INSERT INTO FPS_FingerPrint.ClientTransaction(FingerPrintCode, SubscriberId, CookieCode, SessionKey, Flagged, RobotDetail, Url, TransTime, CreatedDate, ModifiedDate)
	SELECT	tmp.FingerPrintCode
		,	tmp.SubscriberId
		,	tmp.CookieCode
		,	tmp.SessionKey
		,	tmp.Flagged
        ,	tmp.RobotDetail
		,	tmp.Url
		,	tmp.TransTime
		,	NOW() AS CreatedDate
		,	NOW() AS CreatedDate
	FROM Temp_FingerPrint tmp;
    
	INSERT INTO FPS_FingerPrint.ClientTransactionDailySum(
			TransDate
            ,	SubscriberId
            ,	TotalTrans
            ,	TotalValidTrans
            ,	CreateDate
            ,	ModifiedDate
    )
    with group_data as (
		SELECT CAST(tmp.TransTime as DATE) as TransDate
				,	tmp.SubscriberId
				,	COUNT(tmp.SubscriberId) as CountTrans
		FROM Temp_FingerPrint tmp
		GROUP BY TransDate, tmp.SubscriberId
	)
    SELECT 	gd.TransDate
			,	gd.SubscriberId
			,	gd.CountTrans as TotalTrans
			,	0 as TotalValidTrans
			,	NOW() AS CreatedDate
			,	NOW() AS ModifiedDate
	FROM group_data gd
    ON DUPLICATE KEY UPDATE TotalTrans = TotalTrans + gd.CountTrans,
							ModifiedDate = NOW();
END$$
DELIMITER ;