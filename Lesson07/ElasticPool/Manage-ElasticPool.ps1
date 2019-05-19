
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
	[String] $ElasticPoolName,
    [parameter(Mandatory=$false)]
	[String] $ElasticPoolEdition,
    [parameter(Mandatory=$false)]
	[int] $eDTU,
    [parameter(Mandatory=$false)]
	[int] $MaxeDTU,
    [parameter(Mandatory=$false)]
	[int] $MineDTU=0,
    [parameter(Mandatory=$false)]
	[String] $AzureProfileFilePath,
    [parameter(Mandatory=$false)]
    # Create/Remove an elastic Pool
	[String] $Operation = "Create", 
    # Comma delimited list of databases to be added to the pool
    [parameter(Mandatory=$false)]
	[String] $DatabasesToAdd  

)


# log the execution of the script
Start-Transcript -Path ".\Log\Manage-ElasticPool.txt" -Append

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

#Check if the pool exists 
Get-AzureRmSqlElasticPool -ElasticPoolName $ElasticPoolName -ServerName $SqlServer -ResourceGroupName $ResourceGroup -ErrorVariable notexists -ErrorAction SilentlyContinue

if($Operation -eq "Create")
{
	if([string]::IsNullOrEmpty($ElasticPoolEdition))
	{
		Write-Host "Please provide a valid value for Elastic Pool Edition (Basic/Standard/Premium)" -ForegroundColor yellow
        Write-Host "Exiting...." -ForegroundColor Yellow
        break;
	}

Write-Host "Creating elastic pool $ElasticPoolName " -ForegroundColor Green
# Create elastic pool if it doesn't exists
if($notexists)
{
$CreateElasticPool = @{
    ElasticPoolName = $ElasticPoolName;
    Edition = $ElasticPoolEdition;
    Dtu = $eDTU;
    DatabaseDtuMin = $MineDTU;
    DatabaseDtuMax = $MaxeDTU;
    ServerName = $SqlServer;
    ResourceGroupName = $ResourceGroup;
    };
  New-AzureRmSqlElasticPool @CreateElasticPool;

}
else
{
Write-Host "Elastic pool $ElasticPoolName already exists!!!" -ForegroundColor Green
}


if([string]::IsNullOrEmpty($DatabasesToAdd) -and $Operation -eq "Create")
	{
		Write-Host "Please provide a valid value for DatabasesToAdd parameter" -ForegroundColor yellow
        Write-Host "Exiting...." -ForegroundColor Yellow
        break;
	}
# Add databases to the pool 
$Databases = $DatabasesToAdd.Split(',');
foreach($db in $Databases)
{

Write-Host "Adding database $db to elastic pool $ElasticPoolName " -ForegroundColor Green
Set-AzureRmSqlDatabase -ResourceGroupName $ResourceGroup -ServerName $SqlServer -DatabaseName $db -ElasticPoolName $ElasticPoolName


}

}

#remove an elastic pool

if($Operation -eq "Remove")
{
#Get all databases in the elastic pool
$epdbs = Get-AzureRmSqlElasticPoolDatabase -ElasticPoolName $ElasticPoolName -ServerName $SqlServer -ResourceGroupName $ResourceGroup

# iterate through the databases and take them out of the pool.
foreach($item in $epdbs)
{

$db = $item.DatabaseName;

#Take database out of pool
Write-Host "Taking database $db out of elastic pool $ElasticPoolName " -ForegroundColor Green
$RemoveDbsFromPool = @{
ResourceGroupName = $ResourceGroup;
ServerName = $SqlServer;
DatabaseName = $db;
Edition = 'Basic';
RequestedServiceObjectiveName = 'Basic';
};
Set-AzureRmSqlDatabase @RemoveDbsFromPool;
}

#Remove elastic pool 
Write-Host "Removing Elastic Pool $ElasticPoolName " -ForegroundColor Green
$RemovePool = @{
ResourceGroupName = $ResourceGroup;
ServerName = $SqlServer;
ElasticPoolName = $ElasticPoolName;
};

Remove-AzureRmSqlElasticPool @RemovePool -Force;

}


