CREATE PROCEDURE [flw].[AGent_MailtoTrelloboard] 
@Environment NVARCHAR(50) = NULL,
@RunInterval INT = 5
WITH EXECUTE AS CALLER
AS 
BEGIN
	IF (@Environment NOT IN ('UDV', 'TEST', 'PROD'))
		SET @Environment = NULL

	IF (@RunInterval IS NULL)
		SET @RunInterval = 2

DECLARE @JobID VARCHAR(50)
   ,@Package AS VARCHAR(100)
   ,@Started AS DATETIME
   ,@Ended AS DATETIME
   ,@Runduration AS SMALLINT
   ,@SSISError AS VARCHAR(2000)
   ,@SQLMessage AS VARCHAR(2000)
   ,@MessageToDescription AS VARCHAR(2000)
   ,@SubjectText AS VARCHAR(500)	--sp_param
   ,@BodyText AS NVARCHAR(MAX) = ''
   ,@TrelloboardMail AS VARCHAR(100)
   ,@Timer AS INT = 30
   ,@WaitDateTime DATETIME
   ,@MailserverProfile AS VARCHAR(20)


SET @WaitDateTime = DATEADD(MINUTE, @RunInterval, 0)



WHILE (1=1)
	BEGIN

WAITFOR DELAY @WaitDateTime

DECLARE db_cursor CURSOR
FOR
    SELECT  [FailedJobID]
    FROM    DataFlowManagement.flw.FailedJobsToTrello
    WHERE   isHandled = 0

OPEN db_cursor   
FETCH NEXT FROM db_cursor INTO @JobID   

WHILE @@FETCH_STATUS = 0
    BEGIN   
        DECLARE @TempTable TABLE
            (
             JobFlowName VARCHAR(100)
            ,FejletStep VARCHAR(100)
            ,FejletSQL_Message VARCHAR(4000)
            ,FejletStepStarted DATETIME
            ,StepFejletDatoTid DATETIME
            ,RunDuration SMALLINT
            ,SSIS_ProjectName VARCHAR(200)
            ,PackageName VARCHAR(100)
            ,ErrorMessage VARCHAR(4000)
            );
        WITH    GetError
                  AS ( SELECT   a.*
                               ,msdb.dbo.agent_datetime(run_date, run_time) AS aa
                               ,LEAD(a.step_id) OVER ( ORDER BY a.instance_id DESC ) AS FejletStep_id
                               ,LEAD(a.step_name) OVER ( ORDER BY a.instance_id DESC ) AS FejletStep_Name
                               ,LEAD(a.message) OVER ( ORDER BY a.instance_id DESC ) AS FejletSQL_Message
                               ,LEAD(a.run_date) OVER ( ORDER BY a.instance_id DESC ) AS FejletRundate
                               ,LEAD(a.run_time) OVER ( ORDER BY a.instance_id DESC ) AS FejletRuntime
                               ,LEAD(a.run_duration) OVER ( ORDER BY a.instance_id DESC ) AS FejletRunduration
							   ,IIF(CHARINDEX('/ISSERVER "\"\SSISDB\', b.command) = 1, SUBSTRING(b.command, 26, CHARINDEX('\',
                                SUBSTRING(b.command, 26, 100)) - 1), '') AS Name, 
								LEAD(IIF(CHARINDEX('/ISSERVER "\"\SSISDB\', b.command) = 1, SUBSTRING(b.command,26, CHARINDEX('\',
                                SUBSTRING(b.command, 26, 100)) - 1), '')) OVER ( ORDER BY a.instance_id DESC ) AS AlternativName
                       FROM     msdb.dbo.sysjobhistory a
					   LEFT OUTER JOIN msdb.dbo.sysjobsteps b ON b.job_id = a.job_id AND b.step_id = a.step_id
                       WHERE    a.job_id = @JobID
                        --AND run_date = CONVERT(VARCHAR,  GetDate(), 112)
                                AND msdb.dbo.agent_datetime(run_date, run_time) BETWEEN DATEADD(MINUTE,
                                                              -@Timer, GETDATE())
                                                              AND
                                                              DATEADD(MINUTE,
                                                              @Timer, GETDATE())
                     ),
                ErrorData
                  AS ( SELECT   e.subsystem + '_' + REPLACE(b.name,
                                                            'BI - Flow - ', '') AS Name
                               ,b.name AS JobFlowName
                               ,CAST(GetError.FejletStep_id AS VARCHAR)
                                + ' - ' + GetError.FejletStep_Name AS FejletIStep
                               ,GetError.FejletSQL_Message
                               ,msdb.dbo.agent_datetime(GetError.FejletRundate,
                                                        GetError.FejletRuntime) AS FejletStepStarted
                               ,msdb.dbo.agent_datetime(GetError.run_date,
                                                        GetError.run_time) AS StepFejletDatoTid
                               ,GetError.FejletRunduration / 100 % 100 AS RundurationMinutes
							   ,GetError.AlternativName
                       FROM     GetError
                                INNER JOIN msdb.dbo.sysjobs b ON b.job_id = GetError.job_id
                                INNER JOIN msdb.dbo.sysjobsteps c ON c.job_id = GetError.job_id
                                                              AND c.step_id = GetError.step_id
                                OUTER APPLY ( SELECT    subsystem
                                              FROM      msdb.dbo.sysjobsteps
                                              WHERE     GetError.job_id = job_id
                                                        AND GetError.FejletStep_id = step_id
                                            ) e
                       WHERE    GetError.step_name = 'FEJL - AgentJob'
                     )
					 
					 
            INSERT  INTO @TempTable
                    (JobFlowName
                    ,FejletStep
                    ,FejletSQL_Message
                    ,FejletStepStarted
                    ,StepFejletDatoTid
                    ,RunDuration
                    ,SSIS_ProjectName
                    ,PackageName
                    ,ErrorMessage
                    )
                    SELECT  ED.JobFlowName
                           ,ED.FejletIStep
                           ,ED.FejletSQL_Message
                           ,ED.FejletStepStarted
                           ,ED.StepFejletDatoTid
                           ,ED.RundurationMinutes
                           ,SI.SSIS_Project_Name
                           ,COALESCE(SI.package_name,  ED.FejletIStep COLLATE Danish_Norwegian_CI_AS) AS package_name
                           ,COALESCE(SI.Error_Message, ED.FejletSQL_Message) AS Error_Message
                    FROM    ErrorData ED -- Beriger med top 3 error message fra SSIS DB
                            OUTER APPLY ( SELECT  DISTINCT
                                                    t1.SSIS_Project_Name
                                                   ,t1.package_name
                                   --,t1.Start_Time
                                   --,t1.End_Time
                                                   ,STUFF(
                   (SELECT  ', ' + t2.[Error_Message]
                    FROM    ( SELECT TOP 3
                                        *
                              FROM      SSISDB.dbo.SSISErrors_Last30Days
                              WHERE     SSIS_Project_Name = ED.AlternativName COLLATE Danish_Norwegian_CI_AS
                                        AND Start_Time > DATEADD(MINUTE, -@Timer,
                                                              GETDATE())
                                        AND Start_Time < DATEADD(MINUTE, @Timer,
                                                              GETDATE())
                            ) t2
                    WHERE   t1.SSIS_Project_Name = t2.SSIS_Project_Name
                    ORDER BY t2.[Error_Message]
                                                    FOR   XML PATH('')
                                                             ,TYPE
                   ).value('.', 'varchar(max)'), 1, 2, '') AS [Error_Message]
                                          FROM      ( SELECT TOP 3
                                                              *
                                                      FROM    SSISDB.dbo.SSISErrors_Last30Days
                                                      WHERE   SSIS_Project_Name = ED.AlternativName COLLATE Danish_Norwegian_CI_AS
                                                              AND Start_Time > DATEADD(MINUTE,
                                                              -@Timer, GETDATE())
                                                              AND Start_Time < DATEADD(MINUTE,
                                                              @Timer, GETDATE())
                                                    ) t1
                                          GROUP BY  t1.SSIS_Project_Name
                                                   ,t1.package_name
                                   --,t1.Start_Time
                                   --,t1.End_Time
                                        ) SI


