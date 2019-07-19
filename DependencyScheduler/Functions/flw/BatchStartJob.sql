-- =============================================
-- Author:		Graves Kilsgaard
-- Create date: 25.09.2014
-- Description:	Er Jobbet et Batch Start Job
-- =============================================
CREATE FUNCTION [flw].[BatchStartJob]
(
	@parmJobID	 uniqueidentifier
)
RETURNS INT
AS
BEGIN
	-- Declare the return variable here
	DECLARE @Result INT;

	SET	@Result		=	(SELECT	TOP 1 BatchStartJob 
						   FROM [flw].[JobListe]
						  WHERE JobID				=	@parmJobID
						)
	
	IF (@Result IS NULL)
		SET @Result		=	0

	-- Return the result of the function
	RETURN @Result
END