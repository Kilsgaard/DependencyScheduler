-- =============================================
-- Author:		Graves Kilsgaard
-- Create date: 26.09.2014
-- Description:	Tæller om der er disablede jobs i afhængigheden..
-- =============================================
Create FUNCTION [flw].[Agent_JobAfhaengighedDisabled] 
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
							AND JLCParent.Aktiv						=	0 -- Jobbet skal tælles hvis det har været disablet
					   )

	-- Return the result of the function
	RETURN @Result

END