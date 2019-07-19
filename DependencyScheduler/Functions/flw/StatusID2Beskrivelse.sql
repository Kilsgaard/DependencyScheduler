

-- =============================================
-- Author:		Graves Kilsgaard
-- Create date: 14.08.2014
-- Description:	Returnere Beskrivelsen for en StatusID 
-- =============================================
create FUNCTION [flw].[StatusID2Beskrivelse]
(
	@parmStatusID	INT
)
RETURNS nvarchar(10)
AS
BEGIN
	-- Declare the return variable here
	DECLARE @Result nvarchar(10)

	
	SET @Result		=	(SELECT Status_Beskrivelse
						   FROM [flw].[JobStatus]
						  WHERE Status_ID	= @parmStatusID
						)   

	-- Return the result of the function
	RETURN @Result

END