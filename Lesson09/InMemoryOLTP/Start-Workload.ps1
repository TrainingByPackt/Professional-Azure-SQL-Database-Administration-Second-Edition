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
    [string] $workloadtype, # disk/Inmem
    [int]$numberoforderstoinsert=10
    
		
)

If($workloadtype -eq "inmem")
{
    $query = "Execute uspInsertOrders_Inmem @numberoforderstoinsert=$numberoforderstoinsert"

}
elseif($workloadtype -eq "disk")
{
   $query = "Execute uspInsertOrders @numberoforderstoinsert=$numberoforderstoinsert"
    
}else
{
    Write-Host "Invalid workload type $workloadtype"
    break;
}

$sqlserver = $sqlserver + ".database.windows.net"

$arguments = "-S$sqlserver -U$sqluser -P$sqlpassword -d$database -Q`"$query`" -n100 -r100"

$arguments

$sw = [Diagnostics.Stopwatch]::StartNew()

Start-Process -FilePath $ostresspath -ArgumentList $arguments -RedirectStandardOutput workloadoutput.txt -RedirectStandardError workloaderror.txt -NoNewWindow -PassThru -Wait

$sw.Stop()
Write-Host "`n Elapsed Time (Seconds): " $sw.Elapsed.TotalSeconds -ForegroundColor Green

Read-Host "Press a key to exit!!!" 