<#
.SYNOPSIS
    Task 7.2 - Configure Azure Disk Encryption
.DESCRIPTION
    Comprehensive demonstration of Azure Disk Encryption for Windows Server VMs.
    Covers Key Vault setup, ADE enablement, and encryption status monitoring.
.EXAMPLE
    .\task-7.2-azure-disk-encryption.ps1
.NOTES
    Module: Module 7 - Secure Storage with Encryption
    Task: 7.2 - Configure Azure Disk Encryption
    Prerequisites:
    - Azure subscription
    - Az PowerShell modules
    - Azure VM with managed disks
    PowerShell Version: 5.1+
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

Write-Host "=== AZ-801 Module 7: Task 7.2 - Configure Azure Disk Encryption ===" -ForegroundColor Cyan
Write-Host ""

try {
    # Step 1: Azure Disk Encryption Overview
    Write-Host "[Step 1] Azure Disk Encryption Overview" -ForegroundColor Yellow
    Write-Host "ADE uses BitLocker for Windows VMs and DM-Crypt for Linux VMs" -ForegroundColor White
    Write-Host "  - Encrypts OS and data disks" -ForegroundColor White
    Write-Host "  - Keys stored in Azure Key Vault" -ForegroundColor White
    Write-Host "  - Integration with Azure Security Center" -ForegroundColor White
    Write-Host ""

    # Step 2: Check Azure modules
    Write-Host "[Step 2] Checking Azure modules" -ForegroundColor Yellow
    foreach ($mod in @('Az.Accounts', 'Az.Compute', 'Az.KeyVault')) {
        $installed = Get-Module -ListAvailable -Name $mod | Select-Object -First 1
        if ($installed) {
            Write-Host "  $mod : Version $($installed.Version) [OK]" -ForegroundColor Green
        } else {
            Write-Host "  $mod : Not installed" -ForegroundColor Yellow
        }
    }
    Write-Host ""

    # Step 3: Connect to Azure
    Write-Host "[Step 3] Connecting to Azure" -ForegroundColor Yellow
    try {
        $context = Get-AzContext
        if ($context) {
            Write-Host "Connected: $($context.Subscription.Name)" -ForegroundColor Green
        } else {
            Write-Host "Run: Connect-AzAccount" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "Run: Connect-AzAccount" -ForegroundColor Yellow
    }
    Write-Host ""

    # Step 4: Create Key Vault
    Write-Host "[Step 4] Creating Azure Key Vault" -ForegroundColor Yellow
    Write-Host @'
  $resourceGroupName = "rg-encryption"
  $location = "East US"
  $keyVaultName = "kv-diskenc-$(Get-Random)"

  New-AzResourceGroup -Name $resourceGroupName -Location $location

  $keyVault = New-AzKeyVault `
      -VaultName $keyVaultName `
      -ResourceGroupName $resourceGroupName `
      -Location $location `
      -EnabledForDiskEncryption

  Write-Host "Key Vault created: $($keyVault.VaultName)"
'@ -ForegroundColor Gray
    Write-Host ""

    # Step 5: Set Key Vault access policy
    Write-Host "[Step 5] Configuring Key Vault access policy" -ForegroundColor Yellow
    Write-Host @'
  # Enable for disk encryption
  Set-AzKeyVaultAccessPolicy `
      -VaultName $keyVaultName `
      -ResourceGroupName $resourceGroupName `
      -EnabledForDiskEncryption

  # Grant permissions to service principal
  $appId = (Get-AzContext).Account.Id
  Set-AzKeyVaultAccessPolicy `
      -VaultName $keyVaultName `
      -ServicePrincipalName $appId `
      -PermissionsToKeys wrapKey `
      -PermissionsToSecrets set
'@ -ForegroundColor Gray
    Write-Host ""

    # Step 6: Enable Azure Disk Encryption
    Write-Host "[Step 6] Enabling Azure Disk Encryption on VM" -ForegroundColor Yellow
    Write-Host @'
  $vmName = "server01"
  $rgName = "rg-servers"

  # Enable encryption on OS and data disks
  Set-AzVMDiskEncryptionExtension `
      -ResourceGroupName $rgName `
      -VMName $vmName `
      -DiskEncryptionKeyVaultUrl $keyVault.VaultUri `
      -DiskEncryptionKeyVaultId $keyVault.ResourceId `
      -VolumeType "All" `
      -Force

  Write-Host "Encryption enabled. Process may take 15-30 minutes."
'@ -ForegroundColor Gray
    Write-Host ""

    # Step 7: Check encryption status
    Write-Host "[Step 7] Checking encryption status" -ForegroundColor Yellow
    Write-Host @'
  $status = Get-AzVMDiskEncryptionStatus `
      -ResourceGroupName $rgName `
      -VMName $vmName

  Write-Host "OS Volume Encrypted: $($status.OsVolumeEncrypted)"
  Write-Host "OS Volume Encryption Settings: $($status.OsVolumeEncryptionSettings)"
  Write-Host "Data Volumes Encrypted: $($status.DataVolumesEncrypted)"
  Write-Host "Progress Message: $($status.ProgressMessage)"
'@ -ForegroundColor Gray
    Write-Host ""

    # Step 8: Retrieve encryption secrets
    Write-Host "[Step 8] Retrieving encryption secrets from Key Vault" -ForegroundColor Yellow
    Write-Host @'
  # Get all secrets from Key Vault
  $secrets = Get-AzKeyVaultSecret -VaultName $keyVaultName

  foreach ($secret in $secrets) {
      Write-Host "Secret: $($secret.Name)"
      Write-Host "  Enabled: $($secret.Enabled)"
      Write-Host "  Created: $($secret.Created)"
  }
'@ -ForegroundColor Gray
    Write-Host ""

    # Step 9: Disable encryption
    Write-Host "[Step 9] Disabling encryption (if needed)" -ForegroundColor Yellow
    Write-Host @'
  # Disable encryption on VM
  Disable-AzVMDiskEncryption `
      -ResourceGroupName $rgName `
      -VMName $vmName `
      -VolumeType "All" `
      -Force

  # Note: Decryption process may take time
'@ -ForegroundColor Gray
    Write-Host ""

    # Step 10: Best practices
    Write-Host "[Step 10] Best practices" -ForegroundColor Yellow
    Write-Host "  1. Use dedicated Key Vault for disk encryption" -ForegroundColor White
    Write-Host "  2. Enable soft delete and purge protection on Key Vault" -ForegroundColor White
    Write-Host "  3. Backup Key Vault keys and secrets" -ForegroundColor White
    Write-Host "  4. Use managed disks (required for ADE)" -ForegroundColor White
    Write-Host "  5. Monitor encryption status regularly" -ForegroundColor White
    Write-Host "  6. Test recovery procedures" -ForegroundColor White
    Write-Host "  7. Document Key Vault and encryption settings" -ForegroundColor White
    Write-Host "  8. Use Azure Policy to enforce encryption" -ForegroundColor White
    Write-Host "  9. Keep VMs running during encryption process" -ForegroundColor White
    Write-Host "  10. Plan maintenance windows for encryption enablement" -ForegroundColor White
    Write-Host ""

} catch {
    Write-Host "[ERROR] $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

Write-Host "Demo completed successfully!" -ForegroundColor Green
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Create Azure Key Vault with disk encryption enabled" -ForegroundColor White
Write-Host "  2. Enable ADE on all Azure VMs" -ForegroundColor White
Write-Host "  3. Monitor encryption status" -ForegroundColor White
Write-Host "  4. Backup Key Vault secrets" -ForegroundColor White
Write-Host "  5. Use Azure Policy for compliance" -ForegroundColor White
