<#
.SYNOPSIS
    Task 7.3 - Recover Encrypted Volumes
.DESCRIPTION
    Comprehensive demonstration of BitLocker encrypted volume recovery procedures.
    Covers recovery key usage, password unlock, and AD DS recovery.
.EXAMPLE
    .\task-7.3-encrypted-volume-recovery.ps1
.NOTES
    Module: Module 7 - Secure Storage with Encryption
    Task: 7.3 - Recover Encrypted Volumes
    Prerequisites:
    - Windows Server with BitLocker-encrypted volumes
    - Administrative privileges
    - Recovery keys or passwords
    PowerShell Version: 5.1+
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

Write-Host "=== AZ-801 Module 7: Task 7.3 - Recover Encrypted Volumes ===" -ForegroundColor Cyan
Write-Host ""

try {
    # Step 1: Recovery Overview
    Write-Host "[Step 1] BitLocker Recovery Overview" -ForegroundColor Yellow
    Write-Host "Recovery scenarios:" -ForegroundColor Cyan
    Write-Host "  - Lost password or PIN" -ForegroundColor White
    Write-Host "  - Hardware changes (motherboard, TPM)" -ForegroundColor White
    Write-Host "  - Corrupted boot files" -ForegroundColor White
    Write-Host "  - BIOS/UEFI changes" -ForegroundColor White
    Write-Host ""

    # Step 2: Check volume status
    Write-Host "[Step 2] Checking BitLocker volume status" -ForegroundColor Yellow
    $volumes = Get-BitLockerVolume
    foreach ($vol in $volumes) {
        Write-Host "Volume: $($vol.MountPoint)" -ForegroundColor White
        Write-Host "  Lock Status: $($vol.LockStatus)" -ForegroundColor $(if ($vol.LockStatus -eq 'Unlocked') {'Green'} else {'Yellow'})
        Write-Host "  Protection Status: $($vol.ProtectionStatus)" -ForegroundColor White
        Write-Host "  Key Protectors: $($vol.KeyProtector.Count)" -ForegroundColor White
        Write-Host ""
    }

    # Step 3: Unlock with recovery password
    Write-Host "[Step 3] Unlocking volume with recovery password" -ForegroundColor Yellow
    Write-Host @'
  # Unlock using 48-digit recovery password
  $recoveryPassword = "123456-789012-345678-901234-567890-123456-789012-345678"
  Unlock-BitLocker -MountPoint "D:" -RecoveryPassword $recoveryPassword

  # Verify unlock status
  $status = Get-BitLockerVolume -MountPoint "D:"
  Write-Host "Lock Status: $($status.LockStatus)"
'@ -ForegroundColor Gray
    Write-Host ""

    # Step 4: Retrieve recovery key from AD
    Write-Host "[Step 4] Retrieving recovery key from Active Directory" -ForegroundColor Yellow
    Write-Host @'
  # Search AD for BitLocker recovery information
  # Requires Active Directory module and appropriate permissions

  Import-Module ActiveDirectory

  $computerName = $env:COMPUTERNAME
  $computer = Get-ADComputer -Identity $computerName -Properties *

  # Get BitLocker recovery information
  $recoveryInfo = Get-ADObject `
      -Filter {objectClass -eq 'msFVE-RecoveryInformation'} `
      -SearchBase $computer.DistinguishedName `
      -Properties msFVE-RecoveryPassword

  foreach ($info in $recoveryInfo) {
      Write-Host "Recovery Password: $($info.'msFVE-RecoveryPassword')"
      Write-Host "Created: $($info.Created)"
  }
'@ -ForegroundColor Gray
    Write-Host ""

    # Step 5: Use manage-bde for recovery
    Write-Host "[Step 5] Using manage-bde for recovery" -ForegroundColor Yellow
    Write-Host "Unlock with recovery password:" -ForegroundColor Cyan
    Write-Host '  manage-bde -unlock D: -RecoveryPassword "123456-..." ' -ForegroundColor Gray
    Write-Host ""
    Write-Host "Unlock with recovery key file:" -ForegroundColor Cyan
    Write-Host '  manage-bde -unlock D: -RecoveryKey "E:\RecoveryKey.bek"' -ForegroundColor Gray
    Write-Host ""

    # Step 6: Suspend BitLocker for troubleshooting
    Write-Host "[Step 6] Suspending BitLocker for troubleshooting" -ForegroundColor Yellow
    Write-Host @'
  # Suspend BitLocker temporarily
  Suspend-BitLocker -MountPoint "C:" -RebootCount 2

  # BitLocker will automatically resume after 2 reboots
  # Use for BIOS updates or hardware changes
'@ -ForegroundColor Gray
    Write-Host ""

    # Step 7: Resume BitLocker protection
    Write-Host "[Step 7] Resuming BitLocker protection" -ForegroundColor Yellow
    Write-Host @'
  # Resume BitLocker immediately
  Resume-BitLocker -MountPoint "C:"

  # Verify protection status
  $vol = Get-BitLockerVolume -MountPoint "C:"
  Write-Host "Protection Status: $($vol.ProtectionStatus)"
'@ -ForegroundColor Gray
    Write-Host ""

    # Step 8: Recover from corrupted volume
    Write-Host "[Step 8] Recovering from corrupted BitLocker volume" -ForegroundColor Yellow
    Write-Host "Use BitLocker repair tool:" -ForegroundColor Cyan
    Write-Host @'
  # Repair BitLocker metadata
  repair-bde C: D: -RecoveryPassword "123456-..."

  # C: = Source (damaged) volume
  # D: = Destination (recovery) volume
  # Requires recovery password or key
'@ -ForegroundColor Gray
    Write-Host ""

    # Step 9: Export recovery information
    Write-Host "[Step 9] Exporting recovery information" -ForegroundColor Yellow
    Write-Host @'
  # Get all key protectors
  $vol = Get-BitLockerVolume -MountPoint "C:"

  foreach ($protector in $vol.KeyProtector) {
      Write-Host "Key Protector ID: $($protector.KeyProtectorId)"
      Write-Host "Type: $($protector.KeyProtectorType)"

      if ($protector.KeyProtectorType -eq 'RecoveryPassword') {
          Write-Host "Recovery Password: $($protector.RecoveryPassword)"
      }
  }

  # Export to file
  $vol.KeyProtector | Export-Csv -Path "C:\BitLockerKeys.csv" -NoTypeInformation
'@ -ForegroundColor Gray
    Write-Host ""

    # Step 10: Best practices
    Write-Host "[Step 10] Recovery best practices" -ForegroundColor Yellow
    Write-Host "  1. Store recovery passwords in multiple secure locations" -ForegroundColor White
    Write-Host "  2. Backup recovery keys to Active Directory" -ForegroundColor White
    Write-Host "  3. Print recovery passwords and store securely" -ForegroundColor White
    Write-Host "  4. Document recovery procedures" -ForegroundColor White
    Write-Host "  5. Test recovery process regularly" -ForegroundColor White
    Write-Host "  6. Use suspend (not disable) for temporary access" -ForegroundColor White
    Write-Host "  7. Keep recovery keys separate from encrypted devices" -ForegroundColor White
    Write-Host "  8. Train IT staff on recovery procedures" -ForegroundColor White
    Write-Host "  9. Use repair-bde for severely corrupted volumes" -ForegroundColor White
    Write-Host "  10. Maintain current backups of critical data" -ForegroundColor White
    Write-Host ""

} catch {
    Write-Host "[ERROR] $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

Write-Host "Demo completed successfully!" -ForegroundColor Green
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Verify recovery keys are backed up to AD" -ForegroundColor White
Write-Host "  2. Store recovery passwords in secure location" -ForegroundColor White
Write-Host "  3. Document recovery procedures" -ForegroundColor White
Write-Host "  4. Test recovery process in lab environment" -ForegroundColor White
Write-Host "  5. Train helpdesk staff on recovery procedures" -ForegroundColor White
