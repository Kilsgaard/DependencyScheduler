


-- =============================================
-- Author:		Graves Kilsgaard
-- Create date: 12.08.2014
-- Description:	Aktiverer jobs som er klar ifølge afhængighederne
-- =============================================
CREATE PROCEDURE [flw].[AGent_AktiverNaeste] @parmCurrentJobID UNIQUEIDENTIFIER
AS
BEGIN
   -- SET NOCOUNT ON added to prevent extra result sets from
   -- interfering with SELECT statements.
   SET NOCOUNT ON;


   DECLARE @message NVARCHAR(4000)
   DECLARE @result DATETIME

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
      -- ----- Variable Declaration -----
      DECLARE @ChildJobID AS UNIQUEIDENTIFIER
      DECLARE @ParentJobID AS UNIQUEIDENTIFIER

      DECLARE @AntAfhaengigheder AS INT
      DECLARE @NoRun AS INT

      DECLARE @StatusID AS INT
      DECLARE @CurrentBatchID AS INT = [flw].[CurrentBatchID](@parmCurrentJobID)
      DECLARE @CurrentSPName AS VARCHAR(128) = (
                                                  SELECT OBJECT_NAME(@@PROCID)
                                               )

      DECLARE @Messagetxt AS VARCHAR(4000) = ''

      -- ----- Start: Code -----

      -- ----- Find jobs som skal tjekkes for specielle afhængigheder -----
      DECLARE [ChildCursor] CURSOR FOR
      SELECT DISTINCT
         [JAH].[ChildJobID]
      FROM [flw].[JobAfhaengighed] AS [JAH] WITH (NOLOCK)
      WHERE [JAH].[ParentJobID] = @parmCurrentJobID

      -- -----																																		
      OPEN [ChildCursor]
      FETCH NEXT FROM [ChildCursor]
      INTO @ChildJobID
      WHILE (@@FETCH_STATUS = 0)
      BEGIN
         -- ----- Debug -----
         /*
			PRINT '----->' + [flw].[JobID2Name](@ChildJobID)
			PRINT '> JobAfhængighed: ' + CAST([flw].[Agent_JobAfhaengighed](@ChildJobID) AS VARCHAR(50))
			PRINT '> JobSkip (Inaktiv/Udenfor Batch/Sprunget Over): ' + CAST([flw].[Agent_JobAfhaengighedSkip](@ChildJobID) AS VARCHAR(50))
			PRINT '> JobSlut OK: ' + CAST([flw].[Agent_JobAfhaengighedSlut](@ChildJobID) AS VARCHAR(50))
			*/
         -- ----- Variables -----
         SET @Messagetxt = ''

         -- ----- Hvis StartJob -----
         IF ([flw].[BatchStartJob](@ChildJobID) = 1)
         BEGIN
            -- ----- Debug -----
            --PRINT '----> BatchSlut'

            -- ----- Set Status -----				
            SET @StatusID = [flw].[StatusIDBatchStart]()

            EXECUTE [flw].[SkiftStatus] @parmJobID = @ChildJobID, @parmStatusID = @StatusID
         END
         -- ----- Hvis aktiv Schedule		   -----	
         --       Og Jobbet ikke er sat inaktiv -----
         ELSE IF (
                    [flw].[ExistsAgentJobSchedule](@ChildJobID) > 0
               AND  [flw].[JobStatusID](@ChildJobID) <> [flw].[StatusIDInaktiv]()
                 )
         BEGIN
            -- ----- Hvis Schedule inden for denne batch Bare sæt til SchedulerStart
            --			Ellers skal jobbet sættes uden for batch
            IF ([flw].[ScheduleNextRun](@ChildJobID) > [flw].[BatchStartNextRun]([flw].[BatchStartJobID](@ChildJobID)))
            BEGIN
               -- ----- Debug -----
               --PRINT '----> Uden for Batch'

               --childjob
               SET @result = ([flw].[ScheduleNextRun](@ChildJobID))
               SET @message = 'Result 1 : ' + ISNULL(CONVERT(NVARCHAR(50), @result, 121), N'<NULL>')

               INSERT INTO [flw].[SchedulerDebugLog]([CurrentBatchID],[JobId],[DebugMsg],[DebugMtts])
               VALUES(@CurrentBatchID, @ChildJobID, @message, SYSDATETIME())

               --batchstartjob
               SET @result = ([flw].[BatchStartNextRun]([flw].[BatchStartJobID](@ChildJobID)))
               SET @message = 'Result 2 : ' + ISNULL(CONVERT(NVARCHAR(50), @result, 121), N'<NULL>')

               INSERT INTO [flw].[SchedulerDebugLog]([CurrentBatchID],[JobId],[DebugMsg],[DebugMtts])
               VALUES(@CurrentBatchID, [flw].[BatchStartJobID](@ChildJobID), @message, SYSDATETIME())


               -- ----- Set Status -----
               SET @StatusID = [flw].[StatusIDUdenforBatch]()

               EXECUTE [flw].[SkiftStatus] @parmJobID = @ChildJobID, @parmStatusID = @StatusID
               -- ----- Log start af job		
               SET @Messagetxt
                  = 'Schedulen skal ikke startes inden for dette batch vindue' + ' - BatchJobbet kører igen: ' + CAST([flw].[BatchStartNextRun]([flw].[BatchStartJobID](@ChildJobID)) AS VARCHAR(50)) + ' - Scheduleren skal køre igen: '
                    + CAST([flw].[ScheduleNextRun](@ChildJobID) AS VARCHAR(50))

               EXECUTE [flw].[SkrivLog]
                  @parmJobID = @ChildJobID
                 ,@parmBatchID = @CurrentBatchID
                 ,@parmStatusID = @StatusID
                 ,@parmCallerJobID = @parmCurrentJobID
                 ,@parmCallerSPName = @CurrentSPName
                 ,@parmMessage = @Messagetxt
            END
            ELSE
            BEGIN

               --childjob
               SET @result = ([flw].[ScheduleNextRun](@ChildJobID))
               SET @message = 'Result 3 : ' + ISNULL(CONVERT(NVARCHAR(50), @result, 121), N'<NULL>')

               INSERT INTO [flw].[SchedulerDebugLog]([CurrentBatchID],[JobId],[DebugMsg],[DebugMtts])
               VALUES(@CurrentBatchID, @ChildJobID, @message, SYSDATETIME())

               --batchstartjob
               SET @result = ([flw].[BatchStartNextRun]([flw].[BatchStartJobID](@ChildJobID)))
               SET @message = 'Result 4 : ' + ISNULL(CONVERT(NVARCHAR(50), @result, 121), N'<NULL>')

               INSERT INTO [flw].[SchedulerDebugLog]([CurrentBatchID],[JobId],[DebugMsg],[DebugMtts])
               VALUES(@CurrentBatchID, [flw].[BatchStartJobID](@ChildJobID), @message, SYSDATETIME())

               -- ----- Debug -----
               --PRINT '----> SchedulerStart'

               -- ----- Set Status -----
               SET @StatusID = [flw].[StatusIDSchedulerStart]()

               EXECUTE [flw].[SkiftStatus] @parmJobID = @ChildJobID, @parmStatusID = @StatusID
               -- ----- Log start af job		
               SET @Messagetxt
                  = 'Schedulen skal startes inden for dette batch vindue' + ' - BatchJobbet kører igen: ' + CAST([flw].[BatchStartNextRun]([flw].[BatchStartJobID](@ChildJobID)) AS VARCHAR(50)) + ' - Scheduleren skal køre igen: '
                    + CAST([flw].[ScheduleNextRun](@ChildJobID) AS VARCHAR(50))

               EXECUTE [flw].[SkrivLog]
                  @parmJobID = @ChildJobID
                 ,@parmBatchID = @CurrentBatchID
                 ,@parmStatusID = @StatusID
                 ,@parmCallerJobID = @parmCurrentJobID
                 ,@parmCallerSPName = @CurrentSPName
                 ,@parmMessage = @Messagetxt
            END
         END
         -- ----- Hvis Antalafhængigheder er = 0
         ELSE IF (
                    [flw].[Agent_JobAfhaengighed](@ChildJobID) = 0
               AND  [flw].[BatchStartJob](@ChildJobID) = 0
                 )
         BEGIN
            -- ----- Hvis foregående jobs er har været skipped -----
            -- 			og ingen slut ok, så skip dette 
            IF (
                  [flw].[Agent_JobAfhaengighedSkip](@ChildJobID) > 0
             AND  [flw].[Agent_JobAfhaengighedSlut](@ChildJobID) = 0
             AND  [flw].[Agent_JobAfhaengighedDisabled](@ChildJobID) = 0
               )
            BEGIN
               -- ----- Debug -----
               --PRINT '----> Status SpringOver'

               -- ----- Set Status -----
               SET @StatusID = [flw].[StatusIDSprungetOver]()

               EXECUTE [flw].[SkiftStatus] @parmJobID = @ChildJobID, @parmStatusID = @StatusID
               -- ----- Log start af job		
               EXECUTE [flw].[SkrivLog]
                  @parmJobID = @ChildJobID
                 ,@parmBatchID = @CurrentBatchID
                 ,@parmStatusID = @StatusID
                 ,@parmCallerJobID = @parmCurrentJobID
                 ,@parmCallerSPName = @CurrentSPName

            END
            -- ----- Hvis jobbet er sat til status Inaktiv -----
            ELSE IF ([flw].[JobStatusID](@ChildJobID) = [flw].[StatusIDInaktiv]())
            BEGIN
               -- ----- Debug -----
               --PRINT '----> Status SpringOver'

               -- ----- Set Status -----
               SET @StatusID = [flw].[StatusIDInaktivKlar]()

               EXECUTE [flw].[SkiftStatus] @parmJobID = @ChildJobID, @parmStatusID = @StatusID
               -- ----- Log start af job		
               EXECUTE [flw].[SkrivLog]
                  @parmJobID = @ChildJobID
                 ,@parmBatchID = @CurrentBatchID
                 ,@parmStatusID = @StatusID
                 ,@parmCallerJobID = @parmCurrentJobID
                 ,@parmCallerSPName = @CurrentSPName

            END
            ELSE
            BEGIN
               -- ----- Debug -----
               --PRINT '----> Status Klar'

               -- ----- Set Status -----
               SET @StatusID = [flw].[StatusIDKlar]()

               EXECUTE [flw].[SkiftStatus] @parmJobID = @ChildJobID, @parmStatusID = @StatusID
               -- ----- Log start af job		
               EXECUTE [flw].[SkrivLog]
                  @parmJobID = @ChildJobID
                 ,@parmBatchID = @CurrentBatchID
                 ,@parmStatusID = @StatusID
                 ,@parmCallerJobID = @parmCurrentJobID
                 ,@parmCallerSPName = @CurrentSPName

            END
         END

         -- ---- Næste fra ChildCursor 
         FETCH NEXT FROM [ChildCursor]
         INTO @ChildJobID
      END
      -- -----
      CLOSE [ChildCursor]
      DEALLOCATE [ChildCursor]
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