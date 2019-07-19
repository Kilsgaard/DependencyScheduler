-- =============================================
-- Author:		Graves Kilsgaard
-- Create date: 2014.09.05
-- Description:	Findes et jobid i Scheduler
-- =============================================
CREATE FUNCTION [flw].[ExistsJobID] 
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
	IF EXISTS (SELECT job_id 
				 FROM [dbo].[sysjobs]
			    WHERE job_id	=	@parmJobID
			  ) 
	BEGIN
		SET @Result		=	1
	END

	-- Return the result of the function
	RETURN @Result
END