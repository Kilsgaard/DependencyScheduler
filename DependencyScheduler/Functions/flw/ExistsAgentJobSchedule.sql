-- =============================================
-- Author:		Graves Kilsgaard
-- Create date: 2014.09.05
-- Description:	Er der et aktivt schedule på et AgentJob
-- =============================================
CREATE FUNCTION [flw].[ExistsAgentJobSchedule] 
(
	-- Add the parameters for the function here
	@parmJobID uniqueidentifier
)
RETURNS int
AS
BEGIN
	-- Declare the return variable here
	DECLARE @Result int		=	0

	-- Add the T-SQL statements to compute the return value here
	SET @Result		=	(SELECT COUNT(*)
						   FROM [dbo].[sysschedules]		AS	dboSSC
					 INNER JOIN [dbo].[sysjobschedules]		AS	dboJSC
							 ON dboSSC.schedule_id			=	dboJSC.schedule_id
						  WHERE dboJSC.job_id				=	@parmJobID
							AND dboSSC.enabled				=	1
						) 

	-- Return the result of the function
	RETURN @Result
END