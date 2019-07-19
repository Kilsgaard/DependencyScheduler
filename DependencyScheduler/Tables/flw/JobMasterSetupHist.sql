CREATE TABLE [flw].[JobMasterSetupHist] (
    [JobID]              UNIQUEIDENTIFIER NOT NULL,
    [MinMellemAfvikling] INT              NOT NULL,
    [CurrentBatchID]     INT              NOT NULL,
    [BatchStart]         DATETIME         NULL,
    [BatchStop]          DATETIME         NULL,
    [NextRun]            DATETIME         NULL,
    CONSTRAINT [PK_JobMasterSetupHist] PRIMARY KEY CLUSTERED ([JobID] ASC, [CurrentBatchID] ASC)
);

