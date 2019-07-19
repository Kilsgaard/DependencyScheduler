CREATE TABLE [flw].[FailedJobsToTrello] (
    [FailedJobID]    UNIQUEIDENTIFIER NOT NULL,
    [FailedDateTime] DATETIME2 (7)    NOT NULL,
    [isHandled]      BIT              CONSTRAINT [DF_FailedJobsToTrello_isHandled] DEFAULT ((0)) NOT NULL
);

