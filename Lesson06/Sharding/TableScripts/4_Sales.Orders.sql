-- Code is reviewed and is in working condition

/****** Object:  Table [Sales].[Orders]    Script Date: 12/22/2017 4:40:30 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO
IF OBJECT_ID('Sales.Orders') IS NULL
BEGIN
CREATE TABLE [Sales].[Orders](
	[OrderID] [int] NOT NULL,
	[CustomerID] [int] NOT NULL,
	[SalespersonPersonID] [int] NOT NULL,
	[PickedByPersonID] [int] NULL,
	[ContactPersonID] [int] NOT NULL,
	[BackorderOrderID] [int] NULL,
	[OrderDate] [date] NOT NULL,
	[ExpectedDeliveryDate] [date] NOT NULL,
	[CustomerPurchaseOrderNumber] [nvarchar](20) NULL,
	[IsUndersupplyBackordered] [bit] NOT NULL,
	[Comments] [nvarchar](max) NULL,
	[DeliveryInstructions] [nvarchar](max) NULL,
	[InternalComments] [nvarchar](max) NULL,
	[PickingCompletedWhen] [smalldatetime] NULL,
	[LastEditedBy] [int] NOT NULL,
	[LastEditedWhen] [smalldatetime] NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
END
ELSE
BEGIN
PRINT 'There is already an object named Orders in the database'
END
