-- =============================================
-- Author:		Graves Kilsgaard
-- Create date: 26.09.2014
-- Description:	Tæller antal aktive Afhængigheder til det specificerede Job
-- =============================================
CREATE FUNCTION [flw].[Agent_JobAfhaengighed] 
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
							AND	JLCStatus.Job_Afhaengighed			=	1 -- Jobs som tæller med ifølge JobStatus tabel
							--- Hvorfor har jeg lavet denne???? AND	JLCParent.Aktiv						=	1 -- Kun aktive jobs må køres
					   )

	-- Return the result of the function
	RETURN @Result

END