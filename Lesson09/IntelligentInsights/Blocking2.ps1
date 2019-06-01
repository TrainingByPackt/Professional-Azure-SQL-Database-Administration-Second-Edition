param
(
[string]$server="packtdbserver2.database.windows.net",
[string]$database="toystore_ADR",
[string]$user="dbadmin",
[string]$password="Awesome@1234"
)


$query2="
begin tran
update Application.People set FullName='Ram Doe' WHERE PersonID=2

update Application.People set IsPermittedToLogOn=0 WHERE PersonID=2
"
Write-Host $query2
Invoke-Sqlcmd -ServerInstance $server -Database $database -Username $user -Password $password -Query $query2 -QueryTimeout 0
pop-location


