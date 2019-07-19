-- =============================================
-- Author:		Graves Kilsgaard
-- Create date: 2014.09.16
-- Description:	Returner om jobbet er aktivt
-- =============================================
create FUNCTION [flw].[JobAktiv] 
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
	IF EXISTS (SELECT Aktiv 
				 FROM [flw].[JobListe]
			    WHERE JobID		=	@parmJobID
				  AND Aktiv		=	1
			  ) 
	BEGIN
		SET @Result		=	1
	END

	-- Return the result of the function
	RETURN @Result
END