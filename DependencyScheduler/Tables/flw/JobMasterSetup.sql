CREATE TABLE [flw].[JobMasterSetup] (
    [JobID]              UNIQUEIDENTIFIER NOT NULL,
    [MinMellemAfvikling] INT              NOT NULL,
    [CurrentBatchID]     INT              NULL,
    [BatchStart]         DATETIME         NULL,
    [BatchStop]          DATETIME         NULL,
    [NextRun]            DATETIME         NULL,
    CONSTRAINT [PK_JobMasterSetup] PRIMARY KEY CLUSTERED ([JobID] ASC)
);

