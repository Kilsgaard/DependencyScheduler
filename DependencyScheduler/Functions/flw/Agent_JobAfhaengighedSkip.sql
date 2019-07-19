-- =============================================
-- Author:		Graves Kilsgaard
-- Create date: 26.09.2014
-- Description:	Tæller antal aktive Afhængigheder til det specificerede Job
-- =============================================
CREATE FUNCTION [flw].[Agent_JobAfhaengighedSkip] 
(
	-- Add the parameters for the function here
	 @parmJobID				uniqueidentifier
	--,@parmJobAfhaengighed	INT
)
RETURNS int
AS
BEGIN
	-- Declare the return variable here
	DECLARE @Result int		= 0

	-- ----- Tæl afhængigheder til jobbet -----
	SET	@Result		=	(SELECT Count(*)
						   FROM	[flw].[JobAfhaengighed]				AS	JAF	WITH (NOLOCK)
				     INNER JOIN	[flw].[JobListe]					AS	JLCParent WITH (NOLOCK)
					  	     ON	JAF.ParentJobID						=	JLCParent.JobID
				     INNER JOIN	[flw].[JobStatus]					AS	JLCStatus
						     ON	JLCStatus.Status_ID					=	JLCParent.Status_ID
					      WHERE	JAF.ChildJobID						=	@parmJobID
							AND	JLCStatus.Job_Afhaengighed			=	3 -- Hvis jobbet er skippet ifølge status i JobStatus
							AND JLCParent.Aktiv						=	1 -- Jobbet skal være aktiv, ellers må den ikke for så bliver den også skippet.
					   )

	-- Return the result of the function
	RETURN @Result

END