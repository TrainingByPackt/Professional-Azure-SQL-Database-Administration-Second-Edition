	## Code is reviewed and is in working condition

	Try
	{
		
		Login-AzureRmAccount
        		$removesqldb = @{
                ResourceGroupName=$resourcegroupname
                ServerName=$azuresqlservername;
                DatabaseName= $databasename;
            }
            Remove-AzureRmSqlDatabase;
  
		
	}
	catch
	{
		$ErrorMessage = $_.Exception.Message
	    $FailedItem = $_.Exception.ItemName
		Write-host $ErrorMessage $FailedItem -ForegroundColor Red
	}


