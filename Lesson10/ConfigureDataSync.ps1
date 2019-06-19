using namespace Microsoft.Azure.Commands.Sql.DataSync.Model
using namespace System.Collections.Generic

param(
# Hub database info
# Subscription id for hub database
[string]$SubscriptionId = "b85b0984-a391-4f22-a832-fb6e46c39f38",
# Resource group name for hub database
[string]$ResourceGroupName = "Packt",
# Server name for hub database
[string]$ServerName = "packtdbserver",
# Database name for hub database
[string]$DatabaseName = "toystore",

# Sync database info
# Resource group name for sync database
[string]$SyncDatabaseResourceGroupName = "Packt",
# Server name for sync database
[string]$SyncDatabaseServerName = "packtdbserver",
# Sync database name
[string]$SyncDatabaseName = "toystoresyncdb",

# Sync group info
# Sync group name
[string]$SyncGroupName = "toystoresyncgroup",
# Conflict resolution Policy. Value can be HubWin or MemberWin
[string]$ConflictResolutionPolicy = "HubWin",
# Sync interval in seconds. Value must be no less than 300
[string]$IntervalInSeconds = 300,

# Member database info
# Member name
[string]$SyncMemberName = "member1",
# Member server name
[string]$MemberServerName = "packtdbserver",
# Member database name
[string]$MemberDatabaseName = "toystore_rpt",
# Member database type. Value can be AzureSqlDatabase or SqlServerDatabase
[string]$MemberDatabaseType = "AzureSqlDatabase",
# Sync direction. Value can be Bidirectional, Onewaymembertohub, Onewayhubtomember
[string]$SyncDirection = "Bidirectional",
[string]$TablesColumnsToSync = '[Sales].[Orders].[CustomerID]',
[string]$hubdbuser = "dbadmin",
[string]$hubdbpassword="Awesome@1234"
)

# Provision the data sync meta data database.
$SyncDatabaseName = $SyncDatabaseName + "_" + (Get-Random).ToString()

# get details of the hub database. 
$hubdb = Get-AzSqlDatabase -DatabaseName $DatabaseName -ServerName $ServerName -ResourceGroupName $ResourceGroupName

# Use the script from Lesson01 to provision a new Azure SQL database
# The new Azure SQL Database is created in the same logical server and location as the hub database.

.\ProvisionAzureSQLDatabase.ps1 -ResourceGroup $hubdb.ResourceGroupName `
    -Location $hubdb.Location `
    -SQLServer $hubdb.ServerName `
    -UserName $hubdbuser `
    -Password $hubdbpassword `
    -SQLDatabase $SyncDatabaseName `
    -Edition "Standard" `
    -ServiceObjective "S0"

# Other info
# Temp file to save the sync schema
$TempFile1 = $env:TEMP+"\syncSchema.json"
$TempFile2 = $env:TEMP+"\dbSchema.json"

# List of included columns and tables in quoted name
$IncludedColumnsAndTables =  @($TablesColumnsToSync)
$MetadataList = [System.Collections.ArrayList]::new($IncludedColumnsAndTables)


Connect-AzAccount 
select-Azsubscription -SubscriptionId $SubscriptionId

# Use this section if it is safe to show password in the script.
# Otherwise, use the PromptForCredential
 
 $PWord = ConvertTo-SecureString -String $hubdbpassword -AsPlainText -Force
 $Credential = New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList $hubdbuser, $PWord

#$Credential = $Host.ui.PromptForCredential("Need credential", 
#              "Please enter your user name and password for server "+$ServerName+".database.windows.net", 
#              "", 
#              "")

# Create a new sync group
Write-Host "Creating Sync Group"$SyncGroupName
New-AzSqlSyncGroup   -ResourceGroupName $ResourceGroupName `
                            -ServerName $ServerName `
                            -DatabaseName $DatabaseName `
                            -Name $SyncGroupName `
                            -SyncDatabaseName $SyncDatabaseName `
                            -SyncDatabaseServerName $SyncDatabaseServerName `
                            -SyncDatabaseResourceGroupName $SyncDatabaseResourceGroupName `
                            -ConflictResolutionPolicy $ConflictResolutionPolicy `
                            -DatabaseCredential $Credential

# Use this section if it is safe to show password in the script.
#$User = "username"
$Password = ConvertTo-SecureString -String $hubdbpassword -AsPlainText -Force
$Credential = New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList $hubdbuser, $Password

#$Credential = $Host.ui.PromptForCredential("Need credential", 
#             "Please enter your user name and password for server "+$MemberServerName, 
#              "", 
#              "")

# Add a new sync member
# You can add members from other subscriptions, you don't need to specify Subscription Id for the member
Write-Host "Adding member"$SyncMemberName" to the sync group"
New-AzSqlSyncMember   -ResourceGroupName $ResourceGroupName `
                            -ServerName $ServerName `
                            -DatabaseName $DatabaseName `
                            -SyncGroupName $SyncGroupName `
                            -Name $SyncMemberName `
                            -MemberDatabaseCredential $Credential `
                            -MemberDatabaseName $MemberDatabaseName `
                            -MemberServerName ($MemberServerName + ".database.windows.net") `
                            -MemberDatabaseType $MemberDatabaseType `
                            -SyncDirection $SyncDirection

