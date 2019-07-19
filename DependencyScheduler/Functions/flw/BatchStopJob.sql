-- =============================================
-- Author:		Graves Kilsgaard
-- Create date: 25.09.2014
-- Description:	Er Jobbet et Batch Stop Job
-- =============================================
Create FUNCTION [flw].[BatchStopJob]
(
	@parmJobID	 uniqueidentifier
)
RETURNS INT
AS
BEGIN
	-- Declare the return variable here
	DECLARE @Result INT;

	SET	@Result		=	(SELECT	TOP 1 BatchStopJob 
						   FROM [flw].[JobListe]
						  WHERE JobID				=	@parmJobID
						)
	
	IF (@Result IS NULL)
		SET @Result		=	0

	-- Return the result of the function
	RETURN @Result
END