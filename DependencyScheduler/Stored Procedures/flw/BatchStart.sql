
-- =============================================
-- Author:		Graves Kilsgaard
-- Create date: 11.08.2012
-- Description:	Start af Batch Kørsel til afvikling af ETL flow
-- =============================================
CREATE PROCEDURE [flw].[BatchStart]
	@parmJobID				AS	uniqueidentifier
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	-- ----- Variable Declaration -----
	DECLARE	@AppLockReturn		AS	INT
	DECLARE	@DeleteDateTime		AS	DATETIME2 = SYSDATETIME()

	-- ----- START: Transaction Begin -----
	BEGIN TRY 
		-- Get the current transaction count 
		DECLARE @TranCounter INT = @@TRANCOUNT 
				, @SavePoint NVARCHAR(32) = CAST(@@PROCID AS NVARCHAR(20)) + N'_' + CAST(@@NESTLEVEL AS NVARCHAR(2)); 
		-- Decide to join existing transaction or start new 
		IF @TranCounter > 0 
			SAVE TRANSACTION @SavePoint; 
		ELSE 
			BEGIN TRANSACTION;
			-- Get AppLock
			EXEC @AppLockReturn	= sp_getapplock @Resource = 'Scheduler', 
												@LockMode = 'Exclusive'

			IF @AppLockReturn NOT IN (0, 1)
			BEGIN
					RAISERROR ( 'Unable to acquire Lock', 16, 1 )
			END 
			ELSE
			BEGIN
	-- ----- STOP: Transaction Begin -----
			
			-- ----- Variable Declaration -----			
			DECLARE @BatchID					AS	int					=	[flw].[CurrentBatchID](@parmJobID)		
			DECLARE @BatchStartJobID			AS	uniqueidentifier	=	[flw].[BatchStartJobID](@parmJobID)

         -- ----- Opdater Næste Runtime og BatchStart -----
         UPDATE [flw].[JobMasterSetup]
         SET
            NextRun = [flw].[ScheduleCalcNextRun](@BatchStartJobID)
           ,BatchStart = GETDATE()
           ,[BatchStop] = NULL
         WHERE JobID = @BatchStartJobID;

			-- ----- Start: Code -----
			EXECUTE [flw].[Agent_AktiverBatch] @parmBatchID = @BatchID ,@parmStartJobID = @BatchStartJobID
			-- ----- Stop: Code -----

			-- Delete marker jobs for execution på batchid hvis der er nogen
			UPDATE [flw].[JobsForExecution]
				SET [IsDeleted] = 1, [DeleteDateTime] = @DeleteDateTime
			WHERE BatchID = @BatchID
			AND IsDeleted = 0

	-- ----- START: Transaction END -----
			END 
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