-- Code is reviewed and is in working condition

DROP SEQUENCE IF EXISTS [Sequences].[OrderID] 
GO
-- Create OrderID Sequence
CREATE SEQUENCE [Sequences].[OrderID] 
 AS [int]
 START WITH 73593
 INCREMENT BY 1
 MINVALUE -2147483648
 MAXVALUE 2147483647
 CACHE 
GO

IF OBJECT_ID('uspInsertOrders') IS NOT NULL
DROP PROCEDURE uspInsertOrders
GO
CREATE PROCEDURE uspInsertOrders
@numberoforderstoinsert INT = 10
AS
BEGIN

DECLARE 
@i INT = 1,
@orderid INT
WHILE (@i <= @numberoforderstoinsert)
BEGIN
	SET @orderid = NEXT VALUE FOR Sequences.OrderID;

	INSERT INTO [Sales].[Orders]
        ([OrderID]
        ,[CustomerID]
        ,[SalespersonPersonID]
        ,[PickedByPersonID]
        ,[ContactPersonID]
        ,[BackorderOrderID]
        ,[OrderDate]
        ,[ExpectedDeliveryDate]
        ,[CustomerPurchaseOrderNumber]
        ,[IsUndersupplyBackordered]
        ,[Comments]
        ,[DeliveryInstructions]
        ,[InternalComments]
        ,[PickingCompletedWhen]
        ,[LastEditedBy]
        ,[LastEditedWhen]
		)
	
	SELECT TOP 1
		@orderid
		,[CustomerID]
		,1 AS [SalespersonPersonID]
        ,1 AS [PickedByPersonID]
        ,1 AS [ContactPersonID]
        ,1 AS [BackorderOrderID]
        ,GETDATE() AS orderdate
        ,GETDATE() + 3 AS ExpectedDeliveryDate
        ,10923 AS [CustomerPurchaseOrderNumber]
        ,1 AS [IsUndersupplyBackordered]
        ,'No Comments' AS [Comments]
        ,'No Instructions' AS [DeliveryInstructions]
        ,'No Comments' AS [InternalComments]
        ,NULL AS [PickingCompletedWhen]
        ,1 AS [LastEditedBy]
        ,GetDate() AS [LastEditedWhen]
	FROM Sales.Customers c 
	ORDER BY NEWID() 
		
		
SET @i+=1;
END
END
GO

--======================= IN-MEMORY OBJECTS ==================================================

-- If the query returns 1, In-Memory is supported
SELECT DatabasePropertyEx(DB_NAME(), 'IsXTPSupported')

-- Elevate the lower isolation level to snapshot for the memory optimized tables
ALTER DATABASE CURRENT SET MEMORY_OPTIMIZED_ELEVATE_TO_SNAPSHOT = ON
GO
DROP PROCEDURE IF EXISTS uspInsertOrders_Inmem
GO
DROP TABLE IF EXISTS [Sales].[Orders_Inmem]
GO
-- Create in memory version of Orders table
CREATE TABLE [Sales].[Orders_Inmem](
	[OrderID] [int] IDENTITY NOT NULL,
	[CustomerID] [int] NOT NULL,
	[SalespersonPersonID] [int] NOT NULL,
	[PickedByPersonID] [int] NULL,
	[ContactPersonID] [int] NOT NULL,
	[BackorderOrderID] [int] NULL,
	[OrderDate] [date] NOT NULL,
	[ExpectedDeliveryDate] [date] NOT NULL,
	[CustomerPurchaseOrderNumber] [nvarchar](20) NULL,
	[IsUndersupplyBackordered] [bit] NOT NULL,
	[Comments] [nvarchar](4000) NULL,
	[DeliveryInstructions] [nvarchar](4000) NULL,
	[InternalComments] [nvarchar](4000) NULL,
	[PickingCompletedWhen] [smalldatetime] NULL,
	[LastEditedBy] [int] NOT NULL,
	[LastEditedWhen] [smalldatetime] NOT NULL,
 CONSTRAINT [PK_OrderID_Inmem] PRIMARY KEY NONCLUSTERED 
	( [OrderID] ASC )
)WITH (MEMORY_OPTIMIZED=ON)
GO

-- Create in memory version of customers table
DROP PROCEDURE IF EXISTS uspInsertOrders_Inmem
GO
DROP TABLE IF EXISTS [Sales].[Customers_Inmem]
GO

