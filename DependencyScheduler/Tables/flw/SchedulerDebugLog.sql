CREATE TABLE [flw].[SchedulerDebugLog] (
    [RowId]          BIGINT           IDENTITY (1, 1) NOT NULL,
    [CurrentBatchID] INT              NULL,
    [JobId]          UNIQUEIDENTIFIER NULL,
    [DebugMsg]       NVARCHAR (4000)  NULL,
    [DebugMtts]      DATETIME2 (7)    CONSTRAINT [DF_SchedulerDebugLog_DebugMtts] DEFAULT (sysdatetime()) NOT NULL
)
WITH (DATA_COMPRESSION = ROW);

