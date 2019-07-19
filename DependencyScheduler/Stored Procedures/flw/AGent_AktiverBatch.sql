
-- =============================================
-- Author:		Graves Kilsgaard
-- Create date: 11.08.2014
-- Description:	Disabler alle agent jobs som optræder i etl.Jobliste
-- =============================================
CREATE PROCEDURE [flw].[AGent_AktiverBatch]
   -- Add the parameters for the stored procedure here
   @parmBatchID    INT
  ,@parmStartJobID UNIQUEIDENTIFIER
AS
BEGIN
   -- SET NOCOUNT ON added to prevent extra result sets from
   -- interfering with SELECT statements.
   SET NOCOUNT ON;
   -- ----- Variable Declaration -----
   DECLARE @CurrentSPName AS VARCHAR(128) = (SELECT OBJECT_NAME(@@PROCID))

   -- ----- START: Transaction Begin -----
   BEGIN TRY
      -- Get the current transaction count 
      DECLARE
         @TranCounter INT = @@TRANCOUNT
        ,@SavePoint NVARCHAR(32) = CAST(@@PROCID AS NVARCHAR(20)) + N'_' + CAST(@@NESTLEVEL AS NVARCHAR(2));
      -- Decide to join existing transaction or start new 
      IF @TranCounter > 0
         SAVE TRANSACTION @SavePoint;
      ELSE
         BEGIN TRANSACTION;
      -- ----- STOP: Transaction Begin -----

      -- ----- DECLARE Variables -----
      DECLARE @JobID AS UNIQUEIDENTIFIER
      DECLARE @CurrentBatchID AS INT = [flw].[CurrentBatchID](@parmStartJobID)
      DECLARE @StatusID AS INT = [flw].[StatusIDVenter]()

      -- ----- Start: Code -----
      -- ----- Rekrusivt kald Find alle jobs for den påglædende Batch -----
      DECLARE [UpdateCursor] CURSOR FOR 
         WITH [CTE] ([ParentJobID], [ChildJobID], [Level]) AS
            (
               SELECT
                  [JAF].[ParentJobID]
               ,[JAF].[ChildJobID]
               ,0 AS [Level]
               FROM [flw].[JobAfhaengighed] AS [JAF]
               WHERE [JAF].[ParentJobID] = @parmStartJobID
               UNION ALL
               SELECT
                  [JAF].[ParentJobID]
               ,[JAF].[ChildJobID]
               ,[Level] + 1
               FROM [flw].[JobAfhaengighed] AS [JAF]
               CROSS APPLY
               (
                  SELECT [BatchStartJob]
                  FROM [flw].[JobListe] AS [jl]
                  WHERE [jl].[JobID] = [JAF].[ChildJobID]
                  AND [jl].[BatchStartJob] = 0
               ) AS [Job]
               INNER JOIN [CTE]
                  ON [JAF].[ParentJobID] = [CTE].[ChildJobID]
            )
      SELECT DISTINCT [ChildJobID]
      FROM [CTE];

      -- ----- Loop Cursor med alle jobs -----	
      OPEN [UpdateCursor]
      FETCH NEXT FROM [UpdateCursor]
      INTO @JobID
      WHILE (@@FETCH_STATUS = 0)
      BEGIN
         -- ----- GraKil - 16.09.2014 - kun aktive jobs må køres
         IF ([flw].[JobAktiv](@JobID) = 0)
            SET @StatusID = [flw].[StatusIDInaktiv]()
         ELSE
            SET @StatusID = [flw].[StatusIDVenter]()
         -- ----- GraKil - 16.09.2014 - kun aktive jobs må køres

         EXECUTE [flw].[SkiftStatus] @parmJobID = @JobID, @parmStatusID = @StatusID
         
         EXECUTE  [flw].[OpdaterAGentJobsNextRun] @parmJobID = @JobID
         	
         -- Log start af job			
         EXECUTE [flw].[SkrivLog]
            @parmJobID = @JobID
           ,@parmBatchID = @CurrentBatchID
           ,@parmStatusID = @StatusID
           ,@parmCallerJobID = @parmStartJobID
           ,@parmCallerSPName = @CurrentSPName
         -- ----- END LOOP -----
         FETCH NEXT FROM [UpdateCursor]
         INTO @JobID
      END
      -- -----
      CLOSE [UpdateCursor]
      DEALLOCATE [UpdateCursor]
      -- ----- Stop: Code -----

      -- ----- START: Transaction END -----
      -- Commit only if the transaction was started in this procedure
      IF @TranCounter = 0
         COMMIT TRANSACTION;
   END TRY
   BEGIN CATCH
      -- Only rollback if transaction was started in this procedure
      IF @TranCounter = 0
         ROLLBACK TRANSACTION;
      -- It's not our transaction but it's still OK
      ELSE IF XACT_STATE() = 1
         ROLLBACK TRANSACTION @SavePoint
      -- All hope is lot - rollback!
      ELSE IF XACT_STATE() = -1
         ROLLBACK TRANSACTION;

      THROW;
      RETURN 1;
   END CATCH
-- ----- STOP: Transaction END -----
END