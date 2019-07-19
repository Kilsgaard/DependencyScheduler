CREATE TABLE [flw].[JobsForExecution] (
    [BatchID]           INT              NOT NULL,
    [ExecutionID]       INT              IDENTITY (1, 1) NOT NULL,
    [CallingJobID]      UNIQUEIDENTIFIER NOT NULL,
    [JobID]             UNIQUEIDENTIFIER NOT NULL,
    [JobStepName]       NVARCHAR (128)   NULL,
    [InsertDateTime]    DATETIME2 (7)    CONSTRAINT [DF_JobsForExecution_InsertDateTime] DEFAULT (sysdatetime()) NOT NULL,
    [ExecutionDateTime] DATETIME2 (7)    NULL,
    [ExecutionStatus]   BIT              CONSTRAINT [DF_JobsForExecution_ExecutionStatus] DEFAULT ((0)) NOT NULL,
    [IsDeleted]         BIT              CONSTRAINT [DF_JobsForExecution_IsDeleted] DEFAULT ((0)) NOT NULL,
    [DeleteDateTime]    DATETIME2 (7)    NULL,
    CONSTRAINT [PK_JobsForExecution] PRIMARY KEY CLUSTERED ([BatchID] ASC, [ExecutionID] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_flw_JobsForExecution_BatchID_JobID]
    ON [flw].[JobsForExecution]([BatchID] ASC, [JobID] ASC) WHERE ([IsDeleted]=(0));

