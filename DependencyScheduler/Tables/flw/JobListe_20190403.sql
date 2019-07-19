CREATE TABLE [flw].[JobListe_20190403] (
    [JobID]         UNIQUEIDENTIFIER NOT NULL,
    [Aktiv]         BIT              NOT NULL,
    [Beskrivelse]   NVARCHAR (200)   NULL,
    [Status_ID]     INT              NOT NULL,
    [JobType_ID]    INT              NOT NULL,
    [OprettetDato]  DATETIME         NULL,
    [AendretDato]   DATETIME         NULL,
    [BatchStartJob] BIT              NOT NULL,
    [BatchStopJob]  BIT              NOT NULL,
    [Kommentar]     VARCHAR (4000)   NOT NULL
);

