## Code is reviewed and is in working condition

param
(
    [Parameter(Mandatory=$true)]
	[string]$sqlserver,
	[Parameter(Mandatory=$true)]
	[string]$database,
	[Parameter(Mandatory=$true)]
	[string]$sqluser,
	[Parameter(Mandatory=$true)]
	[string]$sqlpassword,
    [Parameter(Mandatory=$false)]
    [string]$ostresspath="C:\Program Files\Microsoft Corporation\RMLUtils\ostress.exe",
    [Parameter(Mandatory=$false)]
    [string]$workloadsql="C:\Code\Lesson6\workload.sql"
		
)

#$query = "SELECT a.* FROM sys.objects a, sys.objects b,sys.objects c,sys.objects d,sys.objects e,sys.objects f,sys.objects g,sys.objects h"
$sqlserver = $sqlserver + ".database.windows.net"

$arguments = "-S$sqlserver -U$sqluser -P$sqlpassword -d$database -i$workloadsql -n25 -r30 -q"
$arguments
Start-Process -FilePath $ostresspath -ArgumentList $arguments -RedirectStandardOutput workloadoutput.txt -RedirectStandardError workloaderror.txt -NoNewWindow -PassThru -Wait