## Code is reviewed and is in working condition

param(
    
    [Parameter(Mandatory=$true)]
    [string]$servername,
    [Parameter(Mandatory=$true)]
	[string]$sqldb,
    [Parameter(Mandatory=$true)]
	[string]$user,
    [Parameter(Mandatory=$true)]
	[string]$password,
    [Parameter(Mandatory=$true)]
	[string] $bacpacfilepath,
    [Parameter(Mandatory=$true)]
	[string] $sqlpackagepath
)

#C:\Users\Administrator\Documents\Packtpub\toystore.bacpac
$arguments = "/a:Import /tsn:tcp:$servername.database.windows.net,1433 /tu:$user /tp:$password /tdn:$sqldb /p:DatabaseEdition=Basic /sf:$bacpacfilepath"
#$sqlpackagepath = "C:\Program Files (x86)\Microsoft SQL Server\140\DAC\bin\sqlpackage.exe"

Start-Process -FilePath $sqlpackagepath -ArgumentList $arguments -NoNewWindow -Wait