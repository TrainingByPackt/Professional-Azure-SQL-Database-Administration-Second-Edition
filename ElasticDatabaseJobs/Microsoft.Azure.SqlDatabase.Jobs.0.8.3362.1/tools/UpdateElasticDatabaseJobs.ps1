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

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Import-Module Azure
$azureModule = Get-Module Azure
if ($azureModule.Version -ge '1.0')
{
    &$PSScriptRoot\UpdateElasticDatabaseJobs_1.0.ps1 @PSBoundParameters
}
elseif ($azureModule.Version -ge '0.9')
{
    &$PSScriptRoot\UpdateElasticDatabaseJobs_0.9.ps1 @PSBoundParameters
}
else
{
    throw "Azure PowerShell version $($azureModule.Version) is not supported by this Elastic Database Jobs script."
}
