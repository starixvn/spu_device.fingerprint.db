/*<info serverAlias="FPSDC-FPS_FingerPrint" databaseType="2" executers="fpsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `FPS_FP_Monitor_RecoverTypeSum_Get`;
DELIMITER $$

CREATE DEFINER=`fpsOwner`@`%` PROCEDURE `FPS_FP_Monitor_RecoverTypeSum_Get`(
		ip_FromDate	DATE,
		ip_ToDate 	DATE
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20221026@Jonathan.Doan
		Task :		
		DB:			FPS_FingerPrint
		Original:

		Revisions: 
			- 20221026@Jonathan.Doan: Created [Redmine ID: #179603]
            
		Param's Explanation (filtered by):	

		Example:
			- CALL FPS_FP_Monitor_RecoverTypeSum_Get('2022-10-01', '2022-10-31');
			
	*/
   
    /*******LOG TEST********************/
    IF (SELECT ofs.OffsetValue FROM FPS_FingerPrint.Offset AS ofs WHERE ofs.Id = 7) = 1 THEN		
		INSERT INTO CTS_Log.FPSLog(SpName, JsonString, OtherText, InsertTime)
		SELECT 'FPS_FP_Monitor_RecoverTypeSum_Get', NULL, CONCAT('ip_FromDate:',DATE_FORMAT(ip_FromDate, '%Y-%m-%d %T'),', ip_ToDate:',DATE_FORMAT(ip_ToDate, '%Y-%m-%d %T')), CURRENT_TIMESTAMP();
	END IF;
    /*******LOG TEST********************/
    
	WITH tmp_SumDaily AS
    (
		SELECT 	st.SubscriberId
			, 	SUM(st.Total) AS Total
			, 	SUM(st.NullDevice) AS NullDevice
			, 	SUM(st.NewDevice) AS NewDevice
			, 	SUM(st.RecoverByFP) AS RecoverByFP
			, 	SUM(st.RecoverByCookies) AS RecoverByCookies
			, 	SUM(st.RecoverByFPnCookies) AS RecoverByFPnCookies
			, 	SUM(st.RecoverByEvolution) AS RecoverByEvolution
		FROM FPS_FingerPrint.RecoverDailySum AS st 
		WHERE st.TransDate BETWEEN ip_FromDate AND ip_ToDate
		GROUP BY st.SubscriberId
	)
    SELECT 	sub.Name AS SubscriberName
		, 	tmp.Total
		, 	tmp.NullDevice
		, 	tmp.NewDevice
		, 	tmp.RecoverByFP
		, 	tmp.RecoverByCookies
		, 	tmp.RecoverByFPnCookies
		, 	tmp.RecoverByEvolution
    FROM tmp_SumDaily AS tmp
		INNER JOIN FPS_FingerPrint.Subscribers AS sub ON sub.Id = tmp.SubscriberId;

END$$
DELIMITER ;
