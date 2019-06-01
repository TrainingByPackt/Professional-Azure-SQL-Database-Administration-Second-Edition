param
(
[string]$server="packtdbserver.database.windows.net",
[string]$database="toystore",
[string]$user="dbadmin",
[string]$password="Awesome@1234"
)


# Query to simulate high log IO and increase Disk size (Resource limit alert)
$query="DROP TABLE IF EXISTS t1;
GO
CREATE TABLE t1 (Sno INT IDENTITY,col1 CHAR(8000));
GO
INSERT INTO t1 VALUES ('dummy')
GO 100000"

Invoke-Sqlcmd -ServerInstance $server -Database $database -Username $user -Password $password -Query $query -AbortOnError

pop-location