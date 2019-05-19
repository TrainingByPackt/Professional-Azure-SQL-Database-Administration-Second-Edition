-- Code is reviewed and is in working condition
-- Exercise: Managing Server Level Firewall rules from Transact SQL
-- Run in Master database

-- List out all existing Server firewall rules
Select * from sys.firewall_rules
GO

-- Add a new server level firewall rule
-- Server level firewall rule are added to Master database
Execute sp_set_firewall_rule @name = N'Work', 
    @start_ip_address = '115.118.1.0', 
    @end_ip_address = '115.118.16.255'
GO
-- List out all existing Server firewall rules
Select * from sys.firewall_rules

GO
-- Update the firewall rule with new IP
Execute sp_set_firewall_rule @name = N'Work', 
    @start_ip_address = '115.118.10.0', 
    @end_ip_address = '115.118.16.255'

-- List out all existing Server firewall rules
Select * from sys.firewall_rules

GO

-- Delete an existing firewall rule
Execute sp_delete_firewall_rule @name= N'Work'

-- List out all existing Server firewall rules
Select * from sys.firewall_rules


