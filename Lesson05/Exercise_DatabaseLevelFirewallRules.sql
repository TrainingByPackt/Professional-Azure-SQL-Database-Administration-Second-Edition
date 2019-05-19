-- Code is reviewed and is in working condition

-- Exercise: Managing Database Level Firewall rules from Transact SQL.
-- can be executed in master or any user database

-- list out existing database level firewall rule
SELECT * FROM sys.database_firewall_rules
GO

-- Add a new database level firewall rule
Exec sp_set_database_firewall_rule @name=N'MasterDB',
		@start_ip_address='115.118.10.0',
		@end_ip_address='115.118.16.255'

-- list out existing database level firewall rule
SELECT * FROM sys.database_firewall_rules
GO

-- Update an existing database level firewall rule
Exec sp_set_database_firewall_rule
		@name=N'MasterDB',
		@start_ip_address='115.118.1.0',
		@end_ip_address='115.118.16.255'

-- list out existing database level firewall rule
SELECT * FROM sys.database_firewall_rules
GO

-- Delete an existing database level firewall rule
Exec sp_delete_database_firewall_rule @name=N'MasterDB'
GO

-- list out existing database level firewall rule
SELECT * FROM sys.database_firewall_rules
GO