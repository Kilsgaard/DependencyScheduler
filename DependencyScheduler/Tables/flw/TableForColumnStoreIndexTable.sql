CREATE TABLE [flw].[TableForColumnStoreIndexTable] (
    [CurrentBatchID]   INT              NOT NULL,
    [JobID]            UNIQUEIDENTIFIER NOT NULL,
    [DBName]           VARCHAR (128)    NOT NULL,
    [SchemaName]       VARCHAR (5)      NOT NULL,
    [TableName]        VARCHAR (128)    NOT NULL,
    [IndexName]        VARCHAR (128)    NOT NULL,
    [IndexColumns]     VARCHAR (MAX)    NOT NULL,
    [FileGroupName]    VARCHAR (128)    NULL,
    [CSIFileGroupName] VARCHAR (128)    NULL,
    CONSTRAINT [PK_TableForColumnStoreIndexTable_1TableForColumnStoreIndex] PRIMARY KEY CLUSTERED ([CurrentBatchID] ASC, [JobID] ASC, [DBName] ASC, [SchemaName] ASC, [TableName] ASC, [IndexName] ASC)
);

