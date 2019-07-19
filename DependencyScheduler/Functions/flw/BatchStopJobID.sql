-- =============================================
-- Author:		Graves Kilsgaard
-- Create date: 25.09.2014
-- Description:	Returnere JobID for Batch Stop Jobbet 
-- =============================================
CREATE FUNCTION [flw].[BatchStopJobID]
(
	@parmJobID	 uniqueidentifier
)
RETURNS Uniqueidentifier
AS
BEGIN
	-- Declare the return variable here
	DECLARE @Result Uniqueidentifier;

	-- ----- Køre Frem fra current JobID og finder StopJobID -----
	WITH CTE ([ParentJobID], [ChildJobID], Level)
	AS
	(	
			SELECT	 JAF.ParentJobID
					,JAF.ChildJobID
					,0	AS	Level
			  FROM	[flw].[JobAfhaengighed]					AS	JAF
			 WHERE	JAF.ParentJobID							=	@parmJobID

			 UNION	ALL

			SELECT	 JAF.ParentJobID
					,JAF.ChildJobID
					,Level + 1
			  FROM	[flw].[JobAfhaengighed]					AS	JAF
		INNER JOIN	CTE
 				ON	JAF.ChildJobID							=	CTE.ParentJobID
			   AND	[flw].[BatchStopJob](JAF.childJobID)	=	0
	)
	  SELECT	TOP 1 @Result = CTE.ParentJobId
		FROM	CTE
	ORDER BY	Level DESC;

	-- Return the result of the function
	RETURN @Result
END