# Refresh database schema from hub database
# Specify the -SyncMemberName parameter if you want to refresh schema from the member database
Write-Host "Refreshing database schema from hub database"
$StartTime= Get-Date
Update-AzSqlSyncSchema   -ResourceGroupName $ResourceGroupName `
                              -ServerName $ServerName `
                              -DatabaseName $DatabaseName `
                              -SyncGroupName $SyncGroupName


#Waiting for successful refresh

$StartTime=$StartTime.ToUniversalTime()
$timer=0
$timeout=90
# Check the log and see if refresh has gone through
Write-Host "Check for successful refresh"
$IsSucceeded = $false
While ($IsSucceeded -eq $false)
{
    Start-Sleep -s 10
    $timer=$timer+10
    $Details = Get-AzSqlSyncSchema -SyncGroupName $SyncGroupName -ServerName $ServerName -DatabaseName $DatabaseName -ResourceGroupName $ResourceGroupName
    if ($Details.LastUpdateTime -gt $StartTime)
      {
        Write-Host "Refresh was successful"
        $IsSucceeded = $true
      }
    if ($timer -eq $timeout) 
      {
              Write-Host "Refresh timed out"
        break;
      }
}



# Get the database schema 
Write-Host "Adding tables and columns to the sync schema"
$databaseSchema = Get-AzSqlSyncSchema   -ResourceGroupName $ResourceGroupName `
                                             -ServerName $ServerName `
                                             -DatabaseName $DatabaseName `
                                             -SyncGroupName $SyncGroupName `

$databaseSchema | ConvertTo-Json -depth 5 -Compress | Out-File $TempFile2
$newSchema = [AzureSqlSyncGroupSchemaModel]::new()
$newSchema.Tables = [List[AzureSqlSyncGroupSchemaTableModel]]::new();

# Add columns and tables to the sync schema
foreach ($tableSchema in $databaseSchema.Tables)
{
    $newTableSchema = [AzureSqlSyncGroupSchemaTableModel]::new()
    $newTableSchema.QuotedName = $tableSchema.QuotedName
    $newTableSchema.Columns = [List[AzureSqlSyncGroupSchemaColumnModel]]::new();
    $addAllColumns = $false
    if ($MetadataList.Contains($tableSchema.QuotedName))
    {
        if ($tableSchema.HasError)
        {
            $fullTableName = $tableSchema.QuotedName
            Write-Host "Can't add table $fullTableName to the sync schema" -foregroundcolor "Red"
            Write-Host $tableSchema.ErrorId -foregroundcolor "Red"
            continue;
        }
        else
        {
            $addAllColumns = $true
        }
    }
    foreach($columnSchema in $tableSchema.Columns)
    {
        $fullColumnName = $tableSchema.QuotedName + "." + $columnSchema.QuotedName
        if ($addAllColumns -or $MetadataList.Contains($fullColumnName))
        {
            if ((-not $addAllColumns) -and $tableSchema.HasError)
            {
                Write-Host "Can't add column $fullColumnName to the sync schema" -foregroundcolor "Red"
                Write-Host $tableSchema.ErrorId -foregroundcolor "Red"c            }
            elseif ((-not $addAllColumns) -and $columnSchema.HasError)
            {
                Write-Host "Can't add column $fullColumnName to the sync schema" -foregroundcolor "Red"
                Write-Host $columnSchema.ErrorId -foregroundcolor "Red"
            }
            else
            {
                Write-Host "Adding"$fullColumnName" to the sync schema"
                $newColumnSchema = [AzureSqlSyncGroupSchemaColumnModel]::new()
                $newColumnSchema.QuotedName = $columnSchema.QuotedName
                $newColumnSchema.DataSize = $columnSchema.DataSize
                $newColumnSchema.DataType = $columnSchema.DataType
                $newTableSchema.Columns.Add($newColumnSchema)
            }
        }
    }
    if ($newTableSchema.Columns.Count -gt 0)
    {
        $newSchema.Tables.Add($newTableSchema)
    }
}

# Convert sync schema to Json format
$schemaString = $newSchema | ConvertTo-Json -depth 5 -Compress

# workaround a powershell bug
$schemaString = $schemaString.Replace('"Tables"', '"tables"').Replace('"Columns"', '"columns"').Replace('"QuotedName"', '"quotedName"').Replace('"MasterSyncMemberName"','"masterSyncMemberName"')

# Save the sync schema to a temp file
$schemaString | Out-File $TempFile1

# Update sync schema
Write-Host "Updating the sync schema"
Update-AzSqlSyncGroup  -ResourceGroupName $ResourceGroupName `
                            -ServerName $ServerName `
                            -DatabaseName $DatabaseName `
                            -Name $SyncGroupName `
                            -Schema $TempFile1

$SyncLogStartTime = Get-Date

# Trigger sync manually
Write-Host "Trigger sync manually"
Start-AzSqlSyncGroupSync  -ResourceGroupName $ResourceGroupName `
                               -ServerName $ServerName `
                               -DatabaseName $DatabaseName `
                               -SyncGroupName $SyncGroupName

