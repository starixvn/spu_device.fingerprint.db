/*<info serverAlias="FPSDC-FPS_FingerPrint" databaseType="2" executers="fpsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `FPS_FP_Transform_RawTransaction_Insert`;
DELIMITER $$

CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `FPS_FP_Transform_RawTransaction_Insert`(
		ip_Transaction LONGTEXT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20220218@Terry.Nguyen
		Task :		
		DB:			FPS_FingerPrint
		Original:

		Revisions: 
            
		Param's Explanation (filtered by):	

		Example:
			- CALL FPS_FP_Transform_Transaction_Insert(100);
			
	*/
    DROP TEMPORARY TABLE IF EXISTS Temp_Transactions;
    
	CREATE TEMPORARY TABLE Temp_Transactions(
			LoginName					VARCHAR(100) CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI' NOT NULL	
		,	SubscriberId				INT						NOT NULL
		,	SessionKey					VARCHAR(200)	 		NOT NULL
		,	TransTime					DATETIME(4)	 			NULL		
		,	ClientIp					VARCHAR(45)				NULL		
		,	UserAgent					VARCHAR(500)			NULL
		,	Url							VARCHAR(100)			NULL
		,	Action						VARCHAR(100)			NULL
		,	TransKey					VARCHAR(500)			NULL
        ,	CustId						BIGINT					NULL
        ,	SubAccId					BIGINT					NULL
    );     
    
    INSERT INTO Temp_Transactions(
		LoginName
        , SubscriberId
        , SessionKey
        , TransTime
        , ClientIp
        , UserAgent
        , Url
        , Action
        , TransKey
        , CustId
        , SubAccId)
	SELECT	tmp.LoginName
		,	tmp.SubscriberId
		,	tmp.SessionKey
		,	tmp.TransTime
        ,	tmp.ClientIp
        ,	tmp.UserAgent
        ,	tmp.Url
        ,	tmp.Action
        ,	tmp.TransKey
        ,	tmp.CustId
        ,	tmp.SubAccId
	FROM	JSON_TABLE(
			ip_Transaction,
			 "$[*]" COLUMNS(
					LoginName				VARCHAR(100)	PATH "$.LoginName"       
				,	SubscriberId			INT 			PATH "$.SubscriberId"   
				,	SessionKey				VARCHAR(200) 	PATH "$.SessionKey"
				,	TransTime				DATETIME(4)		PATH "$.TransTime"
				,	ClientIp				VARCHAR(45)		PATH "$.ClientIp"
				,	UserAgent				VARCHAR(500)	PATH "$.UserAgent"
				,	Url						VARCHAR(100) 	PATH "$.Url"
				,	Action					VARCHAR(100) 	PATH "$.Action"
				,	TransKey				VARCHAR(200) 	PATH "$.TransKey"
				,	CustId					BIGINT		 	PATH "$.CustId"
				,	SubAccId				BIGINT		 	PATH "$.SubAccId"
				)
		   ) AS  tmp; 
		
    INSERT INTO FPS_FingerPrint.RawTransaction(
						LoginName
					,	SubscriberId                    
                    ,	SessionKey
					,	Transtime
					,	ClientIP
					,	UserAgent
                    ,	Url                    
                    ,	Action                    
					,	ModifiedDate
					,	CreatedDate
                    ,	TransKey
                    ,	CustId
                    ,	SubAccId)
	SELECT			tmp.LoginName
					,	tmp.SubscriberId					
                     ,	tmp.SessionKey
					,	tmp.TransTime
					,	tmp.ClientIp
					,	tmp.UserAgent
                    ,	tmp.Url                   
                    ,	tmp.Action                   
					, 	NOW()
					, 	NOW()
                    ,	tmp.TransKey
                    ,	tmp.CustId
                    ,	tmp.SubAccId
	FROM Temp_Transactions tmp; 
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Transactions;
END$$
DELIMITER ;