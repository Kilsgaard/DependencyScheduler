﻿
-- =============================================
-- Author:		Graves Kilsgaard
-- Create date: 26.08.2012
-- Description:	Procedure til oprettelse af nyt Job
-- =============================================
CREATE PROCEDURE [flw].[OpretNytJob] 
	-- Add the parameters for the stored procedure here
	@parmJobID			uniqueidentifier	= null, 
	@parmJobName		varchar(128)		= null,
	@parmBeskrivelse	varchar(200)		= '',
	@parmAktiv			bit					= 0, -- Default = ikke Aktiv
	@parmStatus_ID		int					= 5, -- Status = Inaktiv
	@parmBatchStartJob	bit					= 0, -- Er jobbet et Batch Start Job
	@parmBatchStopJob	bit					= 0, -- Er jobbet et Batch Stop Job
	@parmJobType_ID		int					= 1, -- Kan kun være 1 - AgentJob
   @parmKommentar NVARCHAR(4000) = '',
	@Output				varchar(MAx)		= null output
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
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

		IF (@parmJobID IS NULL)	OR (@parmJobName IS NULL)
		BEGIN
			SET @Return		=	0
			raiserror('Fejl: Problemer med JobID eller JobNavn', 18, 1)		
		END
		-- ----- STOP: Validering af JobID/JobNavn -----

		-- ----- START: Validering af StatusID -----
		IF ([flw].ExistsStatusID(@parmStatus_ID) = 0)
		BEGIN
			SET @Return		=	0
			raiserror('Fejl: StatusID eksistere ikke', 18, 1)		
		END
		-- ----- STOP: Validering af StatusID -----

		-- ----- START: Validering Job Exists -----
		IF ([flw].ExistsJobListe(@parmJobID) = 1)
		BEGIN
			SET @Return		=	0
			raiserror('Fejl: Jobbet eksistere allerede i JobListen', 18, 1)		
		END
		-- ----- STOP: Validering Job Exists -----
		
		-- ----- Start: Code -----
		INSERT INTO [flw].[JobListe]
					  ( [JobID]
					   ,[Aktiv]
					   ,[Beskrivelse]
					   ,[Status_ID]
					   ,[JobType_ID]
					   ,[BatchStartJob]
					   ,[BatchStopJob]
                  ,[Kommentar]
					  )
	         VALUES
   				      ( @parmJobID
					   ,@parmAktiv
					   ,@parmBeskrivelse
					   ,@parmStatus_ID
					   ,@parmJobType_ID
					   ,@parmBatchStartJob
					   ,@parmBatchStopJob
                  ,''
					  );

		-- ----- Skift Status på Agent Job -----
		EXECUTE [flw].[SkiftStatus] @parmJobID	=	@parmJobID  ,@parmStatusID = @parmStatus_ID;
	
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