CREATE TABLE [Sales].[Customers_Inmem](
	[CustomerID] [int] NOT NULL,
	[CustomerName] [nvarchar](100) NOT NULL,
	[BillToCustomerID] [int] NOT NULL,
	[CustomerCategoryID] [int] NOT NULL,
	[BuyingGroupID] [int] NULL,
	[PrimaryContactPersonID] [int] NOT NULL,
	[AlternateContactPersonID] [int] NULL,
	[DeliveryMethodID] [int] NOT NULL,
	[DeliveryCityID] [int] NOT NULL,
	[PostalCityID] [int] NOT NULL,
	[CreditLimit] [decimal](18, 2) NULL,
	[AccountOpenedDate] [date] NOT NULL,
	[StandardDiscountPercentage] [decimal](18, 3) NOT NULL,
	[IsStatementSent] [bit] NOT NULL,
	[IsOnCreditHold] [bit] NOT NULL,
	[PaymentDays] [int] NOT NULL,
	[PhoneNumber] [nvarchar](20) NOT NULL,
	[FaxNumber] [nvarchar](20) NOT NULL,
	[DeliveryRun] [nvarchar](5) NULL,
	[RunPosition] [nvarchar](5) NULL,
	[WebsiteURL] [nvarchar](256) NOT NULL,
	[DeliveryAddressLine1] [nvarchar](60) NOT NULL,
	[DeliveryAddressLine2] [nvarchar](60) NULL,
	[DeliveryPostalCode] [nvarchar](10) NOT NULL,
	[DeliveryLocation] [varchar](1) NOT NULL,
	[PostalAddressLine1] [nvarchar](60) NOT NULL,
	[PostalAddressLine2] [nvarchar](60) NULL,
	[PostalPostalCode] [nvarchar](10) NOT NULL,
	[LastEditedBy] [int] NOT NULL,
	[ValidFrom] [datetime2](7) NOT NULL,
	[ValidTo] [datetime2](7) NOT NULL,
 CONSTRAINT [PK_CustomerID_Inmem] PRIMARY KEY NONCLUSTERED 
( [CustomerID] ASC )
) WITH (MEMORY_OPTIMIZED=ON)
GO

-- Populate Sales.Customers_InMem table with data
DELETE FROM Sales.Customers_InMem
GO
INSERT INTO Sales.Customers_InMem
SELECT * FROM Sales.Customers
GO

-- Create natively compiled version of uspInsertOrders
-- Create disk based procedure to insert orders
DROP PROCEDURE IF EXISTS uspInsertOrders_Inmem
GO
CREATE PROCEDURE uspInsertOrders_Inmem
@numberoforderstoinsert INT = 10
WITH NATIVE_COMPILATION, SCHEMABINDING, EXECUTE AS OWNER
AS
BEGIN ATOMIC WITH
  (TRANSACTION ISOLATION LEVEL = SNAPSHOT,
   LANGUAGE = N'us_english')

DECLARE 
	@i INT = 1,
	@orderid INT
WHILE (@i <= @numberoforderstoinsert)
	BEGIN
		
		INSERT INTO [Sales].[Orders_Inmem]
           (
           [CustomerID]
           ,[SalespersonPersonID]
           ,[PickedByPersonID]
           ,[ContactPersonID]
           ,[BackorderOrderID]
           ,[OrderDate]
           ,[ExpectedDeliveryDate]
           ,[CustomerPurchaseOrderNumber]
           ,[IsUndersupplyBackordered]
           ,[Comments]
           ,[DeliveryInstructions]
           ,[InternalComments]
           ,[PickingCompletedWhen]
           ,[LastEditedBy]
           ,[LastEditedWhen]
		   )
	
		SELECT TOP 1
		    [CustomerID]
		   ,1 AS [SalespersonPersonID]
           ,1 AS [PickedByPersonID]
           ,1 AS [ContactPersonID]
           ,1 AS [BackorderOrderID]
           ,GETDATE() AS orderdate
           ,GETDATE() + 3 AS ExpectedDeliveryDate
           ,10923 AS [CustomerPurchaseOrderNumber]
           ,1 AS [IsUndersupplyBackordered]
           ,'No Comments' AS [Comments]
           ,'No Instructions' AS [DeliveryInstructions]
           ,'No Comments' AS [InternalComments]
           ,NULL AS [PickingCompletedWhen]
           ,1 AS [LastEditedBy]
           ,GetDate() AS [LastEditedWhen]
		FROM Sales.Customers_Inmem c 
		ORDER BY NEWID() 

	SET @i+=1;
	END

END
GO