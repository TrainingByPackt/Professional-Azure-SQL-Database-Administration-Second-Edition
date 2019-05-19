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
	[String] $SplitMergeDatabase,
    [String] $AzureProfileFilePath,
    [parameter(Mandatory=$true)]
	[String] $SplitMergeServiceEndpoint,
    [parameter(Mandatory=$true)]
    [String] $ShardMapManagerDatabaseName,
    [parameter(Mandatory=$true)]
    [String] $Shard2,
    [parameter(Mandatory=$true)]
    [String] $ShardMapName,
    [parameter(Mandatory=$true)]
    [String] $SplitRangeLow,
    [parameter(Mandatory=$true)]
    [String] $SplitRangeHigh,
    [parameter(Mandatory=$true)]
    [String] $SplitValue,
    [bool] $CreateSplitMergeDatabase = $false
    
)

Start-Transcript -Path "$ScriptPath\Log\SplitToyStoreShard.txt" -Append

$CertificateThumbprint = $null

$ScriptPath = split-path -parent $MyInvocation.MyCommand.Definition

$AzureProfileFilePath = "..\..\MyAzureProfile.json"

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

# create the split-merge database.
# if you have already deployed the web service this step isn't requied.

if($CreateSplitMergeDatabase)
{
#Create a database to store split merge status
$command = "..\..\Lesson01\ProvisionAzureSQLDatabase.ps1\ProvisionAzureSQLDatabase.ps1 -ResourceGroup $ResourceGroup -SQLServer $SqlServer -UserName $UserName -Password $Password -SQLDatabase $SplitMergeDatabase -Edition Basic" 
Invoke-Expression -Command $command
Exit;

}


# Import SplitMerge module
$ScriptDir = Split-Path -parent $MyInvocation.MyCommand.Path
Import-Module $ScriptDir\SplitMerge -Force


Write-Output 'Sending split request'
$splitOperationId = Submit-SplitRequest `
    -SplitMergeServiceEndpoint $SplitMergeServiceEndpoint `
    -ShardMapManagerServerName "$SqlServer.database.windows.net" `
    -ShardMapManagerDatabaseName $ShardMapManagerDatabaseName `
    -TargetServerName "$SqlServer.database.windows.net" `
    -TargetDatabaseName $Shard2 `
    -UserName $UserName `
    -Password $Password `
    -ShardMapName $ShardMapName `
    -ShardKeyType 'Int32' `
    -SplitRangeLowKey $SplitRangeLow `
    -SplitValue $SplitValue `
    -SplitRangeHighKey $SplitRangeHigh `
    -CertificateThumbprint $CertificateThumbprint


# Get split request output
Wait-SplitMergeRequest -SplitMergeServiceEndpoint $SplitMergeServiceEndpoint -OperationId $splitOperationId -CertificateThumbprint $CertificateThumbprint


