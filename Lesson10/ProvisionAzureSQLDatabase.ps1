param
(
[parameter(Mandatory=$true)]
[String] $ResourceGroup,
[parameter(Mandatory=$false)]
[String] $Location = "East US 2",
[parameter(Mandatory=$true)]
[String] $SQLServer,
[parameter(Mandatory=$false)]
[String] $UserName="sqladmin",
[parameter(Mandatory=$false)]
[String] $Password="Packt@pub2",
[parameter(Mandatory=$true)]
[String] $SQLDatabase,
[parameter(Mandatory=$false)]
[String] $Edition="Basic",
[parameter(Mandatory=$false)]
[String] $ServiceObjective,
[parameter(Mandatory=$false)]
[String] $AzureProfileFilePath
)

# log the execution of the script
Start-Transcript -Path .\log\ProvisionAzureSQLDatabase.txt -Append
$scriptpath  = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
$Codedir = Split-Path -Parent -Path $scriptpath

# Set AzureProfileFilePath relative to the script directory if it's not provided as parameter
if([string]::IsNullOrEmpty($AzureProfileFilePath))
{
    $AzureProfileFilePath="$Codedir\MyAzureProfile.json"
}

#Login to Azure Account
if((Test-Path -Path $AzureProfileFilePath))
{
	#If Azure profile file is available get the profile information from the file
    $profile = Import-AzureRmContext -Path $AzureProfileFilePath
	#retrieve the subscription id from the profile.
    $SubscriptionID = $profile.Context.Subscription.SubscriptionId
}
else
{
    Write-Host "File Not Found $AzureProfileFilePath" -ForegroundColor Red
	
	# If the Azure Profile file isn't available, login using the dialog box.
    # Provide your Azure Credentials in the login dialog box
    $profile = Login-AzureRmAccount
    $SubscriptionID =  $profile.Context.Subscription.SubscriptionId
}

#Set the Azure Context
Set-AzureRmContext -SubscriptionId $SubscriptionID | Out-Null

#Set serviceobjective
if([string]::IsNullOrEmpty($ServiceObjective))
{
    If($Edition -eq "Basic")
        {
            $ServiceObjective = "Basic"

        }
        elseif ($Edition -eq "Standard")
        {
            $ServiceObjective = "S0"
            
        }
        elseif ($Edition -eq "Premium")
        {
            $ServiceObjective = "P1"
            
        }
        elseif ($Edition -eq "GeneralPurpose")
        {
            $ServiceObjective = "GP_Gen4_2"
            
        }
        elseif ($Edition -eq "BusinessCritical")
        {
            $ServiceObjective = "BC_Gen4_1"
            
        }
         elseif ($Edition -eq "Hyperscale")
        {
            $ServiceObjective = "HS_Gen4_1"
            
        }
}

# Check if resource group exists
# An error is returned and stored in notexists variable if resource group exists
Get-AzureRmResourceGroup -Name $ResourceGroup -Location $Location -ErrorVariable notexists -ErrorAction SilentlyContinue

#Provision Azure Resource Group
if($notexists)
{

Write-Host "Provisioning Azure Resource Group $ResourceGroup" -ForegroundColor Green
$_ResourceGroup = @{
  Name = $ResourceGroup;
  Location = $Location;
  }
New-AzureRmResourceGroup @_ResourceGroup;
}
else
{

Write-Host $notexits -ForegroundColor Yellow
}

#Check if Azure SQL Server Exists
# An error is returned and stored in notexists variable if resource group exists
Get-AzureRmSqlServer -ServerName $SQLServer -ResourceGroupName $ResourceGroup -ErrorVariable notexists -ErrorAction SilentlyContinue

#Provision Azure SQL Server

if($notexists)
{
Write-Host "Provisioning Azure SQL Server $SQLServer" -ForegroundColor Green

$credentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $UserName, $(ConvertTo-SecureString -String $Password -AsPlainText -Force)
$_SqlServer = @{
  ResourceGroupName = $ResourceGroup;
  ServerName = $SQLServer;
  Location = $Location;
  SqlAdministratorCredentials = $credentials;
  ServerVersion = '12.0';
  }
New-AzureRmSqlServer @_SqlServer;
}
else
{

Write-Host $notexits -ForegroundColor Yellow
}


# Check if Azure SQL Database Exists
# An error is returned and stored in notexists variable if resource group exists
Get-AzureRmSqlDatabase -DatabaseName $SQLDatabase -ServerName $SQLServer -ResourceGroupName $ResourceGroup -ErrorVariable notexits -ErrorAction SilentlyContinue

if($notexits)
{
# Provision Azure SQL Database
Write-Host "Provisioning Azure SQL Database $SQLDatabase" -ForegroundColor Green

$_SqlDatabase = @{
 ResourceGroupName = $ResourceGroup;
 ServerName = $SQLServer;
 DatabaseName = $SQLDatabase;
 Edition = $Edition;
 RequestedServiceObjectiveName = $ServiceObjective;
 };
New-AzureRmSqlDatabase @_SqlDatabase;
}

else
{

Write-Host $notexits -ForegroundColor Yellow
}


#Set firewall rule

#get the public ip
$startip = (Invoke-WebRequest http://myexternalip.com/raw -UseBasicParsing).Content.trim();
$endip=$startip

Write-host "Creating firewall rule for $azuresqlservername with StartIP: $startip and EndIP: $endip " -ForegroundColor Green
$FirewallRuleName = "PacktPub_" + (Get-Date).toString("yyyyMMddHHMMss") 
#create the firewall rule
$NewFirewallRule = @{
 ResourceGroupName = $ResourceGroup;
 ServerName = $SQLServer;
 FirewallRuleName = $FirewallRuleName;
 StartIpAddress = $startip;
 EndIpAddress=$endip;
 };
New-AzureRmSqlServerFirewallRule @NewFirewallRule;






