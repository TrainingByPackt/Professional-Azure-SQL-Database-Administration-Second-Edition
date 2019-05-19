-- Code is reviewed and is in working condition

-- Clean up 
DROP PROCEDURE IF EXISTS uspInsertOrders_Inmem
GO
DROP PROCEDURE IF EXISTS uspInsertOrders
GO
DROP TABLE IF EXISTS [Sales].Orders_Inmem
GO
DROP TABLE IF EXISTS [Sales].Customers_Inmem
GO
-- delete inserted data from the orders table.
DELETE FROM sales.orders WHERE orderdate=CONVERT(date, getdate())
GO
-- Change the database edition to basic
ALTER DATABASE toystore 
    MODIFY (EDITION = 'basic');