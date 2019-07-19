﻿

-- =============================================
-- Author:		Graves Kilsgaard
-- Create date: 14.08.2014
-- Description:	Returnere StatusID for Status: Manuel Start
-- =============================================
CREATE FUNCTION [flw].[StatusIDManuelStart]
(

)
RETURNS int
AS
BEGIN
	-- Declare the return variable here
	DECLARE @Result int

	
	SET @Result		=	(SELECT Status_ID
						   FROM [flw].[JobStatus]
						  WHERE Status_Beskrivelse	in ('Manuel Start')
						)   

	-- Return the result of the function
	RETURN @Result

END