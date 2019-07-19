-- =============================================
-- Author:		Graves Kilsgaard
-- Create date: 2014.09.05
-- Description:	Findes et jobnavn i Scheduler
-- =============================================
CREATE FUNCTION [flw].[ExistsJobName] 
(
	-- Add the parameters for the function here
	@parmJobName varchar(128)
)
RETURNS int
AS
BEGIN
	-- Declare the return variable here
	DECLARE @Result int		=	0

	-- Add the T-SQL statements to compute the return value here
	IF EXISTS (SELECT name
				 FROM [dbo].[sysjobs]
			    WHERE name		=	@parmJobName
			  ) 
	BEGIN
		SET @Result		=	1
	END

	-- Return the result of the function
	RETURN @Result
END