


-- =============================================
-- Author:		Graves Kilsgaard
-- Create date: 14.08.2014
-- Description:	Returnere StatusID for Status: Afvikler
-- =============================================
CREATE FUNCTION [flw].[StatusIDGenstarter]
(

)
RETURNS INT
AS
BEGIN
	-- Declare the return variable here
	DECLARE @Result INT

	
	SET @Result		=	(SELECT Status_ID
						   FROM [flw].[JobStatus]
						  WHERE Status_Beskrivelse	IN ('Genstarter')
						)   

	-- Return the result of the function
	RETURN @Result

END