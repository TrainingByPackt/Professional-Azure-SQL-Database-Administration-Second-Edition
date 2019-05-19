## Code is reviewed and is in working condition

param(
		[Parameter(Mandatory=$true)]
		[string]$sqlserver,
		[Parameter(Mandatory=$true)]
		[string]$database,
		[Parameter(Mandatory=$true)]
		[string]$sqluser,
		[Parameter(Mandatory=$true)]
		[string]$sqlpassword,
		[Parameter(Mandatory=$true)]
		[string]$resourcegroupname,
		[string]$newdatabasename	
)

# Login to Azure subscription
Login-AzureRmAccount

# list the earliest restore point
# Ask user for the point in time the database is to be restored

While (1)
		{
            #Retrieve the distinct restore points from which a SQL Database can be restored
			$restoredetails = Get-AzureRmSqlDatabaseRestorePoints -ServerName $sqlserver -DatabaseName $database -ResourceGroupName $resourcegroupname
			#get the earliest restore date
            $erd=$restoredetails.EarliestRestoreDate.ToString();
			#ask for the point in time the database is to be restored
            $restoretime = Read-Host "The earliest restore time is $erd.`n Enter a restore time between Earlist restore time and current time." 
			#convert the input to datatime data type
            $restoretime = $restoretime -as [DateTime]
			#if restore time isn't a valid data, prompt for a valid date
            if(!$restoretime)
			{
				Write-Host "Enter a valid date" -ForegroundColor Red
			}else
			{
                #end the while loop if restore date is a valid date
				break;
			}
		}

        #set the new database name
	    if([string]::IsNullOrEmpty($newdatabasename))
        { 
            $newdatabasename = $database + (Get-Date).ToString("MMddyyyymm")
        }

        # get the original database object
		$db = Get-AzureRmSqlDatabase -DatabaseName $database -ServerName $sqlserver -ResourceGroupName $resourcegroupname

		Write-Host "Restoring Database $database as of $newdatabasename to the time $restoretime"
        
        #restore the database to point in time
	    $restore = Restore-AzureRmSqlDatabase -FromPointInTimeBackup -PointInTime $restoretime -ResourceId $db.ResourceId -ServerName $db.ServerName -TargetDatabaseName $newdatabasename -Edition $db.Edition -ServiceObjectiveName $db.CurrentServiceObjectiveName -ResourceGroupName $db.ResourceGroupName 
                        
		
        # restore deleted database
            

		if($rerror -ne $null)
		{
			Write-Host $rerror -ForegroundColor red;
		}
		if($restore -ne $null)
		{
			Write-Host "Database $newdatabasename restored Successfully";
		}
