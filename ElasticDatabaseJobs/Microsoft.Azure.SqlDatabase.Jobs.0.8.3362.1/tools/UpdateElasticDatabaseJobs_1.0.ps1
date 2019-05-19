######################################################################################
### Update Elastic Database Jobs Script
###
### This script updates the Elastic Database Jobs service binaries within an existing
### installation in the current Azure subscription.
###
### Parameters:
### $ResourceGroupName:         Specifies the resource group for the existing installation.
###                             It is recommended to use the default setting of __ElasticDatabaseJob
###                             since Azure Portal uses this resource group name to identify
###                             Elastic Database Job installations.
### $ServiceVmSize:             Modifies the service VM size.  A0/A1/A2/A3 are acceptable
###                             parameter values.
### $ServiceWorkerCount:        The worker count to be used across the Azure Cloud Service.
###                             If not specified, the current worker count configuration
###                             will continue to be used.
### $ChangeServiceLogin:        If specified, the $NewSqlServerUsername and $NewSqlServerPassword parameters are 
###                             enabled.
### $NewSqlServerUsername:      The new username to be used by the Elastic Database Jobs service to connect to the
###                             Azure SQL database.  If not provided, a UI will prompt for credentials.
###                             This login must already exist in the Azure SQL database before this script is executed,
###                             and the Azure SQL database must have a firewall rule that allows access from this 
###                             machine
##                              so that the connection string can be verified.
### $NewSqlServerPassword:      The new password to be used by the Elastic Database Jobs service to connect to the
###                             Azure SQL database.  If not provided, a UI will prompt for credentials.
######################################################################################


param (
    [Parameter(ParameterSetName="Default")]
    [Parameter(ParameterSetName="ChangeCredential")]
    $ResourceGroupName = "__ElasticDatabaseJob",
    
    [Parameter(ParameterSetName="Default")]
    [Parameter(ParameterSetName="ChangeCredential")]
    $CsmTemplateUri = "http://elasticscale.blob.core.windows.net/edj-151110-release/ElasticDatabaseJobServiceUpdateCsmTemplate.json?sv=2014-02-14&sr=c&sig=rm%2Bzc%2FlPZL7sL83COKpcb1s1lVk%2BbBb%2FP4q87UXrQEY%3D&st=2015-11-16T08%3A00%3A00Z&se=2025-11-24T08%3A00%3A00Z&sp=r",
    
    [Parameter(ParameterSetName="Default")]
    [Parameter(ParameterSetName="ChangeCredential")]
    $ServiceDeploymentLabel = $null,
    
    [Parameter(ParameterSetName="Default")]
    [Parameter(ParameterSetName="ChangeCredential")]
    $ServiceVmSize = "A0",
    
    [Parameter(ParameterSetName="Default")]
    [Parameter(ParameterSetName="ChangeCredential")]
    $ServiceWorkerCount = $null,
    
    [Parameter(ParameterSetName="Default")]
    [Parameter(ParameterSetName="ChangeCredential")]
    [switch]$NoPrompt,
    
    [Parameter(ParameterSetName="ChangeCredential", Mandatory=$true)]
    [switch]$ChangeServiceLogin,
    
    [Parameter(ParameterSetName="ChangeCredential")]
    $NewSqlServerUsername = $null,
    
    [Parameter(ParameterSetName="ChangeCredential")]
    $NewSqlServerPassword = $null
)

######################################################################################
### Helper functions
######################################################################################

function GetAzureServiceName()
{
    param (
        [Parameter(Mandatory=$true)][string]$ResourceGroupName
    )

    # Try to determine the service name used within the resource group already.
    # https://github.com/Azure/azure-powershell/issues/1493
    $azureResources =  Get-AzureRmResource | where -Property ResourceGroupName -eq $ResourceGroupName
    if(!$azureResources)
    {
        throw "Could not find the resource group $ResourceGroupName"
    }

    $ServiceName = $null
    Foreach($azureResource in $azureResources)
    {
        if($azureResource.Name.Contains("/"))
        {
            # Ignore resource names created by compounding parents
            continue;
        }

        if($ServiceName -and !$azureResource.Name.Equals($ServiceName))
        {
            throw ("There were multiple different service names found in the subscription, supply the desired one using the -ServiceName parameter.  Service names: $ServiceName " + $azureResource.Name)
        }
        $ServiceName = $azureResource.Name
    }

    if(!$ServiceName)
    {
        throw "Could not identify any Azure resources within the resource group $ResourceGroupName"
    }

    return $ServiceName
}

