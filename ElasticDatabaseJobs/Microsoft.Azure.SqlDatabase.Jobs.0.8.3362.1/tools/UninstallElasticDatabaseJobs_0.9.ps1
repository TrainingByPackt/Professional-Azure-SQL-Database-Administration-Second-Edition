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

Switch-AzureMode AzureResourceManager

$resourceGroup = Get-AzureResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
if(!$resourceGroup)
{
    Write-Host "The Azure Resource Group: $ResourceGroupName has already been deleted.  Elastic database job is uninstalled."
    return
}

if (-not $NoPrompt)
{
    Write-Host "All Elastic Database Jobs Azure components and its stored data will be be deleted if uninstall is continued."
    Write-Host "If you would like to continue with uninstallation, press enter. To quit, press Control-C." -ForegroundColor Yellow
    Read-Host
}

Write-Host "Removing the Azure Resource Group: $ResourceGroupName.  This may take a few minutes.”
Remove-AzureResourceGroup -Name $ResourceGroupName -Force
Write-Host "Completed removing the Azure Resource Group: $ResourceGroupName.  Elastic database job is now uninstalled."
