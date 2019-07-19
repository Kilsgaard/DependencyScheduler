CREATE TABLE [flw].[JobAfhaengighed_20190403] (
    [ParentJobID]  UNIQUEIDENTIFIER NOT NULL,
    [ChildJobID]   UNIQUEIDENTIFIER NOT NULL,
    [OprettetDato] DATETIME         NULL,
    [AendretDato]  DATETIME         NULL
);

