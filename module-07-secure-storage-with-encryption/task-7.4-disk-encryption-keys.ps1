<#
.SYNOPSIS
    Task 7.4 - Manage Disk Encryption Keys
.DESCRIPTION
    Comprehensive demonstration of managing disk encryption keys in Azure Key Vault.
    Covers key creation, backup, restore, rotation, and access policies.
.EXAMPLE
    .\task-7.4-disk-encryption-keys.ps1
.NOTES
    Module: Module 7 - Secure Storage with Encryption
    Task: 7.4 - Manage Disk Encryption Keys
    Prerequisites:
    - Azure subscription
    - Az PowerShell modules
    - Azure Key Vault
    PowerShell Version: 5.1+
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

Write-Host "=== AZ-801 Module 7: Task 7.4 - Manage Disk Encryption Keys ===" -ForegroundColor Cyan
Write-Host ""

try {
    # Step 1: Key Management Overview
    Write-Host "[Step 1] Encryption Key Management Overview" -ForegroundColor Yellow
    Write-Host "Azure Key Vault stores:" -ForegroundColor Cyan
    Write-Host "  - Encryption keys (KEK - Key Encryption Keys)" -ForegroundColor White
    Write-Host "  - Disk encryption secrets (BEK - BitLocker Encryption Keys)" -ForegroundColor White
    Write-Host "  - Certificates for authentication" -ForegroundColor White
    Write-Host ""

    # Step 2: Check Azure modules
    Write-Host "[Step 2] Checking Azure PowerShell modules" -ForegroundColor Yellow
    foreach ($mod in @('Az.Accounts', 'Az.KeyVault', 'Az.Compute')) {
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

    # Step 4: Get Key Vault
    Write-Host "[Step 4] Accessing Azure Key Vault" -ForegroundColor Yellow
    Write-Host @'
  $resourceGroupName = "rg-encryption"
  $keyVaultName = "kv-diskenc-12345"

  # Get Key Vault
  $keyVault = Get-AzKeyVault `
      -ResourceGroupName $resourceGroupName `
      -VaultName $keyVaultName

  Write-Host "Key Vault: $($keyVault.VaultName)"
  Write-Host "Location: $($keyVault.Location)"
  Write-Host "Resource ID: $($keyVault.ResourceId)"
'@ -ForegroundColor Gray
    Write-Host ""

    # Step 5: View encryption keys
    Write-Host "[Step 5] Viewing encryption keys and secrets" -ForegroundColor Yellow
    Write-Host @'
  # Get all keys
  $keys = Get-AzKeyVaultKey -VaultName $keyVaultName

  foreach ($key in $keys) {
      Write-Host "Key: $($key.Name)"
      Write-Host "  Enabled: $($key.Enabled)"
      Write-Host "  Created: $($key.Created)"
      Write-Host "  Key Type: $($key.KeyType)"
  }

  # Get all secrets (BitLocker keys)
  $secrets = Get-AzKeyVaultSecret -VaultName $keyVaultName

  foreach ($secret in $secrets) {
      Write-Host "Secret: $($secret.Name)"
      Write-Host "  Content Type: $($secret.ContentType)"
      Write-Host "  Created: $($secret.Created)"
  }
'@ -ForegroundColor Gray
    Write-Host ""

    # Step 6: Backup encryption keys
    Write-Host "[Step 6] Backing up encryption keys" -ForegroundColor Yellow
    Write-Host @'
  # Backup a key
  $keyBackupPath = "C:\Backup\key-backup.blob"
  Backup-AzKeyVaultKey `
      -VaultName $keyVaultName `
      -Name "DiskEncryptionKey" `
      -OutputFile $keyBackupPath

  Write-Host "Key backed up to: $keyBackupPath"

  # Backup a secret
  $secretBackupPath = "C:\Backup\secret-backup.blob"
  Backup-AzKeyVaultSecret `
      -VaultName $keyVaultName `
      -Name "DiskEncryptionSecret" `
      -OutputFile $secretBackupPath

  Write-Host "Secret backed up to: $secretBackupPath"
'@ -ForegroundColor Gray
    Write-Host ""

    # Step 7: Restore encryption keys
    Write-Host "[Step 7] Restoring encryption keys" -ForegroundColor Yellow
    Write-Host @'
  # Restore a key from backup
  Restore-AzKeyVaultKey `
      -VaultName $keyVaultName `
      -InputFile $keyBackupPath

  # Restore a secret from backup
  Restore-AzKeyVaultSecret `
      -VaultName $keyVaultName `
      -InputFile $secretBackupPath

  Write-Host "Keys and secrets restored successfully"
'@ -ForegroundColor Gray
    Write-Host ""

    # Step 8: Set access policies
    Write-Host "[Step 8] Configuring Key Vault access policies" -ForegroundColor Yellow
    Write-Host @'
  # Grant user access to keys and secrets
  $userObjectId = (Get-AzADUser -UserPrincipalName "admin@contoso.com").Id

  Set-AzKeyVaultAccessPolicy `
      -VaultName $keyVaultName `
      -ObjectId $userObjectId `
      -PermissionsToKeys get,list,backup,restore `
      -PermissionsToSecrets get,list,backup,restore

  # Grant application access
  $appId = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  Set-AzKeyVaultAccessPolicy `
      -VaultName $keyVaultName `
      -ServicePrincipalName $appId `
      -PermissionsToKeys wrapKey,unwrapKey `
      -PermissionsToSecrets get
'@ -ForegroundColor Gray
    Write-Host ""

    # Step 9: Enable Key Vault protection features
    Write-Host "[Step 9] Enabling Key Vault protection features" -ForegroundColor Yellow
    Write-Host @'
  # Enable soft delete
  Update-AzKeyVault `
      -ResourceGroupName $resourceGroupName `
      -VaultName $keyVaultName `
      -EnableSoftDelete

  # Enable purge protection
  Update-AzKeyVault `
      -ResourceGroupName $resourceGroupName `
      -VaultName $keyVaultName `
      -EnablePurgeProtection

  Write-Host "Soft delete and purge protection enabled"
'@ -ForegroundColor Gray
    Write-Host ""

    # Step 10: Best practices
    Write-Host "[Step 10] Key management best practices" -ForegroundColor Yellow
    Write-Host "  1. Backup keys regularly to secure storage" -ForegroundColor White
    Write-Host "  2. Enable soft delete for accidental deletion protection" -ForegroundColor White
    Write-Host "  3. Enable purge protection for critical keys" -ForegroundColor White
    Write-Host "  4. Use RBAC for fine-grained access control" -ForegroundColor White
    Write-Host "  5. Implement key rotation policies" -ForegroundColor White
    Write-Host "  6. Monitor Key Vault with Azure Monitor" -ForegroundColor White
    Write-Host "  7. Use separate Key Vaults for prod/non-prod" -ForegroundColor White
    Write-Host "  8. Enable diagnostic logging" -ForegroundColor White
    Write-Host "  9. Restrict network access with firewalls" -ForegroundColor White
    Write-Host "  10. Document key lifecycle procedures" -ForegroundColor White
    Write-Host ""

    Write-Host "Useful commands:" -ForegroundColor Cyan
    Write-Host '  Get-AzKeyVault -ResourceGroupName "rg" -VaultName "kv"' -ForegroundColor Gray
    Write-Host '  Get-AzKeyVaultKey -VaultName "kv" | Format-Table' -ForegroundColor Gray
    Write-Host '  Get-AzKeyVaultSecret -VaultName "kv" | Format-Table' -ForegroundColor Gray
    Write-Host ""

} catch {
    Write-Host "[ERROR] $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

Write-Host "Demo completed successfully!" -ForegroundColor Green
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Create secure backup process for encryption keys" -ForegroundColor White
Write-Host "  2. Enable soft delete and purge protection" -ForegroundColor White
Write-Host "  3. Configure appropriate access policies" -ForegroundColor White
Write-Host "  4. Implement key rotation procedures" -ForegroundColor White
Write-Host "  5. Enable monitoring and alerting" -ForegroundColor White
