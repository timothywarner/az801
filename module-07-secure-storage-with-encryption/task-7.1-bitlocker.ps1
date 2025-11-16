<#
.SYNOPSIS
    Task 7.1 - Configure BitLocker Drive Encryption
.DESCRIPTION
    Comprehensive demonstration of BitLocker drive encryption deployment and management.
    Covers TPM, recovery keys, protectors, and Active Directory backup.
.EXAMPLE
    .\task-7.1-bitlocker.ps1
.NOTES
    Module: Module 7 - Secure Storage with Encryption
    Task: 7.1 - Configure BitLocker
    Prerequisites:
    - Windows Server with TPM 2.0 (or compatible mode)
    - Administrative privileges
    - BitLocker feature installed
    PowerShell Version: 5.1+
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

Write-Host "=== AZ-801 Module 7: Task 7.1 - Configure BitLocker ===" -ForegroundColor Cyan
Write-Host ""

try {
    # Step 1: BitLocker Overview
    Write-Host "[Step 1] BitLocker Overview" -ForegroundColor Yellow

    Write-Host "BitLocker features:" -ForegroundColor Cyan
    Write-Host "  - Full disk encryption for data protection" -ForegroundColor White
    Write-Host "  - TPM integration for hardware-based security" -ForegroundColor White
    Write-Host "  - Multiple protector types (TPM, PIN, Password, Key)" -ForegroundColor White
    Write-Host "  - Recovery key backup to Active Directory" -ForegroundColor White
    Write-Host "  - Encryption algorithm: AES 128-bit or 256-bit" -ForegroundColor White
    Write-Host ""

    # Step 2: Check BitLocker capability
    Write-Host "[Step 2] Checking BitLocker capability" -ForegroundColor Yellow

    Write-Host "Checking TPM status..." -ForegroundColor Cyan
    try {
        $tpm = Get-Tpm
        Write-Host "TPM Present: $($tpm.TpmPresent)" -ForegroundColor White
        Write-Host "TPM Ready: $($tpm.TpmReady)" -ForegroundColor White
        Write-Host "TPM Enabled: $($tpm.TpmEnabled)" -ForegroundColor White
        Write-Host "TPM Activated: $($tpm.TpmActivated)" -ForegroundColor White
    } catch {
        Write-Host "TPM not available or not configured" -ForegroundColor Yellow
    }
    Write-Host ""

    # Step 3: Check BitLocker status
    Write-Host "[Step 3] Checking BitLocker volume status" -ForegroundColor Yellow

    $volumes = Get-BitLockerVolume
    foreach ($vol in $volumes) {
        Write-Host "Volume: $($vol.MountPoint)" -ForegroundColor White
        Write-Host "  Protection Status: $($vol.ProtectionStatus)" -ForegroundColor $(if ($vol.ProtectionStatus -eq 'On') {'Green'} else {'Yellow'})
        Write-Host "  Encryption Percentage: $($vol.EncryptionPercentage)%" -ForegroundColor White
        Write-Host "  Volume Status: $($vol.VolumeStatus)" -ForegroundColor White
        Write-Host "  Key Protectors: $($vol.KeyProtector.Count)" -ForegroundColor White
        Write-Host ""
    }

    # Step 4: Enable BitLocker with recovery password
    Write-Host "[Step 4] Enabling BitLocker with recovery password" -ForegroundColor Yellow

    Write-Host "Example: Enable BitLocker on C: drive" -ForegroundColor Cyan
    Write-Host @'
  # Enable BitLocker with recovery password protector
  Enable-BitLocker `
      -MountPoint "C:" `
      -RecoveryPasswordProtector `
      -EncryptionMethod Aes256 `
      -UsedSpaceOnly `
      -SkipHardwareTest

  # Note: Use -UsedSpaceOnly for faster encryption on new drives
  # Use -SkipHardwareTest to skip reboot (testing only)
'@ -ForegroundColor Gray
    Write-Host ""

    # Step 5: Add key protectors
    Write-Host "[Step 5] Adding BitLocker key protectors" -ForegroundColor Yellow

    Write-Host "Add TPM protector:" -ForegroundColor Cyan
    Write-Host '  Add-BitLockerKeyProtector -MountPoint "C:" -TpmProtector' -ForegroundColor Gray
    Write-Host ""

    Write-Host "Add Password protector:" -ForegroundColor Cyan
    Write-Host @'
  $password = ConvertTo-SecureString "P@ssw0rd123!" -AsPlainText -Force
  Add-BitLockerKeyProtector -MountPoint "C:" -PasswordProtector -Password $password
'@ -ForegroundColor Gray
    Write-Host ""

    Write-Host "Add Recovery Key protector (saves key file):" -ForegroundColor Cyan
    Write-Host '  Add-BitLockerKeyProtector -MountPoint "C:" -RecoveryKeyProtector -RecoveryKeyPath "E:\"' -ForegroundColor Gray
    Write-Host ""

    # Step 6: Backup recovery information
    Write-Host "[Step 6] Backing up recovery information" -ForegroundColor Yellow

    Write-Host "Backup recovery password to Active Directory:" -ForegroundColor Cyan
    Write-Host @'
  # Get recovery password key protector
  $vol = Get-BitLockerVolume -MountPoint "C:"
  $keyProtector = $vol.KeyProtector | Where-Object {$_.KeyProtectorType -eq 'RecoveryPassword'}

  # Backup to AD DS
  Backup-BitLockerKeyProtector `
      -MountPoint "C:" `
      -KeyProtectorId $keyProtector[0].KeyProtectorId

  # Note: Requires AD schema update for BitLocker recovery information
'@ -ForegroundColor Gray
    Write-Host ""

    # Step 7: Manage BitLocker
    Write-Host "[Step 7] Managing BitLocker encryption" -ForegroundColor Yellow

    Write-Host "Suspend BitLocker (for updates/BIOS changes):" -ForegroundColor Cyan
    Write-Host '  Suspend-BitLocker -MountPoint "C:" -RebootCount 2' -ForegroundColor Gray
    Write-Host ""

    Write-Host "Resume BitLocker:" -ForegroundColor Cyan
    Write-Host '  Resume-BitLocker -MountPoint "C:"' -ForegroundColor Gray
    Write-Host ""

    Write-Host "Disable BitLocker (decrypt drive):" -ForegroundColor Cyan
    Write-Host '  Disable-BitLocker -MountPoint "C:"' -ForegroundColor Gray
    Write-Host ""

    # Step 8: Monitor encryption progress
    Write-Host "[Step 8] Monitoring encryption progress" -ForegroundColor Yellow

    Write-Host "Check encryption status:" -ForegroundColor Cyan
    Write-Host @'
  $vol = Get-BitLockerVolume -MountPoint "C:"
  Write-Host "Encryption Progress: $($vol.EncryptionPercentage)%"
  Write-Host "Volume Status: $($vol.VolumeStatus)"

  # Monitor real-time
  while ((Get-BitLockerVolume -MountPoint "C:").EncryptionPercentage -lt 100) {
      $progress = (Get-BitLockerVolume -MountPoint "C:").EncryptionPercentage
      Write-Host "Encryption progress: $progress%"
      Start-Sleep -Seconds 10
  }
'@ -ForegroundColor Gray
    Write-Host ""

    # Step 9: Using manage-bde command
    Write-Host "[Step 9] Using manage-bde.exe (alternative method)" -ForegroundColor Yellow

    Write-Host "Common manage-bde commands:" -ForegroundColor Cyan
    Write-Host '  manage-bde -status C:             # Check BitLocker status' -ForegroundColor Gray
    Write-Host '  manage-bde -on C: -rp             # Enable with recovery password' -ForegroundColor Gray
    Write-Host '  manage-bde -protectors -add C: -tp  # Add TPM protector' -ForegroundColor Gray
    Write-Host '  manage-bde -protectors -get C:    # List protectors' -ForegroundColor Gray
    Write-Host '  manage-bde -pause C:              # Suspend BitLocker' -ForegroundColor Gray
    Write-Host '  manage-bde -resume C:             # Resume BitLocker' -ForegroundColor Gray
    Write-Host ""

    # Step 10: Best practices
    Write-Host "[Step 10] BitLocker best practices" -ForegroundColor Yellow

    Write-Host "Best practices:" -ForegroundColor Cyan
    Write-Host "  1. Always create recovery password protector" -ForegroundColor White
    Write-Host "  2. Backup recovery information to Active Directory" -ForegroundColor White
    Write-Host "  3. Store recovery keys in secure location" -ForegroundColor White
    Write-Host "  4. Use AES-256 encryption for maximum security" -ForegroundColor White
    Write-Host "  5. Use TPM + PIN for enhanced security" -ForegroundColor White
    Write-Host "  6. Suspend BitLocker before BIOS/firmware updates" -ForegroundColor White
    Write-Host "  7. Use -UsedSpaceOnly for faster initial encryption" -ForegroundColor White
    Write-Host "  8. Document recovery procedures" -ForegroundColor White
    Write-Host "  9. Test recovery process regularly" -ForegroundColor White
    Write-Host "  10. Use Group Policy for enterprise deployment" -ForegroundColor White
    Write-Host ""

    Write-Host "Useful commands:" -ForegroundColor Cyan
    Write-Host '  Get-BitLockerVolume | Format-List *' -ForegroundColor Gray
    Write-Host '  Get-BitLockerVolume -MountPoint "C:" | Select-Object *' -ForegroundColor Gray
    Write-Host '  (Get-BitLockerVolume -MountPoint "C:").KeyProtector' -ForegroundColor Gray
    Write-Host ""

} catch {
    Write-Host "[ERROR] $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

Write-Host "Demo completed successfully!" -ForegroundColor Green
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Enable BitLocker on all data volumes" -ForegroundColor White
Write-Host "  2. Configure appropriate key protectors (TPM + PIN recommended)" -ForegroundColor White
Write-Host "  3. Backup recovery passwords to Active Directory" -ForegroundColor White
Write-Host "  4. Document recovery procedures" -ForegroundColor White
Write-Host "  5. Deploy via Group Policy for consistency" -ForegroundColor White
