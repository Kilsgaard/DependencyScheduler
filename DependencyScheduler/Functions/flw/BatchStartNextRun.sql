-- =============================================
-- Author:		Graves Kilsgaard
-- Create date: 25.09.2014
-- Description:	Start tid for Jobbet
-- =============================================
CREATE FUNCTION [flw].[BatchStartNextRun]
(
	@parmJobID	 uniqueidentifier
)
RETURNS Datetime
AS
BEGIN
	-- Declare the return variable here
	DECLARE @Result			AS Datetime

	SET	@Result		=	(SELECT TOP 1 NextRun
						   FROM [flw].[JobMasterSetup]
						  WHERE JobID					= @parmJobID
						)

	-- Return the result of the function
	RETURN @Result
END