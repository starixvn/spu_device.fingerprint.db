/*<info serverAlias="FPSDC-FPS_FingerPrint" databaseType="2" executers="fpsService" isFunction="0" isNested="0"></info>*/
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
			ip_GroupType: 0- Not a group, 1- Trans Group(the same RawFingerPrintId or Cookie);

		Example:
			CALL FPS_FP_Transform_DeviceIdentify(0,'[
						{"Id":3356314495,"TransTime":"2022-02-20 00:00:05.2640","RawFingerPrintId":1,"CookieId":1 ,"GroupId":0},
						{"Id":3356314496,"TransTime":"2022-02-20 00:00:05.2757","RawFingerPrintId":2,"CookieId":1,"GroupId":0},
						{"Id":3356314498,"TransTime":"2022-02-20 00:00:05.4575","RawFingerPrintId":3,"CookieId":1,"GroupId":0}
					]');
			
            CALL FPS_FP_Transform_DeviceIdentify(1,'[
						{"Id":3356314503,"TransTime":"2022-02-20 00:00:05","RawFingerPrintId":1,"CookieId":1,"GroupId":3356314503},
						{"Id":3356314519,"TransTime":"2022-02-20 00:00:06.2956","RawFingerPrintId":1,"CookieId":1,"GroupId":3356314503},
						{"Id":3356314505,"TransTime":"2022-02-20 00:00:05.7028","RawFingerPrintId":2,"CookieId":2,"GroupId":3356314505},
						{"Id":3356314721,"TransTime":"2022-02-20 00:00:02.8868","RawFingerPrintId":3,"CookieId":3,"GroupId":3356314505}
					]');
	*/
    
    DECLARE lv_GroupDeviceId	BIGINT UNSIGNED;
    DECLARE lv_CreatedDate		DATETIME(4);
    
	/*******LOG TEST********************/
    IF (SELECT ofs.OffsetValue FROM FPS_FingerPrint.Offset AS ofs WHERE Id = 7) = 1 THEN		
		INSERT INTO CTS_Log.FPSLog(SpName, JsonString, OtherText, InsertTime)
		SELECT 'FPS_FP_Transform_DeviceIdentify', ip_TransJson,CONCAT('ip_GroupType:',ip_GroupType), CURRENT_TIMESTAMP();
	END IF;
    /*******LOG TEST********************/
    
    DROP TEMPORARY TABLE IF EXISTS Temp_InputTrans;
    CREATE TEMPORARY TABLE Temp_InputTrans(
			Id					BIGINT UNSIGNED PRIMARY KEY
		,	TransTime			DATETIME(4)
		,	RawFingerPrintId	BIGINT UNSIGNED
        ,	CookieId			BIGINT UNSIGNED
        ,	DeviceId			BIGINT UNSIGNED
        ,	RecoverType			TINYINT DEFAULT 0	#0 New, 1 By RawFingerPrintId, 2 By Cookie
        ,	GroupId				BIGINT UNSIGNED
        
		,	INDEX IX_Temp_InputTrans_RawFingerPrintId(RawFingerPrintId)
        ,	INDEX IX_Temp_InputTrans_CookieId(CookieId)
        ,	INDEX IX_Temp_InputTrans_GroupId(GroupId)
    );    
    
    DROP TEMPORARY TABLE IF EXISTS Temp_TransDevice;
    CREATE TEMPORARY TABLE Temp_TransDevice(
			Id					BIGINT UNSIGNED PRIMARY KEY
		,	TransTime			DATETIME(4)
		,	RawFingerPrintId	BIGINT UNSIGNED
        ,	CookieId			BIGINT UNSIGNED
        ,	DeviceId			BIGINT UNSIGNED
        ,	RecoverType			TINYINT DEFAULT 0	#0 New, 1 By RawFingerPrintId, 2 By Cookie
        ,	GroupId				BIGINT UNSIGNED
        
		,	INDEX IX_Temp_TransDevice_RawFingerPrintId(RawFingerPrintId)
        ,	INDEX IX_Temp_TransDevice_CookieId(CookieId)
        ,	INDEX IX_Temp_TransDevice_GroupId(GroupId)
    );  
    
	DROP TEMPORARY TABLE IF EXISTS Temp_GroupDevice;
    CREATE TEMPORARY TABLE Temp_GroupDevice(
			GroupId				BIGINT UNSIGNED PRIMARY KEY
        ,	Id					BIGINT UNSIGNED
		,	TransTime			DATETIME(4)
		,	RawFingerPrintId	BIGINT UNSIGNED
        ,	CookieId			BIGINT UNSIGNED
        ,	DeviceId			BIGINT UNSIGNED
     );
     
     DROP TEMPORARY TABLE IF EXISTS Temp_ExistingRawFingerPrintId;
     CREATE TEMPORARY TABLE Temp_ExistingRawFingerPrintId(
        	Id				BIGINT UNSIGNED PRIMARY KEY
		,   DeviceId		BIGINT UNSIGNED
     );
     
     DROP TEMPORARY TABLE IF EXISTS Temp_ExistingCookieId;
     CREATE TEMPORARY TABLE Temp_ExistingCookieId(
        	Id				BIGINT UNSIGNED PRIMARY KEY
        ,   DeviceId		BIGINT UNSIGNED
     );     

	SET lv_CreatedDate = CURRENT_TIMESTAMP(4);    

    INSERT INTO Temp_InputTrans(Id, TransTime, RawFingerPrintId, CookieId, GroupId)
	SELECT	tmpJs.Id
		,	tmpJs.TransTime
		,	tmpJs.RawFingerPrintId
        ,	tmpJs.CookieId
        ,	tmpJs.GroupId
    FROM JSON_TABLE(
			ip_TransJson,
			 "$[*]" COLUMNS(
								Id					BIGINT UNSIGNED	PATH "$.Id"
							,	TransTime			DATETIME(4)		PATH "$.TransTime"
							,	RawFingerPrintId	VARCHAR(64)		PATH "$.RawFingerPrintId"
                            ,	CookieId			BIGINT UNSIGNED	PATH "$.CookieId"
                            ,	GroupId				BIGINT UNSIGNED	PATH "$.GroupId"
						)
		) AS tmpJs;	

    /*====RECOVER DEVICE: Get Exisitng By RawFingerPrintId*/

	INSERT INTO Temp_ExistingRawFingerPrintId(Id, DeviceId)
    SELECT	tmpTs.Id
		,	df.DeviceId
    FROM Temp_InputTrans AS tmpTs
		INNER JOIN FPS_FingerPrint.DeviceFingerPrint AS df ON tmpTs.RawFingerPrintId = df.RawFingerPrintId;

    UPDATE Temp_InputTrans AS tmpTs
		INNER JOIN Temp_ExistingRawFingerPrintId AS tmpEf ON tmpTs.Id = tmpEf.Id
	SET 	tmpTs.RecoverType = 1
		,	tmpTs.DeviceId = tmpEf.DeviceId;
    
    /*====RECOVER DEVICE: Get Exisitng By Cookie*/    
	INSERT INTO Temp_ExistingCookieId(Id, DeviceId)
    SELECT	tmpTs.Id
		,	dc.DeviceId
    FROM Temp_InputTrans AS tmpTs
		INNER JOIN FPS_FingerPrint.DeviceCookie AS dc ON tmpTs.CookieId = dc.CookieId;
    
    UPDATE Temp_InputTrans AS tmpTs
		INNER JOIN Temp_ExistingCookieId AS tmpEc ON tmpTs.Id = tmpEc.Id
	SET 	tmpTs.RecoverType = tmpTs.RecoverType + 2
		,	tmpTs.DeviceId = tmpEc.DeviceId;
    
    /*====RECOVER DEVICE: PROCESS FOR Group*/
    IF (ip_GroupType != 0) THEN
		
		INSERT IGNORE INTO Temp_GroupDevice(GroupId, DeviceId, Id, TransTime, RawFingerPrintId, CookieId)
        SELECT	tmpIt.GroupId
			,	tmpIt.DeviceId
            ,	tmpIt.Id
            ,	tmpIt.TransTime
            ,	tmpIt.RawFingerPrintId
            ,	tmpIt.CookieId
		FROM Temp_InputTrans AS tmpIt;        
        
		UPDATE Temp_InputTrans AS tmpTs
			INNER JOIN Temp_GroupDevice AS tmpGd ON tmpTs.GroupId = tmpGd.GroupId
		SET tmpTs.DeviceId = tmpGd.DeviceId
        WHERE tmpTs.DeviceId IS NULL;
        
    END IF;
    
     /*====RECOVER DEVICE: Insert New RawFingerPrintId For Old Device*/     
    INSERT IGNORE INTO FPS_FingerPrint.DeviceFingerPrint(RawFingerPrintId, DeviceId, CreatedDate, ModifiedDate)
    SELECT	tmpIt.RawFingerPrintId
		,	tmpIt.DeviceId
		,	lv_CreatedDate
        ,	tmpIt.TransTime
    FROM Temp_InputTrans AS tmpIt
    WHERE tmpIt.RecoverType = 2;
    
    /*====RECOVER DEVICE: Insert New Cookie For Old Device*/
    INSERT IGNORE INTO FPS_FingerPrint.DeviceCookie(CookieId, DeviceId, CreatedDate, ModifiedDate)
    SELECT	tmpIt.CookieId
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

		INSERT IGNORE INTO FPS_FingerPrint.Device(FirstRawFingerPrintId, CreatedDate, ModifiedDate)
		SELECT 	tmpIt.RawFingerPrintId
			,	lv_CreatedDate
			,	tmpIt.TransTime
		FROM Temp_InputTrans AS tmpIt
		WHERE tmpIt.DeviceId IS NULL;	
    
        INSERT INTO Temp_TransDevice(Id, TransTime, RawFingerPrintId, CookieId, DeviceId, RecoverType, GroupId)
        SELECT	tmpIt.Id
			,	tmpIt.TransTime
            ,	tmpIt.RawFingerPrintId
            ,	tmpIt.CookieId
            ,	dv.Id
            ,	tmpIt.RecoverType
            ,	tmpIt.GroupId
		FROM Temp_InputTrans AS tmpIt
			INNER JOIN FPS_FingerPrint.Device AS dv ON dv.FirstRawFingerPrintId = tmpIt.RawFingerPrintId;
        
        INSERT IGNORE INTO FPS_FingerPrint.DeviceFingerPrint(RawFingerPrintId, DeviceId,  CreatedDate, ModifiedDate)
        SELECT 	tmpTd.RawFingerPrintId
			,	tmpTd.DeviceId
			,	lv_CreatedDate
			,	tmpTd.TransTime            
		FROM Temp_TransDevice AS tmpTd;
	
		INSERT IGNORE INTO FPS_FingerPrint.DeviceCookie(CookieId, DeviceId,  CreatedDate, ModifiedDate)
        SELECT 	tmpTd.CookieId
			,	tmpTd.DeviceId
			,	lv_CreatedDate
			,	tmpTd.TransTime            
		FROM Temp_TransDevice AS tmpTd;
    
    ELSE		
        
		INSERT IGNORE INTO FPS_FingerPrint.Device(FirstRawFingerPrintId, CreatedDate, ModifiedDate)
		SELECT 	tmpIt.RawFingerPrintId
			,	lv_CreatedDate
			,	tmpIt.TransTime AS ModifiedDate
		FROM Temp_GroupDevice AS tmpIt
		WHERE tmpIt.Id = tmpIt.GroupId;	
        
		INSERT INTO Temp_TransDevice(Id, TransTime, RawFingerPrintId, CookieId, DeviceId, RecoverType, GroupId)
        SELECT	tmpIt.Id
			,	tmpIt.TransTime
            ,	tmpIt.RawFingerPrintId
            ,	tmpIt.CookieId
            ,	dv.Id
            ,	tmpIt.RecoverType
            ,	tmpIt.GroupId
		FROM Temp_InputTrans AS tmpIt
			INNER JOIN Temp_GroupDevice AS tmpGd ON tmpGd.GroupId = tmpIt.GroupId
			INNER JOIN FPS_FingerPrint.Device AS dv ON dv.FirstRawFingerPrintId = tmpGd.RawFingerPrintId;            
  
        INSERT IGNORE INTO FPS_FingerPrint.DeviceFingerPrint(RawFingerPrintId, DeviceId,  CreatedDate, ModifiedDate)
        SELECT 	tmpTd.RawFingerPrintId
			,	tmpTd.DeviceId 
			,	lv_CreatedDate
			,	tmpTd.TransTime AS ModifiedDate        
		FROM Temp_TransDevice AS tmpTd
        WHERE tmpTd.Id != tmpTd.GroupId; 
        
		INSERT IGNORE INTO FPS_FingerPrint.DeviceCookie(CookieId, DeviceId,  CreatedDate, ModifiedDate)
        SELECT 	tmpTd.CookieId
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
		INNER JOIN(	SELECT	tmpTd.RawFingerPrintId
						,	MAX(tmpTd.TransTime) AS MaxTransTime
					FROM Temp_TransDevice AS tmpTd
                    GROUP BY tmpTd.RawFingerPrintId
                    HAVING COUNT(1) > 1) AS tmpGd ON tmpGd.RawFingerPrintId = dv.RawFingerPrintId
	SET dv.ModifiedDate = tmpGd.MaxTransTime;
    
    UPDATE FPS_FingerPrint.DeviceCookie AS dv
		INNER JOIN(	SELECT	tmpTd.CookieId
						,	MAX(tmpTd.TransTime) AS MaxTransTime
					FROM Temp_TransDevice AS tmpTd
                    GROUP BY tmpTd.CookieId
                    HAVING COUNT(1) > 1) AS tmpGd ON tmpGd.CookieId = dv.CookieId
	SET dv.ModifiedDate = tmpGd.MaxTransTime;
    
	/*****UPDATE Trans******************/
	UPDATE Temp_InputTrans AS tmpIt
		INNER JOIN Temp_TransDevice AS tmpTd ON tmpIt.Id = tmpTd.Id
	SET tmpIt.DeviceId = tmpTd.DeviceId
	WHERE tmpIt.DeviceId IS NULL;      
    
	INSERT IGNORE INTO FPS_FingerPrint.TransactionDevice(ServerTransId, TransTime, CustId , SubAccId, LoginName, SubscriberId, RawFingerPrintId, CookieId, DeviceId, ClientIP, UserAgentId, Url, Action, CreatedDate, TransKey, Flagged)
    SELECT  	ts.ServerTransId
            ,	ts.TransTime
			, 	ts.CustId
			, 	ts.SubAccId
			, 	ts.LoginName
			, 	ts.SubscriberId
			, 	ts.RawFingerPrintId
			, 	ts.CookieId
			, 	tmpIt.DeviceId
			, 	ts.ClientIP
			, 	ts.UserAgentId
			, 	ts.Url
			, 	ts.Action
			, 	lv_CreatedDate
			, 	ts.TransKey
			, 	ts.Flagged    
	FROM Temp_InputTrans AS tmpIt 
		INNER JOIN FPS_FingerPrint.Transaction AS ts ON tmpIt.Id = ts.Id;   
	
    DELETE ts
    FROM FPS_FingerPrint.Transaction AS ts
		INNER JOIN Temp_InputTrans AS tmpIt ON tmpIt.Id = ts.Id; 

END$$
DELIMITER ;