function GetServiceDeployment()
{
    return Get-AzureRmResource `
            -ResourceGroupName $ResourceGroupName `
            -ResourceType "$ServiceResourceType" `
            -ResourceName $ServiceName
}

function GetDataEncryptionCertificate()
{
    param (
        [Parameter(Mandatory=$true)][string]$AzureSqlDatabaseConnectionString
    )
    
    Log "Azure Sql Database connection string: $AzureSqlDatabaseConnectionString"
    
    try
    {
        $sqlConn = New-Object -TypeName "System.Data.SqlClient.SqlConnection" -ArgumentList $AzureSqlDatabaseConnectionString
        $sqlConn.Open();
        
        $sqlCmd = $sqlConn.CreateCommand();
        $sqlCmd.CommandText = "SELECT DerEncodedCertificate FROM __ElasticDatabaseJob.Certificate WHERE Role = 'Primary'"
        [byte[]]$bytes = $sqlCmd.ExecuteScalar();
        
        $dataEncryptionCertificate = New-Object -TypeName "System.Security.Cryptography.X509Certificates.X509Certificate2" -ArgumentList (,$bytes)
        return $dataEncryptionCertificate   
    }
    finally
    {
        $sqlConn.Close();
    }
}

######################################################################################
### Script starts here
######################################################################################

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Import-Module "$PSScriptRoot\ElasticDatabaseJobsCommon.psm1" -Force

# See if subscriptions have been initialized
Log "Looking up subscriptions"
if ($(Get-AzureRmSubscription | Measure-Object).Count -eq 0)
{
    Write-Host "Getting your subscriptions..."
    Add-AzureRmAccount
}

$importantSettingsColor = "Yellow"
$otherSettingsColor = "Gray"
$helpColor = "Gray"
$logColor = "Cyan"

# Get the current subscription
$subscription = Get-AzureRmContext

# Get the resource group and its location
Log "Looking up the resource group: $ResourceGroupName..."
$ResourceGroup = Get-AzureRmResourceGroup -Name $ResourceGroupName
$ResourceGroup

# Use the resource group's location since the Azure Service's location is empty.  Should be the same.
$ServiceLocation = $ResourceGroup.Location

# Determine the service name
Log "Looking up the service name..."
$ServiceName = GetAzureServiceName -ResourceGroupName $ResourceGroupName
$ServiceName

$ServiceResourceType = "Microsoft.ClassicCompute/domainNames/slots"

# Build the production deployment name
if(!$ServiceDeploymentLabel)
{
    $ServiceDeploymentLabelGuid = [Guid]::NewGuid()
    $ServiceDeploymentLabel = ("EdjUpdate_$ServiceDeploymentLabelGuid").ToLowerInvariant().Replace("-", "")
}

# Look up the production deployment
Log "Looking up the service deployment..."
$serviceDeployment = GetServiceDeployment
$serviceDeployment

if($serviceDeployment.Properties.DeploymentLabel.Equals($ServiceDeploymentLabel))
{
    Log "Update deployment already in place"
    return
}

$serviceDeploymentConfiguration = $serviceDeployment.Properties.Configuration
$serviceConfigurationXml = New-Object System.Xml.XmlDocument
$serviceConfigurationXml.LoadXml($serviceDeploymentConfiguration)

if ($ChangeServiceLogin)
{
    LoadCryptographyAssembly
    
    # Determine the SQL server name and database name
    $xmlnsManager = New-Object System.Xml.XmlNamespaceManager($serviceConfigurationXml.NameTable)
    $xmlnsManager.AddNamespace("sc", "http://schemas.microsoft.com/ServiceHosting/2008/10/ServiceConfiguration")
    $currentConnectionString = $serviceConfigurationXml.SelectSingleNode("//sc:Setting[@name='StatusDbConnectionString']", $xmlnsManager).Value
    $currentConnectionStringBuilder = New-Object -Type "System.Data.SqlClient.SqlConnectionStringBuilder" -ArgumentList $currentConnectionString
    $AzureSqlServerName = $currentConnectionStringBuilder.DataSource
    $AzureSqlDatabaseName = $currentConnectionStringBuilder.InitialCatalog
    
    # Get the new username / password
    if(!$NewSqlServerUsername -or !$NewSqlServerPassword)
    {
        Log "Please provide the new SQL Server username and password"
        $psCredentials = Get-Credential -Message "Please provide the new SQL Server username and password"
        $NewSqlServerUsername = $psCredentials.UserName
        $NewSqlServerPassword = $psCredentials.GetNetworkCredential().Password
    }
    
    # Determine new sql connection string (without password)
    # Dns suffix is not needed because it's already baked into $AzureSqlServerName (which we got from the connection string) 
    $databaseConnectionStringNoPassword = GetSqlDatabaseConnectionStringNoPassword `
        -AzureRmSqlServerName $AzureSqlServerName `
        -AzureRmSqlDatabaseName $AzureSqlDatabaseName `
        -SqlServerAdministratorUserName $NewSqlServerUsername
    $databaseConnectionString = GetSqlDatabaseConnectionStringWithPassword `
        -DatabaseConnectionStringNoPassword $databaseConnectionStringNoPassword `
        -SqlServerAdministratorPassword $NewSqlServerPassword
    
    Log "Testing for connectivity to database with new username and password"
    Log
    TestSqlServerDatabaseConnection -AzureRmSqlDatabaseConnectionString $databaseConnectionString
    
    Log "Getting the data encryption certificate to encrypt the new password"
    Log
    $DataEncryptionCertificate = GetDataEncryptionCertificate -AzureRmSqlDatabaseConnectionString $databaseConnectionString
    
    # Determine new encrypted password
    $encrypter = New-Object -TypeName Microsoft.Azure.SqlDatabase.ElasticScale.RsaPasswordEncrypter -ArgumentList $DataEncryptionCertificate
    $encryptedBytes = $encrypter.Encrypt($NewSqlServerPassword)
    $encryptedSqlServerAdministratorPassword = [Convert]::ToBase64String($encryptedBytes)
    
    # Manipulate the service configuration for the new connection string and password
    $serviceConfigurationXml.SelectSingleNode("//sc:Setting[@name='StatusDbConnectionString']", $xmlnsManager).Value = $databaseConnectionStringNoPassword
    $serviceConfigurationXml.SelectSingleNode("//sc:Setting[@name='StatusDbEncryptedPassword']", $xmlnsManager).Value = $encryptedSqlServerAdministratorPassword
}

