/*<info serverAlias="FPSDC-FPS_FingerPrint" databaseType="2" executers="fpsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `FPS_FP_Transform_DeviceIdentify`;
DELIMITER $$

CREATE DEFINER=`fpsOwner`@`%` PROCEDURE `FPS_FP_Transform_DeviceIdentify`(		
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
			- 20220307@Terry.Nguyen: Created [Redmine ID: #162668]
            
		Param's Explanation (filtered by):	
			ip_GroupType: 0- Not a group, 1- Trans Group(the same FingerPrintCode or Cookie);

		Example:
			CALL FPS_FP_Transform_DeviceIdentify(0,'[
						{"Id":3356314495,"TransTime":"2022-02-20 00:00:05.2640","FingerPrintCode":"53b9f5d0e59645d09cfb56690a7b0916","CookieCode": "Cookie01f5d0e59645d09cfb56690a7b0916" ,"GroupId":0},
						{"Id":3356314496,"TransTime":"2022-02-20 00:00:05.2757","FingerPrintCode":"e61bec118a0a44869ea57aec2b57d5a6","CookieCode":"Cookie02f5d0e59645d09cfb56690a7b0916","GroupId":0},
						{"Id":3356314498,"TransTime":"2022-02-20 00:00:05.4575","FingerPrintCode":"1245f5a2122b4f74b9e09c416497f6e6","CookieCode":"Cookie03f5d0e59645d09cfb56690a7b0916","GroupId":0}
					]');
			
            CALL FPS_FP_Transform_DeviceIdentify(1,'[
						{"Id":3356314503,"TransTime":"2022-02-20 00:00:05","FingerPrintCode":"ac918eadfdc1499cb1aade3183f6363f","CookieCode":"Cookie04f5d0e59645d09cfb56690a7b0916","GroupId":3356314503},
						{"Id":3356314519,"TransTime":"2022-02-20 00:00:06.2956","FingerPrintCode":"ac918eadfdc1499cb1aade3183f6363f","CookieCode":"Cookie05f5d0e59645d09cfb56690a7b0916","GroupId":3356314503},
						{"Id":3356314505,"TransTime":"2022-02-20 00:00:05.7028","FingerPrintCode":"66e37de75aad4166ae4dc7270dcd995a","CookieCode":"Cookie06f5d0e59645d09cfb56690a7b0916","GroupId":3356314505},
						{"Id":3356314721,"TransTime":"2022-02-20 00:00:02.8868","FingerPrintCode":"88e37de75aad4166ae4dc7270dcd995a","CookieCode":"Cookie06f5d0e59645d09cfb56690a7b0916","GroupId":3356314505}
					]');
	*/
    
    DECLARE lv_GroupDeviceId	BIGINT UNSIGNED;
    DECLARE lv_CreatedDate		DATETIME(4);
    
	/*******LOG TEST********************/
    INSERT INTO FPS_FingerPrint.Test_LOG(SpName, JsonString, OtherText, InsertTime)
    SELECT 'FPS_FP_Transform_DeviceIdentify', ip_TransJson,CONCAT('ip_GroupType:',ip_GroupType), CURRENT_TIMESTAMP();
    /*******LOG TEST********************/
    
    DROP TEMPORARY TABLE IF EXISTS Temp_InputTrans;
    CREATE TEMPORARY TABLE Temp_InputTrans(
			Id				BIGINT UNSIGNED PRIMARY KEY
		,	TransTime		DATETIME(4)
		,	FingerPrintCode	VARCHAR(64)
        ,	CookieCode		VARCHAR(64)
        ,	DeviceId		BIGINT UNSIGNED
        ,	RecoverType		TINYINT DEFAULT 0	#0 New, 1 By FingerPrintCode, 2 By Cookie
        ,	GroupId			BIGINT UNSIGNED
        
		,	INDEX IX_Temp_InputTrans_FingerPrintCode(FingerPrintCode)
        ,	INDEX IX_Temp_InputTrans_CookieCode(CookieCode)
        ,	INDEX IX_Temp_InputTrans_GroupId(GroupId)
    );    
    
    DROP TEMPORARY TABLE IF EXISTS Temp_TransDevice;
    CREATE TEMPORARY TABLE Temp_TransDevice(
			Id				BIGINT UNSIGNED PRIMARY KEY
		,	TransTime		DATETIME(4)
		,	FingerPrintCode	VARCHAR(64)
        ,	CookieCode		VARCHAR(64)
        ,	DeviceId		BIGINT UNSIGNED
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
		,	TransTime		DATETIME(4)
		,	FingerPrintCode	VARCHAR(64)
        ,	CookieCode		VARCHAR(64)
        ,	DeviceId		BIGINT UNSIGNED
     );
     
     DROP TEMPORARY TABLE IF EXISTS Temp_ExistingFingerPrintCode;
     CREATE TEMPORARY TABLE Temp_ExistingFingerPrintCode(
        	Id				BIGINT UNSIGNED PRIMARY KEY
		,   DeviceId		BIGINT UNSIGNED
     );
     
     DROP TEMPORARY TABLE IF EXISTS Temp_ExistingCookieCode;
     CREATE TEMPORARY TABLE Temp_ExistingCookieCode(
        	Id				BIGINT UNSIGNED PRIMARY KEY
        ,   DeviceId		BIGINT UNSIGNED
     );     

	SET lv_CreatedDate = CURRENT_TIMESTAMP(4);    

    INSERT INTO Temp_InputTrans(Id, TransTime, FingerPrintCode, CookieCode, GroupId)
	SELECT	tmpJs.Id
		,	tmpJs.TransTime
		,	tmpJs.FingerPrintCode
        ,	tmpJs.CookieCode
        ,	tmpJs.GroupId
    FROM JSON_TABLE(
			ip_TransJson,
			 "$[*]" COLUMNS(
								Id				BIGINT UNSIGNED	PATH "$.Id"
							,	TransTime		DATETIME(4)		PATH "$.TransTime"
							,	FingerPrintCode	VARCHAR(64)		PATH "$.FingerPrintCode"
                            ,	CookieCode		VARCHAR(64)		PATH "$.CookieCode"
                            ,	GroupId			BIGINT UNSIGNED	PATH "$.GroupId")
		) AS tmpJs;	

    /*====RECOVER DEVICE: Get Exisitng By FingerPrintCode*/

	INSERT INTO Temp_ExistingFingerPrintCode(Id, DeviceId)
    SELECT	tmpTs.Id
		,	df.DeviceId
    FROM Temp_InputTrans AS tmpTs
		INNER JOIN FPS_FingerPrint.DeviceFingerPrint AS df ON tmpTs.FingerPrintCode = df.FingerPrintCode;

    UPDATE Temp_InputTrans AS tmpTs
		INNER JOIN Temp_ExistingFingerPrintCode AS tmpEf ON tmpTs.Id = tmpEf.Id
	SET 	tmpTs.RecoverType = 1
		,	tmpTs.DeviceId = tmpEf.DeviceId;
    
    /*====RECOVER DEVICE: Get Exisitng By Cookie*/    
	INSERT INTO Temp_ExistingCookieCode(Id, DeviceId)
    SELECT	tmpTs.Id
		,	dc.DeviceId
    FROM Temp_InputTrans AS tmpTs
		INNER JOIN FPS_FingerPrint.DeviceCookie AS dc ON tmpTs.CookieCode = dc.CookieCode;
    
    UPDATE Temp_InputTrans AS tmpTs
		INNER JOIN Temp_ExistingCookieCode AS tmpEc ON tmpTs.Id = tmpEc.Id
	SET 	tmpTs.RecoverType = tmpTs.RecoverType + 2
		,	tmpTs.DeviceId = tmpEc.DeviceId;
    
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
    INSERT IGNORE INTO FPS_FingerPrint.DeviceFingerPrint(FingerPrintCode, DeviceId, CreatedDate, ModifiedDate)
    SELECT	tmpIt.FingerPrintCode
		,	tmpIt.DeviceId
		,	lv_CreatedDate
        ,	tmpIt.TransTime
    FROM Temp_InputTrans AS tmpIt
    WHERE tmpIt.RecoverType = 2;
    
    /*====RECOVER DEVICE: Insert New Cookie For Old Device*/
    INSERT IGNORE INTO FPS_FingerPrint.DeviceCookie(CookieCode, DeviceId, CreatedDate, ModifiedDate)
    SELECT	tmpIt.CookieCode
		,	tmpIt.DeviceId
		,	lv_CreatedDate
        ,	tmpIt.TransTime
    FROM Temp_InputTrans AS tmpIt 
    WHERE tmpIt.RecoverType = 1;  
    
    /*====RECOVER DEVICE: Update Modified Date Of Old Device*/
    UPDATE FPS_FingerPrint.Device AS dv
		INNER JOIN (SELECT	tmpIt.DeviceId
						,	MAX(tmpIt.TransTime) AS TransTime
					FROM Temp_InputTrans AS tmpIt WHERE tmpIt.DeviceId > 0
                    GROUP BY tmpIt.DeviceId) AS tmpDv ON dv.Id = tmpDv.DeviceId
	SET dv.ModifiedDate = tmpDv.TransTime;
    
    /*====NEW DEVICE */
    IF (ip_GroupType = 0) THEN	

		INSERT IGNORE INTO FPS_FingerPrint.Device(FirstFingerprintCode, CreatedDate, ModifiedDate)
		SELECT 	tmpIt.FingerprintCode
			,	lv_CreatedDate
			,	tmpIt.TransTime
		FROM Temp_InputTrans AS tmpIt
		WHERE tmpIt.DeviceId IS NULL;	
    
        INSERT INTO Temp_TransDevice(Id, TransTime, FingerPrintCode, CookieCode, DeviceId, RecoverType, GroupId)
        SELECT	tmpIt.Id
			,	tmpIt.TransTime
            ,	tmpIt.FingerPrintCode
            ,	tmpIt.CookieCode
            ,	dv.Id
            ,	tmpIt.RecoverType
            ,	tmpIt.GroupId
		FROM Temp_InputTrans AS tmpIt
			INNER JOIN FPS_FingerPrint.Device AS dv ON dv.FirstFingerprintCode = tmpIt.FingerPrintCode;
        
        INSERT IGNORE INTO FPS_FingerPrint.DeviceFingerPrint(FingerPrintCode, DeviceId,  CreatedDate, ModifiedDate)
        SELECT 	tmpTd.FingerprintCode
			,	tmpTd.DeviceId
			,	lv_CreatedDate
			,	tmpTd.TransTime            
		FROM Temp_TransDevice AS tmpTd;
	
		INSERT IGNORE INTO FPS_FingerPrint.DeviceCookie(CookieCode, DeviceId,  CreatedDate, ModifiedDate)
        SELECT 	tmpTd.CookieCode
			,	tmpTd.DeviceId
			,	lv_CreatedDate
			,	tmpTd.TransTime            
		FROM Temp_TransDevice AS tmpTd;
    
    ELSE		
        
		INSERT IGNORE INTO FPS_FingerPrint.Device(FirstFingerprintCode, CreatedDate, ModifiedDate)
		SELECT 	tmpIt.FingerprintCode
			,	lv_CreatedDate
			,	tmpIt.TransTime AS ModifiedDate
		FROM Temp_GroupDevice AS tmpIt
		WHERE tmpIt.Id = tmpIt.GroupId;	
        
		INSERT INTO Temp_TransDevice(Id, TransTime, FingerPrintCode, CookieCode, DeviceId, RecoverType, GroupId)
        SELECT	tmpIt.Id
			,	tmpIt.TransTime
            ,	tmpIt.FingerPrintCode
            ,	tmpIt.CookieCode
            ,	dv.Id
            ,	tmpIt.RecoverType
            ,	tmpIt.GroupId
		FROM Temp_InputTrans AS tmpIt
			INNER JOIN Temp_GroupDevice AS tmpGd ON tmpGd.GroupId = tmpIt.GroupId
			INNER JOIN FPS_FingerPrint.Device AS dv ON dv.FirstFingerprintCode = tmpGd.FingerPrintCode;            
  
        INSERT IGNORE INTO FPS_FingerPrint.DeviceFingerPrint(FingerPrintCode, DeviceId,  CreatedDate, ModifiedDate)
        SELECT 	tmpTd.FingerprintCode
			,	tmpTd.DeviceId 
			,	lv_CreatedDate
			,	tmpTd.TransTime AS ModifiedDate        
		FROM Temp_TransDevice AS tmpTd
        WHERE tmpTd.Id != tmpTd.GroupId; 
        
		INSERT IGNORE INTO FPS_FingerPrint.DeviceCookie(CookieCode, DeviceId,  CreatedDate, ModifiedDate)
        SELECT 	tmpTd.CookieCode
			,	tmpTd.DeviceId AS DeviceId
			,	lv_CreatedDate
			,	tmpTd.TransTime AS ModifiedDate              
		FROM Temp_TransDevice AS tmpTd
        WHERE tmpTd.Id != tmpTd.GroupId;  
        
	END IF;
    
    /****UPDATE ModifiedDate*****/
    UPDATE FPS_FingerPrint.Device AS dv
		INNER JOIN(	SELECT	tmpTd.DeviceId
						,	MAX(tmpTd.TransTime) AS MaxTransTime
					FROM Temp_TransDevice AS tmpTd
                    GROUP BY tmpTd.DeviceId
                    HAVING COUNT(1) > 1) AS tmpGd ON tmpGd.DeviceId = dv.Id
	SET dv.ModifiedDate = tmpGd.MaxTransTime;
    
    UPDATE FPS_FingerPrint.DeviceFingerPrint AS dv
		INNER JOIN(	SELECT	tmpTd.FingerPrintCode
						,	MAX(tmpTd.TransTime) AS MaxTransTime
					FROM Temp_TransDevice AS tmpTd
                    GROUP BY tmpTd.FingerPrintCode
                    HAVING COUNT(1) > 1) AS tmpGd ON tmpGd.FingerPrintCode = dv.FingerPrintCode
	SET dv.ModifiedDate = tmpGd.MaxTransTime;
    
    UPDATE FPS_FingerPrint.DeviceCookie AS dv
		INNER JOIN(	SELECT	tmpTd.CookieCode
						,	MAX(tmpTd.TransTime) AS MaxTransTime
					FROM Temp_TransDevice AS tmpTd
                    GROUP BY tmpTd.CookieCode
                    HAVING COUNT(1) > 1) AS tmpGd ON tmpGd.CookieCode = dv.CookieCode
	SET dv.ModifiedDate = tmpGd.MaxTransTime;
    
	/*****UPDATE Trans******************/
	INSERT IGNORE INTO FPS_FingerPrint.TransactionDevice(ServerTransId, TransTime, CustId , SubAccId, LoginName, SubscriberId, FingerPrintCode, CookieCode, DeviceId, ClientIP, UserAgent, Url, Action, CreatedDate, TransKey, Flagged)
    SELECT  	ts.ServerTransId
            ,	ts.TransTime
			, 	ts.CustId
			, 	ts.SubAccId
			, 	ts.LoginName
			, 	ts.SubscriberId
			, 	ts.FingerPrintCode
			, 	ts.CookieCode
			, 	tmpTd.DeviceId
			, 	ts.ClientIP
			, 	ts.UserAgent
			, 	ts.Url
			, 	ts.Action
			, 	lv_CreatedDate
			, 	ts.TransKey
			, 	ts.Flagged    
	FROM Temp_InputTrans AS tmpIt 
		LEFT JOIN Temp_TransDevice AS tmpTd	ON tmpIt.Id = tmpTd.Id
        INNER JOIN Transaction AS ts ON tmpIt.Id = ts.Id;   
	
    DELETE ts
    FROM FPS_FingerPrint.Transaction AS ts
		INNER JOIN Temp_InputTrans AS tmpIt ON tmpIt.Id = ts.Id; 

END$$
DELIMITER ;
