## Code is reviewed and is in working condition

#Export Azure SQL Database bacpac to Azure Storage
#.\BackupAzureSQLDBToAzureStorage.ps1 -storageaccountname "toyfactorystorage" -resourcegroupname "toystore" -container "backups" -sqlserver toyfactory -database "toystore" -sqluser "sqladmin" -sqlpassword "Packt@pub2"
param(
[string]$storageaccountname,
[string]$resourcegroupname,
[string]$sqlserver,
[string]$container,
[string]$database,
[string]$sqluser,
[string]$sqlpassword
)

#Login to Azure account
Login-AzureRmAccount

if([string]::IsNullOrEmpty($storageaccountname) -eq $true) 
{ 
	Write-Host "Provide a valid Storage Account Name" -ForegroundColor Red 
	return 
} 
if([string]::IsNullOrEmpty($resourcegroupname) -eq $true) 
{ 
	Write-Host "Provide a valid resource group" -ForegroundColor Red 
	return 
} 
if([string]::IsNullOrEmpty($container) -eq $true) 
{ 
	Write-Host "Provide a valid Storage Container Name" -ForegroundColor Red 
	return 
} 
 
# create bacpac file name
$bacpacFilename = $database + "_"+(Get-Date).ToString("ddMMyyyymm") + ".bacpac" 


# set the current storage account 
$storageaccountkey = Get-AzureRmStorageAccountKey -ResourceGroupName $resourcegroupname -Name $storageaccountname 
# set the default storage account
Set-AzureRmCurrentStorageAccount -StorageAccountName $storageaccountname -ResourceGroupName $resourcegroupname | Out-Null
 
# set the bacpac location 
$bloblocation = "https://$storageaccountname.blob.core.windows.net/$container/$bacpacFilename" 

#set the credential 
$securesqlpassword = ConvertTo-SecureString -String $sqlpassword -AsPlainText -Force 
$credentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $sqluser, $securesqlpassword 


Write-Host "Exporting $database to $bloblocation..." -ForegroundColor Green 

$export = New-AzureRmSqlDatabaseExport -ResourceGroupName $resourcegroupname -ServerName $sqlserver.Split('.')[0] -DatabaseName $database -StorageUri $bloblocation -AdministratorLogin $credentials.UserName -AdministratorLoginPassword $credentials.Password -StorageKeyType StorageAccessKey -StorageKey $storageaccountkey.Value[0].Tostring() 


#Write-Host $export -ForegroundColor Green 


# Check status of the export 
While(1 -eq 1) 
{ 
	$exportstatus = Get-AzureRmSqlDatabaseImportExportStatus -OperationStatusLink $export.OperationStatusLink 
	if($exportstatus.Status -eq "Succeeded") 
	{ 
		Write-Host $exportstatus.StatusMessage -ForegroundColor Green 
		return 
	} 
	If($exportstatus.Status -eq "InProgress") 
	{ 
		Write-Host $exportstatus.StatusMessage -ForegroundColor Green 
		Start-Sleep -Seconds 5 
	} 
} 
