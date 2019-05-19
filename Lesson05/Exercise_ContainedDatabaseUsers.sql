-- Code is reviewed and is in working condition

-- Exercise: Creating contained database users for Azure AD authentication.
-- Execute in toystore database

--Create a contained database user (SQL Authentication)
CREATE USER Mike WITH PASSWORD='John@pwd'
GO
-- Make Mike toystore database ownner
ALTER ROLE db_owner ADD MEMBER Mike


--Create a contained database user (Azure AD Authentication)
CREATE USER [John@dataplatformlabs.com] FROM EXTERNAL PROVIDER

-- Give read access to John on all tables
ALTER ROLE db_datareader ADD Member [John@dataplatformlabs.com]
