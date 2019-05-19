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
    [string]$workloadsql="C:\Code\Lesson09\workload.sql",
    [int]$numberofexecutions = 10
		
)


$sqlserver = $sqlserver + ".database.windows.net"

for([int] $i=1;$i -le $numberofexecutions;$i++)
{
Write-Host "Iteration $i`:Executing queries in Workload.sql" -ForegroundColor Green

Invoke-Sqlcmd -ServerInstance $sqlserver -Database $database -Username $sqluser -Password $sqlpassword -InputFile $workloadsql -QueryTimeout 0 | Out-Null
Write-Host "Sleeping for 5 seconds before next execution.." -ForegroundColor Yellow
Start-Sleep -Seconds 5

}

Read-Host "Workload execution completed. Press a key to continue";


