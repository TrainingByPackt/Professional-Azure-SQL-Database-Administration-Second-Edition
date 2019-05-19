#######################################################################################################
### Uninstall Elastic Database Jobs Script
###
### This script uninstalls the Elastic Database Jobs component from the current Azure subscription.
###
### Parameters:
### $ResourceGroupName:  Specifies the resource group for the existing installation.
###                      It is recommended to use the default setting of __ElasticDatabaseJob
###                      since Azure Portal uses this resource group name to identify
###                      Elastic Database Job installations.
#######################################################################################################

param (
    $ResourceGroupName = "__ElasticDatabaseJob",
    [switch]$NoPrompt
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Import-Module Azure
$azureModule = Get-Module Azure
if ($azureModule.Version -ge '1.0')
{
    &$PSScriptRoot\UninstallElasticDatabaseJobs_1.0.ps1 @PSBoundParameters
}
elseif ($azureModule.Version -ge '0.9')
{
    &$PSScriptRoot\UninstallElasticDatabaseJobs_0.9.ps1 @PSBoundParameters
}
else
{
    throw "Azure PowerShell version $($azureModule.Version) is not supported by this Elastic Database Jobs script."
}
