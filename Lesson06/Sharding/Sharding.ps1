## Code is reviewed and is in working condition

param
(
    [parameter(Mandatory=$true)]
	[String] $ResourceGroup,
    [parameter(Mandatory=$true)]
	[String] $SqlServer,
    [parameter(Mandatory=$true)]
	[String] $UserName,
    [parameter(Mandatory=$true)]
	[String] $Password,
    [parameter(Mandatory=$true)]
	[String] $ShardMapManagerDatabase,
    [parameter(Mandatory=$true)]
	[String] $DatabaseToShard,
    [parameter(Mandatory=$false)]
	[String] $AzureProfileFilePath
    

)


# log the execution of the script
Start-Transcript -Path ".\Log\Sharding.txt" -Append

# Set AzureProfileFilePath relative to the script directory if it's not provided as parameter

if([string]::IsNullOrEmpty($AzureProfileFilePath))
{
    $AzureProfileFilePath="..\..\MyAzureProfile.json"
}

#Login to Azure Account

if((Test-Path -Path $AzureProfileFilePath))
{
    $profile = Select-AzureRmProfile -Path $AzureProfileFilePath
    $SubscriptionID = $profile.Context.Subscription.SubscriptionId
}
else
{
    Write-Host "File Not Found $AzureProfileFilePath" -ForegroundColor Red

    # Provide your Azure Credentials in the login dialog box
    $profile = Login-AzureRmAccount
    $SubscriptionID =  $profile.Context.Subscription.SubscriptionId
}

#Set the Azure Context
Set-AzureRmContext -SubscriptionId $SubscriptionID | Out-Null

# Import the ShardManagement module
Import-Module '..\Elastic DB tool scripts\ShardManagement\ShardManagement.psm1'


$SQLServerFQDN = "$SqlServer.database.windows.net"


# Provision a new Azure SQL Database
# call ProvisionAzureSQLDatabase.ps1 created in lesson 1 to create a new Azure SQL Database to act as Shard Map Manager


$command = "..\..\Lesson01\ProvisionAzureSQLDatabase.ps1 -ResourceGroup $ResourceGroup -SQLServer $SqlServer -UserName $UserName -Password $Password -SQLDatabase $ShardMapManagerDatabase -Edition Standard" 
Invoke-Expression -Command $command

# Setup the shards

# Rename existing toystore database to toystore_shard1
$Shard1 = $DatabaseToShard + "_Shard_1_100"
$Shard2 = $DatabaseToShard + "_Shard_200"



# Establish credentials for Azure SQL Database server 
$SqlServercredential = new-object System.Management.Automation.PSCredential($UserName, ($Password | ConvertTo-SecureString -asPlainText -Force)) 

# Create connection context for Azure SQL Database server
$SqlServerContext = New-AzureSqlDatabaseServerContext -FullyQualifiedServerName $SQLServerFQDN -Credential $SqlServercredential

# Get Azure SQL Database context
$SqlDatabaseContext = Get-AzureSqlDatabase -ConnectionContext $SqlServerContext -DatabaseName $DatabaseToShard

# Rename the existing database as _shard1
Set-AzureSqlDatabase -ConnectionContext $SqlServerContext -Database $SqlDatabaseContext -NewDatabaseName $shard1

# create shard2 Azure SQL Database
$command1 = "..\..\Lesson01\ProvisionAzureSQLDatabase.ps1 -ResourceGroup $ResourceGroup -SQLServer $SqlServer -UserName $UserName -Password $Password -SQLDatabase $shard2 -Edition Standard" 
Invoke-Expression -Command $command1


# Create tables to be sharded in Shard2
$files = Get-ChildItem -Path ".\TableScripts\"

ForEach($file in $files)
{ 
    Write-Host "Creating table $file in $shard2" -ForegroundColor Green
    Invoke-Sqlcmd -ServerInstance $SQLServerFQDN -Username $UserName -Password $Password -Database $shard2 -InputFile $file.FullName | out-null
}


# Register the database created above as Shard Map Manager

Write-host "Configuring database $ShardMapManagerDatabase as Shard Map Manager" -ForegroundColor Green
$ShardMapManager = New-ShardMapManager -UserName $UserName -Password $Password -SqlServerName $SQLServerFQDN  -SqlDatabaseName $ShardMapManagerDatabase  -ReplaceExisting $true



# Create Shard Map for Range Mapping

$ShardMapName = "toystorerangemap"

$ShardMap = New-RangeShardMap -KeyType $([int]) -ShardMapManager $ShardMapManager -RangeShardMapName $ShardMapName 

# Add shards (databases) to shard maps
Write-host "Adding $Shard1 and $Shard2 to the Shard Map $ShardMapName" -ForegroundColor Green
$Shards = "$Shard1","$shard2"
foreach ($Shard in $Shards)
{
    Add-Shard -ShardMap $ShardMap -SqlServerName $SQLServerFQDN -SqlDatabaseName $Shard 
}

# Add Range Key Mapping on the first Shard
# Mapping is only required on first shard as currently it has all the data. 

$LowKey = 0
$HighKey = 200
Write-host "Add range keys to $Shard1 (Shard1)" -ForegroundColor Green
Add-RangeMapping -KeyType $([int]) -RangeShardMap $ShardMap -RangeLow $LowKey -RangeHigh $HighKey -SqlServerName $SQLServerFQDN -SqlDatabaseName $Shard1

# Add Schema Mappings to the $shardMap 
# This is where you define the sharded and the reference tables
Write-host "Adding schema mappings to the Shard Map Manager Database" -ForegroundColor Green
$ShardingKey = "Customerid"
$ShardedTableName = "Customers","Orders"
$ReferenceTableName = "Countries"

$SchemaInfo = New-Object Microsoft.Azure.SqlDatabase.ElasticScale.ShardManagement.Schema.SchemaInfo
	
$SchemaInfo.Add($(New-Object Microsoft.Azure.SqlDatabase.ElasticScale.ShardManagement.Schema.ShardedTableInfo("Sales","Customers", "Customerid")))
$SchemaInfo.Add($(New-Object Microsoft.Azure.SqlDatabase.ElasticScale.ShardManagement.Schema.ShardedTableInfo("Sales","Orders", "Customerid")))

$SchemaInfo.Add($(New-Object Microsoft.Azure.SqlDatabase.ElasticScale.ShardManagement.Schema.ReferenceTableInfo("Application",$ReferenceTableName)))

$SchemaInfoCollection = $ShardMapManager.GetSchemaInfoCollection()

# Add the SchemaInfo for this Shard Map to the Schema Info Collection
if ($($SchemaInfoCollection | Where Key -eq $ShardMapName) -eq $null)
{
	$SchemaInfoCollection.Add($ShardMapName, $SchemaInfo)
}
else
{
	$SchemaInfoCollection.Replace($ShardMapName, $SchemaInfo)
}

Write-host "$DatabaseToShard is now Sharded." -ForegroundColor Green