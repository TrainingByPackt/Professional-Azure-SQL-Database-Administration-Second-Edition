-- Code is reviewed and is in working condition

USE [toystore]
GO
ALTER proc [dbo].[BackUpDatabase ] 
As
-- Backup command isn’t supported on Azure SQL Database
--backup database toystore to disk = 'C:\torystore.bak'
--with init, stats=10
GO
ALTER proc [dbo].[EmailProc] 
As
-- Database mail isn’t supported on Azure SQL Database
--EXEC msdb.dbo.sp_send_dbmail  
--    @profile_name = 'toystore Administrator',  
--    @recipients = 'yourfriend@toystore.com',  
--    @body = 'The stored procedure finished successfully.',  
--    @subject = 'Automated Success Message' ;  
GO
ALTER Proc [dbo].[Enable_CDC]
As
-- Change Data Capture isn’t supported on Azure SQL Database
--EXEC sys.sp_cdc_enable_db  
GO
ALTER proc [dbo].[ExceuteSQLJob]
as
--EXEC msdb.dbo.sp_start_job N'Weekly Sales Data Backup' ;  
GO
ALTER proc [dbo].[Multipart] 
as
--select * from toystore.dbo.city
-- Multipart names other than tempdb aren’t supported on Azure SQL Database
select * from city
