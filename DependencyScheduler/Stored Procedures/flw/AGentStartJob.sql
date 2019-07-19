
-- =============================================
-- Author:		Graves Kilsgaard
-- Create date: 12.08.2014
-- Description:	Job Agent - START JOB
-- =============================================
CREATE PROCEDURE [flw].[AGentStartJob] 
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

			-- ----- Start: Code -----

			-- ----- Variable Declaration -----	
			DECLARE @StatusAfvikler	AS INT				=	[flw].StatusIDAfvikler()

			-- ----- Hvis jobbet er BatchStartJob, træk et nyt BatchID for at starte Ny Batch kørsel -----
			IF ([flw].[BatchStartJob](@parmJobID) = 1)
			BEGIN
				EXEC [flw].[OpretNyBatchID]				@parmJobID = @parmJobID
			END

			-- ----- Skift status til Starter -----
			EXECUTE [flw].[SkiftStatus]  @parmJobID			= @parmJobID	
										,@parmStatusID		= @StatusAfvikler

			-- Log start af job		
			DECLARE @CurrentBatchID		AS INT				= [flw].CurrentBatchID(@parmJobID)	

			EXECUTE [flw].[SkrivLog]	 @parmJobID		=	@parmJobID
										,@parmBatchID	=	@CurrentBatchID
										,@parmStatusID	=	@StatusAfvikler
			-- ----- Stop: Code -----

	-- ----- START: Transaction END -----
		-- Get AppLock
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