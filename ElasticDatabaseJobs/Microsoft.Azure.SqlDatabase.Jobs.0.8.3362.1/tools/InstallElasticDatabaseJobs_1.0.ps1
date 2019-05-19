###########################################################################################################################
### Install Elastic Database Jobs Script
###
### This script installs the Elastic Database Jobs Azure components in the current Azure subscription.
###
### Parameters:
### $ResourceGroupName:                     Specifies the resource group for the existing installation.
###                                         It is recommended to use the default setting of __ElasticDatabaseJob
###                                         since Azure Portal uses this resource group name to identify
###                                         Elastic Database Job installations.
### $ResourceGroupLocation:                 The Azure location to use for creation of the Azure components.
###                                         A single installation can execute jobs across all Azure
###                                         locations.  To minimize latency, a location should be 
###                                         selected to most closely match the location of databases
###                                         targetted for job execution.
### $ServiceVmSize:                         Modifies the service VM size.  A0/A1/A2/A3 are acceptable
###                                         parameter values.
### $ServiceWorkerCount:                    The worker count to be used across the Azure Cloud Service.
###                                         If not specified, the current worker count configuration
###                                         will continue to be used.
### $SqlServerDatabaseSlo:                  Modifies the SQL server database SLO.  S0/S1/S2/S3 are
###                                         acceptable parameter values.
### $SqlServerAdministratorUsername:        The administrator username to use for the newly created
###                                         Azure SQL database.  If not provided, a UI will prompt for credentials.
### $SqlServerAdministratorPassword:        The administrator password to use for the newly created
###                                         Azure SQL database.  If not provided, a UI will prompt for credentials.
### $SqlServerFirewallStartIpAddress:       Starting IP Address of the firewall exception rule for the Control Database.
###                                         If not specified, default is 0.0.0.0. 
### $SqlServerFirewallEndIpAddress:         Ending IP Address of the firewall exception rule for the Control Database.
###                                         If not specified, default is 255.255.255.255.
### $ServiceMaxConcurrentJobTasksPerWorker: How many Job Tasks a single worker role will process at a time.  If not
###                                         specified, will be set to 50.
### $ServiceName:                           Can be used to name the service and the control database.  If not specified,
###                                         one will be created by the installation script.
### $NoPrompt:                              Whether to wait for user to approve the service settings before beginning 
###                                         the installation.
### $NoHost:                                Whether to mute Write-Host output.
### $SkipSetupWait:                         Whether to skip the wait for service installation step.
### 
###########################################################################################################################

param (
    $ResourceGroupName = "__ElasticDatabaseJob",
    $ResourceGroupLocation = "Central US",
    $ServiceWorkerCount = "1",
    $ServiceVmSize = "A0",
    $SqlServerDatabaseSlo = "S0",
    $SqlServerAdministratorUsername = $null,
    $SqlServerAdministratorPassword = $null,
    $SqlServerFirewallStartIpAddress = "0.0.0.0",
    $SqlServerFirewallEndIpAddress = "255.255.255.255",
    $ServiceMaxConcurrentJobTasksPerWorker = "100",
    $SqlServerLocation = $ResourceGroupLocation,
    $ServiceBusLocation = $ResourceGroupLocation,
    $ServiceLocation = $ResourceGroupLocation,
    $ServiceName = $null,
    $StorageLocation = $ResourceGroupLocation,
    $CsmTemplateUri = "http://elasticscale.blob.core.windows.net/edj-151110-release/ElasticDatabaseJobCsmTemplate.json?sv=2014-02-14&sr=c&sig=rm%2Bzc%2FlPZL7sL83COKpcb1s1lVk%2BbBb%2FP4q87UXrQEY%3D&st=2015-11-16T08%3A00%3A00Z&se=2025-11-24T08%3A00%3A00Z&sp=r",
    [switch]$NoPrompt,
    [switch]$NoHost,
    [switch]$SkipSetupWait
)

######################################################################################
### Helper functions
######################################################################################

function TestSqlServerPasswordStrength
{
    param (
        [Parameter(Mandatory=$true)][string]$sqlServerAdministratorPassword
    )

    $passwordPatterns = '\d','[a-z]','[A-Z]','\W'
    $score = 0

    Foreach($passwordPattern in $passwordPatterns)
    {
        if(Select-String -InputObject $sqlServerAdministratorPassword -Pattern $passwordPattern -CaseSensitive)
        {
            $score = $score + 1
        }
    }

    if($score -lt 4)
    {
        throw "The provided SQL Server administrator password is not sufficiently strong.  There needs to be atleast one character from each of the following sets: lower case character (a-z), upper case character (A-Z), digits (0-9), non word character."
    }
}

