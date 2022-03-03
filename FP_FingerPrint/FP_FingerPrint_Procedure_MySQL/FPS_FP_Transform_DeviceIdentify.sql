/*<info serverAlias="xxxx" databaseType="2" executers="fpsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `FPS_FP_Transform_DeviceIdentify`;
DELIMITER $$

CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `FPS_FP_Transform_DeviceIdentify`(		
		ip_GroupType	TINYINT
   ,    ip_TransJson	LONGTEXT	
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20220228@Casey.Huynh
		Task :		
		DB:			FPS_FingerPrint
		Original:

		Revisions:
            
		Param's Explanation (filtered by):	
			ip_GroupType: 0- Not a group, 1- Trans Group(the same FingerPrintCode or Cookie);

		Example:
			CALL FPS_FP_Transform_DeviceIdentify(0,'[
						{"Id":3356314495,"Transtime":"2022-02-20 00:00:05.2640","FingerPrintCode":"53b9f5d0e59645d09cfb56690a7b0916","CookieCode": "Cookie01f5d0e59645d09cfb56690a7b0916" ,"GroupId":0},
						{"Id":3356314496,"Transtime":"2022-02-20 00:00:05.2757","FingerPrintCode":"e61bec118a0a44869ea57aec2b57d5a6","CookieCode":"Cookie02f5d0e59645d09cfb56690a7b0916","GroupId":0},
						{"Id":3356314498,"Transtime":"2022-02-20 00:00:05.4575","FingerPrintCode":"1245f5a2122b4f74b9e09c416497f6e6","CookieCode":"Cookie03f5d0e59645d09cfb56690a7b0916","GroupId":0}
					]');
			
            CALL FPS_FP_Transform_DeviceIdentify(1,'[
						{"Id":3356314503,"Transtime":"2022-02-20 00:00:05","FingerPrintCode":"ac918eadfdc1499cb1aade3183f6363f","CookieCode":"Cookie04f5d0e59645d09cfb56690a7b0916","GroupId":3356314503},
						{"Id":3356314519,"Transtime":"2022-02-20 00:00:06.2956","FingerPrintCode":"ac918eadfdc1499cb1aade3183f6363f","CookieCode":"Cookie05f5d0e59645d09cfb56690a7b0916","GroupId":3356314503},
						{"Id":3356314505,"Transtime":"2022-02-20 00:00:05.7028","FingerPrintCode":"66e37de75aad4166ae4dc7270dcd995a","CookieCode":"Cookie06f5d0e59645d09cfb56690a7b0916","GroupId":3356314505},
						{"Id":3356314721,"Transtime":"2022-02-20 00:00:02.8868","FingerPrintCode":"88e37de75aad4166ae4dc7270dcd995a","CookieCode":"Cookie06f5d0e59645d09cfb56690a7b0916","GroupId":3356314505}
					]');
	*/
    
    DECLARE lv_GroupDeviceId BIGINT UNSIGNED;
    DECLARE lv_CreatedDate DATETIME(4);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_InputTrans;
    CREATE TEMPORARY TABLE Temp_InputTrans(
			Id				BIGINT UNSIGNED PRIMARY KEY
		,	Transtime		DATETIME(4)
		,	FingerPrintCode	VARCHAR(64)
        ,	CookieCode		VARCHAR(64)
        ,	DeviceID		BIGINT UNSIGNED
        ,	RecoverType		TINYINT DEFAULT 0	#0 New, 1 By FingerPrintCode, 2 By Cookie
        ,	GroupId			BIGINT UNSIGNED
        
		,	INDEX IX_Temp_InputTrans_FingerPrintCode(FingerPrintCode)
        ,	INDEX IX_Temp_InputTrans_CookieCode(CookieCode)
        ,	INDEX IX_Temp_InputTrans_GroupId(GroupId)
    );    
    
	DROP TEMPORARY TABLE IF EXISTS Temp_GroupDevice;
    CREATE TEMPORARY TABLE Temp_GroupDevice(
			GroupId			BIGINT UNSIGNED PRIMARY KEY
        ,	Id				BIGINT UNSIGNED
		,	Transtime		DATETIME(4)
		,	FingerPrintCode	VARCHAR(64)
        ,	CookieCode		VARCHAR(64)
        ,	DeviceID		BIGINT UNSIGNED
     );

	SET lv_CreatedDate = CURRENT_TIMESTAMP(4);
    
    
    INSERT INTO Temp_InputTrans(Id, Transtime, FingerPrintCode, CookieCode, GroupId)
	SELECT	tmpJs.Id
		,	tmpJs.Transtime
		,	tmpJs.FingerPrintCode
        ,	tmpJs.CookieCode
        ,	tmpJs.GroupId
    FROM JSON_TABLE(
			ip_TransJson,
			 "$[*]" COLUMNS(
								Id				BIGINT UNSIGNED	PATH "$.Id"
							,	Transtime		DATETIME(4)		PATH "$.Transtime"
							,	FingerPrintCode	VARCHAR(64)		PATH "$.FingerPrintCode"
                            ,	CookieCode		VARCHAR(64)		PATH "$.CookieCode"
                            ,	GroupId			BIGINT UNSIGNED	PATH "$.GroupId")
		) AS tmpJs;	

    /*====RECOVER DEVICE: Get Exisitng By FingerPrintCode*/
	UPDATE Temp_InputTrans AS tmpTs
		INNER JOIN FPS_FingerPrint.DeviceFingerPrint AS df ON tmpTs.FingerPrintCode = df.FingerPrintCode
	SET 	tmpTs.RecoverType = 1
		,	tmpTs.DeviceId = df.DeviceId;
        
    /*====RECOVER DEVICE: Get Exisitng By Cookie*/    
    UPDATE Temp_InputTrans AS tmpTs
		INNER JOIN FPS_FingerPrint.DeviceCookie AS dc ON tmpTs.CookieCode = dc.CookieCode
	SET 	tmpTs.RecoverType = tmpTs.RecoverType + 2
		,	tmpTs.DeviceId = dc.DeviceId;
        
    /*====RECOVER DEVICE: PROCESS FOR Group*/
    IF (ip_GroupType != 0) THEN
		
		INSERT IGNORE INTO Temp_GroupDevice(GroupId, DeviceId, Id, TransTime, FingerPrintCode, CookieCode)
        SELECT	tmpIt.GroupId
			,	tmpIt.DeviceId
            ,	tmpIt.Id
            ,	tmpIt.TransTime
            ,	tmpIt.FingerPrintCode
            ,	tmpIt.CookieCode
		FROM Temp_InputTrans AS tmpIt;        
        
		UPDATE Temp_InputTrans AS tmpTs
			INNER JOIN Temp_GroupDevice AS tmpGd ON tmpTs.GroupId = tmpGd.GroupId
		SET tmpTs.DeviceId = tmpGd.DeviceId
        WHERE tmpTs.DeviceId IS NULL;
        
    END IF;
    
     /*====RECOVER DEVICE: Insert New FingerprintCode For Old Device*/     
    INSERT INTO FPS_FingerPrint.DeviceFingerPrint(FingerPrintCode, DeviceId, CreatedDate, ModifiedDate)
    SELECT	tmpIt.FingerPrintCode
		,	tmpIt.DeviceId
		,	lv_CreatedDate
        ,	tmpIt.Transtime
    FROM Temp_InputTrans AS tmpIt
    WHERE tmpIt.RecoverType = 2 
    ON DUPLICATE KEY UPDATE ModifiedDate = tmpIt.Transtime;
    
    /*====RECOVER DEVICE: Insert New Cookie For Old Device*/
    INSERT INTO FPS_FingerPrint.DeviceCookie(CookieCode, DeviceId, CreatedDate, ModifiedDate)
    SELECT	tmpIt.CookieCode
		,	tmpIt.DeviceId
		,	lv_CreatedDate
        ,	tmpIt.Transtime
    FROM Temp_InputTrans AS tmpIt 
    WHERE tmpIt.RecoverType IN (1,3)
    ON DUPLICATE KEY UPDATE ModifiedDate = tmpIt.Transtime;  
    
    /*====RECOVER DEVICE: Update Modified Date Of Old Device*/
    UPDATE FPS_FingerPrint.Device AS dv
		INNER JOIN (SELECT	tmpIt.DeviceId
						,	MAX(tmpIt.Transtime) AS Transtime
					FROM Temp_InputTrans AS tmpIt WHERE tmpIt.DeviceId > 0
                    GROUP BY tmpIt.DeviceId) AS tmpDv ON dv.Id = tmpDv.DeviceId
	SET dv.ModifiedDate = tmpDv.Transtime;
    
    /*====NEW DEVICE */
    IF (ip_GroupType = 0) THEN	

		INSERT IGNORE INTO FPS_FingerPrint.Device(FirstFingerprintCode, CreatedDate, ModifiedDate)
		SELECT 	tmpIt.FingerprintCode
			,	lv_CreatedDate
			,	tmpIt.Transtime
		FROM Temp_InputTrans AS tmpIt
		WHERE tmpIt.DeviceId IS NULL;	
        
		UPDATE Temp_InputTrans AS tmpIt
			INNER JOIN FPS_FingerPrint.Device AS dv ON dv.FirstFingerprintCode = tmpIt.FingerPrintCode
		SET	tmpIt.DeviceId = dv.Id;
        
        INSERT IGNORE INTO FPS_FingerPrint.DeviceFingerPrint(FingerPrintCode, DeviceId,  CreatedDate, ModifiedDate)
        SELECT 	tmpIt.FingerprintCode
			,	tmpIt.DeviceId
			,	lv_CreatedDate
			,	tmpIt.Transtime            
		FROM Temp_InputTrans AS tmpIt;
	
		INSERT IGNORE INTO FPS_FingerPrint.DeviceCookie(CookieCode, DeviceId,  CreatedDate, ModifiedDate)
        SELECT 	tmpIt.CookieCode
			,	tmpIt.DeviceId
			,	lv_CreatedDate
			,	tmpIt.Transtime            
		FROM Temp_InputTrans AS tmpIt;
    
    ELSE		
        
		INSERT IGNORE INTO FPS_FingerPrint.Device(FirstFingerprintCode, CreatedDate, ModifiedDate)
		SELECT 	tmpIt.FingerprintCode
			,	lv_CreatedDate
			,	tmpIt.Transtime AS ModifiedDate
		FROM Temp_GroupDevice AS tmpIt
		WHERE tmpIt.Id = tmpIt.GroupId;	
        
        UPDATE Temp_GroupDevice AS tmpGd
			INNER JOIN FPS_FingerPrint.Device AS dv ON dv.FirstFingerprintCode = tmpGd.FingerPrintCode
        SET  tmpGd.DeviceId = dv.Id;	
        
        UPDATE Temp_InputTrans AS tmpIt
			INNER JOIN Temp_GroupDevice AS tmpGd ON tmpGd.GroupId = tmpIt.GroupId
		SET	tmpIt.DeviceId = tmpGd.DeviceId;        
  
        INSERT INTO FPS_FingerPrint.DeviceFingerPrint(FingerPrintCode, DeviceId,  CreatedDate, ModifiedDate)
        SELECT 	tmpIt.FingerprintCode
			,	tmpIt.DeviceId 
			,	lv_CreatedDate
			,	tmpIt.Transtime AS ModifiedDate        
		FROM Temp_InputTrans AS tmpIt
        WHERE tmpIt.Id != tmpIt.GroupId
        ON DUPLICATE KEY UPDATE ModifiedDate = tmpIt.Transtime; 
        
		INSERT IGNORE INTO FPS_FingerPrint.DeviceCookie(CookieCode, DeviceId,  CreatedDate, ModifiedDate)
        SELECT 	tmpIt.CookieCode
			,	tmpIt.DeviceId AS DeviceId
			,	lv_CreatedDate
			,	tmpIt.Transtime AS ModifiedDate              
		FROM Temp_InputTrans AS tmpIt
        ON DUPLICATE KEY UPDATE ModifiedDate = tmpIt.Transtime; 
        
	END IF;
	
	INSERT IGNORE INTO FPS_FingerPrint.TransactionDevice(Id, RawTransId, Transtime, CustId , SubAccId, LoginName, SubscriberId, FingerPrintCode, CookieCode, DeviceId, ClientIP, UserAgent, Url, Action, CreatedDate, TransKey, Flagged)
    SELECT  	ts.Id
			, 	ts.RawTransId
            ,	ts.Transtime
			, 	ts.CustId
			, 	ts.SubAccId
			, 	ts.LoginName
			, 	ts.SubscriberId
			, 	ts.FingerPrintCode
			, 	ts.CookieCode
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
