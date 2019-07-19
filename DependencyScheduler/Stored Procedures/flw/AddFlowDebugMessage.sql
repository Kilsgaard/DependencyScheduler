

CREATE PROCEDURE [flw].[AddFlowDebugMessage]
	@Name NVARCHAR(256) = NULL
  ,@DebugMessage NVARCHAR(4000) = NULL
  ,@DW_ID_Audit INT = NULL
AS
BEGIN

	INSERT	INTO [Flw].[FlowDebugLog]
				([Name], [DebugMessage], [DW_ID_Audit])
	VALUES	(@Name, @DebugMessage, @DW_ID_Audit)
END