param
(
[string]$server="packtdbserver2.database.windows.net",
[string]$database="toystore_ADR",
[string]$user="dbadmin",
[string]$password="Awesome@1234"
)




$query3="
begin tran
update Application.People set FullName='John Doe' WHERE PersonID=2

update Application.People set IsPermittedToLogOn=0 WHERE PersonID=2
"
Write-Host $query3
Invoke-Sqlcmd -ServerInstance $server -Database $database -Username $user -Password $password -Query $query3 -QueryTimeout 0
pop-location
