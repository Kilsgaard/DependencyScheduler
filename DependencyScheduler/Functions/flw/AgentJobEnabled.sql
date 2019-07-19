
-- =============================================
-- Author:		Graves Kilsgaard
-- Create date: 22.08.2014
-- Description:	Returnere om Agent jobbet skal være Enabled eller Disabled
-- =============================================
CREATE FUNCTION [flw].[AgentJobEnabled] 
(
	@Status_ID	INT
)
RETURNS int
AS
BEGIN
	-- Declare the return variable here
	DECLARE @Result int

	-- Add the T-SQL statements to compute the return value here
	SET @Result		=	(SELECT	[Agent_Status]
						   FROM	[flw].[JobStatus]
						  WHERE	[Status_ID]			=	@Status_ID
						)

	-- Return the result of the function
	RETURN @Result

END