# Manipulate the service configuration for the service worker count, if specified
if($ServiceWorkerCount)
{
    $intServiceWorkerCount = [Int32]::Parse($ServiceWorkerCount)
    if($intServiceWorkerCount -le 0 -or $intServiceWorkerCount -gt 10)
    {
        throw "ServiceWorkerCount specification must be between 1-9: $ServiceWorkerCount"
    }

    $instancesXmlElement = [System.Xml.XmlElement]$serviceConfigurationXml.SelectSingleNode("/*[name()='ServiceConfiguration']/*[name()='Role']/*[name()='Instances']")
    $instancesXmlElement.SetAttribute("count", $intServiceWorkerCount.ToString())
}
$serviceDeploymentConfiguration = $serviceConfigurationXml.OuterXml

# Determine the service binary location
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
    throw "Invalid service binary vm size: $ServiceVmSize"
}

$CsmTemplateParameters = @{ 	
        "SERVICE_NAME"               = $ServiceName;
        "SERVICE_PACKAGELINK"        = $serviceBinaryLocation;
        "SERVICE_LOCATION"           = $ServiceLocation;
        "SERVICE_DEPLOYMENT_LABEL"   = $ServiceDeploymentLabel;
        "SERVICE_CSCFG"              = $serviceDeploymentConfiguration;
}

Log 
Log "Using the following settings to launch the Elastic Database Job service binary update:"
Log
Log "Resource Group Name:      $ResourceGroupName"
Log "Service Name:             $ServiceName"
Log "Service Deployment Label: $ServiceDeploymentLabel"
Log "Service VM Size:          $ServiceVmSize"
Log "CSM Template Uri:         $CsmTemplateUri"
Log "Service Configuration:    $serviceDeploymentConfiguration"
Log

if (-not $NoPrompt)
{
    Write-Host "If these settings are ok, press enter. To quit, press Control-C." -ForegroundColor Yellow
    Read-Host
}

Log "Deploying new service binary..."
Log
New-AzureRmResourceGroupDeployment `
            -ResourceGroupName $ResourceGroupName `
            -Name $ServiceDeploymentLabel `
            -TemplateUri $CsmTemplateUri `
            -TemplateParameterObject $CsmTemplateParameters
            
Log
Log "Update has completed successfully."
Log