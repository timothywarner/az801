<#
.SYNOPSIS
    Task 14.3 - Recover to New VM

.DESCRIPTION
    Demonstrates restoring Azure VM to a new VM from recovery points.

.NOTES
    Module: Module 14 - Backup and Recover Azure VMs
    Task: 14.3 - Recover to New VM
    Prerequisites: Az.RecoveryServices, Az.Compute modules
    PowerShell Version: 5.1+
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ResourceGroupName = "rg-vm-backup",
    
    [Parameter(Mandatory = $false)]
    [string]$NewVMName = "vm-restored-01"
)

$ErrorActionPreference = 'Stop'
Write-Host "=== AZ-801 Module 14: Task 14.3 - Recover to New VM ===" -ForegroundColor Cyan
Write-Host ""

try {
    Write-Host "[Step 1] Authenticating to Azure" -ForegroundColor Yellow
    
    $context = Get-AzContext -ErrorAction SilentlyContinue
    if (-not $context) {
        Connect-AzAccount
    }
    Write-Host "  Connected" -ForegroundColor Green
    Write-Host ""

    Write-Host "[Step 2] Recovery Options" -ForegroundColor Yellow
    Write-Host "Azure VM restore options:" -ForegroundColor Cyan
    Write-Host "  1. Create new VM - Full VM restoration" -ForegroundColor White
    Write-Host "  2. Restore disks - Disks only (custom VM config)" -ForegroundColor White
    Write-Host "  3. Replace existing - Replace existing VM disks" -ForegroundColor White
    Write-Host "  4. Cross-region restore - Restore to secondary region" -ForegroundColor White
    Write-Host ""

    Write-Host "[Step 3] Restore VM Configuration" -ForegroundColor Yellow
    Write-Host "Step-by-step VM restore process:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. Get backup item:" -ForegroundColor White
    Write-Host '   $vault = Get-AzRecoveryServicesVault -Name "VaultName"' -ForegroundColor Gray
    Write-Host '   Set-AzRecoveryServicesVaultContext -Vault $vault' -ForegroundColor Gray
    Write-Host '   $container = Get-AzRecoveryServicesBackupContainer -ContainerType AzureVM' -ForegroundColor Gray
    Write-Host '   $item = Get-AzRecoveryServicesBackupItem -Container $container[0] -WorkloadType AzureVM' -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "2. Select recovery point:" -ForegroundColor White
    Write-Host '   $rp = Get-AzRecoveryServicesBackupRecoveryPoint -Item $item' -ForegroundColor Gray
    Write-Host '   $selectedRP = $rp[0]  # Most recent' -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "3. Create restore configuration:" -ForegroundColor White
    Write-Host '   $restoreConfig = Get-AzRecoveryServicesBackupWorkloadRecoveryConfig `' -ForegroundColor Gray
    Write-Host '       -RecoveryPoint $selectedRP `' -ForegroundColor Gray
    Write-Host '       -TargetResourceGroupName "rg-restored-vms" `' -ForegroundColor Gray
    Write-Host '       -RestoreAsUnmanagedDisks' -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "4. Start restore job:" -ForegroundColor White
    Write-Host '   $restoreJob = Restore-AzRecoveryServicesBackupItem `' -ForegroundColor Gray
    Write-Host '       -RecoveryPoint $selectedRP `' -ForegroundColor Gray
    Write-Host '       -StorageAccountName "restorestorageacct" `' -ForegroundColor Gray
    Write-Host '       -StorageAccountResourceGroupName "rg-storage" `' -ForegroundColor Gray
    Write-Host '       -TargetResourceGroupName "rg-restored-vms"' -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "5. Monitor restore job:" -ForegroundColor White
    Write-Host '   Wait-AzRecoveryServicesBackupJob -Job $restoreJob -Timeout 43200' -ForegroundColor Gray
    Write-Host '   $jobDetails = Get-AzRecoveryServicesBackupJobDetail -Job $restoreJob' -ForegroundColor Gray
    Write-Host ""

    Write-Host "[Step 4] Create VM from Restored Disks" -ForegroundColor Yellow
    Write-Host "After disk restore completes:" -ForegroundColor Cyan
    Write-Host '  # Get restore details' -ForegroundColor Gray
    Write-Host '  $details = Get-AzRecoveryServicesBackupJobDetail -Job $restoreJob' -ForegroundColor Gray
    Write-Host '  $properties = $details.Properties' -ForegroundColor Gray
    Write-Host '  $templateBlobURI = $properties["Template Blob Uri"]' -ForegroundColor Gray
    Write-Host ""
    Write-Host '  # Download and deploy ARM template' -ForegroundColor Gray
    Write-Host '  $templatePath = "C:\Temp\VMTemplate.json"' -ForegroundColor Gray
    Write-Host '  Invoke-WebRequest -Uri $templateBlobURI -OutFile $templatePath' -ForegroundColor Gray
    Write-Host ""
    Write-Host '  # Deploy restored VM' -ForegroundColor Gray
    Write-Host '  New-AzResourceGroupDeployment `' -ForegroundColor Gray
    Write-Host '      -ResourceGroupName "rg-restored-vms" `' -ForegroundColor Gray
    Write-Host '      -TemplateFile $templatePath `' -ForegroundColor Gray
    Write-Host '      -Name "RestoreDeployment"' -ForegroundColor Gray
    Write-Host ""

    Write-Host "[Step 5] Cross-Region Restore" -ForegroundColor Yellow
    Write-Host "Restore VM to secondary region (if GRS enabled):" -ForegroundColor Cyan
    Write-Host '  $vault = Get-AzRecoveryServicesVault -Name "VaultName"' -ForegroundColor Gray
    Write-Host '  $container = Get-AzRecoveryServicesBackupContainer `' -ForegroundColor Gray
    Write-Host '      -ContainerType AzureVM -VaultId $vault.ID -Status Registered' -ForegroundColor Gray
    Write-Host ""
    Write-Host '  # Get recovery points from secondary region' -ForegroundColor Gray
    Write-Host '  $rpSecondary = Get-AzRecoveryServicesBackupRecoveryPoint `' -ForegroundColor Gray
    Write-Host '      -Item $item -UseSecondaryRegion' -ForegroundColor Gray
    Write-Host ""
    Write-Host '  # Restore to secondary region' -ForegroundColor Gray
    Write-Host '  Restore-AzRecoveryServicesBackupItem `' -ForegroundColor Gray
    Write-Host '      -RecoveryPoint $rpSecondary[0] `' -ForegroundColor Gray
    Write-Host '      -TargetResourceGroupName "rg-dr-region" `' -ForegroundColor Gray
    Write-Host '      -UseSecondaryRegion' -ForegroundColor Gray
    Write-Host ""

    Write-Host "[Step 6] Best Practices" -ForegroundColor Yellow
    Write-Host "[INFO] VM Restore Best Practices:" -ForegroundColor Cyan
    Write-Host "  - Test restore procedures regularly" -ForegroundColor White
    Write-Host "  - Verify VM configuration after restore" -ForegroundColor White
    Write-Host "  - Update DNS and load balancer after restore" -ForegroundColor White
    Write-Host "  - Reconfigure networking and NSGs" -ForegroundColor White
    Write-Host "  - Document restore procedures" -ForegroundColor White
    Write-Host "  - Use managed disks for simplified restore" -ForegroundColor White
    Write-Host "  - Enable cross-region restore for DR scenarios" -ForegroundColor White
    Write-Host ""

} catch {
    Write-Host "[ERROR] $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

Write-Host "Script completed successfully!" -ForegroundColor Green
