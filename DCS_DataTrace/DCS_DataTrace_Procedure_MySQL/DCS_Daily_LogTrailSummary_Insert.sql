/*<info serverAlias="DCSS_DataTrace" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DT_Summary_LogTrail_Insert`;
DELIMITER $$

CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DT_Summary_LogTrail_Insert`(
    IN ip_LogTrailJson LONGTEXT
)
    SQL SECURITY INVOKER
BEGIN
	/*
	Created: 20232610@Teddy.le
	Task : Insert data into DailyLogTrailSummary
	DB: DCS_DataTrace
	Original:

	Revisions:
		-20232610@Teddy.le: Created [Redmine ID: 195968]
		
	Param's Explanation (filtered by):

	Example:
		SET sql_safe_updates = 0;
        CALL DCS_DataTrace.DCS_DT_Summary_LogTrail_Insert('[{"Date":"2023-10-26","SubscriberID":101,"Source":"https://spu-fps-api.nexdev.net","Method":"/api/transaction","Total":10, "SystemName":"new fps"}]');
	*/
    
	DECLARE lv_CurrentDatetime DATETIME DEFAULT CURRENT_TIMESTAMP();
    
	DROP TEMPORARY TABLE IF EXISTS Temp_InputLogTrail;

	CREATE TEMPORARY TABLE Temp_InputLogTrail(
			ID 							BIGINT UNSIGNED NOT NULL AUTO_INCREMENT
		, 	Date						DATE NOT NULL
		, 	SubscriberID				INT UNSIGNED DEFAULT 0
		, 	Source						VARCHAR(100) DEFAULT NULL
		, 	Method						VARCHAR(100) DEFAULT NULL
		, 	SystemName					VARCHAR(45) DEFAULT NULL
        , 	Total						INT UNSIGNED DEFAULT 0
        , 	CreatedTime					DATETIME DEFAULT NULL
        , 	ModifiedTime				DATETIME DEFAULT NULL
		, 	IsUpdate					BOOL DEFAULT 0
        ,   PRIMARY KEY (`ID`)
		,	KEY `IX_DailyLogTrailSummary_SubscriberID_Source_Method` (`Date`, `SubscriberID`, `Source`, `Method`, `SystemName`)
	);
	
    INSERT INTO Temp_InputLogTrail(Date, SubscriberID, Source, Method, SystemName, Total)
	SELECT	tmp.Date
		,	tmp.SubscriberID
		,	tmp.Source
		,	tmp.Method
        ,	tmp.SystemName
        ,	tmp.Total
	FROM JSON_TABLE(
			ip_LogTrailJson,
			 "$[*]" COLUMNS(
					Date						DATE			PATH "$.Date"
				,	SubscriberID				INT UNSIGNED		PATH "$.SubscriberID"
				,	Source						VARCHAR(100)		PATH "$.Source"
				,	Method						VARCHAR(100) 		PATH "$.Method"
                ,   SystemName					VARCHAR(45)			PATH "$.SystemName"
				,	Total						INT UNSIGNED		PATH "$.Total"
			)
		) AS tmp;

	
    UPDATE DCS_DataTrace.DailyLogTrailSummary AS dl
		INNER JOIN Temp_InputLogTrail AS tmp ON 	dl.Date = tmp.Date
											AND dl.SubscriberID = tmp.SubscriberID
											AND dl.Source = tmp.Source
											AND dl.Method = tmp.Method
                                            AND dl.SystemName = tmp.SystemName
	SET dl.Total 			= dl.Total + tmp.Total,
		dl.ModifiedTime 	= lv_CurrentDatetime,
		tmp.IsUpdate 		= 1;
    
    INSERT INTO DCS_DataTrace.DailyLogTrailSummary(Date, SubscriberID, Source, Method, SystemName, Total, CreatedTime, ModifiedTime)
    SELECT 	tmp.Date
        ,	tmp.SubscriberID
		,	tmp.Source
		,	tmp.Method
        ,	tmp.SystemName
        ,	tmp.Total
        ,	lv_CurrentDatetime AS CreatedTime
        ,	lv_CurrentDatetime AS ModifiedTime
	FROM Temp_InputLogTrail AS tmp
    WHERE tmp.IsUpdate = 0;
END$$
DELIMITER ;