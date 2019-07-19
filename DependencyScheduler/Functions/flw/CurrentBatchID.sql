
-- =============================================
-- Author:		Graves Kilsgaard
-- Create date: 14.08.2014
-- Description:	Returnere nuværende BatchID
-- =============================================
CREATE FUNCTION [flw].[CurrentBatchID] 
(
	@parmJobID	uniqueidentifier
)
RETURNS int
AS
BEGIN
	-- Declare the return variable here
	DECLARE @Result int

	
	-- ----- Hent BatchID fra tabellen JobMasterSetup -----
	SET @Result		=	(SELECT	TOP 1	CurrentBatchID
						   FROM	[flw].[JobMasterSetup]
						  WHERE	JobID	=	[flw].[BatchStartJobID](@parmJobID)
						)

	IF (@Result IS NULL)
		SET @Result	=	0

	-- Return the result of the function
	RETURN @Result
END