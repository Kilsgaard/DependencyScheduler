

-- =============================================
-- Author:		Graves Kilsgaard
-- Create date: 29.08.2014
-- Description:	Job Agent - Error Job afvikles ved fejl på job
-- =============================================
CREATE PROCEDURE [flw].[AGentFejlJob] 
	@parmJobID				AS	uniqueidentifier
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	-- ----- Variable Declaration -----
	DECLARE	@AppLockReturn	AS INT

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
			DECLARE	@CurrentBatchID		AS INT				=	[flw].CurrentBatchID(@parmJobID)
			DECLARE @StatusFejl		AS INT					=	[flw].StatusIDFejl()

			-- ----- Start: Code -----
			-- Skift status til Starter
			EXECUTE [flw].[SkiftStatus]  @parmJobID			=	@parmJobID	
										,@parmStatusID		=	@StatusFejl

			-- Log start af job		
			EXECUTE [flw].[SkrivLog]	 @parmJobID			=	@parmJobID
										,@parmBatchID		=	@CurrentBatchID
										,@parmStatusID		=	@StatusFejl
										,@parmSuccess		=	0	-- Fejlet
			
			-- ----- Stop: Code -----

	-- ----- START: Transaction END -----
		-- Get AppLock
		END 
		-- Commit only if the transaction was started in this procedure
		IF @TranCounter = 0
			COMMIT TRANSACTION;
		
		-- Indsæt en række i flw.FailedJobsToTrello
		INSERT INTO flw.FailedJobsToTrello (FailedJobID, FailedDateTime) VALUES (@parmJobID, GETDATE())
					
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