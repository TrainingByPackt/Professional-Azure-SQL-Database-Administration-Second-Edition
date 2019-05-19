## Code is reviewed and is in working condition

param(
[Parameter(Mandatory=$true)]
		[string]$resourcegroupname,
[Parameter(Mandatory=$true)]
		[string]$azuresqlservername,
[Parameter(Mandatory=$true)]
		[string]$databasename,
[Parameter(Mandatory=$true)]
		[string]$newservicetier,
[Parameter(Mandatory=$true)]
		[string]$servicetierperfomancelevel,
[Parameter(Mandatory=$true)]
		[string]$AzureProfileFilePath

)	



Try
	{
Write-Host "Login to your Azure Account" -ForegroundColor Yellow
		
# log the execution of the script
Start-Transcript -Path .\log\ScaleUpAzureSQLDB.txt -Append

# Set AzureProfileFilePath relative to the script directory if it's not provided as parameter
if([string]::IsNullOrEmpty($AzureProfileFilePath))
{
    $AzureProfileFilePath="..\MyAzureProfile.json"
}

#Login to Azure Account
if((Test-Path -Path $AzureProfileFilePath))
{
	#If Azure profile file is available get the profile information from the file
    $profile = Select-AzureRmProfile -Path $AzureProfileFilePath
	#retrieve the subscription id from the profile.
    $SubscriptionID = $profile.Context.Subscription.SubscriptionId
}
else
{
    Write-Host "File Not Found $AzureProfileFilePath" -ForegroundColor Yellow
	
	# If the Azure Profile file isn't available, login using the dialog box.
    # Provide your Azure Credentials in the login dialog box
    $profile = Login-AzureRmAccount
    $SubscriptionID =  $profile.Context.Subscription.SubscriptionId
}

#Set the Azure Context
Set-AzureRmContext -SubscriptionId $SubscriptionID | Out-Null

Write-Host "Modifying Service Tier to $newservicetier..." -ForegroundColor Yellow
       
Set-AzureRmSqlDatabase -ResourceGroupName $resourcegroupname -ServerName $azuresqlservername `
                -DatabaseName $databasename -Edition $newservicetier `
                -RequestedServiceObjectiveName $servicetierperfomancelevel
  
		
	}
	catch
	{
		$ErrorMessage = $_.Exception.Message
	    $FailedItem = $_.Exception.ItemName
		Write-host $ErrorMessage $FailedItem -ForegroundColor Red
	}


