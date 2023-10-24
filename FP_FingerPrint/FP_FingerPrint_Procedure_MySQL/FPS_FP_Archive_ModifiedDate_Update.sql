/*<info serverAlias="FPSDC-FPS_FingerPrint" databaseType="2" executers="fpsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `FPS_FP_Archive_ModifiedDate_Update`;
DELIMITER $$

CREATE DEFINER=`fpsOwner`@`%` PROCEDURE `FPS_FP_Archive_ModifiedDate_Update`(
	ip_BatchSize INT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20220628@Jonathan.Doan
		Task :		
		DB:			FPS_FingerPrint
		Original:

		Revisions:
			- 20220628@Jonathan.Doan: Created [Redmine ID: #174020]
			- 20221213@Jonathan.Doan: Update more table [Redmine ID: #180264]
			- 20231023@Jonathan.Doan: Apply BotD [Redmine ID: #195880]
            
		Param's Explanation (filtered by):

		Example:
			CALL FPS_FP_Archive_ModifiedDate_Update(100);
	*/
    DECLARE lv_offsetId INT DEFAULT 11;
    DECLARE lv_offsetValue BIGINT;
    DECLARE lv_maxOffsetValue BIGINT;

    /*******LOG TEST********************/
    IF (SELECT ofs.OffsetValue FROM FPS_FingerPrint.Offset AS ofs WHERE Id = 7) = 1 THEN
		INSERT INTO CTS_Log.FPSLog(SpName, JsonString, OtherText, InsertTime)
		SELECT 'FPS_FP_Archive_ModifiedDate_Update', NULL,CONCAT('ip_BatchSize:',ip_BatchSize), CURRENT_TIMESTAMP();
    END IF;
    /*******LOG TEST********************/

    /*******INIT TEMPORARY TABLE********************/
    DROP TEMPORARY TABLE IF EXISTS Temp_Transaction;
	CREATE TEMPORARY TABLE Temp_Transaction(
        	Id					BIGINT UNSIGNED PRIMARY KEY
        ,	AccountId			BIGINT UNSIGNED DEFAULT NULL
        ,	BrowserInstanceId	BIGINT UNSIGNED DEFAULT NULL
        ,	RawFingerPrintId	BIGINT UNSIGNED DEFAULT NULL
        ,	RawUserAgentId		BIGINT UNSIGNED DEFAULT NULL
        ,	CookieId			BIGINT UNSIGNED DEFAULT NULL
        ,	DeviceId			BIGINT UNSIGNED DEFAULT NULL
        ,	BotComponentId		BIGINT UNSIGNED DEFAULT NULL
        ,	CreatedDate			DATETIME(4)
        , 	INDEX IX_Temp_Transaction_CreatedDate(CreatedDate)
    );

    DROP TEMPORARY TABLE IF EXISTS Temp_Account;
	CREATE TEMPORARY TABLE Temp_Account(
        	AccountId			BIGINT UNSIGNED PRIMARY KEY
        ,	CreatedDate			DATETIME(4)
    );

    DROP TEMPORARY TABLE IF EXISTS Temp_BrowserInstance;
	CREATE TEMPORARY TABLE Temp_BrowserInstance(
        	BrowserInstanceId	BIGINT UNSIGNED PRIMARY KEY
        ,	CreatedDate			DATETIME(4)
    );

    DROP TEMPORARY TABLE IF EXISTS Temp_Device;
	CREATE TEMPORARY TABLE Temp_Device(
        	DeviceId			BIGINT UNSIGNED PRIMARY KEY
        ,	CreatedDate			DATETIME(4)
    );

    DROP TEMPORARY TABLE IF EXISTS Temp_Cookie;
	CREATE TEMPORARY TABLE Temp_Cookie(
        	CookieId			BIGINT UNSIGNED PRIMARY KEY
        ,	CreatedDate			DATETIME(4)
    );

    DROP TEMPORARY TABLE IF EXISTS Temp_RawFingerPrint;
	CREATE TEMPORARY TABLE Temp_RawFingerPrint(
        	RawFingerPrintId	BIGINT UNSIGNED PRIMARY KEY
        ,	CreatedDate			DATETIME(4)
    );

    DROP TEMPORARY TABLE IF EXISTS Temp_RawUserAgent;
	CREATE TEMPORARY TABLE Temp_RawUserAgent(
        	RawUserAgentId		BIGINT UNSIGNED PRIMARY KEY
        ,	CreatedDate			DATETIME(4)
    );
    
    DROP TEMPORARY TABLE IF EXISTS Temp_BotComponent;
	CREATE TEMPORARY TABLE Temp_BotComponent(
        	BotComponentId		BIGINT UNSIGNED PRIMARY KEY
        ,	CreatedDate			DATETIME(4)
    );
    
    /*******INIT DATA********************/
    SELECT off.OffsetValue
    INTO lv_offsetValue
    FROM FPS_FingerPrint.Offset AS off
    WHERE off.Id = lv_offsetId;

    INSERT INTO Temp_Transaction(Id, AccountId, RawFingerPrintId, RawUserAgentId, CookieId, DeviceId, BotComponentId, CreatedDate)
    SELECT 	Id
        ,	AccountId
        ,	RawFingerPrintId
        ,	UserAgentId AS RawUserAgentId
        ,	CookieId
        ,	DeviceId
        ,	BotComponentId
        ,	CreatedDate
	FROM FPS_FingerPrint.TransactionCompleted
	WHERE Id > lv_offsetValue
	LIMIT ip_BatchSize;
    
    INSERT INTO Temp_Account(AccountId, CreatedDate)
    SELECT 	AccountId
		,	MAX(CreatedDate)
    FROM Temp_Transaction
    WHERE AccountId IS NOT NULL
    GROUP BY AccountId;
    
    INSERT INTO Temp_BrowserInstance(BrowserInstanceId, CreatedDate)
    SELECT 	bifp.BrowserInstanceId
		,	MAX(tmp.CreatedDate)
    FROM Temp_Transaction AS tmp
		INNER JOIN FPS_FingerPrint.BrowserInstanceRawFingerPrint AS bifp ON bifp.RawFingerPrintId = tmp.RawFingerPrintId
    WHERE bifp.BrowserInstanceId IS NOT NULL
    GROUP BY bifp.BrowserInstanceId;
    
    INSERT INTO Temp_Device(DeviceId, CreatedDate)
    SELECT 	DeviceId
		,	MAX(CreatedDate)
    FROM Temp_Transaction
    WHERE DeviceId IS NOT NULL
    GROUP BY DeviceId;

    INSERT INTO Temp_Cookie(CookieId, CreatedDate)
    SELECT 	CookieId
		,	MAX(CreatedDate)
    FROM Temp_Transaction
    WHERE CookieId IS NOT NULL
    GROUP BY CookieId;

    INSERT INTO Temp_RawFingerPrint(RawFingerPrintId, CreatedDate)
    SELECT 	RawFingerPrintId
		,	MAX(CreatedDate)
    FROM Temp_Transaction
    WHERE RawFingerPrintId IS NOT NULL
    GROUP BY RawFingerPrintId;

    INSERT INTO Temp_RawUserAgent(RawUserAgentId, CreatedDate)
    SELECT 	RawUserAgentId
		,	MAX(CreatedDate)
    FROM Temp_Transaction
    WHERE RawUserAgentId IS NOT NULL
    GROUP BY RawUserAgentId;

    INSERT INTO Temp_BotComponent(BotComponentId, CreatedDate)
    SELECT 	BotComponentId
		,	MAX(CreatedDate)
    FROM Temp_Transaction
    WHERE BotComponentId IS NOT NULL
    GROUP BY BotComponentId;
    
    SELECT MAX(Id)
    INTO lv_maxOffsetValue
    FROM Temp_Transaction;

    /*******UPDATE DATA********************/
	UPDATE FPS_FingerPrint.Account AS main
		INNER JOIN Temp_Account AS tmp ON main.Id = tmp.AccountId
	SET main.ModifiedDate = tmp.CreatedDate;
    
	UPDATE FPS_FingerPrint.BrowserInstance AS main
		INNER JOIN Temp_BrowserInstance AS tmp ON main.Id = tmp.BrowserInstanceId
	SET main.ModifiedDate = tmp.CreatedDate;
    
	UPDATE FPS_FingerPrint.Device AS main
		INNER JOIN Temp_Device AS tmp ON main.Id = tmp.DeviceId
	SET main.ModifiedDate = tmp.CreatedDate;
    
	UPDATE FPS_FingerPrint.Cookie AS main
		INNER JOIN Temp_Cookie AS tmp ON main.Id = tmp.CookieId
	SET main.ModifiedDate = tmp.CreatedDate;
    
	UPDATE FPS_FingerPrint.RawFingerPrint AS main
		INNER JOIN Temp_RawFingerPrint AS tmp ON main.Id = tmp.RawFingerPrintId
	SET main.ModifiedDate = tmp.CreatedDate;
    
	UPDATE FPS_FingerPrint.RawUserAgent AS main
		INNER JOIN Temp_RawUserAgent AS tmp ON main.Id = tmp.RawUserAgentId
	SET main.ModifiedDate = tmp.CreatedDate;
    
	UPDATE FPS_FingerPrint.BotComponent AS main
		INNER JOIN Temp_BotComponent AS tmp ON main.Id = tmp.BotComponentId
	SET main.ModifiedDate = tmp.CreatedDate;
    
    IF lv_maxOffsetValue IS NOT NULL
    THEN
		UPDATE FPS_FingerPrint.Offset
		SET OffsetValue = lv_maxOffsetValue
		WHERE Id = lv_offsetId;
    END IF;

END$$
DELIMITER ;
