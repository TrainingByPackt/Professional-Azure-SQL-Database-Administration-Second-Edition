-- Code is reviewed and is in working condition

USE [toystore]
GO
create proc [dbo].[BackUpDatabase] 
as
backup database toystore to disk = 'C:\torystore.bak'
with init, stats=10
GO
create proc [dbo].[EmailProc] 
as
EXEC msdb.dbo.sp_send_dbmail  
    @profile_name = 'toystore Administrator',  
    @recipients = 'yourfriend@toystore.com',  
    @body = 'The stored procedure finished successfully.',  
    @subject = 'Automated Success Message' ;  
go
create Proc [dbo].[Enable_CDC]
as
EXEC sys.sp_cdc_enable_db  
GO
create proc [dbo].[ExceuteSQLJob]
as
begin
EXEC msdb.dbo.sp_start_job N'Weekly Sales Data Backup' ;  
end
GO
create proc [dbo].[Multipart] 
as
select * from toystore.dbo.CITY

