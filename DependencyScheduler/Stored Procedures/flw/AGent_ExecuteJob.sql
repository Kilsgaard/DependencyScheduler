

-- =============================================
-- Author:		Henrik Munch
-- Create date: 2015-10-25
-- Description:	Executer et Sql Agent i Execution køen
-- =============================================
CREATE PROCEDURE [flw].[AGent_ExecuteJob]
	 @parmExecuterJobID		uniqueidentifier
	,@DelayInSeconds		INT					= 2
AS
BEGIN

	SET NOCOUNT ON;	

	-- ----- DEBUG 
	/*
	DECLARE	@parmExecuterJobID		uniqueidentifier	= 'AB845CBC-1C20-41B5-9BBB-76916183CE1F'
	DECLARE @DelayInSeconds			INT					= 5
	*/
	-- Restart af logik label
	StartExecution:

	BEGIN TRY 

		IF @DelayInSeconds IS NULL 
		OR @DelayInSeconds < 2
			SET @DelayInSeconds = 2
		IF @DelayInSeconds > 10
			SET @DelayInSeconds = 10

		DECLARE @BatchId		INT					=	[flw].[CurrentBatchID](@parmExecuterJobID)
		DECLARE	@CurrentSPName	VARCHAR(128)		=	(SELECT OBJECT_NAME(@@PROCID))
		DECLARE @LogMessage		VARCHAR(4000)		=	''
		DECLARE	@StatusID		INT
		DECLARE @JobId			UNIQUEIDENTIFIER
		DECLARE @JobIdString	NVARCHAR(50)
		DECLARE @JobStepName	NVARCHAR(128)
		DECLARE @ExecutionID	INT
		

		DECLARE	@AppLockReturn		AS	INT
		DECLARE @TranCounter INT = @@TRANCOUNT 
				, @SavePoint NVARCHAR(32) = CAST(@@PROCID AS NVARCHAR(20)) + N'_' + CAST(@@NESTLEVEL AS NVARCHAR(2)); 

		IF @TranCounter > 0 
			SAVE TRANSACTION @SavePoint; 
		ELSE 
			BEGIN TRANSACTION;

		EXEC @AppLockReturn	= sp_getapplock @Resource = 'Scheduler', 
											@LockMode = 'Exclusive'

		IF @AppLockReturn NOT IN (0, 1)
		BEGIN
			RAISERROR ( 'Unable to acquire Lock', 16, 1 )
		END 

		-- Nuværende BatchId
		SET @JobId				= NULL
		SET @JobStepName		= NULL
		SET @ExecutionID		= NULL

		-- Næste job til afvikling i Nuværende BatchId, der ikke allerede er startet og som ikke er slette-markeret
		SELECT TOP 1 @JobId				= [JobID]
					,@JobStepName		= [JobStepName]
					,@ExecutionID		= [ExecutionID]
		  FROM [flw].[JobsForExecution]
		 WHERE [CallingJobID]			=	@parmExecuterJobID
		   AND [BatchID]				=	@BatchId
		   AND ExecutionStatus			=	0
		   AND IsDeleted				=	0
		ORDER BY ExecutionID ASC
		
		IF(@JobId IS NOT NULL)
		BEGIN
			SET @JobIdString = CAST(@JobId AS NVARCHAR(50))
	
			-- Hvis jobbet findes startes det, ellers meldes fejl
			IF EXISTS
			(
				SELECT * 
				  FROM [dbo].[sysjobs]	as	j WITH (NOLOCK)
				 WHERE j.job_id			=	@JobId
			)
			BEGIN
				--Hvis der ikke er angivet et step navn startes jobbet i default start step
				--Ellers startes jobbet i det angivne step, hvis det findes ellers meldes fejl
				IF (@JobStepName is null or LEN(@JobStepName)=0)
				BEGIN
					-- ----- Log Start Execution
					SET @StatusID	=	[flw].[StatusIDAfvikler]()
					SET @LogMessage	=	'Starter jobbet i: StartStep'

					EXECUTE [flw].[SkrivLog]	 @parmJobID			=	@JobId
												,@parmBatchID		=	@BatchId
												,@parmStatusID		=	@StatusID
												,@parmCallerJobID	=	@parmExecuterJobID
												,@parmCallerSPName	=	@CurrentSPName
												,@parmMessage		=	@LogMessage	

					-- -----
					EXEC [dbo].[sp_start_job] @job_id=@JobId
				END
				ELSE
					IF EXISTS
					(
						    SELECT * 
							  FROM [dbo].[sysjobs]		as	j WITH (NOLOCK)
						INNER JOIN [dbo].[sysjobsteps]	as	js WITH (NOLOCK)
								ON j.job_id				=	js.job_id 
							 WHERE j.job_id				=	@JobId
							   AND js.step_name			=	RTRIM(@JobStepName)
					)
					BEGIN
						-- ----- Log Start Execution
						SET @StatusID	=	[flw].[StatusIDAfvikler]()
						SET @LogMessage	=	'Starter jobbet i: ' + CAST(@JobStepName AS NVARCHAR(500))

						EXECUTE [flw].[SkrivLog]	 @parmJobID			=	@JobId
													,@parmBatchID		=	@BatchId
													,@parmStatusID		=	@StatusID
													,@parmCallerJobID	=	@parmExecuterJobID
													,@parmCallerSPName	=	@CurrentSPName
													,@parmMessage		=	@LogMessage	
						-- -----
						EXEC [dbo].[sp_start_job] @job_id=@JobId, @step_name=@JobStepName
					END
					ELSE
					BEGIN
						-- ----- Log Error Execution
						SET @StatusID	=	[flw].[StatusIDFejl]()

						EXECUTE [flw].[SkrivLog]	 @parmJobID			=	@JobId
													,@parmBatchID		=	@BatchId
													,@parmStatusID		=	@StatusID
													,@parmCallerJobID	=	@parmExecuterJobID
													,@parmCallerSPName	=	@CurrentSPName
													,@parmMessage		=	'Jobbet eksistere ikke'

						-- -----
						RAISERROR ( '@BatchId ''%i'', Step ''%s'' in JobId ''%s'' does not exist', 16, 1, @BatchId, @JobStepName, @JobIdString)
					END
			END
			ELSE
			BEGIN
				-- ----- Log Error Execution
				SET @StatusID	=	[flw].[StatusIDFejl]()

				EXECUTE [flw].[SkrivLog]	 @parmJobID			=	@JobId
											,@parmBatchID		=	@BatchId
											,@parmStatusID		=	@StatusID
											,@parmCallerJobID	=	@parmExecuterJobID
											,@parmCallerSPName	=	@CurrentSPName
											,@parmMessage		=	'Jobbet eksistere ikke'

				-- -----
				RAISERROR ( '@BatchId ''%i'', JobId ''%s'' does not exist', 16, 1, @BatchId, @JobIdString)
			END

			-- Opdater JobExecution MetaData
			UPDATE [flw].[JobsForExecution]
			   SET  ExecutionStatus			= 1
				   ,ExecutionDateTime		= SYSDATETIME()
			 WHERE [BatchID]				= @BatchId
			   AND ExecutionID				= @ExecutionID
		END
	
		IF @TranCounter = 0
			COMMIT TRANSACTION;

	END TRY
	BEGIN CATCH
		IF @TranCounter = 0
			ROLLBACK TRANSACTION;
		ELSE IF XACT_STATE() = 1
			ROLLBACK TRANSACTION @SavePoint
		ELSE IF XACT_STATE() = -1
			ROLLBACK TRANSACTION;

		THROW;
		RETURN 1;
	END CATCH

	-- Sover i @DelayInSeconds antal sekunder
	WAITFOR DELAY @DelayInSeconds

	-- Hvis flere jobs - hopper tilbage til label StartExecution

	IF (SELECT TOP 1 [JobID]
		  FROM [flw].[JobsForExecution]
		 WHERE [CallingJobID]		=	@parmExecuterJobID
		   AND [BatchID]			=	@BatchId
		   AND ExecutionStatus		=	0
		   AND IsDeleted			=	0
		ORDER BY ExecutionID ASC
	   ) IS NOT NULL
	BEGIN
		GOTO StartExecution;
	END
END