## Code is reviewed and is in working condition

param
(
    [parameter(Mandatory=$true)]
	[String] $ResourceGroup,
    [parameter(Mandatory=$false)]
	[String] $PrimarySqlServer,
    [parameter(Mandatory=$false)]
	[String] $UserName,
    [parameter(Mandatory=$false)]
	[String] $Password,
    [parameter(Mandatory=$false)]
	[String] $SecondarySqlServer,
    [parameter(Mandatory=$false)]
	[String] $SecondaryServerLocation,
    [parameter(Mandatory=$false)]
	[bool] $Failover = $false,
    [parameter(Mandatory=$false)]
	[String] $DatabasesToReplicate,
    [parameter(Mandatory=$true)]
    [String] $FailoverGroupName,
    [parameter(Mandatory=$false)]
	[String] $Operation = "none", 
    [parameter(Mandatory=$false)]
	[String] $AzureProfileFilePath
    

)


# log the execution of the script
Start-Transcript -Path ".\Log\Manage-FailoverGroup.txt" -Append

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

IF($Operation -eq "Create")
{

# An error is returned and stored in notexists variable if resource group exists
Get-AzureRmSqlServer -ServerName $SecondarySqlServer -ResourceGroupName $ResourceGroup -ErrorVariable notexists -ErrorAction SilentlyContinue

# provision the secondary server if it doesn't exists

if($notexists)
{
 Write-Host "Provisioning Azure SQL Server $SecondarySqlServer" -ForegroundColor Green
 $credentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $UserName, $(ConvertTo-SecureString -String $Password -AsPlainText -Force)
 $_SecondarySqlServer = @{
  ResourceGroupName = $ResourceGroup;
  ServerName = $SecondarySqlServer;
  Location = $SecondaryServerLocation;
  SqlAdministratorCredentials = $credentials;
  ServerVersion = '12.0';
        }
        New-AzureRmSqlServer @_SecondarySqlServer;
}
else
{
Write-Host $notexits -ForegroundColor Yellow
}

# Create the failover group
Write-Host "Creating the failover group $FailoverGroupName " -ForegroundColor Green
$failovergroup = New-AzureRMSqlDatabaseFailoverGroup `
      –ResourceGroupName $ResourceGroup `
      -ServerName $PrimarySqlServer `
      -PartnerServerName $SecondarySqlServer  `
      –FailoverGroupName $FailoverGroupName `
      –FailoverPolicy Automatic `
      -GracePeriodWithDataLossHours 1

}


# Add databases to the failover group
if(![string]::IsNullOrEmpty($DatabasesToReplicate.Replace(',','')) -and $Failover -eq $false -and $Operation -eq "Create")
{
    $dbname = $DatabasesToReplicate.Split(',');
    foreach($db in $dbname)
    {

        Write-Host "Adding database $db to failover group $FailoverGroupName " -ForegroundColor Green
        $database = Get-AzureRmSqlDatabase -DatabaseName $db -ResourceGroupName $ResourceGroup -ServerName $PrimarySqlServer
        Add-AzureRmSqlDatabaseToFailoverGroup -ResourceGroupName $ResourceGroup -ServerName $PrimarySqlServer -FailoverGroupName $FailoverGroupName -Database $database
    }

}


# failover to secondary
if($Failover)
{
Write-Host "Failover to secondary server $SecondarySqlServer " -ForegroundColor Green
Switch-AzureRMSqlDatabaseFailoverGroup -ResourceGroupName $ResourceGroup -ServerName $SecondarySqlServer -FailoverGroupName $FailoverGroupName
}

if($Operation -eq "Remove")
{
Write-Host "Deleting the failover group $FailoverGroupName " -ForegroundColor Green
Remove-AzureRmSqlDatabaseFailoverGroup -ResourceGroupName $ResourceGroup -ServerName $PrimarySqlServer -FailoverGroupName $FailoverGroupName

# remove the replication link
$dbname = $DatabasesToReplicate.Split(',');
    foreach($db in $dbname)
    {

        Write-Host "Removing replication for database $db " -ForegroundColor Green
        $database = Get-AzureRmSqlDatabase -DatabaseName $db -ResourceGroupName $ResourceGroup -ServerName $PrimarySqlServer
        $database | Remove-AzureRmSqlDatabaseSecondary -PartnerResourceGroupName $ResourceGroup -ServerName $PrimarySqlServer -PartnerServerName $SecondarySqlServer
    }

}