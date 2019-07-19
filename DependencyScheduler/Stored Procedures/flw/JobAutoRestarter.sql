
CREATE PROCEDURE [flw].[JobAutoRestarter]
AS
BEGIN
   /*
DROP TABLE #temp
SELECT * 
INTO #temp
FROM  [flw].[ListJobLog] a
WHERE a.[BatchID] IN (
SELECT [CurrentBatchID]
FROM  [flw].[JobMasterSetup] 
)
AND [a].[JobName] = 'BI - Flow - DPA_Digital_Post'

UNION all


SELECT        [a].[BatchID]
        ,[a].[Log_ID] +500
        ,[a].[Status]
        ,[a].[Success]
        ,[a].[JobListe Aktiv]
        ,[a].[JobName]
        ,[a].[JobType_Beskrivelse]
        ,DATEADD(DAY, +1, [a].[OprettetDato] )
        ,[a].[JobID]
        ,[a].[Log_Message]
        ,[a].[CallerJobName]
        ,[a].[CallerSPName]
        ,[a].[DebugTxt]
FROM  [flw].[ListJobLog] a
WHERE a.[BatchID] IN (
SELECT [CurrentBatchID]
FROM  [flw].[JobMasterSetup] 
)
AND [a].[JobName] = 'BI - Flow - DPA_Digital_Post'

delete from #temp 
where log_id = 719754


SELECT * 
FROM  #temp
ORDER BY [OprettetDato]

*/
   DECLARE @Log_Id INT
   DECLARE @JobName NVARCHAR(128)
   DECLARE @JobId UNIQUEIDENTIFIER
   DECLARE @JobStepName NVARCHAR(128)
   DECLARE @JobStepType NVARCHAR(128)
   DECLARE @JobMessage NVARCHAR(4000)
   DECLARE @SSISExecutionId INT
   DECLARE @Counter INT
   DECLARE @MailProfile NVARCHAR(500)
   DECLARE @Messages NVARCHAR(MAX)
   DECLARE @Subject NVARCHAR(4000)
   DECLARE @Recipients NVARCHAR(4000)
   DECLARE @RestartJob BIT = 0 -- 0 = No, 1 = Yes
   DECLARE @RestartStepName NVARCHAR(128)

   /*
      Da der er sket deadlocks mellem jobrestarter og flow motor komponenterne, så har jobrestarter
      fået sat LOW i deadlock priority, så hvis der sker deadlocks mellem den og andre sessions,
      der kører med NORMAL/HIGH deadlock priority, så vil jobrestarter blive valgt som victim.
      SQL Agent jobbet der kører jobrestarter er sat til at genstarte sig selv i tilfælde af at den bliver killed
      Den bliver STOPPED af Batch slut jobbet!
   */
   SET DEADLOCK_PRIORITY LOW;

   IF (OBJECT_ID('tempdb..#RestartedJobs') <> 0)
      DROP TABLE #RestartedJobs

   CREATE TABLE #RestartedJobs (
   JobName     NVARCHAR(128)
  ,FailedStepName    NVARCHAR(128)
  ,RestartStepName    NVARCHAR(128)
  ,RestartedAt DATETIME
   )

   SET @MailProfile = REPLACE(REPLACE(@@SERVERNAME, @@SERVICENAME, ''), '\', '')

   WHILE (1 = 1)
   BEGIN
      --PRINT 'New Cycle'
      SET @JobName = NULL
      SET @JobId = NULL
      SET @JobStepName = NULL
      SET @JobStepType = NULL
      SET @JobMessage = NULL
      SET @SSISExecutionId = NULL
      SET @Counter = NULL
      SET @RestartJob = 0
      SET @RestartStepName = NULL

      --PRINT ISNULL(@Log_Id,-1)

      SELECT TOP 1
         @Log_Id = [a].[Log_ID]
        ,@JobName = [a].[JobName]
        ,@JobId = a.[JobID]
        ,@JobStepName = [jh].[step_name]
        ,@JobStepType = [js].[subsystem]
        ,@JobMessage = [jh].[message]
        ,@SSISExecutionId =   
            IIF([js].[subsystem] = 'SSIS',
                TRY_CAST(SUBSTRING([jh].[message], PATINDEX('%Execution ID:%', [jh].[message]) + LEN('Execution ID:'), 
                  (PATINDEX('%, Execution Status:%', [jh].[message]) - (PATINDEX('%Execution ID:%', [jh].[message]) + LEN('Execution ID:')))) AS INT)
                  ,NULL)
         --*
      FROM [flw].[ListJobLog] [a]
      INNER JOIN [flw].[JobMasterSetup] [x]
         ON [x].[CurrentBatchID] = [a].[BatchID]
      CROSS APPLY (
         SELECT TOP 1 *
         FROM [msdb].[dbo].[sysjobhistory] [jh]
         WHERE [jh].[job_id] = [a].[JobID]
           AND [msdb].[dbo].[agent_datetime]([jh].[run_date], [jh].[run_time]) >= [x].[BatchStart]
           AND [jh].[step_id] != 0
           AND [jh].[run_status] = 0
         ORDER BY [msdb].[dbo].[agent_datetime]([jh].[run_date], [jh].[run_time]) DESC
      ) jh
      INNER JOIN [msdb].[dbo].[sysjobsteps] [js]
         ON [js].[job_id] = [jh].[job_id]
        AND [js].[step_id] = [jh].[step_id]
      CROSS APPLY
      (
         SELECT MAX([Log_ID]) AS [MaxLog_id]
         FROM [flw].[ListJobLog] [b]
         WHERE [b].[BatchID] = [a].[BatchID]
           AND [b].[JobID] = [a].[JobID]
           AND [b].[Status] = [a].[Status]
      ) [b]
      WHERE [a].[Status] = 'Fejl'
        AND [a].[Log_ID] = [b].[MaxLog_id]
        AND NOT EXISTS
      (
         SELECT *
         FROM [flw].[ListJobLog] [b]
         WHERE [b].[BatchID] = [a].[BatchID]
           AND [b].[JobID] = [a].[JobID]
           AND [b].[Log_ID] > [a].[Log_ID]
      )
        AND a.[JobID] NOT IN (
               SELECT [Job ID]
               FROM [flw].[ListJobs]
               WHERE [BatchStartJob] = 1
                  OR [BatchStopJob] = 1
            )
        AND [a].[Log_ID] > ISNULL(@Log_Id, 0)
      ORDER BY [Log_ID]

      --PRINT @Log_Id
      --PRINT @JobName
      --PRINT @JobStepName
      --PRINT @JobStepType
      --PRINT @JobMessage
      --PRINT @SSISExecutionId

      SET @Counter = 0

      IF (@JobStepType = 'SSIS' AND @SSISExecutionId IS NOT NULL)
      BEGIN
         SELECT @Counter += SIGN(COUNT(*))
         FROM [SSISDB].[dbo].[SSISErrors_Last30Days] [a]
         WHERE [a].[operation_id] = @SSISExecutionId
           AND (
                  [a].[Error_Message] LIKE '%deadlock%'
              OR  [a].[Error_Message] LIKE '%TCP Provider%Timeout error%'
              OR  [a].[Error_Message] LIKE '%TCP Provider%The semaphore timeout period has expired%'
              OR  [a].[Error_Message] LIKE '%Unable to complete login process due to delay in opening server connection%'
              OR  [a].[Error_Message] LIKE '%Login timeout expired%' 
           )


         SELECT @Counter -= SIGN(COUNT(*))
         FROM [SSISDB].[dbo].[SSISErrors_Last30Days] [a]
         WHERE [a].[operation_id] = @SSISExecutionId
           AND NOT (
                  [a].[Error_Message] LIKE '%deadlock%'
              OR  [a].[Error_Message] LIKE '%TCP Provider%Timeout error%'
              OR  [a].[Error_Message] LIKE '%TCP Provider%The semaphore timeout period has expired%'
              OR  [a].[Error_Message] LIKE '%Unable to complete login process due to delay in opening server connection%'
              OR  [a].[Error_Message] LIKE '%Login timeout expired%' 
               )
      END
      ELSE 
      BEGIN
         SELECT @Counter += SIGN(COUNT(*))
         FROM
         (SELECT ISNULL(@JobMessage,'') AS [Error_Message]) [a]
          WHERE (
                  [a].[Error_Message] LIKE '%deadlock%'
              OR  [a].[Error_Message] LIKE '%TCP Provider%Timeout error%'
              OR  [a].[Error_Message] LIKE '%TCP Provider%The semaphore timeout period has expired%'
              OR  [a].[Error_Message] LIKE '%Unable to complete login process due to delay in opening server connection%'
              OR  [a].[Error_Message] LIKE '%Login timeout expired%' 
         )
      END

      --PRINT @Counter

      IF (@Counter > 0 AND (SELECT COUNT(*) FROM [#RestartedJobs] WHERE [JobName] = @JobName) < 5)
      BEGIN
         SET @RestartJob = 1
         SET @RestartStepName = @JobStepName
         --SET @Subject = 'Automatic restart of SQL Agent job [' + @JobName + '] in failed step [' + @RestartStepName + ']'
         SET @Subject = '[The job RESTARTED.] SQL Server Job System:  [' + @JobName + '] automatically restarted in failed step [' + @RestartStepName + '] on \\' + CAST(@@SERVERNAME AS NVARCHAR(50)) + '.'
      END
      -- Hvis det fejlende job har et dummy step der hedder 'AUTOCOMPLETE_ON_FAIL'
      -- skal jobbet autocompletes og genstartes automatisk i steppet 'STOP - AgentJob'
      ELSE IF EXISTS(
         SELECT * 
         FROM [msdb].dbo.[sysjobs] a
         INNER JOIN [msdb].dbo.[sysjobsteps] b
         ON [b].[job_id] = [a].[job_id]
         WHERE a.[name] = @JobName
         AND b.[step_name] = 'AUTOCOMPLETE_ON_FAIL'
      )
      BEGIN
         SET @RestartJob = 1
         SET @RestartStepName = 'STOP - AgentJob'
         SET @Subject = 'AutoCompletion of SQL Agent job [' + @JobName + '] using step [' + @RestartStepName + ']'
      END
      -- Hvis det fejlende job har et dummy step der hedder 'AUTOSKIP_ON_FAIL'
      -- skal jobbet autoskippes og genstartes automatisk i steppet 'SKIP - AgentJob'
      ELSE IF EXISTS(
         SELECT * 
         FROM [msdb].dbo.[sysjobs] a
         INNER JOIN [msdb].dbo.[sysjobsteps] b
         ON [b].[job_id] = [a].[job_id]
         WHERE a.[name] = @JobName
         AND b.[step_name] = 'AUTOSKIP_ON_FAIL'
      )
      BEGIN
         SET @RestartJob = 1
         SET @RestartStepName = 'SKIP - AgentJob'
         SET @Subject = 'AutoSkip of SQL Agent job [' + @JobName + '] using step [' + @RestartStepName + ']'
      END

      IF (@RestartJob = 1)
      BEGIN
         WAITFOR DELAY '00:00:05'
         --PRINT 'Restarting SQL Agent job [' + @JobName + '] in step [' + @RestartStepName + ']'
         IF NOT EXISTS
         (
            SELECT 1
            FROM [msdb].[dbo].[sysjobs_view] [job]
            INNER JOIN [msdb].[dbo].[sysjobactivity] [activity]
               ON [job].[job_id] = [activity].[job_id]
            CROSS APPLY
            (
               SELECT TOP 1
                  [session_id]
               FROM [msdb].[dbo].[syssessions]
               ORDER BY [agent_start_date] DESC
            ) [CurSess]
            WHERE [activity].[run_requested_date] IS NOT NULL
              AND [activity].[stop_execution_date] IS NULL
              AND [job].[name] = @JobName
              AND [CurSess].[session_id] = [activity].[session_id]
         )
         BEGIN

            DECLARE @StatusGenstarter AS INT = [flw].[StatusIDGenstarter]()
            EXECUTE [flw].[SkiftStatus] @parmJobID = @JobId, @parmStatusID = @StatusGenstarter
            DECLARE @CurrentBatchID AS INT = [flw].[CurrentBatchID](@JobId)
            EXECUTE [flw].[SkrivLog] @parmJobID = @JobId, @parmBatchID = @CurrentBatchID, @parmStatusID = @StatusGenstarter

            --PRINT 'starting job [' + @JobName + '] in step [' + @RestartStepName + ']'
            EXEC msdb.dbo.sp_start_job @job_name = @JobName, @step_name = @RestartStepName
            INSERT INTO #RestartedJobs
            (
               [JobName]
              ,[FailedStepName]
              ,[RestartStepName]
              ,[RestartedAt]
            )
            VALUES
            (
               @JobName, @JobStepName, @RestartStepName, GETDATE()
            )

            --PRINT 'sending mail'
            SELECT @Recipients = [email_address]
            FROM [msdb].[dbo].[sysoperators]
            WHERE [name] = 'BI-drift'

            IF (LEN(ISNULL(@Recipients, '')) = 0)
               SET @Recipients = 'henrik.munch@rm.dk'

            SET @Messages = @JobMessage

            IF EXISTS
            (
               SELECT *
               FROM [msdb].[dbo].[sysmail_profile]
               WHERE [name] = @MailProfile
            )
            BEGIN
               EXEC [msdb].[dbo].[sp_send_dbmail]
                  @profile_name = @MailProfile
                 ,@recipients = @Recipients
                 ,@body = @Messages
                 ,@subject = @Subject
            END
         END
      END
      
      WAITFOR DELAY '00:01:00'
   END
END