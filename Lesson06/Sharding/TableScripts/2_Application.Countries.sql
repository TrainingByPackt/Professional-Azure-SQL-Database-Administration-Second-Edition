-- Code is reviewed and is in working condition

/****** Object:  Table [Application].[Countries]    Script Date: 12/22/2017 4:36:55 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO
IF OBJECT_ID('Application.Countries') IS NULL
BEGIN
CREATE TABLE [Application].[Countries](
	[CountryID] [int] NOT NULL,
	[CountryName] [nvarchar](60) NOT NULL,
	[FormalName] [nvarchar](60) NOT NULL,
	[IsoAlpha3Code] [nvarchar](3) NULL,
	[IsoNumericCode] [int] NULL,
	[CountryType] [nvarchar](20) NULL,
	[LatestRecordedPopulation] [bigint] NULL,
	[Continent] [nvarchar](30) NOT NULL,
	[Region] [nvarchar](30) NOT NULL,
	[Subregion] [nvarchar](30) NOT NULL,
	[Border] [geography] NULL,
	[LastEditedBy] [int] NOT NULL,
	[ValidFrom] [datetime2](7) NOT NULL,
	[ValidTo] [datetime2](7) NOT NULL,
 CONSTRAINT [PK_Application_Countries] PRIMARY KEY CLUSTERED 
(
	[CountryID] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_Application_Countries_CountryName] UNIQUE NONCLUSTERED 
(
	[CountryName] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_Application_Countries_FormalName] UNIQUE NONCLUSTERED 
(
	[FormalName] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

END
ELSE
BEGIN
PRINT 'There is already an object named Countries in the database'
END

