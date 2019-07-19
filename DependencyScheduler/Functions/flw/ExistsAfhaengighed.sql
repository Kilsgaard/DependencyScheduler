
-- =============================================
-- Author:		Graves Kilsgaard
-- Create date: 2014.09.05
-- Description:	Findes en afhængighed
-- =============================================
CREATE FUNCTION [flw].[ExistsAfhaengighed] 
(
	-- Add the parameters for the function here
	 @parmParentJobID uniqueidentifier
	,@parmChildJobID uniqueidentifier
)
RETURNS int
AS
BEGIN
	-- Declare the return variable here
	DECLARE @Result int		=	0

	-- Add the T-SQL statements to compute the return value here
	IF EXISTS (SELECT ParentJobID
				 FROM [flw].[JobAfhaengighed]
			    WHERE ParentJobID				=	@parmParentJobID
				  AND ChildJobID				=	@parmChildJobID
			  ) 
	BEGIN
		SET @Result		=	1
	END
	
	-- Return the result of the function
	RETURN @Result
END