

-- Run the queries from 1-3 on database with and without Accelerated Database Recovery turned on
-- The script is to compare the transaction rollback speed with and without Accelerated Database Recovery turned on

-- Step 1: Check ADR is off or on
SELECT 
	[Name],
	is_accelerated_database_recovery_on 
FROM sys.databases 
WHERE [Name]='toystore'



-- Step 2: Create orders table and insert records in the table.
-- Observe that the begin transaction does not have a corresponding commit transaction

CREATE TABLE Orders 
(
	OrderId INT IDENTITY, 
	Quantity INT,
	Amount MONEY,
	OrderDate DATETIME2
)
GO
BEGIN TRANSACTION
DECLARE @i INT=1

WHILE (@i <= 10000000)
BEGIN 
   INSERT INTO Orders VALUES(@i*2,@i*0.5,DATEADD(MINUTE,@i,GETDATE()))
   Set @i = @i + 1
END

-- Step 3. Execut the below query to cancel kill session in which query in step 2 is running and record the
-- estimated time remaining to rollback the transaction

KILL 112
GO
KILL 112 with statusonly
GO
SELECT session_id,status from sys.dm_exec_requests where session_id=112

-- Repeat Steps 1 - 3 for database with ADR enabled. 