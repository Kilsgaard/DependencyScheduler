
-- =============================================
-- Author:		Graves Kilsgaard
-- Create date: 13.08.2014
-- Description:	Funktion til hentning af AGentJob navn fra ID
-- =============================================
CREATE FUNCTION [flw].[JobID2Name] 
(
	@parmJobID		uniqueidentifier
)
RETURNS NVARCHAR(128)
AS
BEGIN
	-- Declare the return variable here
	DECLARE @Result NVARCHAR(128) = NULL

	SET @Result = (SELECT name
					 FROM [dbo].[sysjobs]
				    WHERE job_id	=	@parmJobID
				  )

	-- Return the result of the function
	RETURN @Result
END