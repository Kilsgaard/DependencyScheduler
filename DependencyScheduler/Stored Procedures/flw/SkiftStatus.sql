
-- =============================================
-- Author:		Graves Kilsgaard
-- Create date: 12.08.2014
-- Description:	Skifter status på Job i JobListe
-- =============================================
CREATE PROCEDURE [flw].[SkiftStatus] 
	-- Add the parameters for the stored procedure here
	@parmJobID			uniqueidentifier	=	null, 
	@parmJobName		varchar(128)		=	null,
	@parmStatusID		int					=	-1
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

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
	-- ----- STOP: Transaction Begin -----

		-- ----- START: Validering af JobID/JobNavn -----
		IF (@parmJobID IS NULL) AND (@parmJobName IS NULL)
		BEGIN
			raiserror('Fejl: Der mangler JobID eller JobNavn', 18, 1)
			RETURN	0
		END 

		IF (NOT @parmJobID IS NULL) AND (NOT @parmJobName IS NULL)
		BEGIN
			raiserror('Fejl: Både JobID og JobNavn er angivet', 18, 1)
			RETURN	0
		END

		IF (@parmJobName IS NULL) AND (NOT @parmJobID IS NULL)
		BEGIN
			SET @parmJobName		=	[flw].JobID2Name(@parmJobID)
		END

		IF (NOT @parmJobName IS NULL) AND (@parmJobID IS NULL)
		BEGIN
			SET @parmJobID			=	[flw].JobName2ID(@parmJobName)
		END

		IF (@parmJobID IS NULL)	OR (@parmJobName IS NULL)
		BEGIN
			raiserror('Fejl: Problemer med JobID eller JobNavn', 18, 1)
			RETURN	0
		END
		-- ----- STOP: Validering af JobID/JobNavn -----

		-- ----- START: Validering af Status_ID -----
		IF ([flw].[ExistsStatusID](@parmStatusID) = 0)
		BEGIN
			raiserror('Fejl: Status_ID eksistere ikke', 18, 1)
			RETURN	0
		END
		-- ----- STOP: Validering af Status_ID -----

		-- ----- Start: Code -----
		IF EXISTS (SELECT Status_ID 
					 FROM [flw].[JobStatus]
					WHERE Status_ID		=	@parmStatusID
				  ) 
			IF EXISTS (SELECT JobID 
						 FROM [flw].[JobListe]
						WHERE JobID		=	@parmJobID
					  )
		BEGIN
			DECLARE @AgentEnabled AS INT		=	[flw].AgentJobEnabled(@parmStatusID)

			UPDATE	[flw].[JobListe]
			   SET	Status_ID		=	@parmStatusID
			 WHERE	JobID			=	@parmJobID
	
			IF (@AgentEnabled = 0 OR @AgentEnabled = 1)
			BEGIN
				EXEC msdb.dbo.sp_update_job @job_id = @parmJobID, @enabled = @AgentEnabled	
			END
		END
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