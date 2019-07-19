CREATE TABLE [flw].[JobAfhaengighed] (
    [ParentJobID]  UNIQUEIDENTIFIER NOT NULL,
    [ChildJobID]   UNIQUEIDENTIFIER NOT NULL,
    [OprettetDato] DATETIME         NULL,
    [AendretDato]  DATETIME         NULL,
    CONSTRAINT [PK_JobAfhaengighed] PRIMARY KEY CLUSTERED ([ParentJobID] ASC, [ChildJobID] ASC),
    CONSTRAINT [FK_JobAfhaengighed_JobListe_Child] FOREIGN KEY ([ChildJobID]) REFERENCES [flw].[JobListe] ([JobID]),
    CONSTRAINT [FK_JobAfhaengighed_JobListe_Parent] FOREIGN KEY ([ParentJobID]) REFERENCES [flw].[JobListe] ([JobID])
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_flw_JobAfhaengighed]
    ON [flw].[JobAfhaengighed]([ChildJobID] ASC, [ParentJobID] ASC);


GO





CREATE TRIGGER [flw].[trg_JobAfhaengighed_OprettetDato]
ON [flw].[JobAfhaengighed]
AFTER INSERT
AS
    UPDATE [flw].[JobAfhaengighed]
    SET [OprettetDato] = GETDATE()
    WHERE [ParentJobID] IN (SELECT DISTINCT [ParentJobID] FROM Inserted)
	 OR  [ChildJobID] IN (SELECT DISTINCT [ChildJobID] FROM Inserted)
GO




CREATE TRIGGER [flw].[trg_JobAfhaengighed_AendretDato]
ON [flw].[JobAfhaengighed]
AFTER UPDATE
AS
    UPDATE [flw].[JobAfhaengighed]
    SET [AendretDato] = GETDATE()
    WHERE [ParentJobID] IN (SELECT DISTINCT [ParentJobID] FROM Inserted)
	 OR  [ChildJobID] IN (SELECT DISTINCT [ChildJobID] FROM Inserted)