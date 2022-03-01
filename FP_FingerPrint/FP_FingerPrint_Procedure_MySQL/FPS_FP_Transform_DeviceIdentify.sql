/*<info serverAlias="xxxx" databaseType="2" executers="fpsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `FPS_FP_Transform_DeviceIdentify`;
DELIMITER $$

CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `FPS_FP_Transform_DeviceIdentify`(		
		ip_GroupId		BIGINT UNSIGNED
   ,    ip_TransJson	LONGTEXT
	
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20220218@Terry.Nguyen
		Task :		
		DB:			FPS_FingerPrint_Review
		Original:

		Revisions:
            
		Param's Explanation (filtered by):	
			ip_GroupId: 0-Not a group, MinTransId If a Group;

		Example:
			CALL FPS_FP_Transform_DeviceIdentify(1,
				'[	{"Id" : 1,"TransTime" : "2022-02-27 00:00:00","FingerPrintCode" : "100000009abcdefghijkrtgyuhn","CookieId" : 1},
					{"Id" : 62,"TransTime" : "2022-02-27 00:00:00","FingerPrintCode" : "100000009abcdefghijkrtgyuhn","CookieId" : 1},
					{"Id" : 73,"TransTime" : null,"FingerPrintCode" : "45e9c4defb87b8ae6406480e012b6c5b","CookieId" : 1}]');;
			
	*/
    
    DECLARE lv_GroupDeviceId BIGINT UNSIGNED;
    DECLARE lv_CreatedDate DATETIME(4);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_InputTrans;
    CREATE TEMPORARY TABLE Temp_InputTrans(
			Id				BIGINT UNSIGNED PRIMARY KEY
		,	TransTime		DATETIME(4)
		,	FingerPrintCode	VARCHAR(64)
        ,	CookieId		BIGINT UNSIGNED
        ,	DeviceID		BIGINT UNSIGNED
        ,	RecoverType		TINYINT DEFAULT 0	#0 New, 1 By FingerPrintCode, 2 By Cookie
        
		,	INDEX IX_Temp_InputTrans_FingerPrintCode(FingerPrintCode)
        ,	INDEX IX_Temp_InputTrans_CookieId(CookieId)
    );    
    
	DROP TEMPORARY TABLE IF EXISTS Temp_NewTrans;
    CREATE TEMPORARY TABLE Temp_NewTrans(
			GroupId			BIGINT UNSIGNED PRIMARY KEY
        ,	DeviceID		BIGINT UNSIGNED
        ,	FingerPrintCode	VARCHAR(64)
        ,	CookieId		BIGINT UNSIGNED
    );

	SET lv_CreatedDate = CURRENT_TIMESTAMP(4);
    
    INSERT INTO Temp_InputTrans(Id, Transtime, FingerPrintCode, CookieId)
	SELECT	tmpJs.Id
		,	tmpJs.Transtime
		,	tmpJs.FingerPrintCode
        ,	tmpJs.CookieId
    FROM JSON_TABLE(
			ip_TransJson,
			 "$[*]" COLUMNS(
								Id				BIGINT UNSIGNED	PATH "$.Id"
							,	TransTime		DATETIME(4)		PATH "$.TransTime"
							,	FingerPrintCode	VARCHAR(64)		PATH "$.FingerPrintCode"
                            ,	CookieId		BIGINT			PATH "$.CookieId")
		) AS tmpJs;	

    /*====RECOVER DEVICE: Get Exisitng By FingerPrintCode*/
	UPDATE Temp_InputTrans AS tmpTs
		INNER JOIN FPS_FingerPrint.DeviceFingerPrint AS df ON tmpTs.FingerPrintCode = df.FingerPrintCode
	SET 	tmpTs.RecoverType = 1
		,	tmpTs.DeviceId = df.DeviceId;
 
    /*====RECOVER DEVICE: Get Exisitng By Cookie*/    
    UPDATE Temp_InputTrans AS tmpTs
		INNER JOIN FPS_FingerPrint.DeviceCookie AS dc ON tmpTs.CookieId = dc.CookieId
	SET 	tmpTs.RecoverType = tmpTs.RecoverType + 2
		,	tmpTs.DeviceId = dc.DeviceId
	WHERE	tmpTs.DeviceId IS NULL;

    /*====RECOVER DEVICE: PROCESS FOR Group*/
    IF (ip_GroupId != 0) THEN
		SELECT 	DeviceID
        INTO	lv_GroupDeviceId
		FROM Temp_InputTrans AS tmpTs
        WHERE tmpTs.DeviceId > 0 LIMIT 1;
        
		UPDATE Temp_InputTrans AS tmpTs
		SET tmpTs.DeviceId = lv_GroupDeviceId
        WHERE tmpTs.DeviceId IS NULL;
    END IF;
    
     /*====RECOVER DEVICE: Insert New FingerprintCode For Old Device*/     
    INSERT INTO FPS_FingerPrint.DeviceFingerPrint(FingerPrintCode, DeviceId, CreatedDate, ModifiedDate)
    SELECT	tmpIt.FingerPrintCode
		,	tmpIt.DeviceId
		,	lv_CreatedDate
        ,	tmpIt.TransTime
    FROM Temp_InputTrans AS tmpIt
    WHERE tmpIt.RecoverType = 2
    ON DUPLICATE KEY UPDATE ModifiedDate = tmpIt.TransTime;
    
    /*====RECOVER DEVICE: Insert New Cookie For Old Device*/
    INSERT INTO FPS_FingerPrint.DeviceCookie(CookieId, DeviceId, CreatedDate, ModifiedDate)
    SELECT	tmpIt.CookieId
		,	tmpIt.DeviceId
		,	lv_CreatedDate
        ,	tmpIt.TransTime
    FROM Temp_InputTrans AS tmpIt
    WHERE tmpIt.RecoverType IN (1,3)
    ON DUPLICATE KEY UPDATE ModifiedDate = tmpIt.TransTime;    

    /*====RECOVER DEVICE: Update Modified Date Of Old Device*/
    UPDATE FPS_FingerPrint.Device AS dv
		INNER JOIN (SELECT	tmpIt.DeviceId
						,	MAX(tmpIt.TransTime) AS TransTime
					FROM Temp_InputTrans AS tmpIt WHERE DeviceId > 0
                    GROUP BY tmpIt.DeviceId) AS tmpDv ON dv.Id = tmpDv.DeviceId
	SET dv.ModifiedDate = tmpDv.TransTime;
    
    /*====NEW DEVICE */
    IF (ip_GroupId = 0) THEN    
		        
		INSERT IGNORE INTO FPS_FingerPrint.Device(FirstFingerprintCode, CreatedDate, ModifiedDate)
		SELECT 	tmpIt.FingerprintCode
			,	lv_CreatedDate
			,	tmpIt.TransTime
		FROM Temp_InputTrans AS tmpIt
		WHERE tmpIt.DeviceId IS NULL;	
        
		UPDATE Temp_InputTrans AS tmpIt
			INNER JOIN FPS_FingerPrint.Device AS dv ON dv.FirstFingerprintCode = tmpIt.FingerPrintCode
		SET	tmpIt.DeviceId = dv.Id;
        
        INSERT IGNORE INTO FPS_FingerPrint.DeviceFingerPrint(FingerPrintCode, DeviceId,  CreatedDate, ModifiedDate)
        SELECT 	tmpIt.FingerprintCode
			,	tmpIt.DeviceId
			,	lv_CreatedDate
			,	tmpIt.TransTime            
		FROM Temp_InputTrans AS tmpIt;
	
		INSERT IGNORE INTO FPS_FingerPrint.DeviceCookie(CookieId, DeviceId,  CreatedDate, ModifiedDate)
        SELECT 	tmpIt.CookieId
			,	tmpIt.DeviceId
			,	lv_CreatedDate
			,	tmpIt.TransTime            
		FROM Temp_InputTrans AS tmpIt;
    
    ELSE
		INSERT IGNORE INTO FPS_FingerPrint.Device(FirstFingerprintCode, CreatedDate, ModifiedDate)
		SELECT 	tmpIt.FingerprintCode
			,	lv_CreatedDate
			,	tmpIt.TransTime
		FROM Temp_InputTrans AS tmpIt
		WHERE tmpIt.Id = ip_GroupId;	
        
        UPDATE Temp_InputTrans AS tmpIt
			INNER JOIN FPS_FingerPrint.Device AS dv ON dv.FirstFingerprintCode = tmpIt.FingerPrintCode
		SET	tmpIt.DeviceId = dv.Id
        WHERE tmpIt.Id = ip_GroupId;	
        
        SELECT tmpIt.DeviceID
        INTO lv_GroupDeviceId
        FROM Temp_InputTrans AS tmpIt
		WHERE tmpIt.Id = ip_GroupId LIMIT 1;
     
        UPDATE Temp_InputTrans AS tmpIt
        SET tmpIt.DeviceID = tmpIt.DeviceID
        WHERE tmpIt.DeviceId IS NULL;
        
        INSERT IGNORE INTO FPS_FingerPrint.DeviceFingerPrint(FingerPrintCode, DeviceId,  CreatedDate, ModifiedDate)
        SELECT 	tmpIt.FingerprintCode
			,	lv_GroupDeviceId AS DeviceId
			,	lv_CreatedDate
			,	tmpIt.TransTime            
		FROM Temp_InputTrans AS tmpIt
        WHERE tmpIt.Id != ip_GroupId;
        
		INSERT IGNORE INTO FPS_FingerPrint.DeviceCookie(CookieId, DeviceId,  CreatedDate, ModifiedDate)
        SELECT 	tmpIt.CookieId
			,	lv_GroupDeviceId AS DeviceId
			,	lv_CreatedDate
			,	tmpIt.TransTime            
		FROM Temp_InputTrans AS tmpIt
        WHERE tmpIt.Id != ip_GroupId;
        
	END IF;
	SELECT * FROM Temp_InputTrans AS tmpIt	;
	INSERT IGNORE INTO FPS_FingerPrint.TransactionCompleted(Id, RawTransId, TransTime, CustId , SubAccId, LoginName, SubscriberId, FingerPrintCode, CookieId, DeviceId, ClientIP, UserAgent, Url, Action, CreatedDate, TransKey, Flagged)
    SELECT  	ts.Id
			, 	ts.RawTransId
            ,	ts.TransTime
			, 	ts.CustId
			, 	ts.SubAccId
			, 	ts.LoginName
			, 	ts.SubscriberId
			, 	ts.FingerPrintCode
			, 	ts.CookieId
			, 	tmpIt.DeviceId
			, 	ts.ClientIP
			, 	ts.UserAgent
			, 	ts.Url
			, 	ts.Action
			, 	lv_CreatedDate
			, 	ts.TransKey
			, 	ts.Flagged    
	FROM Temp_InputTrans AS tmpIt		
        INNER JOIN Transaction AS ts ON tmpIt.Id = ts.Id;   

    DELETE ts
    FROM FPS_FingerPrint.Transaction AS ts
		INNER JOIN Temp_InputTrans AS tmpIt ON tmpIt.Id = ts.Id;   

END$$
DELIMITER ;
