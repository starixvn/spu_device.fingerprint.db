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
            - 20220808@Jonathan.Doan: Add AddonId [Redmine ID: #175155]
            - 20221025@Jonathan.Doan: Monitor RecoverDailySum [Redmine ID: #179362]
			- 20221123@Jonathan.Doan: Remove field SeverTransId, ClientTransId, AddonId [Redmine ID: #180406]
            
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
    DECLARE lv_countTrans 		INT DEFAULT 0;
    
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
        ,	AccountId			BIGINT UNSIGNED
        ,	SubscriberId		BIGINT UNSIGNED
        ,	LoginName			VARCHAR(100)
        ,	UserAgentId			BIGINT UNSIGNED

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

    DROP TEMPORARY TABLE IF EXISTS Temp_TransNoDevice;
    CREATE TEMPORARY TABLE Temp_TransNoDevice(
			Id					BIGINT UNSIGNED PRIMARY KEY
		,	RawFingerPrintId	BIGINT UNSIGNED
        ,	CookieId			BIGINT UNSIGNED
        ,	DeviceId			BIGINT UNSIGNED
        ,	RecoverType			TINYINT DEFAULT 0	#0 New, 1 By RawFingerPrintId, 2 By Cookie
        ,	GroupId				BIGINT UNSIGNED

        ,	INDEX IX_Temp_TransNoDevice_RecoverType(RecoverType)
    );  

	DROP TEMPORARY TABLE IF EXISTS Temp_GroupDevice;
    CREATE TEMPORARY TABLE Temp_GroupDevice(
			GroupId				BIGINT UNSIGNED PRIMARY KEY
        ,	Id					BIGINT UNSIGNED
		,	TransTime			DATETIME(4)
		,	RawFingerPrintId	BIGINT UNSIGNED
        ,	CookieId			BIGINT UNSIGNED
        ,	DeviceId			BIGINT UNSIGNED
        ,	RecoverType			TINYINT DEFAULT 0
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

    INSERT INTO Temp_InputTrans(Id, TransTime, RawFingerPrintId, CookieId, AccountId, SubscriberId, LoginName, UserAgentId, GroupId)
	SELECT	tmpJs.Id
		,	tmpJs.TransTime
		,	tmpJs.RawFingerPrintId
        ,	tmpJs.CookieId
        ,	tmpJs.AccountId
        ,	tmpJs.SubscriberId
        ,	tmpJs.LoginName
        ,	tmpJs.UserAgentId
        ,	tmpJs.GroupId
    FROM JSON_TABLE(
			ip_TransJson,
			 "$[*]" COLUMNS(
								Id					BIGINT UNSIGNED	PATH "$.Id"
							,	TransTime			DATETIME(4)		PATH "$.TransTime"
							,	RawFingerPrintId	VARCHAR(64)		PATH "$.RawFingerPrintId"
                            ,	AccountId			BIGINT UNSIGNED	PATH "$.AccountId"
                            ,	CookieId			BIGINT UNSIGNED	PATH "$.CookieId"
                            ,	SubscriberId		BIGINT UNSIGNED	PATH "$.SubscriberId"
                            ,	LoginName			VARCHAR(100) 	PATH "$.LoginName"
                            ,	UserAgentId			BIGINT UNSIGNED	PATH "$.UserAgentId"
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
		
		INSERT IGNORE INTO Temp_GroupDevice(GroupId, DeviceId, Id, TransTime, RawFingerPrintId, CookieId, RecoverType)
        SELECT	tmpIt.GroupId
			,	tmpIt.DeviceId
            ,	tmpIt.Id
            ,	tmpIt.TransTime
            ,	tmpIt.RawFingerPrintId
            ,	tmpIt.CookieId
            ,	tmpIt.RecoverType
		FROM Temp_InputTrans AS tmpIt;

		UPDATE Temp_InputTrans AS tmpTs
			INNER JOIN Temp_GroupDevice AS tmpGd ON tmpTs.GroupId = tmpGd.GroupId
		SET tmpTs.DeviceId = tmpGd.DeviceId,
			tmpTs.RecoverType = tmpGd.RecoverType
        WHERE tmpTs.DeviceId IS NULL;

    END IF;

     /*====RECOVER DEVICE: Insert New RawFingerPrintId For Old Device*/     
    INSERT IGNORE INTO FPS_FingerPrint.DeviceFingerPrint(RawFingerPrintId, DeviceId, CreatedDate)
	WITH cte (RawFingerPrintId, DeviceId) AS
	(
		SELECT 	DISTINCT
				tmpIt.RawFingerPrintId
			,	tmpIt.DeviceId
		FROM Temp_InputTrans AS tmpIt
        WHERE tmpIt.RecoverType = 2
	)
	SELECT 	cte.RawFingerPrintId
		,	cte.DeviceId
		,	lv_CreatedDate
	FROM cte
    WHERE NOT EXISTS (SELECT 1 FROM FPS_FingerPrint.DeviceFingerPrint df WHERE df.RawFingerPrintId = cte.RawFingerPrintId);

    /*====RECOVER DEVICE: Insert New Cookie For Old Device*/
    INSERT IGNORE INTO FPS_FingerPrint.DeviceCookie(CookieId, DeviceId, CreatedDate)
	WITH cte (CookieId, DeviceId) AS
	(
		SELECT 	DISTINCT
				tmpIt.CookieId
			,	tmpIt.DeviceId
		FROM Temp_InputTrans AS tmpIt
		WHERE tmpIt.RecoverType = 1
	)
	SELECT 	cte.CookieId
		,	cte.DeviceId
		,	lv_CreatedDate
	FROM cte
    WHERE NOT EXISTS (SELECT 1 FROM FPS_FingerPrint.DeviceCookie dc WHERE dc.CookieId = cte.CookieId);

    /*====NEW DEVICE */
    IF (ip_GroupType = 0) THEN	

		INSERT IGNORE INTO FPS_FingerPrint.Device(FirstRawFingerPrintId, CreatedDate)
		WITH cte (RawFingerPrintId) AS
		(
			SELECT 	DISTINCT
					tmpIt.RawFingerPrintId
			FROM Temp_InputTrans AS tmpIt
			WHERE tmpIt.DeviceId IS NULL
		)
		SELECT 	cte.RawFingerPrintId
			,	lv_CreatedDate
		FROM cte
		WHERE NOT EXISTS (SELECT 1 FROM FPS_FingerPrint.Device d WHERE d.FirstRawFingerPrintId = cte.RawFingerPrintId);

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

        INSERT IGNORE INTO FPS_FingerPrint.DeviceFingerPrint(RawFingerPrintId, DeviceId, CreatedDate)
		WITH cte (RawFingerPrintId, DeviceId) AS
		(
			SELECT 	DISTINCT
					tmpTd.RawFingerPrintId
				,	tmpTd.DeviceId
			FROM Temp_TransDevice AS tmpTd
		)
		SELECT 	cte.RawFingerPrintId
			,	cte.DeviceId
			,	lv_CreatedDate
		FROM cte
		WHERE NOT EXISTS (SELECT 1 FROM FPS_FingerPrint.DeviceFingerPrint df WHERE df.RawFingerPrintId = cte.RawFingerPrintId);

		INSERT IGNORE INTO FPS_FingerPrint.DeviceCookie(CookieId, DeviceId, CreatedDate)
		WITH cte (CookieId, DeviceId) AS
		(
			SELECT 	DISTINCT
					tmpTd.CookieId
				,	tmpTd.DeviceId
			FROM Temp_TransDevice AS tmpTd
		)
		SELECT 	cte.CookieId
			,	cte.DeviceId
			,	lv_CreatedDate
		FROM cte
		WHERE NOT EXISTS (SELECT 1 FROM FPS_FingerPrint.DeviceCookie dc WHERE dc.CookieId = cte.CookieId);

    ELSE		
		INSERT IGNORE INTO FPS_FingerPrint.Device(FirstRawFingerPrintId, CreatedDate)
		WITH cte (RawFingerPrintId) AS
		(
			SELECT 	DISTINCT
					tmpGd.RawFingerPrintId
			FROM Temp_GroupDevice AS tmpGd
			WHERE tmpGd.Id = tmpGd.GroupId
				AND tmpGd.DeviceId IS NULL
		)
		SELECT 	cte.RawFingerPrintId
			,	lv_CreatedDate
		FROM cte
		WHERE NOT EXISTS (SELECT 1 FROM FPS_FingerPrint.Device d WHERE d.FirstRawFingerPrintId = cte.RawFingerPrintId);
        
		INSERT INTO Temp_TransDevice(Id, TransTime, RawFingerPrintId, CookieId, DeviceId, RecoverType, GroupId)
        SELECT	tmpIt.Id
			,	tmpIt.TransTime
            ,	tmpIt.RawFingerPrintId
            ,	tmpIt.CookieId
            ,	dv.Id
            ,	tmpIt.RecoverType
            ,	tmpIt.GroupId
		FROM Temp_InputTrans AS tmpIt
			INNER JOIN Temp_GroupDevice AS tmpGd ON tmpGd.GroupId = tmpIt.GroupId AND tmpGd.Id = tmpIt.Id
			INNER JOIN FPS_FingerPrint.Device AS dv ON dv.FirstRawFingerPrintId = tmpGd.RawFingerPrintId;
        
		INSERT INTO Temp_TransDevice(Id, TransTime, RawFingerPrintId, CookieId, DeviceId, RecoverType, GroupId)
        SELECT	tmpIt.Id
			,	tmpIt.TransTime
            ,	tmpIt.RawFingerPrintId
            ,	tmpIt.CookieId
            ,	dv.Id
            ,	CASE 
					WHEN tmpIt.RawFingerPrintId = tmpGd.RawFingerPrintId AND tmpIt.CookieId = tmpGd.CookieId THEN 3
					WHEN tmpIt.RawFingerPrintId = tmpGd.RawFingerPrintId THEN 1
					WHEN tmpIt.CookieId = tmpGd.CookieId THEN 2
					ELSE -1
				END AS RecoverType
            ,	tmpIt.GroupId
		FROM Temp_InputTrans AS tmpIt
			INNER JOIN Temp_GroupDevice AS tmpGd ON tmpGd.GroupId = tmpIt.GroupId AND tmpGd.Id <> tmpIt.Id
			INNER JOIN FPS_FingerPrint.Device AS dv ON dv.FirstRawFingerPrintId = tmpGd.RawFingerPrintId;
		
		INSERT INTO Temp_TransNoDevice(Id, RawFingerPrintId, CookieId, DeviceId, RecoverType, GroupId)
        SELECT 	Id
			,	RawFingerPrintId
			,	CookieId
			,	DeviceId
			,	RecoverType
			,	GroupId
        FROM Temp_TransDevice
        WHERE RecoverType = -1;
		
		/*====RecoverType = 3 */
		UPDATE Temp_TransNoDevice AS tmpNo
			INNER JOIN Temp_TransDevice AS tmp ON tmp.GroupId = tmpNo.GroupId AND tmp.RecoverType <> -1 AND tmpNo.RawFingerPrintId = tmp.RawFingerPrintId AND tmpNo.CookieId = tmp.CookieId
		SET tmpNo.RecoverType = 3
		WHERE tmpNo.RecoverType = -1;
        
        UPDATE Temp_TransDevice AS tmp
			INNER JOIN Temp_TransNoDevice AS tmpNo ON tmpNo.Id = tmp.Id
		SET tmp.RecoverType = tmpNo.RecoverType
        WHERE tmp.RecoverType = -1;
        
		/*====RecoverType = 1 */
		UPDATE Temp_TransNoDevice AS tmpNo
			INNER JOIN Temp_TransDevice AS tmp ON tmp.GroupId = tmpNo.GroupId AND tmp.RecoverType <> -1 AND tmpNo.RawFingerPrintId = tmp.RawFingerPrintId
		SET tmpNo.RecoverType = 1
		WHERE tmpNo.RecoverType = -1;
        
        UPDATE Temp_TransDevice AS tmp
			INNER JOIN Temp_TransNoDevice AS tmpNo ON tmpNo.Id = tmp.Id
		SET tmp.RecoverType = tmpNo.RecoverType
        WHERE tmp.RecoverType = -1;
        
        
		/*====RecoverType = 2 */
		UPDATE Temp_TransNoDevice AS tmpNo
			INNER JOIN Temp_TransDevice AS tmp ON tmp.GroupId = tmpNo.GroupId AND tmp.RecoverType <> -1 AND tmpNo.CookieId = tmp.CookieId
		SET tmpNo.RecoverType = 2
		WHERE tmpNo.RecoverType = -1;
        
        UPDATE Temp_TransDevice AS tmp
			INNER JOIN Temp_TransNoDevice AS tmpNo ON tmpNo.Id = tmp.Id
		SET tmp.RecoverType = tmpNo.RecoverType
        WHERE tmp.RecoverType = -1;
        
  
		INSERT IGNORE INTO FPS_FingerPrint.DeviceFingerPrint(RawFingerPrintId, DeviceId, CreatedDate)
		WITH cte (RawFingerPrintId, DeviceId) AS
		(
			SELECT 	DISTINCT
					tmpTd.RawFingerPrintId
				,	tmpTd.DeviceId
			FROM Temp_TransDevice AS tmpTd
		)
		SELECT 	cte.RawFingerPrintId
			,	cte.DeviceId
			,	lv_CreatedDate
		FROM cte
		WHERE NOT EXISTS (SELECT 1 FROM FPS_FingerPrint.DeviceFingerPrint df WHERE df.RawFingerPrintId = cte.RawFingerPrintId);
        
        INSERT IGNORE INTO FPS_FingerPrint.DeviceCookie(CookieId, DeviceId, CreatedDate)
		WITH cte (CookieId, DeviceId) AS
		(
			SELECT 	DISTINCT
					tmpTd.CookieId
				,	tmpTd.DeviceId
			FROM Temp_TransDevice AS tmpTd
		)
		SELECT 	cte.CookieId
			,	cte.DeviceId
			,	lv_CreatedDate
		FROM cte
		WHERE NOT EXISTS (SELECT 1 FROM FPS_FingerPrint.DeviceCookie dc WHERE dc.CookieId = cte.CookieId);

	END IF;

	UPDATE Temp_InputTrans AS tmpIt
		INNER JOIN Temp_TransDevice AS tmpTd ON tmpIt.Id = tmpTd.Id
	SET tmpIt.DeviceId = tmpTd.DeviceId,
		tmpIt.RecoverType = tmpTd.RecoverType
	WHERE tmpIt.DeviceId IS NULL;
    
    /*****AccountFingerprint******************/
	INSERT IGNORE INTO FPS_FingerPrint.AccountFingerprint(AccountId, RawFingerPrintId, CreatedDate)
    SELECT	AccountId
        ,	RawFingerPrintId
        ,	lv_CreatedDate
    FROM Temp_InputTrans;

	/*****TransactionDevice******************/
	INSERT INTO FPS_FingerPrint.TransactionDevice(TransTime, CustId , SubAccId, AccountId, LoginName, SubscriberId, RawFingerPrintId, BrowserInstanceId, CookieId, DeviceId, ClientIP, BrowserInfoId, UserAgentId, Url, Action, CreatedDate, TransKey, RecoverType)
	SELECT  ts.TransTime
		, 	ts.CustId
		, 	ts.SubAccId
		, 	ts.AccountId
		, 	ts.LoginName
		, 	ts.SubscriberId
		, 	ts.RawFingerPrintId
		, 	ts.BrowserInstanceId
		, 	ts.CookieId
		, 	tmpIt.DeviceId
		, 	ts.ClientIP
		, 	ts.BrowserInfoId
		, 	ts.UserAgentId
		, 	ts.Url
		, 	ts.Action
		, 	lv_CreatedDate
		, 	ts.TransKey
		, 	tmpIt.RecoverType
	FROM Temp_InputTrans AS tmpIt
		INNER JOIN FPS_FingerPrint.Transaction AS ts ON tmpIt.Id = ts.Id;

    DELETE ts
    FROM FPS_FingerPrint.Transaction AS ts
		INNER JOIN Temp_InputTrans AS tmpIt ON tmpIt.Id = ts.Id;
        
END$$
DELIMITER ;
