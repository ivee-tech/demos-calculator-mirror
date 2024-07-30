CREATE TABLE [dbo].[OperationLogs] (
    [Id]         INT             IDENTITY (1, 1) NOT NULL,
    [Expression] NVARCHAR(1024)    NOT NULL,
    [Result]     DECIMAL (18, 4) NULL,
    [Date]       DATETIME2 (7)   NOT NULL,
    [Error]      NVARCHAR (MAX)  NULL,
    CONSTRAINT [PK_OperationLogs] PRIMARY KEY CLUSTERED ([Id] ASC)
);

