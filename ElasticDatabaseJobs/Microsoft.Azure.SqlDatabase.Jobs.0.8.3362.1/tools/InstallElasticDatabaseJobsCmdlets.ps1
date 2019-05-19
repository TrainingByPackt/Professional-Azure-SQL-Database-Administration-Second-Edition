###########################################################################################################################
### Install Elastic Database Jobs Cmdlets Script
###
### This script installs the Elastic Database Jobs cmdlets to the current user's PowerShell module path.
###
### Parameters:
### $SourceDirectory:                Specifies the folder that contains the ElasticDatabaseJobs module folder.
###########################################################################################################################

param (
    [Parameter(Position=0)]$SourceDirectory = "."
)

$sourceDir = "$PSScriptRoot\ElasticDatabaseJobs"
$psModuleDir = "$env:userprofile\Documents\WindowsPowerShell\Modules"
$null = mkdir $psModuleDir -Force
copy $sourceDir $psModuleDir -Recurse -Force