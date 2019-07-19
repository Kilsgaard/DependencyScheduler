CREATE TABLE [flw].[JobStatus] (
    [Status_ID]          INT            NOT NULL,
    [Status_Beskrivelse] NVARCHAR (15)  NOT NULL,
    [Agent_Status]       INT            NULL,
    [Job_Afhaengighed]   INT            NOT NULL,
    [Beskrivelse]        NVARCHAR (200) NULL,
    CONSTRAINT [PK_flw_JobStatus] PRIMARY KEY CLUSTERED ([Status_ID] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_flw_JobStatus]
    ON [flw].[JobStatus]([Status_Beskrivelse] ASC)
    INCLUDE([Status_ID], [Agent_Status], [Job_Afhaengighed]);

