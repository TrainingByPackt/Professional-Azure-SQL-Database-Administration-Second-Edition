param
(
[string]$server="packtdbserver2.database.windows.net",
[string]$database="toystore_ADR",
[string]$user="dbadmin",
[string]$password="Awesome@1234"
)

# Query to simulate high log IO and increase Disk size (Resource limit alert)
$query1="
begin tran
update Application.People set FullName='Kevin Doe' WHERE PersonID=2
"
Write-Host $query1
$s = New-PSSession
Invoke-Sqlcmd -ServerInstance $server -Database $database -Username $user -Password $password -Query $query1 -QueryTimeout 0
Pop-Location


