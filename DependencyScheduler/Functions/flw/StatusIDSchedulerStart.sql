



-- =============================================
-- Author:		Graves Kilsgaard
-- Create date: 14.08.2014
-- Description:	Returnere StatusID for Status: Scheduler Start
-- =============================================
CREATE FUNCTION [flw].[StatusIDSchedulerStart]
(

)
RETURNS int
AS
BEGIN
	-- Declare the return variable here
	DECLARE @Result int

	
	SET @Result		=	(SELECT Status_ID
						   FROM [flw].[JobStatus]
						  WHERE Status_Beskrivelse	in ('Scheduler Start')
						)   

	-- Return the result of the function
	RETURN @Result

END