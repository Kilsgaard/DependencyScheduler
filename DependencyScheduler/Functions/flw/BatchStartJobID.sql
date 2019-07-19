-- =============================================
-- Author:		Graves Kilsgaard
-- Create date: 25.09.2014
-- Description:	Returnere JobID for Batch Start Jobbet 
-- =============================================
CREATE FUNCTION [flw].[BatchStartJobID]
(
	@parmJobID	 uniqueidentifier
)
RETURNS Uniqueidentifier
AS
BEGIN
	-- Declare the return variable here
	DECLARE @Result Uniqueidentifier;

	-- ----- Køre baglæns fra current JobID og finder StartJobID -----
	-- ----- Køre baglæns fra current JobID og finder StartJobID -----
	WITH CTE ([ParentJobID], [ChildJobID], Level)
	AS
	(	
			SELECT	 JAF.ParentJobID
					,JAF.ChildJobID
					,0	AS	Level
			  FROM	[flw].[JobAfhaengighed]					AS	JAF
			 WHERE	JAF.ChildJobID							=	@parmJobID

			 UNION	ALL

			SELECT	 JAF.ParentJobID
					,JAF.ChildJobID
					,Level + 1
			  FROM	[flw].[JobAfhaengighed]					AS	JAF
		INNER JOIN	CTE
 				ON	JAF.ChildJobID							=	CTE.ParentJobID
			   AND	[flw].[BatchStartJob](JAF.childJobID)	=	0
	)
	  SELECT	TOP 1 @Result = CTE.ParentJobId
		FROM	CTE
	   WHERE	[flw].[BatchStartJob](CTE.ParentJobID)	=	1;
	

	-- Return the result of the function
	RETURN @Result
END