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

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Import-Module Azure
$azureModule = Get-Module Azure
if ($azureModule.Version -ge '1.0')
{
    &$PSScriptRoot\InstallElasticDatabaseJobs_1.0.ps1 @PSBoundParameters
}
elseif ($azureModule.Version -ge '0.9')
{
    &$PSScriptRoot\InstallElasticDatabaseJobs_0.9.ps1 @PSBoundParameters
}
else
{
    throw "Azure PowerShell version $($azureModule.Version) is not supported by this Elastic Database Jobs script."
}
