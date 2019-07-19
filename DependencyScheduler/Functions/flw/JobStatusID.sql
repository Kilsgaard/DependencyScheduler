
-- =============================================
-- Author:		Graves Kilsgaard
-- Create date: 13.08.2014
-- Description:	Funktion til hentning af AGentJob navn fra ID
-- =============================================
CREATE FUNCTION [flw].[JobStatusID] 
(
	@parmJobID		uniqueidentifier
)
RETURNS INT
AS
BEGIN
	-- Declare the return variable here
	DECLARE @Result INT
	 
	SET @Result = (SELECT Status_ID
					 FROM [flw].[JobListe]
				    WHERE JobID		=	@parmJobID
				  )

	-- Return the result of the function
	RETURN @Result
END