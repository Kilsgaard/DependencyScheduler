
-- =============================================
-- Author:		Henrik Munch
-- Create date: 28-09-2018
-- Description:	Procedure til at slette et Job
-- =============================================
CREATE PROCEDURE [flw].[SletJob] 
	-- Add the parameters for the stored procedure here
	@parmJobID			uniqueidentifier	= null, 
	@parmJobName		varchar(128)		= null
AS 
BEGIN

	SET NOCOUNT ON;
	-- ----- Variable Declaration -----
	DECLARE			@Status		AS	INT					=	0
	DECLARE			@Return		AS	Varchar(max)

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
			SET @Return		=	0
			raiserror('Fejl: Der mangler JobID eller JobNavn', 18, 1)	
		END 

		IF (NOT @parmJobID IS NULL) AND (NOT @parmJobName IS NULL)
		BEGIN
			SET @Return		=	0
			raiserror('Fejl: Både JobID og JobNavn er angivet', 18, 1)	
		END

		IF (@parmJobName IS NULL) AND (NOT @parmJobID IS NULL)
		BEGIN
			SET @parmJobName		=	[flw].JobID2Name(@parmJobID)
		END

		IF (NOT @parmJobName IS NULL) AND (@parmJobID IS NULL)
		BEGIN
			SET @parmJobID			=	[flw].JobName2ID(@parmJobName)
		END

		-- ----- START: Validering Job Exists -----
		IF ([flw].ExistsJobListe(@parmJobID) = 0)
		BEGIN
			SET @Return		=	0
			raiserror('Fejl: Jobbet eksisterer ikke i JobListen', 18, 1)		
		END
		-- ----- STOP: Validering Job Exists -----

		-- ----- START: Validering Job ikke batch start eller stop job -----
		IF EXISTS(SELECT * FROM [flw].[JobListe] WHERE [JobID] = @parmJobID AND ( [BatchStartJob] = 1 OR [BatchStopJob] = 1))
      BEGIN
			raiserror('Fejl: Jobbet er et batch start eller stop job og kan ikke slettes', 18, 1)		
		END
		-- ----- STOP: Validering Job ikke batch start eller stop job -----
		
		-- ----- START: Validering jobbet har ingen afhængigheder -----
		IF ((SELECT COUNT(*) FROM [flw].[ListAfhængighedmedNavn] WHERE [ChildJobID] = @parmJobID OR [ParentJobID] = @parmJobID )>0)
      BEGIN
			raiserror('Fejl: Jobbet har job afhængigheder og kan ikke slettes', 18, 1)		
		END
		-- ----- STOP: Validering jobbet har ingen afhængigheder -----
			
      DELETE
      FROM [flw].[JobListe]
      WHERE [JobID] = @parmJobID 

		SET	@Return		=	1
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
	RETURN @Return
END