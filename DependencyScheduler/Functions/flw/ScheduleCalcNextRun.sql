-- =============================================
-- Author:		Graves Kilsgaard
-- Create date: 25.09.2014
-- Description:	Start tid for Jobbet
-- =============================================
CREATE FUNCTION [flw].[ScheduleCalcNextRun]
(
	@parmJobID	 uniqueidentifier
)
RETURNS Datetime
AS
BEGIN
	-- Declare the return variable here
	DECLARE @Result			AS Datetime
	DECLARE @MinutsToAdd	AS INT			=	(SELECT TOP 1 [MinMellemAfvikling]
												   FROM [flw].[JobMasterSetup]
												  WHERE JobID					=	@parmJobID
												)

	SET	@Result		=	(SELECT TOP 1 [MSDB].[dbo].[agent_datetime](next_run_date, next_run_time)
						   FROM [dbo].[sysjobschedules]
						  WHERE Job_id						= @parmJobID
						)

	IF (NOT @Result IS NULL)
	BEGIN
		SET @Result	=	DATEADD(MINUTE, @MinutsToAdd, @Result)
	END
	-- Return the result of the function
	RETURN @Result
END