# Enable Recycle Bin
Enable-ADOptionalFeature 'Recycle Bin Feature' `
-Scope ForestOrConfigurationSet -Target timw.info

# Get msDS-deletedObjectLifetime
Get-ADObject -Identity "CN=Directory Service,CN=Windows NT,CN=Services,CN=Configuration,DC=timw,DC=info" -Property msDS-DeletedObjectLifetime

# Set msDS-deletedObjectLifetime
Set-ADObject -Identity "CN=Directory Service,CN=Windows NT,CN=Services,CN=Configuration,DC=timw,DC=info" -Partition "CN=Configuration,DC=timw,DC=info" -Replace:@{"msDS-DeletedObjectLifetime" = 365 }

# Recover objects from bin
Get-ADObject -Filter 'isDeleted -eq $true -and Name -like "*DEL:*"' –IncludeDeletedObjects

Get-ADObject -Filter 'isDeleted -eq $true -and Name -like "*DEL:*"' –IncludeDeletedObjects | RestoreADObject

# Empty the bin
Get-ADObject -Filter 'isDeleted -eq $true -and Name -like "*DEL:*"' -IncludeDeletedObjects | Remove-ADObject -Confirm:$false
