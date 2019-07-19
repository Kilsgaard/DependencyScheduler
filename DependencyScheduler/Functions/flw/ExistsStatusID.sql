

-- =============================================
-- Author:		Graves Kilsgaard
-- Create date: 14.08.2014
-- Description:	Returnere Beskrivelsen for en StatusID 
-- =============================================
CREATE FUNCTION [flw].[ExistsStatusID]
(
	@parmStatusID	INT
)
RETURNS INT
AS
BEGIN 
	-- Declare the return variable here
	DECLARE @Result int

	
	SET @Result		=	(SELECT Status_ID
						   FROM [flw].[JobStatus]
						  WHERE Status_ID	= @parmStatusID
						)   

	-- Return the result of the function
	IF (@Result IS NULL)
		SET @Result = 0
	ELSE
		SET @Result = 1

	RETURN @Result
END