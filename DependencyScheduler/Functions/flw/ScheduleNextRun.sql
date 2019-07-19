-- =============================================
-- Author:		Graves Kilsgaard
-- Create date: 25.09.2014
-- Description:	Næste start tid for Start Jobbet
-- =============================================
CREATE FUNCTION [flw].[ScheduleNextRun]
(
	@parmJobID	 uniqueidentifier
)
RETURNS Datetime
AS
BEGIN
	-- Declare the return variable here
	DECLARE @Result			AS Datetime

	SET	@Result		=	(SELECT	TOP 1 dboSJA.[next_scheduled_run_date]
						   FROM	[msdb].[dbo].[sysjobactivity]			AS	dboSJA
						  WHERE dboSJA.Job_id 							=	@parmJobID
							AND NOT dboSJA.[next_scheduled_run_date]	IS  NULL
							AND dboSJA.[next_scheduled_run_date]				>	GETDATE()
					   ORDER BY dboSJA.[next_scheduled_run_date] 
						)

	-- Return the result of the function
	RETURN @Result
END