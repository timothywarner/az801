<#
.SYNOPSIS
    AZ-801 Module 25 Task 3 - Troubleshoot Disk Encryption

.DESCRIPTION
    Demonstrates BitLocker and Azure Disk Encryption troubleshooting.
    Covers Get-BitLockerVolume, manage-bde, Azure Disk Encryption diagnostics,
    and recovery procedures.

.NOTES
    Module: 25 - Troubleshoot Advanced Issues
    Exam: AZ-801
#>

#Requires -RunAsAdministrator

Write-Host "`n=== DISK ENCRYPTION TROUBLESHOOTING ===" -ForegroundColor Cyan

#region BitLocker Status

Write-Host "`nBitLocker Volume Status:" -ForegroundColor Green
try {
    $bitlockerVolumes = Get-BitLockerVolume -ErrorAction Stop
    foreach ($vol in $bitlockerVolumes) {
        Write-Host "`nVolume: $($vol.MountPoint)" -ForegroundColor White
        Write-Host "  Protection Status: $($vol.ProtectionStatus)" -ForegroundColor $(
            if ($vol.ProtectionStatus -eq 'On') {'Green'} else {'Yellow'}
        )
        Write-Host "  Encryption: $($vol.VolumeStatus)" -ForegroundColor White
        Write-Host "  Encryption %: $($vol.EncryptionPercentage)%" -ForegroundColor White
        Write-Host "  Key Protectors: $($vol.KeyProtector.Count)" -ForegroundColor White
    }
} catch {
    Write-Host "  BitLocker not available or no encrypted volumes" -ForegroundColor Yellow
}

#endregion

#region BitLocker Commands

Write-Host "`n`n=== BITLOCKER TROUBLESHOOTING COMMANDS ===" -ForegroundColor Cyan

$bitlockerCommands = @"

BitLocker PowerShell Commands:

STATUS CHECK:
Get-BitLockerVolume
Get-BitLockerVolume -MountPoint "C:"

ENABLE BITLOCKER:
Enable-BitLocker -MountPoint "C:" -EncryptionMethod XtsAes256 -UsedSpaceOnly ``
    -RecoveryPasswordProtector

ADD KEY PROTECTOR:
Add-BitLockerKeyProtector -MountPoint "C:" -RecoveryPasswordProtector
Add-BitLockerKeyProtector -MountPoint "C:" -TpmProtector

BACKUP RECOVERY KEY TO AD:
Backup-BitLockerKeyProtector -MountPoint "C:" -KeyProtectorId "{ID}"

SUSPEND/RESUME:
Suspend-BitLocker -MountPoint "C:" -RebootCount 2
Resume-BitLocker -MountPoint "C:"

UNLOCK VOLUME:
Unlock-BitLocker -MountPoint "E:" -Password (Read-Host -AsSecureString)
Unlock-BitLocker -MountPoint "E:" -RecoveryPassword "123456-..."

MANAGE-BDE Commands:

STATUS:
manage-bde -status
manage-bde -status C:

LOCK/UNLOCK:
manage-bde -lock E:
manage-bde -unlock E: -RecoveryPassword 123456-...

PROTECTORS:
manage-bde -protectors -get C:
manage-bde -protectors -add C: -RecoveryPassword

TROUBLESHOOTING:
manage-bde -forcerecovery C:
manage-bde -wipefreespace C:

"@

Write-Host $bitlockerCommands -ForegroundColor White

#endregion

#region Azure Disk Encryption

Write-Host "`n=== AZURE DISK ENCRYPTION ===" -ForegroundColor Cyan

$adeCommands = @"

Azure Disk Encryption Troubleshooting:

CHECK ADE STATUS:
Get-AzVMDiskEncryptionStatus ``
    -ResourceGroupName "RG-Name" ``
    -VMName "VM-Name"

ENABLE ADE:
Set-AzVMDiskEncryptionExtension ``
    -ResourceGroupName "RG" ``
    -VMName "VM" ``
    -DiskEncryptionKeyVaultUrl `$keyVault.VaultUri ``
    -DiskEncryptionKeyVaultId `$keyVault.ResourceId ``
    -VolumeType "All"

CHECK EXTENSION STATUS:
Get-AzVMExtension -ResourceGroupName "RG" -VMName "VM" -Name "AzureDiskEncryption"

ADE EXTENSION LOGS:
C:\WindowsAzure\Logs\Plugins\Microsoft.Azure.Security.AzureDiskEncryption\
C:\WindowsAzure\Logs\Plugins\Microsoft.Azure.Security.AzureDiskEncryptionForLinux\

COMMON ADE ISSUES:

1. ENCRYPTION FAILED - INSUFFICIENT DISK SPACE
   - Need at least 7% free space on OS disk
   - Solution: Clean up disk space, extend volume

2. KEY VAULT ACCESS DENIED
   - VM identity doesn't have access to Key Vault
   - Solution: Grant VM managed identity access to Key Vault

3. ADE EXTENSION FAILED
   - Check extension logs
   - Verify VM Agent running
   - Ensure internet connectivity

4. CANNOT UNLOCK VOLUME
   - Verify Key Vault accessible
   - Check VM managed identity
   - Test: Get-AzKeyVaultSecret

RECOVERY:
# Get recovery key from Key Vault
Get-AzKeyVaultSecret -VaultName "KeyVaultName" -Name "VMName-DiskEncryptionKey"

# Disable ADE
Disable-AzVMDiskEncryption -ResourceGroupName "RG" -VMName "VM" -VolumeType "All"

"@

Write-Host $adeCommands -ForegroundColor White

#endregion

#region Recovery Procedures

Write-Host "`n=== BITLOCKER RECOVERY PROCEDURES ===" -ForegroundColor Cyan

$recoveryProcedures = @"

BitLocker Recovery Scenarios:

1. FORGOT RECOVERY PASSWORD
   - Recovery password should be backed up to:
     * Active Directory (if domain-joined)
     * Azure AD (if Azure AD-joined)
     * Microsoft Account (personal devices)
     * File/print backup

   Retrieve from AD:
   - Open AD Users and Computers
   - Find computer object
   - Properties -> BitLocker Recovery tab

   Retrieve from Azure AD:
   - Azure Portal -> Azure AD -> Devices
   - Find device -> Recovery keys

2. TPM DETECTED UNAUTHORIZED CHANGES
   - BitLocker enters recovery mode
   - Caused by: BIOS changes, boot order, secure boot disabled
   - Solution: Enter recovery key, fix issue, resume protection

3. ENCRYPTION IN PROGRESS - SYSTEM CRASH
   - BitLocker protects partially encrypted volume
   - Solution: Boot system, encryption will resume automatically
   - Check: Get-BitLockerVolume | Select EncryptionPercentage

4. NEED TO DECRYPT URGENTLY
   - Suspend: Suspend-BitLocker -MountPoint "C:" -RebootCount 0
   - Decrypt: Disable-BitLocker -MountPoint "C:"
   - Monitor: Get-BitLockerVolume shows DecryptionInProgress

5. LOST ALL RECOVERY KEYS
   - If no backup exists, data is UNRECOVERABLE
   - Prevention: Always backup recovery keys
   - Use: Backup-BitLockerKeyProtector

BEST PRACTICES:
- Always backup recovery keys before enabling BitLocker
- Test recovery process in non-production
- Document key backup locations
- Regular audits of encrypted volumes
- Use AD/Azure AD for enterprise key management

"@

Write-Host $recoveryProcedures -ForegroundColor White

#endregion

Write-Host "`n=== DISK ENCRYPTION TROUBLESHOOTING COMPLETE ===" -ForegroundColor Green
