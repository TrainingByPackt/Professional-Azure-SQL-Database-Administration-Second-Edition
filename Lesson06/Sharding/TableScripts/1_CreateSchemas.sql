-- Code is reviewed and is in working condition

IF NOT EXISTS(Select 1 from sys.schemas where name='Application')
BEGIN
EXEC sp_executesql N'CREATE SCHEMA [Application]'
END
GO
IF NOT EXISTS(Select 1 from sys.schemas where name='Sales')
BEGIN
EXEC sp_executesql N'CREATE SCHEMA [Sales]'
END
