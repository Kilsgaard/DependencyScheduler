
-- =============================================
-- Author:		Graves Kilsgaard
-- Create date: 13.08.2014
-- Description:	Funktion til hentning af AGentJob navn fra ID
-- =============================================
CREATE FUNCTION [flw].[JobName2ID] 
(
	@parmJobName		NVARCHAR(128)
)
RETURNS uniqueidentifier
AS
BEGIN
	-- Declare the return variable here
	DECLARE @Result uniqueidentifier -- = cast(cast(0 as binary) as uniqueidentifier)
	 
	SET @Result = (SELECT Job_id
					 FROM [dbo].[sysjobs]
				    WHERE name	=	@parmJobName
				  )

	-- Return the result of the function
	RETURN @Result
END