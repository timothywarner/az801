# Enable Recycle Bin
Enable-ADOptionalFeature 'Recycle Bin Feature' `
-Scope ForestOrConfigurationSet -Target timw.info

# Recover objects from bin
Get-ADObject -Filter 'isDeleted -eq $true -and Name -like "*DEL:*"' –IncludeDeletedObjects

Get-ADObject -Filter 'isDeleted -eq $true -and Name -like "*DEL:*"' –IncludeDeletedObjects | RestoreADObject

# Empty the bin
Get-ADObject -Filter 'isDeleted -eq $true -and Name -like "*DEL:*"' -IncludeDeletedObjects | Remove-ADObject -Confirm:$false