function TestElasticDatabaseJobSystem
{
    param (
        [Parameter(Mandatory=$true)][string]$AzureSqlServerName,
        [Parameter(Mandatory=$true)][string]$AzureSqlDatabaseName,
        [Parameter(Mandatory=$true)][string]$SqlServerAdministratorUserName,
        [Parameter(Mandatory=$true)][string]$SqlServerAdministratorPassword,
        [Parameter(Mandatory=$true)][string]$AzureSqlDatabaseDnsSuffix
    )
    
    $secpasswd = ConvertTo-SecureString $SqlServerAdministratorPassword -AsPlainText -Force
    $mycreds = New-Object System.Management.Automation.PSCredential ($SqlServerAdministratorUserName, $secpasswd)

    while($true)
    {
        Log "Attempting to connect to ElasticDatabaseJob control database and validate existence of metadata tables"
        
        try
        {
            New-AzureSqlJobConnection `
                        -ServerName "$AzureSqlServerName$AzureSqlDatabaseDnsSuffix" `
                        -DatabaseName $AzureSqlDatabaseName `
                        -Credential $mycreds
            Log "Successfully connected to control database and metadata tables exist.  System is ready to be used."
            return
        }
        catch
        {
            Log $Error[0]
            Log "Elastic Database Jobs not yet fully up and running.  Sleeping for 10 seconds before retrying.  It can take 5-10 minutes before the system is fully up and running."
            Start-Sleep -Seconds 10
        }
    }
}

######################################################################################
### Script starts here
######################################################################################

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$importantSettingsColor = "Yellow"
$otherSettingsColor = "Gray"
$helpColor = "Gray"
$logColor = "Cyan"

Import-Module "$PSScriptRoot\ElasticDatabaseJobsCommon.psm1" -Force

Log "Removing any loaded ElasticDatabaseJobs PowerShell module(s)"
Remove-Module Microsoft.Azure.SqlDatabase.Jobs.PowerShell -ErrorAction SilentlyContinue
Remove-Module ElasticDatabaseJobs -ErrorAction SilentlyContinue

Log "Importing the ElasticDatabaseJobs PowerShell module"
Import-Module "$PSScriptRoot\ElasticDatabaseJobs"

LoadCryptographyAssembly

# Make sure the Azure account is setup
try
{
    Log "Using the following Azure subscription:"
    Get-AzureRmContext
    Log "Looking up the Azure resource groups to verify that the Azure account credentials are not expired"
    $resourceGroups = Get-AzureRmResourceGroup
}
catch
{
    Log $Error[0]
    Log "The Azure account is not properly setup.  Invoking Add-AzureRmAccount to setup the account."
    Login-AzureRmAccount
    $resourceGroups = Get-AzureRmResourceGroup
}

# Determine the dns suffix
$subscription = Get-AzureRmContext
$environment = Get-AzureRmEnvironment -Name $subscription.Environment
$AzureSqlDatabaseDnsSuffix = $environment.SqlDatabaseDnsSuffix

$serviceBinaryLocations = @{ 	
    "A0" = "http://elasticscale.blob.core.windows.net/edj-151110-release/ElasticDatabaseJobService.cspkg?sv=2014-02-14&sr=c&sig=81CKfOu1hb02GMob3Hy4fNONcAKCdS4MQUTCc0O99Lw%3D&st=2015-11-16T08%3A00%3A00Z&se=2099-11-24T08%3A00%3A00Z&sp=r";
    "A1" = "http://elasticscale.blob.core.windows.net/edj-151110-release/ElasticDatabaseJobService_Small.cspkg?sv=2014-02-14&sr=c&sig=81CKfOu1hb02GMob3Hy4fNONcAKCdS4MQUTCc0O99Lw%3D&st=2015-11-16T08%3A00%3A00Z&se=2099-11-24T08%3A00%3A00Z&sp=r";
    "A2" = "http://elasticscale.blob.core.windows.net/edj-151110-release/ElasticDatabaseJobService_Medium.cspkg?sv=2014-02-14&sr=c&sig=81CKfOu1hb02GMob3Hy4fNONcAKCdS4MQUTCc0O99Lw%3D&st=2015-11-16T08%3A00%3A00Z&se=2099-11-24T08%3A00%3A00Z&sp=r";
    "A3" = "http://elasticscale.blob.core.windows.net/edj-151110-release/ElasticDatabaseJobService_Large.cspkg?sv=2014-02-14&sr=c&sig=81CKfOu1hb02GMob3Hy4fNONcAKCdS4MQUTCc0O99Lw%3D&st=2015-11-16T08%3A00%3A00Z&se=2099-11-24T08%3A00%3A00Z&sp=r";
}

# Determine the service binary location
$serviceBinaryLocation = $serviceBinaryLocations.Get_Item($ServiceVmSize)
if(!$serviceBinaryLocation)
{
    throw "Invalid service binary vm size (outside of A0/A1/A2/A3): $ServiceVmSize"
}

# Validate the service worker count
$intServiceWorkerCount = [Int32]::Parse($ServiceWorkerCount)
if($intServiceWorkerCount -le 0 -or $intServiceWorkerCount -gt 10)
{
    throw "Service worker count must be between 1-9: $ServiceWorkerCount"
}
# Ensure this is a string to conform to the template's parameter definition
$ServiceWorkerCount = $intServiceWorkerCount.ToString()

# Determine the SQL Server Database SLO ID
$sqlServerDatabaseEdition = "Standard"
$sqlServerDatabaseSloIds = @{ 	
    "S0" = "f1173c43-91bd-4aaa-973c-54e79e15235b";
    "S1" = "1b1ebd4d-d903-4baa-97f9-4ea675f5e928";
    "S2" = "455330e1-00cd-488b-b5fa-177c226f28b7";
    "S3" = "789681b8-ca10-4eb0-bdf2-e0b050601b40";
}
$sqlServerDatabaseSloId = $sqlServerDatabaseSloIds.Get_Item($SqlServerDatabaseSlo)
if(!$sqlServerDatabaseSloId)
{
    throw "Invalid SQL Server Database SLO (outside of S0/S1/S2/S3): $SqlServerDatabaseSlo"
}

# Get the username / password for the SQL instance to be installed
if(!$SqlServerAdministratorUsername -or !$SqlServerAdministratorPassword)
{
    Log "Please provide the desired SQL Server administrator username and password"
    $psCredentials = Get-Credential -Message "Please provide the desired SQL Server administrator username and password"
    $SqlServerAdministratorUsername = $psCredentials.UserName
    $SqlServerAdministratorPassword = $psCredentials.GetNetworkCredential().Password
}
TestSqlServerPasswordStrength -SqlServerAdministratorPassword $SqlServerAdministratorPassword

# Create a service name using a GUID to help with uniqueness.  Limit to 24 characters total since storage accounts can only have 24 characters
if(!$ServiceName)
{
    $ServiceNameGuid = [Guid]::NewGuid()
    $ServiceName = ("edj$ServiceNameGuid").ToLowerInvariant().Replace("-", "").Substring(0,24)
}

# Generate a certificate
$DataEncryptionCertificate = [Microsoft.Azure.SqlDatabase.ElasticScale.SelfSignedCertificateGenerator]::CreateLongLivedExportableSelfSignedCertificate(2048)

# Generate a certificate password.  
$CertificateThumbprint = $DataEncryptionCertificate.Thumbprint
$CertificatePfxPassword = [Guid]::NewGuid()

# Export the pfx to base 64
$pfxBase64String = [Convert]::ToBase64String($DataEncryptionCertificate.Export("pfx", $CertificatePfxPassword))

# Determine encrypted password
$encrypter = New-Object -TypeName Microsoft.Azure.SqlDatabase.ElasticScale.RsaPasswordEncrypter -ArgumentList $DataEncryptionCertificate
$encryptedBytes = $encrypter.Encrypt($SqlServerAdministratorPassword)
$encryptedSqlServerAdministratorPassword = [Convert]::ToBase64String($encryptedBytes)

$CsmTemplateParameters = @{ 	
        "SQL_SERVER_SERVER_NAME"                       = $ServiceName;
        "SQL_SERVER_LOCATION"                          = $SqlServerLocation;
        "SQL_SERVER_ADMIN_LOGIN"                       = $SqlServerAdministratorUsername;
        "SQL_SERVER_DATABASE_NAME"                     = $ServiceName;
        "SQL_SERVER_DATABASE_EDITION"                  = $sqlServerDatabaseEdition;
        "SQL_SERVER_DATABASE_SLO_ID"                   = $sqlServerDatabaseSloId;
        "SQL_SERVER_FIREWALL_START_IP_ADDRESS"         = $SqlServerFirewallStartIpAddress;
        "SQL_SERVER_FIREWALL_END_IP_ADDRESS"           = $SqlServerFirewallEndIpAddress;
        "SERVICE_BUS_NAMESPACE_NAME"                   = $ServiceName;
        "SERVICE_BUS_NAMESPACE_LOCATION"               = $ServiceBusLocation;
        "STORAGE_ACCOUNT_NAME"                         = $ServiceName;
        "STORAGE_ACCOUNT_LOCATION"                     = $StorageLocation;
        "SERVICE_NAME"                                 = $ServiceName;
        "SERVICE_LOCATION"                             = $ServiceLocation;
        "SERVICE_PACKAGELINK"                          = $ServiceBinaryLocation;
        "SERVICE_WORKER_COUNT"                         = $ServiceWorkerCount;
        "SERVICE_MAX_CONCURRENT_JOB_TASKS_PER_WORKER"  = $ServiceMaxConcurrentJobTasksPerWorker;
        "SERVICE_CERTIFICATE_PFX"                      = $pfxBase64String;
        "SERVICE_CERTIFICATE_PFX_PASSWORD"             = $CertificatePfxPassword;
        "SERVICE_CERTIFICATE_THUMBPRINT"               = $CertificateThumbprint;
        "SERVICE_STATUS_DB_ENCRYPTED_PASSWORD"         = $encryptedSqlServerAdministratorPassword;
        "SERVICE_STATUS_DB_CONNECTION_STRING"          = "Server=$ServiceName$AzureSqlDatabaseDnsSuffix; Database=$ServiceName; User ID=$SqlServerAdministratorUserName; Encrypt=true; TrustServerCertificate=false";
        "SQL_SERVER_ADMIN_PASSWORD"                    = $SqlServerAdministratorPassword;
}

Log
Log "Resource Group Name:           $ResourceGroupName"
Log "Resource Location:             $ResourceGroupLocation"
Log "Service Vm Size:               $ServiceVmSize"
Log "Template URI:                  $CsmTemplateUri"
Log 
Log "SQL Server Name:               $ServiceName"
Log "SQL Server Location:           $SqlServerLocation"
Log "SQL Server User:               $SqlServerAdministratorUsername"
Log "SQL Server Firewall Start IP:  $SqlServerFirewallStartIpAddress"
Log "SQL Server Firewall End IP:    $SqlServerFirewallEndIpAddress"
Log "SQL Server Full Database Name: $ServiceName$AzureSqlDatabaseDnsSuffix"
Log "Service Bus Namespace:         $ServiceName"
Log "Service Bus Location:          $ServiceBusLocation"
Log "Storage Account Name:          $ServiceName"
Log "Storage Account Location:      $StorageLocation"
Log "Service Name:                  $ServiceName"
Log "Service Location:              $ServiceLocation"
Log "Service Worker Count:          $ServiceWorkerCount"
Log "Service Max Concurrent Tasks:  $ServiceMaxConcurrentJobTasksPerWorker"

if (-not $NoPrompt)
{
    Write-Host "If these settings are ok, press enter. To quit, press Control-C." -ForegroundColor Yellow
    Read-Host
}

######################################################################################
### Setup and ready to create resource group and launch CSM
######################################################################################

Log "Creating New Azure Resource Group: $ResourceGroupName along with the deployment"
Log
New-AzureRmResourceGroup -Name $ResourceGroupName -Location $ResourceGroupLocation
New-AzureRmResourceGroupDeployment -Name ElasticDatabaseJobCsmDeployment -ResourceGroupName $ResourceGroupName -TemplateUri $CsmTemplateUri -TemplateParameterObject $CsmTemplateParameters

Log
Log "Resource group deployment has completed successfully."
Log

$databaseConnectionStringNoPassword = GetSqlDatabaseConnectionStringNoPassword `
    -AzureSqlServerName $ServiceName `
    -AzureSqlDatabaseDnsSuffix $AzureSqlDatabaseDnsSuffix `
    -AzureSqlDatabaseName $ServiceName `
    -SqlServerAdministratorUserName $SqlServerAdministratorUserName
$databaseConnectionString = GetSqlDatabaseConnectionStringWithPassword `
    -DatabaseConnectionStringNoPassword $databaseConnectionStringNoPassword `
    -SqlServerAdministratorPassword $SqlServerAdministratorPassword

Log "Testing for connectivity to database"
Log
TestSqlServerDatabaseConnection -AzureSqlDatabaseConnectionString $databaseConnectionString

if(-not $SkipSetupWait)
{
    Log "Waiting for the ElasticDatabaseJob system to fully initialize"
    Log
    TestElasticDatabaseJobSystem `
        -AzureSqlServerName $ServiceName `
        -AzureSqlDatabaseDnsSuffix $AzureSqlDatabaseDnsSuffix `
        -AzureSqlDatabaseName $ServiceName `
        -SqlServerAdministratorUserName $SqlServerAdministratorUsername `
        -SqlServerAdministratorPassword $SqlServerAdministratorPassword
}