# Check the sync log and wait until the first sync succeeded
Write-Host "Check the sync log"
$IsSucceeded = $false
For ($i = 0; ($i -lt 300) -and (-not $IsSucceeded); $i = $i + 10)
{
    Start-Sleep -s 10
    $SyncLogEndTime = Get-Date
    $SyncLogList = Get-AzSqlSyncGroupLog  -ResourceGroupName $ResourceGroupName `
                                           -ServerName $ServerName `
                                           -DatabaseName $DatabaseName `
                                           -SyncGroupName $SyncGroupName `
                                           -StartTime $SyncLogStartTime.ToUniversalTime() `
                                           -EndTime $SyncLogEndTime.ToUniversalTime()
    if ($SynclogList.Length -gt 0)
    {
        foreach ($SyncLog in $SyncLogList)
        {
            if ($SyncLog.Details.Contains("Sync completed successfully"))
            {
                Write-Host $SyncLog.TimeStamp : $SyncLog.Details
                $IsSucceeded = $true
            }
        }
    }
}

if ($IsSucceeded)
{
    # Enable scheduled sync
    Write-Host "Enable the scheduled sync with 300 seconds interval"
    Update-AzSqlSyncGroup  -ResourceGroupName $ResourceGroupName `
                                -ServerName $ServerName `
                                -DatabaseName $DatabaseName `
                                -Name $SyncGroupName `
                                -IntervalInSeconds $IntervalInSeconds
}
else
{
    # Output all log if sync doesn't succeed in 300 seconds
    $SyncLogEndTime = Get-Date
    $SyncLogList = Get-AzSqlSyncGroupLog  -ResourceGroupName $ResourceGroupName `
                                           -ServerName $ServerName `
                                           -DatabaseName $DatabaseName `
                                           -SyncGroupName $SyncGroupName `
                                           -StartTime $SyncLogStartTime.ToUniversalTime() `
                                           -EndTime $SyncLogEndTime.ToUniversalTime()
    if ($SynclogList.Length -gt 0)
    {
        foreach ($SyncLog in $SyncLogList)
        {
            Write-Host $SyncLog.TimeStamp : $SyncLog.Details
        }
    }
}

