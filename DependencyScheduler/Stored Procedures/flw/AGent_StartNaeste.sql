

-- =============================================
-- Author:		Graves Kilsgaard
-- Create date: 13.08.2014
-- Description:	Starter Aktiverede jobs
-- =============================================
CREATE PROCEDURE [flw].[AGent_StartNaeste]
	@parmCurrentJobID	uniqueidentifier
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
		
		-- ----- Variable Declaration -----
		DECLARE		@ChildJobID				AS	uniqueidentifier
		DECLARE		@StatusID				AS	INT
		DECLARE		@CurrentBatchID			AS	INT	
		DECLARE		@charJobID				AS	varchar(36)	
		DECLARE		@SQLCommand				AS	varchar(1000)
		DECLARE		@CurrentSPName			AS	VARCHAR(128)		=	(SELECT OBJECT_NAME(@@PROCID))


		-- ----- Find jobs som skal tjekkes for specielle afhængigheder -----
		DECLARE ChildCursor CURSOR FOR
		 SELECT DISTINCT  JAH.ChildJobID
		   FROM	[flw].[JobAfhaengighed]			AS	JAH WITH (NOLOCK)
		  WHERE	JAH.ParentJobID					=	@parmCurrentJobID

		-- -----																																		
	 	 OPEN ChildCursor
		FETCH NEXT FROM ChildCursor INTO @ChildJobID
		WHILE ( @@FETCH_STATUS = 0 )
		BEGIN
			-- ----- Må ikke starte hvis vi er nået til Start Jobbet -----
			IF ([flw].[BatchStartJob](@ChildJobID)		= 0)
			BEGIN
				-- ----- Hvis Jobbet er Markeret som klar til at køre, så skal vi starte ved start step -----
				-- GraKil - 2015.02.15 Tilføjet JobAktiv da flowet ikke tager højde for deaktiverede jobs iløbet af et flow -----
				IF ([flw].[JobStatusID](@ChildJobID)		= [flw].[StatusIDKlar]())
				BEGIN
					IF ([flw].[JobAktiv](@ChildJobID)	= 1)
					BEGIN
						-- Skift status til Starter
						SET	@StatusID									=	[flw].[StatusIDManuelStart]()
						SET @CurrentBatchID								=	[flw].CurrentBatchID(@ChildJobID)	

						EXECUTE [flw].[SkiftStatus]  @parmJobID			=	@ChildJobID
													,@parmStatusID		=	@StatusID

						-- Log start af job		
						EXECUTE [flw].[SkrivLog]	 @parmJobID			=	@ChildJobID
													,@parmBatchID		=	@CurrentBatchID
													,@parmStatusID		=	@StatusID
													,@parmCallerJobID	=	@parmCurrentJobID
													,@parmCallerSPName	=	@CurrentSPName
													,@parmMessage		=	'Sætter jobbet klar til at starte i StartStep'

			
						-- Start job
						--SET @charJobID									=	cast(@ChildJobID as varchar(36))
						--SET	@SQLCommand									=	'msdb.dbo.sp_start_job @job_id = ''' + @charJobID + ''' ,@step_name=''START - AgentJob'''

						--EXEC (@SQLCommand) at [loopback]		
						
						-- Hvis der allerede findes en job til execution indenfor samme batchid, slette markeres det og et nyt sættes ind
						IF EXISTS
						(
							SELECT [JobID] FROM [flw].[JobsForExecution] 
							WHERE [BatchID] = @CurrentBatchID AND [JobID] = @ChildJobID 
							AND IsDeleted = 0
						)
						BEGIN
							UPDATE [flw].[JobsForExecution]
							SET IsDeleted = 1, DeleteDateTime = SYSDATETIME()
							WHERE [BatchID] = @CurrentBatchID 
							AND [JobID] = @ChildJobID 
							AND IsDeleted = 0
						END

						-- Nyt job til execution sættes ind
						INSERT INTO [flw].[JobsForExecution]
						([BatchID],[CallingJobID],[JobID],[JobStepName])
						VALUES(@CurrentBatchID,@parmCurrentJobID,@ChildJobID,'START - AgentJob')
					END
					ELSE IF ([flw].[JobAktiv](@ChildJobID)	= 0)
					BEGIN
						-- Skift status til Starter
						SET	@StatusID									=	[flw].[StatusIDManuelStart]()
						SET @CurrentBatchID								=	[flw].CurrentBatchID(@ChildJobID)	

						EXECUTE [flw].[SkiftStatus]  @parmJobID			=	@ChildJobID
													,@parmStatusID		=	@StatusID

						-- Log start af job		
						EXECUTE [flw].[SkrivLog]	 @parmJobID			=	@ChildJobID
													,@parmBatchID		=	@CurrentBatchID
													,@parmStatusID		=	@StatusID
													,@parmCallerJobID	=	@parmCurrentJobID
													,@parmCallerSPName	=	@CurrentSPName
													,@parmMessage		=	'Sætter jobbet klar til at starte i Skipstep'
													,@parmDebugTxt		=	'Sætter jobbet klar til at starte i Skipstep'
			
						-- Start job
						--SET @charJobID									=	cast(@ChildJobID as varchar(36))
						--SET	@SQLCommand									=	'msdb.dbo.sp_start_job @job_id = ''' + @charJobID + ''' ,@step_name=''SKIP - AgentJob'''
	
						--EXEC (@SQLCommand) at [loopback]						

						-- Hvis der allerede findes en job til execution indenfor samme batchid, slette markeres det og et nyt sættes ind
						IF EXISTS
						(
							SELECT [JobID] FROM [flw].[JobsForExecution] 
							WHERE [BatchID] = @CurrentBatchID AND [JobID] = @ChildJobID 
							AND IsDeleted = 0
						)
						BEGIN
							UPDATE [flw].[JobsForExecution]
							SET IsDeleted = 1, DeleteDateTime = SYSDATETIME()
							WHERE [BatchID] = @CurrentBatchID 
							AND [JobID] = @ChildJobID 
							AND IsDeleted = 0
						END

						-- Nyt job til execution sættes ind
						INSERT INTO [flw].[JobsForExecution]
						([BatchID],[CallingJobID],[JobID],[JobStepName])
						VALUES(@CurrentBatchID,@parmCurrentJobID,@ChildJobID,'SKIP - AgentJob')
					END
				END
				-- ----- Hvis Jobbet er markeret til at skulle skippes, køre vi skip steppet -----
				-- GraKil - 2015.02.15 Tilføjet JobAktiv da flowet ikke tager højde for deaktiverede jobs iløbet af et flow -----
				ELSE IF ([flw].[JobStatusID](@ChildJobID)			= [flw].[StatusIDSprungetOver]()
							OR
						 [flw].[JobStatusID](@ChildJobID)			= [flw].[StatusIDInaktivKlar]()	
							OR
						 [flw].[JobStatusID](@ChildJobID)			= [flw].[StatusIDUdenforBatch]()
						)
				BEGIN
					-- Skift status til Starter
					SET	@StatusID									=	[flw].[StatusIDManuelStart]()
					SET @CurrentBatchID								=	[flw].CurrentBatchID(@ChildJobID)	

					EXECUTE [flw].[SkiftStatus]  @parmJobID			=	@ChildJobID
												,@parmStatusID		=	@StatusID

					-- Log start af job		
					EXECUTE [flw].[SkrivLog]	 @parmJobID			=	@ChildJobID
												,@parmBatchID		=	@CurrentBatchID
												,@parmStatusID		=	@StatusID
												,@parmCallerJobID	=	@parmCurrentJobID
												,@parmCallerSPName	=	@CurrentSPName
												,@parmMessage		=	'Sætter jobbet klar til at starte i Skipstep'
			
					-- Start job
					--SET @charJobID									=	cast(@ChildJobID as varchar(36))
					--SET	@SQLCommand									=	'msdb.dbo.sp_start_job @job_id = ''' + @charJobID + ''' ,@step_name=''SKIP - AgentJob'''
	
					--EXEC (@SQLCommand) at [loopback]			

					-- Hvis der allerede findes en job til execution indenfor samme batchid, slette markeres det og et nyt sættes ind
					IF EXISTS
					(
						SELECT [JobID] FROM [flw].[JobsForExecution] 
						WHERE [BatchID] = @CurrentBatchID AND [JobID] = @ChildJobID 
						AND IsDeleted = 0
					)
					BEGIN
						UPDATE [flw].[JobsForExecution]
						SET IsDeleted = 1, DeleteDateTime = SYSDATETIME()
						WHERE [BatchID] = @CurrentBatchID 
						AND [JobID] = @ChildJobID 
						AND IsDeleted = 0
					END

					-- Nyt job til execution sættes ind
					INSERT INTO [flw].[JobsForExecution]
					([BatchID],[CallingJobID],[JobID],[JobStepName])
					VALUES(@CurrentBatchID,@parmCurrentJobID,@ChildJobID,'SKIP - AgentJob')
				END
				--WAITFOR DELAY '00:00:02'
			END
			-- ---- Næste fra ChildCursor 
			FETCH NEXT FROM ChildCursor INTO @ChildJobID
		END
		-- -----
		CLOSE ChildCursor
		DEALLOCATE ChildCursor
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