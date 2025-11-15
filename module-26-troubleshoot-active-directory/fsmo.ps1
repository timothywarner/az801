# Manage FSMO roles

# Discover FSMO role holders
netdom /query fsmo

Get-ADDomain | Select-Object InfrastructureMaster, PDCEmulator, RIDMaster | Format-List

Get-ADForest | Select-Object DomainNamingMaster, SchemaMaster | Format-List

# Move or seize a FSMO role
<#
PDCEmulator or 0
RIDMaster or 1
InfrastructureMaster or 2
SchemaMaster or 3
DomainNamingMaster or 4
#>

Move-ADDirectoryServerOperationMasterRole -Identity "<target-dc-name>" –OperationMasterRole 0, 1, 2, 3, 4 -Confirm:$false -Force