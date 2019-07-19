CREATE TABLE [flw].[FlowDebugLog] (
    [Name]         NVARCHAR (256)  NULL,
    [DebugMessage] NVARCHAR (4000) NULL,
    [DW_ID_Audit]  INT             NULL,
    [LoggedAt]     DATETIME2 (7)   CONSTRAINT [DF_FlowDebugLogg_Logtime] DEFAULT (sysdatetime()) NOT NULL,
    [LoggedBy]     NVARCHAR (50)   CONSTRAINT [DF_FlowDebugLog_LoggedBy] DEFAULT (suser_name()) NOT NULL
)
WITH (DATA_COMPRESSION = ROW);

