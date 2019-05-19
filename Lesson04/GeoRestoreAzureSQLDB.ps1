## Code is reviewed and is in working condition

param(
		[Parameter(Mandatory=$true)]
		[string]$sqlserver,
		[Parameter(Mandatory=$true)]
		[string]$database,
		[Parameter(Mandatory=$true)]
		[string]$sqluser,
		[Parameter(Mandatory=$true)]
		[string]$sqlpassword,
		[Parameter(Mandatory=$true)]
		[string]$resourcegroupname,
		[string]$newdatabasename	
)

#Login to Azure subscription

Login-AzureRmAccount


# get the geo database backup to restore

$geodb = Get-AzureRmSqlDatabaseGeoBackup -ServerName $sqlserver -DatabaseName $database -ResourceGroupName $resourcegroupname

#Display Geo-Database properties
$geodb | Out-Host

#get the database name from the geodb object
$geodtabasename = $geodb.DatabaseName.ToString()

#set the new database name
if([string]::IsNullOrEmpty($newdatabasename))
{ 
    $newdatabasename = $database + (Get-Date).ToString("MMddyyyymm")
}
		
Write-Host "Restoring database $geodtabasename from geo backup" -ForegroundColor Green

# perform the geo restore	 
$restore = Restore-AzureRmSqlDatabase -FromGeoBackup -ResourceId $geodb.ResourceID -ServerName $sqlserver -TargetDatabaseName $newdatabasename -Edition $geodb.Edition -ResourceGroupName $resourcegroupname -ServiceObjectiveName $serviceobjectivename

if($rerror -ne $null)
{
	Write-Host $rerror -ForegroundColor red;
}

if($restore -ne $null)
{
	$restoredb = $restore.DatabaseName.ToString()
    Write-Host "Database $database restored from Geo Backup as database $restoredb" -ForegroundColor Green
}

