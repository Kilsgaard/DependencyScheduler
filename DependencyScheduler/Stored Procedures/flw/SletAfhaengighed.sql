

-- =============================================
-- Author:		Graves Kilsgaard
-- Create date: 26.08.2012
-- Description:	Procedure til sletning af afhængighed
-- =============================================
CREATE PROCEDURE [flw].[SletAfhaengighed]
	-- Add the parameters for the stored procedure here
	@parmParentJobID		uniqueidentifier	= null, 
	@parmParentJobName		varchar(128)		= null,
	@parmChildJobID		uniqueidentifier	= null, 
	@parmChildJobName		varchar(128)		= null
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	-- ----- Variable Declaration -----
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
		IF (@parmParentJobID IS NULL) AND (@parmParentJobName IS NULL)
		BEGIN		
			SET @Return		=	0
			raiserror('Fejl: Der mangler afhængigheds JobID eller JobNavn', 18, 1)	
		END 

		IF (NOT @parmParentJobID IS NULL) AND (NOT @parmParentJobName IS NULL)
		BEGIN
			SET @Return					=	0
			raiserror('Fejl: Både afhængigheds JobID og JobNavn er angivet', 18, 1)	
		END

		IF (@parmParentJobName IS NULL) AND (NOT @parmParentJobID IS NULL)
		BEGIN
			SET @parmParentJobName		=	[flw].JobID2Name(@parmParentJobID)
		END

		IF (NOT @parmParentJobName IS NULL) AND (@parmParentJobID IS NULL)
		BEGIN
			SET @parmParentJobID		=	[flw].JobName2ID(@parmParentJobName)
		END

		IF (@parmParentJobID IS NULL)	OR (@parmParentJobName IS NULL)
		BEGIN
			SET @Return		=	0
			raiserror('Fejl: Problemer med afhængigheds JobID eller JobNavn', 18, 1)		
		END
		-- ----- STOP: Validering af JobID/JobNavn -----
		
		-- ----- START: Validering Job Exists -----
		IF ([flw].ExistsJobListe(@parmParentJobID) = 0)
		BEGIN
			SET @Return		=	0
			raiserror('Fejl: afhængigheds Jobbet eksistere ikke i JobListen', 18, 1)		
		END
		-- ----- STOP: Validering Job Exists -----
		
		-- ----- START: Validering af MasterJobID/JobNavn -----
		IF (@parmChildJobID IS NULL) AND (@parmChildJobName IS NULL)
		BEGIN		
			SET @Return		=	0
			raiserror('Fejl: Der mangler Master JobID eller JobNavn', 18, 1)	
		END 

		IF (NOT @parmChildJobID IS NULL) AND (NOT @parmChildJobName IS NULL)
		BEGIN
			SET @Return		=	0
			raiserror('Fejl: Både Master JobID og JobNavn er angivet', 18, 1)	
		END

		IF (@parmChildJobName IS NULL) AND (NOT @parmChildJobID IS NULL)
		BEGIN
			SET @parmChildJobName		=	[flw].JobID2Name(@parmChildJobID)
		END

		IF (NOT @parmChildJobName IS NULL) AND (@parmChildJobID IS NULL)
		BEGIN
			SET @parmChildJobID		=	[flw].JobName2ID(@parmChildJobName)
		END

		IF (@parmChildJobID IS NULL)	OR (@parmChildJobName IS NULL)
		BEGIN
			SET @Return		=	0
			raiserror('Fejl: Problemer med Master JobID eller JobNavn', 18, 1)		
		END
		-- ----- STOP: Validering af MasterJobID/JobNavn -----

		-- ----- START: Validering Job Exists -----
		IF ([flw].ExistsJobListe(@parmChildJobID) = 0)
		BEGIN
			SET @Return		=	0
			raiserror('Fejl: Master Jobbet eksistere ikke i JobListen', 18, 1)		
		END
		-- ----- STOP: Validering Job Exists -----

		-- ----- START: Eksistere JobAfhængigheden -----
		IF ([flw].[ExistsAfhaengighed](@parmParentJobID, @parmChildJobID) = 0)
		BEGIN
			SET @Return		=	0
			raiserror('Fejl: JobAfhængigheden eksistere ikke', 18, 1)		
		END
		-- ----- START: Eksistere JobAfhængigheden -----

		-- ----- Start: Code -----
		DELETE FROM [flw].[JobAfhaengighed]
			WHERE	[ParentJobID]	=	@parmParentJobID
			  AND	[ChildJobID]	=	@parmChildJobID				 

		SET @Return		=	1
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