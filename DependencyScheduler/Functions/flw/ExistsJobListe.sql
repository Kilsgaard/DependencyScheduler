
-- =============================================
-- Author:		Graves Kilsgaard
-- Create date: 2014.09.05
-- Description:	Findes et jobid i Scheduler
-- =============================================
CREATE FUNCTION [flw].[ExistsJobListe] 
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
	IF EXISTS (SELECT JobID 
				 FROM [flw].[JobListe]
			    WHERE JobID		=	@parmJobID
			  ) 
	BEGIN
		SET @Result		=	1
	END

	-- Return the result of the function
	RETURN @Result
END