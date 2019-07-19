

-- =============================================
-- Author:		Graves Kilsgaard
-- Create date: 25.09.2014
-- Description:	Skriv log for job afvikleren
-- =============================================
CREATE PROCEDURE [flw].[SkrivLog] 
	-- Add the parameters for the stored procedure here
	@parmJobID				uniqueidentifier,
	@parmBatchID			int,
	@parmStatusID			int,
	@parmSuccess			bit					=	1,
	@parmMessage			varchar(4000)		=	NULL,
	@parmDebugTxt			varchar(5000)		=	NULL,
	@parmCallerJobID		varchar(128)		=	NULL,
	@parmCallerSPName		varchar(128)		=	NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	-- ----- Variable Declaration -----
	DECLARE		@JobName	VARCHAR (128)	=	''

	-- ----- Start: Code -----
	IF @parmJobID	is	null
	BEGIN
		SET @parmJobID		=	cast(cast(0 as binary) as uniqueidentifier)
	END
	ELSE
	BEGIN
		SET @Jobname		=	[flw].JobId2Name(@parmJobId)
	END

	INSERT INTO [flw].[JobLog]
				(
					 [BatchID]
					,[JobID]
					,[JobName]
					,[StatusID]
					,[Log_Message]
					,[Success]
					,[DebugTxt]
					,[CallerJobID]
					,[CallerSPName]
				)
		 VALUES (
					@parmBatchID,
					@parmJobID,
					@JobName,
					@parmStatusID,
					@parmMessage,
					@parmSuccess,
					@parmDebugTxt,
					@parmCallerJobID,
					@parmCallerSPName				
				)
	-- ----- Stop: Code -----
END