-- Code is reviewed and is in working condition

-- Create Master Key
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'Packt@pub2';
GO
-- Create database scoped credentials
CREATE DATABASE SCOPED CREDENTIAL toystore_creds1 WITH IDENTITY = 'sqadmin',
SECRET = 'Packt@pub2'
GO
-- Create external data source
CREATE EXTERNAL DATA SOURCE toystore_dsrc
WITH
(
TYPE=SHARD_MAP_MANAGER,
LOCATION='toyfactory.database.windows.net',
DATABASE_NAME='toystore_SMM',
CREDENTIAL= toystore_creds,
SHARD_MAP_NAME='toystorerangemap'
);


-- Create the external table
CREATE EXTERNAL TABLE [dbo].[Customers](
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
	[ValidTo] [datetime2](7) NOT NULL
) WITH
(
DATA_SOURCE = toystore_dsrc,
SCHEMA_NAME = 'Sales',
OBJECT_NAME = 'Customers',
DISTRIBUTION=SHARDED(customerid)
);

-- query the dbo.customers table
SELECT * FROM dbo.Customers

-- Create external orders table
CREATE EXTERNAL TABLE [dbo].[Orders](
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
) WITH
(
DATA_SOURCE = toystore_dsrc,
SCHEMA_NAME = 'Sales',
OBJECT_NAME = 'Orders',
DISTRIBUTION=SHARDED(customerid)
);


Select * from dbo.Orders so join dbo.Customers sc 
on so.customerid = sc.customerid

-- Get existing External Data sources
SELECT * FROM sys.external_data_sources;
-- Get existing External Tables
SELECT * FROM sys.external_tables