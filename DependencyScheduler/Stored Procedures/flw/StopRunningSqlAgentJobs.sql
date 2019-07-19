

CREATE PROCEDURE [flw].[StopRunningSqlAgentJobs]
  @CallingJobID UNIQUEIDENTIFIER = NULL,
  @CallingJobName NVARCHAR(256) = NULL,
  @JobNameLike NVARCHAR(256) = N''
AS
BEGIN
  --SET @CallingJobID = '68B840C7-2A64-47A2-B43B-95813AC0ECA9'
  --SET @JobNameLike = N'BI - gnyf - %'

  DECLARE @JobName NVARCHAR(256)
  DECLARE @MailProfile NVARCHAR(500)
  DECLARE @Messages NVARCHAR(MAX)
  DECLARE @Subject NVARCHAR(4000)
  DECLARE @Recipients NVARCHAR(4000)

  SET @JobNameLike = RTRIM(@JobNameLike)

  IF (@JobNameLike = NULL OR LEN(@JobNameLike) = 0 OR @JobNameLike = '%')
  BEGIN
    PRINT 'invalid parms'  
  END
  ELSE BEGIN
    SET @JobName = N''
    SET @MailProfile = REPLACE(REPLACE(@@SERVERNAME, @@SERVICENAME, ''), '\', '')

    IF (@CallingJobID IS NOT NULL)
    BEGIN
       SELECT @CallingJobName = [name]
       FROM [msdb].[dbo].[sysjobs]
       WHERE [job_id] = @CallingJobID
    END

    SET @CallingJobName = ISNULL(@CallingJobName, '<No Job provided>')

    DECLARE csr_flwjobsrunning CURSOR FAST_FORWARD READ_ONLY FOR
    SELECT [job].[name]
    FROM [msdb].[dbo].[sysjobs] [job]
    INNER JOIN [msdb].[dbo].[sysjobactivity] [activity]
       ON [job].[job_id] = [activity].[job_id]
    CROSS APPLY (
       SELECT TOP 1 [session_id]
       FROM [msdb].[dbo].[syssessions]
       ORDER BY [agent_start_date] DESC
    ) [CurSess]
    WHERE [activity].[run_requested_date] IS NOT NULL
    AND [activity].[stop_execution_date] IS NULL
    AND [job].[name] LIKE @JobNameLike
    AND [CurSess].[session_id] = [activity].[session_id]
    AND ( [job].[job_id] != @CallingJobID OR @CallingJobID IS NULL)
    -- Vi må aldrig stoppe BatchStart og BatchStopJobs
    AND [job].[name] NOT IN (
      SELECT [Job Navn]
      FROM [BIAdmin].[flw].[ListJobs]
      WHERE [BatchStartJob] = 1
      OR [BatchStopJob] = 1
    )

    OPEN csr_flwjobsrunning

    FETCH NEXT FROM csr_flwjobsrunning
    INTO @JobName

    WHILE @@FETCH_STATUS = 0
    BEGIN
       --PRINT @JobName 

       IF EXISTS
       (
          SELECT 1
          FROM [msdb].[dbo].[sysjobs] [job]
          INNER JOIN [msdb].[dbo].[sysjobactivity] [activity]
             ON [job].[job_id] = [activity].[job_id]
          CROSS APPLY (
            SELECT TOP 1 [session_id]
            FROM [msdb].[dbo].[syssessions]
            ORDER BY [agent_start_date] DESC
          ) [CurSess]
          WHERE [activity].[run_requested_date] IS NOT NULL
          AND [activity].[stop_execution_date] IS NULL
          AND [job].[name] = @JobName
          AND [CurSess].[session_id] = [activity].[session_id]
       )
       BEGIN
          EXEC msdb.dbo.sp_stop_job @job_name = @JobName

          SELECT @Recipients = [email_address]
          FROM [msdb].[dbo].[sysoperators]
          WHERE [name] = 'BI-drift'

          IF (LEN(ISNULL(@Recipients, '')) = 0)
             SET @Recipients = 'henrik.munch@rm.dk'

          SET @Subject = 'Kørende job slået ned af job [' + @CallingJobName + ']' 
          SET @Messages = @JobName

          IF EXISTS (
             SELECT *
             FROM [msdb].[dbo].[sysmail_profile]
             WHERE [name] = @MailProfile
          )
          BEGIN
             EXEC [msdb].[dbo].[sp_send_dbmail]
                @profile_name = @MailProfile
               ,@recipients = @Recipients
               ,@body = @Messages
               ,@subject = @Subject;
          END
       END
       WAITFOR DELAY '00:00:02'
       FETCH NEXT FROM csr_flwjobsrunning
       INTO @JobName
    END

    CLOSE csr_flwjobsrunning
    DEALLOCATE csr_flwjobsrunning
    
  END
    
END