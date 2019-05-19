-- Code is reviewed and is in working condition

/*
Activity A - 1
Scenario: 
Let’s say that we have two customers Mike and John and two database users each for our two customers. (Created in previous exercise). 
You have to implement Row Level Security so each customer should only be able to view and edit their records. 
The user CustomerAdmin is allowed to view and edit all customer records.
*/


-- Create Customer table and populate with dummy data
CREATE TABLE Customers
	(
		CustomerID int identity,
		Name sysname,
		CreditCardNumber varchar(100),
		Phone varchar(100),
		Email varchar(100)
	)
Go
INSERT INTO Customers VALUES
	('Mike',0987654312345678,9876543210,'mike@outlook.com'),
	('Mike',0987654356784567,9876549870,'mike1@outlook.com'),
	('Mike',0984567431234567,9876567210,'mike2@outlook.com'),
	('John@dataplatformlabs.com',0987654312345678,9876246210,'john@outlook.com'),
	('John@dataplatformlabs.com',0987654123784567,9876656870,'john2@outlook.com'),
	('John@dataplatformlabs.com',09856787431234567,9876467210,'john3@outlook.com'),
	('CustomerAdmin',0987654312235578,9873456210,'john@outlook.com'),
	('CustomerAdmin',0984564123784567,9872436870,'mike2@outlook.com'),
	('CustomerAdmin',0945677874312367,9872427210,'chris3@outlook.com')

-- Create a contained database user without login
CREATE USER CustomerAdmin WITHOUT LOGIN

-- Grant read access to Customers table to Mike, John and CustomerAdmin
GRANT SELECT ON dbo.Customers TO Mike
GO
GRANT SELECT ON dbo.Customers TO [John@dataplatformlabs.com]
GO
GRANT SELECT ON dbo.Customers TO CustomerAdmin

-- Create security predicate to filter out the rows based on the logged in user
CREATE SCHEMA Security;  
GO  
CREATE FUNCTION Security.fn_securitypredicate(@Customer AS sysname)  
    RETURNS TABLE  
WITH SCHEMABINDING  
AS  
    RETURN SELECT 1 AS predicateresult  
WHERE @Customer = USER_NAME() OR USER_NAME() = 'CustomerAdmin';

GO

-- Create and apply the security profile
CREATE SECURITY POLICY CustomerFilter  
ADD FILTER PREDICATE Security.fn_securitypredicate(Name)   
ON dbo.Customers,
ADD BLOCK PREDICATE Security.fn_securitypredicate(Name)   
ON dbo.Customers AFTER INSERT
WITH (STATE = ON); 

-- What Mike sees!!!

EXECUTE AS USER='Mike'
GO
SELECT USER_NAME()
GO
SELECT * FROM dbo.Customers

-- What Mike can update!!!
EXECUTE AS USER='Mike'
GO
SELECT USER_NAME()
GO
-- CustomerID 4 belongs to John
UPDATE dbo.Customers SET Email='MikeBlue@outlook.com' WHERE
CustomerID=4
GO
-- Switch User context to John
EXECUTE AS USER='John@dataplatformlabs.com'
GO
SELECT USER_NAME()
GO
-- Verify if email is updated or not
SELECT * FROM dbo.Customers WHERE CustomerID=4

-- What Mike can insert!!!

EXECUTE AS USER='Mike'
GO
SELECT USER_NAME()
GO
INSERT INTO dbo.Customers 
	VALUES('John@dataplatformlabs.com',9876543445345678,65412396852,'Mike@dataplatformlabs.com')

-- What CustomerAdmin sees!!!
REVERT;
GO
EXECUTE AS USER='CustomerAdmin'
GO
SELECT USER_NAME()
GO
SELECT * FROM dbo.Customers


-- Switch off the security policy
ALTER SECURITY POLICY CustomerFilter  
WITH (STATE = OFF);  
