<#
.SYNOPSIS
    Task 14.4 - Restore Encrypted VM

.DESCRIPTION
    Demonstrates backup and restore of encrypted Azure VMs using Azure Disk Encryption.

.NOTES
    Module: Module 14 - Backup and Recover Azure VMs
    Task: 14.4 - Restore Encrypted VM
    Prerequisites: Az.RecoveryServices, Az.KeyVault modules
    PowerShell Version: 5.1+
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ResourceGroupName = "rg-encrypted-vms",
    
    [Parameter(Mandatory = $false)]
    [string]$KeyVaultName = "kv-encryption"
)

$ErrorActionPreference = 'Stop'
Write-Host "=== AZ-801 Module 14: Task 14.4 - Restore Encrypted VM ===" -ForegroundColor Cyan
Write-Host ""

try {
    Write-Host "[Step 1] Authenticating to Azure" -ForegroundColor Yellow
    
    $context = Get-AzContext -ErrorAction SilentlyContinue
    if (-not $context) {
        Connect-AzAccount
    }
    Write-Host "  Connected" -ForegroundColor Green
    Write-Host ""

    Write-Host "[Step 2] Azure Disk Encryption Overview" -ForegroundColor Yellow
    Write-Host "Encryption types supported:" -ForegroundColor Cyan
    Write-Host "  - Azure Disk Encryption (ADE) with BEK" -ForegroundColor White
    Write-Host "  - Azure Disk Encryption with BEK + KEK" -ForegroundColor White
    Write-Host "  - Server-side encryption (SSE) with PMK" -ForegroundColor White
    Write-Host "  - Server-side encryption with CMK" -ForegroundColor White
    Write-Host ""

    Write-Host "[Step 3] Prerequisites for Encrypted VM Backup" -ForegroundColor Yellow
    Write-Host "Key Vault configuration:" -ForegroundColor Cyan
    Write-Host '  # Enable Key Vault for deployment' -ForegroundColor Gray
    Write-Host '  Set-AzKeyVaultAccessPolicy `' -ForegroundColor Gray
    Write-Host '      -VaultName "kv-encryption" `' -ForegroundColor Gray
    Write-Host '      -EnabledForDeployment `' -ForegroundColor Gray
    Write-Host '      -EnabledForDiskEncryption `' -ForegroundColor Gray
    Write-Host '      -EnabledForTemplateDeployment' -ForegroundColor Gray
    Write-Host ""
    Write-Host '  # Grant backup service access' -ForegroundColor Gray
    Write-Host '  Set-AzKeyVaultAccessPolicy `' -ForegroundColor Gray
    Write-Host '      -VaultName "kv-encryption" `' -ForegroundColor Gray
    Write-Host '      -ServicePrincipalName "262044b1-e2ce-469f-a196-69ab7ada62d3" `' -ForegroundColor Gray
    Write-Host '      -PermissionsToKeys get,list `' -ForegroundColor Gray
    Write-Host '      -PermissionsToSecrets get,list' -ForegroundColor Gray
    Write-Host ""

    Write-Host "[Step 4] Backup Encrypted VM" -ForegroundColor Yellow
    Write-Host "Enable backup for encrypted VM:" -ForegroundColor Cyan
    Write-Host '  $vault = Get-AzRecoveryServicesVault -Name "VaultName"' -ForegroundColor Gray
    Write-Host '  Set-AzRecoveryServicesVaultContext -Vault $vault' -ForegroundColor Gray
    Write-Host ""
    Write-Host '  $policy = Get-AzRecoveryServicesBackupProtectionPolicy -Name "VMPolicy"' -ForegroundColor Gray
    Write-Host '  Enable-AzRecoveryServicesBackupProtection `' -ForegroundColor Gray
    Write-Host '      -ResourceGroupName "rg-encrypted-vms" `' -ForegroundColor Gray
    Write-Host '      -Name "vm-encrypted-01" `' -ForegroundColor Gray
    Write-Host '      -Policy $policy' -ForegroundColor Gray
    Write-Host ""

    Write-Host "[Step 5] Restore Encrypted VM" -ForegroundColor Yellow
    Write-Host "Restore process for encrypted VMs:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. Ensure Key Vault access:" -ForegroundColor White
    Write-Host '   $kv = Get-AzKeyVault -VaultName "kv-encryption"' -ForegroundColor Gray
    Write-Host '   # Verify encryption keys are accessible' -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "2. Get recovery point:" -ForegroundColor White
    Write-Host '   $container = Get-AzRecoveryServicesBackupContainer -ContainerType AzureVM' -ForegroundColor Gray
    Write-Host '   $item = Get-AzRecoveryServicesBackupItem -Container $container -WorkloadType AzureVM' -ForegroundColor Gray
    Write-Host '   $rp = Get-AzRecoveryServicesBackupRecoveryPoint -Item $item' -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "3. Restore encrypted disks:" -ForegroundColor White
    Write-Host '   $restoreJob = Restore-AzRecoveryServicesBackupItem `' -ForegroundColor Gray
    Write-Host '       -RecoveryPoint $rp[0] `' -ForegroundColor Gray
    Write-Host '       -StorageAccountName "storageacct" `' -ForegroundColor Gray
    Write-Host '       -StorageAccountResourceGroupName "rg-storage" `' -ForegroundColor Gray
    Write-Host '       -TargetResourceGroupName "rg-restored"' -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "4. Create VM with encryption:" -ForegroundColor White
    Write-Host '   # VM will maintain encryption settings' -ForegroundColor Gray
    Write-Host '   # Encryption keys automatically linked from Key Vault' -ForegroundColor Gray
    Write-Host ""

    Write-Host "[Step 6] Restore with Different Key Vault" -ForegroundColor Yellow
    Write-Host "Cross-subscription or cross-region restore:" -ForegroundColor Cyan
    Write-Host '  # Restore BEK (BitLocker Encryption Key)' -ForegroundColor Gray
    Write-Host '  $bekSecretUrl = $rp.KeyAndSecretDetails.SecretUrl' -ForegroundColor Gray
    Write-Host '  Restore-AzKeyVaultSecret `' -ForegroundColor Gray
    Write-Host '      -VaultName "kv-target" `' -ForegroundColor Gray
    Write-Host '      -InputObject $bekSecretUrl' -ForegroundColor Gray
    Write-Host ""
    Write-Host '  # Restore KEK (Key Encryption Key) if used' -ForegroundColor Gray
    Write-Host '  if ($rp.KeyAndSecretDetails.KekUrl) {' -ForegroundColor Gray
    Write-Host '      Restore-AzKeyVaultKey -VaultName "kv-target" -InputObject $kekUrl' -ForegroundColor Gray
    Write-Host '  }' -ForegroundColor Gray
    Write-Host ""

    Write-Host "[Step 7] Troubleshooting Encrypted VM Restore" -ForegroundColor Yellow
    Write-Host "Common issues and solutions:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Issue: Key Vault access denied" -ForegroundColor White
    Write-Host "  Solution: Verify backup service principal permissions" -ForegroundColor Gray
    Write-Host '  Get-AzKeyVaultAccessPolicy -VaultName "kv-encryption"' -ForegroundColor Gray
    Write-Host ""
    Write-Host "Issue: Encryption keys not found" -ForegroundColor White
    Write-Host "  Solution: Ensure keys exist in target Key Vault" -ForegroundColor Gray
    Write-Host '  Get-AzKeyVaultKey -VaultName "kv-encryption"' -ForegroundColor Gray
    Write-Host '  Get-AzKeyVaultSecret -VaultName "kv-encryption"' -ForegroundColor Gray
    Write-Host ""

    Write-Host "[Step 8] Best Practices" -ForegroundColor Yellow
    Write-Host "[INFO] Encrypted VM Backup Best Practices:" -ForegroundColor Cyan
    Write-Host "  - Backup Key Vault separately" -ForegroundColor White
    Write-Host "  - Use geo-redundant Key Vault for production" -ForegroundColor White
    Write-Host "  - Test encrypted VM restore regularly" -ForegroundColor White
    Write-Host "  - Document Key Vault and encryption settings" -ForegroundColor White
    Write-Host "  - Use Azure Policy to enforce encryption" -ForegroundColor White
    Write-Host "  - Monitor Key Vault access logs" -ForegroundColor White
    Write-Host "  - Maintain offline copy of KEK recovery keys" -ForegroundColor White
    Write-Host "  - Use managed identities where possible" -ForegroundColor White
    Write-Host ""

} catch {
    Write-Host "[ERROR] $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

Write-Host "Script completed successfully!" -ForegroundColor Green