-- SET VARIABLES
        IF EXISTS ( SELECT  *
                    FROM    @TempTable )
            BEGIN

                SET @Package = ( SELECT PackageName
                                 FROM   @TempTable
                               )
                SET @Started = ( SELECT FejletStepStarted
                                 FROM   @TempTable
                               )
                SET @Ended = ( SELECT   StepFejletDatoTid
                               FROM     @TempTable
                             )
                SET @Runduration = ( SELECT RunDuration
                                     FROM   @TempTable
                                   )
                SET @SSISError = ( SELECT   ErrorMessage
                                   FROM     @TempTable
                                 )
                SET @SQLMessage = ( SELECT  FejletSQL_Message
                                    FROM    @TempTable
                                  )
                IF @SSISError IS NULL
                SET @MessageToDescription = @SQLMessage
                
                IF @SSISError IS NOT NULL
                SET @MessageToDescription = @SSISError
                
                SET @SubjectText = CONVERT(VARCHAR, GETDATE(), 112) + ' - '
                    + ( SELECT  JobFlowName
                        FROM    @TempTable
                      )
 
                SET @BodyText = CHAR(13) + '## Situation :' + CHAR(13)
                    + CHAR(13) + 'Jobbet er fejlet på ' + @@SERVERNAME
                    + '    `Kortet er automatisk oprettet`' + CHAR(13)
                    + CHAR(13) + 'Packagename : ' + ISNULL(@Package,'Ingen fejldata fra SSISDB. Dette kan skyldes af jobnavnet ikke kan matches.') + CHAR(13)
                    + 'Startet : ' + CONVERT(VARCHAR, @Started, 126)
                    + '       Fejlet : ' + CONVERT(VARCHAR, @Ended, 126)
                    + '       Duration : ' + CAST(@Runduration AS VARCHAR)
                    + CHAR(13) + CHAR(13) + '---' + CHAR(13) + '## Årsag :'
                    + CHAR(13) + CHAR(13) + @MessageToDescription + CHAR(13)
                    + CHAR(13) + '---' + CHAR(13) + '## Løsning :' + CHAR(13)
                    + CHAR(13)



                SET @TrelloboardMail = 'tombrox1+frb5t6cx7fpdfkr39jy6@boards.trello.com'
				SET @MailserverProfile = replace(replace(@@SERVERNAME, @@servicename, ''), '\','')

---- Execute and create Trello card.

                DECLARE @mailitem_id INT;
                EXEC msdb.dbo.sp_send_dbmail @profile_name = @MailserverProfile,
                    @recipients = @TrelloboardMail, -- varchar(max)
                    @subject = @SubjectText, -- nvarchar(255)
                    @body = @BodyText
	            END
			

			 
        UPDATE  flw.FailedJobsToTrello
        SET     isHandled = 1
        WHERE   FailedJobID = @JobID
			 
			 

        FETCH NEXT FROM db_cursor INTO @JobID   
    END   

CLOSE db_cursor   
DEALLOCATE db_cursor

END
END
GO
GRANT EXECUTE
    ON OBJECT::[flw].[AGent_MailtoTrelloboard] TO PUBLIC
    AS [dbo];

