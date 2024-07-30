/****** Object:  Table [dbo].[OperationLogs]    Script Date: 2/04/2024 10:17:56 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[OperationLogs](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Expression] [nvarchar](1024) NOT NULL,
	[Result] [decimal](18, 4) NULL,
	[Date] [datetime2](7) NOT NULL,
	[Error] [nvarchar](max) NULL,
 CONSTRAINT [PK_OperationLogs] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO


