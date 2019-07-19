CREATE TABLE [flw].[JobListe] (
    [JobID]         UNIQUEIDENTIFIER NOT NULL,
    [Aktiv]         BIT              NOT NULL,
    [Beskrivelse]   NVARCHAR (200)   NULL,
    [Status_ID]     INT              NOT NULL,
    [JobType_ID]    INT              NOT NULL,
    [OprettetDato]  DATETIME         NULL,
    [AendretDato]   DATETIME         NULL,
    [BatchStartJob] BIT              NOT NULL,
    [BatchStopJob]  BIT              NOT NULL,
    [Kommentar]     VARCHAR (4000)   NOT NULL,
    CONSTRAINT [PK_JobListe] PRIMARY KEY CLUSTERED ([JobID] ASC),
    CONSTRAINT [FK_JobListe_JobStatus] FOREIGN KEY ([Status_ID]) REFERENCES [flw].[JobStatus] ([Status_ID]),
    CONSTRAINT [FK_JobListe_JobType] FOREIGN KEY ([JobType_ID]) REFERENCES [flw].[JobType] ([JobType_ID])
);


GO
CREATE TRIGGER [flw].[trg_JobListe_OprettetDato]
ON [flw].[JobListe]
AFTER INSERT	
AS
    UPDATE [flw].[JobListe]
    SET [OprettetDato] = GETDATE()
    WHERE [JobID] IN (SELECT DISTINCT [JobID] FROM Inserted)
GO
CREATE TRIGGER [flw].[trg_JobListe_AendretDato]
ON [flw].[JobListe]
AFTER UPDATE
AS
    UPDATE [flw].[JobListe]
    SET [AendretDato] = GETDATE()
    WHERE [JobID] IN (SELECT DISTINCT [JobID] FROM Inserted)