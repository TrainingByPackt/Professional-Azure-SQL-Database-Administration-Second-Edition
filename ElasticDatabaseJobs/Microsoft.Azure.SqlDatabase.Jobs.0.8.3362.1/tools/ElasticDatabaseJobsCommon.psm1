###########################################################################################################################
### Common helper methods for Elastic Database Jobs Install/Update Scripts
###
###########################################################################################################################

function Log([Parameter(ValueFromPipeline=$true)]$Message, $LogColor = "Cyan")
{
    if(-not $NoHost)
    {
        Write-Host $Message -ForegroundColor $LogColor
    }
    else
    {
        Write-Output $Message
    }
}

function GetSqlDatabaseConnectionStringNoPassword()
{
    param (
        [Parameter(Mandatory=$true)][string]$AzureSqlServerName,
        [Parameter(Mandatory=$false)][string]$AzureSqlDatabaseDnsSuffix = "",
        [Parameter(Mandatory=$true)][string]$AzureSqlDatabaseName,
        [Parameter(Mandatory=$true)][string]$SqlServerAdministratorUserName
    )
    
    "Server=$AzureSqlServerName$AzureSqlDatabaseDnsSuffix; Database=$($AzureSqlDatabaseName); User ID=$SqlServerAdministratorUserName; Encrypt=true; TrustServerCertificate=false"
}

function GetSqlDatabaseConnectionStringWithPassword()
{
    param (
        [Parameter(Mandatory=$true)][string]$DatabaseConnectionStringNoPassword,
        [Parameter(Mandatory=$true)][string]$SqlServerAdministratorPassword
    )

    "$DatabaseConnectionStringNoPassword;Password=$SqlServerAdministratorPassword"
}

function TestSqlServerDatabaseConnection
{
    param (
        [Parameter(Mandatory=$true)][string]$AzureSqlDatabaseConnectionString
    )

    Log "Azure Sql Database connection string: $AzureSqlDatabaseConnectionString"

    while($true)
    {
        # Verify connection strings
        Log "Attempting to connect to Azure SQL Database"
        $sqlConn = New-Object -TypeName "System.Data.SqlClient.SqlConnection" -ArgumentList $AzureSqlDatabaseConnectionString 

        try
        {
            $sqlConn.Open()
            Log "Successfully connected to Azure SQL Database"
            return
        }
        catch
        {
            Log $_.Exception.Message
            Log "Sleeping for 10 seconds before retrying"
            Start-Sleep -Seconds 10
        }
        finally
        {
            $sqlConn.Dispose()
        }
    }

    Log "Successfully connected to Azure Sql Database"
    return $databaseConnectionStringNoPassword
}

function LoadCryptographyAssembly()
{
    $EdjCryptographyAssembly = "$PSScriptRoot\Microsoft.Azure.SqlDatabase.ElasticScale.Cryptography.dll"
    Log "Loading assembly $EdjCryptographyAssembly"
    Unblock-File $EdjCryptographyAssembly 
    Add-Type -Path $EdjCryptographyAssembly
}
