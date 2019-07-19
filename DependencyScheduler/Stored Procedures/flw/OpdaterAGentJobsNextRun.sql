CREATE PROCEDURE [flw].[OpdaterAGentJobsNextRun] @parmJobID UNIQUEIDENTIFIER
AS
/*
Da der har været problemer med at NextRun Datetime for et SQL Agent Job
ikke altid har været korrekt (mangler at blive opdateret, hvis jobbet ikke er blevet
afviklet på den planlagte schedule alligevel, f.eks fordi at batch flowet ikke 
har kørt som planlagt) vil denne her procedure trigger en opdatering af et jobs 
NextRun Datetime, ved at enable/disable eller disable/enable/disable jobbet

Henrik Munch, 20180211
*/
BEGIN TRY
   SET NOCOUNT ON;

   DECLARE @msg NVARCHAR(4000)
   DECLARE @NextRunDatetime DATETIME

   IF EXISTS
   (
      SELECT *
      FROM [dbo].[sysschedules] AS [sch]
      INNER JOIN [dbo].[sysjobschedules] AS [jsch]
         ON [jsch].[schedule_id] = [sch].[schedule_id]
      INNER JOIN [dbo].[sysjobs] AS [j]
         ON [j].[job_id] = [jsch].[job_id]
      WHERE [sch].[enabled] = 1
        AND [j].[job_id] = @parmJobID
   )
   BEGIN

      SELECT TOP 1 @NextRunDatetime = [next_scheduled_run_date]
      FROM [dbo].[sysjobactivity]
      WHERE [job_id] = @parmJobID
        AND NOT [next_scheduled_run_date] IS NULL
        AND [next_scheduled_run_date] > GETDATE()
      ORDER BY [next_scheduled_run_date]

      INSERT INTO [flw].[SchedulerDebugLog]
      ([CurrentBatchID],[JobId],[DebugMsg],[DebugMtts])
      VALUES(0, @parmJobID, ISNULL(CONVERT(NVARCHAR(500), @NextRunDatetime, 121), '<NULL>'), SYSDATETIME())

      IF EXISTS
      (
         SELECT *
         FROM [dbo].[sysjobs]
         WHERE [job_id] = @parmJobID
           AND [enabled] = 0
      )
      BEGIN
         EXEC [msdb].[dbo].[sp_update_job] @job_id = @parmJobID, @enabled = 1
         WAITFOR DELAY '00:00:00.500'
         EXEC [msdb].[dbo].[sp_update_job] @job_id = @parmJobID, @enabled = 0
      END
      ELSE
      BEGIN
         EXEC [msdb].[dbo].[sp_update_job] @job_id = @parmJobID, @enabled = 0
         WAITFOR DELAY '00:00:00.500'
         EXEC [msdb].[dbo].[sp_update_job] @job_id = @parmJobID, @enabled = 1
         WAITFOR DELAY '00:00:00.500'
         EXEC [msdb].[dbo].[sp_update_job] @job_id = @parmJobID, @enabled = 0
      END

      SELECT TOP 1 @NextRunDatetime = [next_scheduled_run_date]
      FROM [dbo].[sysjobactivity]
      WHERE [job_id] = @parmJobID
        AND NOT [next_scheduled_run_date] IS NULL
        AND [next_scheduled_run_date] > GETDATE()
      ORDER BY [next_scheduled_run_date]

      INSERT INTO [flw].[SchedulerDebugLog]
      ([CurrentBatchID],[JobId],[DebugMsg],[DebugMtts])
      VALUES(0, @parmJobID, ISNULL(CONVERT(NVARCHAR(500), @NextRunDatetime, 121), '<NULL>'), SYSDATETIME())

   END
END TRY
BEGIN CATCH
   THROW;
END CATCH