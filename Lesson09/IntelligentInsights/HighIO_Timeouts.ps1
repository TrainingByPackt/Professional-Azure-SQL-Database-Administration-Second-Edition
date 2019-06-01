param
(
[string]$server="packtdbserver2.database.windows.net",
[string]$database="toystore_ADR",
[string]$user="dbadmin",
[string]$password="Awesome@1234"
)


# Query to simulate high log IO and increase Disk size (Resource limit alert)
$query="
DROP TABLE IF EXISTS t2;
SELECT a.* INTO t2 FROM sys.objects a, sys.objects b, sys.objects c, sys.objects d, sys.objects e;"
$i=1;
#timeouts
While($i -le 100)
{

    Invoke-Sqlcmd -ServerInstance $server -Database $database -Username $user -Password $password -Query $query -ErrorAction SilentlyContinue 
    Write-Output "Iteration $i"
    $i+=1
    
}

#HighIO
Invoke-Sqlcmd -ServerInstance $server -Database $database -Username $user -Password $password -Query $query -ErrorAction SilentlyContinue -QueryTimeout 0
pop-location
