CREATE TABLE [flw].[JobType] (
    [JobType_ID]          INT        NOT NULL,
    [JobType_Def]         NCHAR (1)  NOT NULL,
    [JobType_Beskrivelse] NCHAR (30) NOT NULL,
    CONSTRAINT [PK_JobBeskrivelse] PRIMARY KEY CLUSTERED ([JobType_ID] ASC)
);

