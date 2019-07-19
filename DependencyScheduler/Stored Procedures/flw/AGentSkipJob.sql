

-- =============================================
-- Author:		Graves Kilsgaard
-- Create date: 29.08.2014
-- Description:	Job Agent - Error Job afvikles hvis et job skal skippes
-- =============================================
CREATE PROCEDURE [flw].[AGentSkipJob] 
	@parmJobID				AS	uniqueidentifier
AS
BEGIN

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	-- ----- Variable Declaration -----
	DECLARE		@AppLockReturn			AS INT
	DECLARE		@CurrentSPName			AS	VARCHAR(128)		=	(SELECT OBJECT_NAME(@@PROCID))

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
				DECLARE @CurrentBatchID			AS INT				=	[flw].CurrentBatchID(@parmJobID)	
				DECLARE @StatusID				AS INT				=	[flw].[StatusIDSprungetOver]()

				-- ----- Start: Code -----
				-- Log start af job		
				EXECUTE [flw].[SkrivLog]	 @parmJobID			=	@parmJobID
											,@parmBatchID		=	@CurrentBatchID
											,@parmStatusID		=	@StatusID
											,@parmCallerJobID	=	@parmJobID
											,@parmCallerSPName	=	@CurrentSPName
				-- Ændre Status
				EXECUTE [flw].[SkiftStatus]  @parmJobID		=	@parmJobID
											,@parmStatusID	=	@StatusID
	
				-- Aktivere og starter jobs		
				EXECUTE [flw].[AGent_AktiverNaeste] @parmCurrentJobID = @parmJobID
				EXECUTE [flw].[AGent_StartNaeste] @parmCurrentJobID = @parmJobID

				-- ----- Stop: Code -----

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