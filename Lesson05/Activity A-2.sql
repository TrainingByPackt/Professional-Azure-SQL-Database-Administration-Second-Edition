-- Code is reviewed and is in working condition

/*
Activity A-2
Scenario: In the previous activity we learn to use Row Level Security to limit access to authorized rows to specific users. However, if a user has access to the set of rows he can still see all the column values. 
In this activity, we’ll implement Dynamic Data Masking to mask the credit card number, phone number and email of a customer from the users. 
*/
-- Create a new user and grant read access on Customers table
CREATE USER TestUser WITHOUT LOGIN;
GO
GRANT SELECT ON dbo.Customers TO TestUser

-- Mask the CreditCardNumber, phone and email column
ALTER TABLE dbo.Customers ALTER COLUMN Phone
 VARCHAR(100) MASKED WITH (FUNCTION = 'default()') 
 GO
ALTER TABLE dbo.Customers ALTER COLUMN Email
 VARCHAR(100) MASKED WITH (FUNCTION = 'email()') 
GO
ALTER TABLE dbo.Customers ALTER COLUMN CreditCardNumber 
VARCHAR(100) MASKED WITH (FUNCTION = 'partial(0,"XXX-XX-",4)')

-- What Test user sees!!!
EXECUTE AS USER='TestUser'
GO
SELECT * FROM dbo.Customers;

-- List out the masked columns
REVERT;
GO
SELECT mc.name, t.name as table_name,mc.masking_function  
FROM sys.masked_columns AS mc  
JOIN sys.tables AS t   
    ON mc.[object_id] = t.[object_id]  
WHERE is_masked = 1
and t.name='Customers'

-- Allow test user to see masked data
GRANT UNMASK TO TestUser; 
GO
EXECUTE AS USER='TestUser'
GO
SELECT * FROM dbo.Customers;
GO

-- Revoke Unmask access. Test user now sees masked data
REVERT;
REVOKE UNMASK TO TestUSER

