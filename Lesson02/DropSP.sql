-- Code is reviewed and is in working condition

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[BackUpDatabase]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
BEGIN
drop procedure BackUpDatabase
END
go
IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[EmailProc]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
BEGIN
drop procedure EmailProc
END
go
IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[Enable_CDC]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
BEGIN
drop procedure Enable_CDC
END
go
IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[ExceuteSQLJob]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
BEGIN
drop procedure ExceuteSQLJob
END
go
IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[Multipart]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
BEGIN
drop procedure Multipart
END
go