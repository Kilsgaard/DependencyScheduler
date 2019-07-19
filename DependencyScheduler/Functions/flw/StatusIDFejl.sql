


-- =============================================
-- Author:		Graves Kilsgaard
-- Create date: 14.08.2014
-- Description:	Returnere StatusID for Status: Fejl
-- =============================================
CREATE FUNCTION [flw].[StatusIDFejl]
(

)
RETURNS int
AS
BEGIN
	-- Declare the return variable here
	DECLARE @Result int

	
	SET @Result		=	(SELECT Status_ID
						   FROM [flw].[JobStatus]
						  WHERE Status_Beskrivelse	in ('Fejl')
						)   

	-- Return the result of the function
	RETURN @Result

END