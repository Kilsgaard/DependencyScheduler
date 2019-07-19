CREATE TABLE [flw].[JobLog] (
    [Log_ID]       INT              IDENTITY (1, 1) NOT NULL,
    [BatchID]      INT              NOT NULL,
    [JobID]        UNIQUEIDENTIFIER NOT NULL,
    [JobName]      VARCHAR (128)    NOT NULL,
    [StatusID]     INT              NOT NULL,
    [Log_Message]  NVARCHAR (4000)  NULL,
    [Success]      BIT              NULL,
    [OprettetDato] DATETIME         NULL,
    [AendretDato]  DATETIME         NULL,
    [DebugTxt]     VARCHAR (5000)   NULL,
    [CallerJobID]  VARCHAR (128)    NULL,
    [CallerSPName] VARCHAR (128)    NULL,
    CONSTRAINT [PK_JobLog] PRIMARY KEY CLUSTERED ([Log_ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX02_flw_joblog]
    ON [flw].[JobLog]([BatchID] ASC)
    INCLUDE([StatusID]);


GO
CREATE NONCLUSTERED INDEX [IX01_flw_JobLog]
    ON [flw].[JobLog]([StatusID] ASC)
    INCLUDE([Log_ID], [JobID], [OprettetDato]);


GO
CREATE NONCLUSTERED INDEX [IX_flw_JobLog_BatchID_JobID]
    ON [flw].[JobLog]([BatchID] ASC, [JobID] ASC)
    INCLUDE([Log_ID], [StatusID]);


GO


CREATE TRIGGER [flw].[trg_JobLog_OprettetDato]
ON [flw].[JobLog]
AFTER INSERT	
AS
    UPDATE [flw].[JobLog]
    SET [OprettetDato] = GETDATE()
    WHERE [Log_ID] IN (SELECT DISTINCT [Log_ID] FROM Inserted)
GO



CREATE TRIGGER [flw].[trg_JobLog_AendretDato]
ON [flw].[JobLog]
AFTER UPDATE
AS
    UPDATE [flw].[JobLog]
    SET [AendretDato] = GETDATE()
    WHERE [Log_ID] IN (SELECT DISTINCT [Log_ID] FROM Inserted)