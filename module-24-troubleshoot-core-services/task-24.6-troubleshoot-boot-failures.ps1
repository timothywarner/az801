<#
.SYNOPSIS
    AZ-801 Module 24 Task 6 - Troubleshoot Boot Failures

.DESCRIPTION
    This script demonstrates Windows Server boot troubleshooting and recovery techniques.
    It covers BCD configuration, bootrec commands, startup repair, safe mode options,
    and boot log analysis for diagnosing and resolving boot failures.

.NOTES
    Module: 24 - Troubleshoot Core Services
    Task: 24.6 - Troubleshoot Boot Failures
    Exam: AZ-801 - Configuring Windows Server Hybrid Advanced Services

.LINK
    https://learn.microsoft.com/en-us/windows-hardware/drivers/devtest/boot-options-in-windows
#>

#Requires -RunAsAdministrator

#region Boot Configuration Data (BCD)

Write-Host "`n=== BOOT CONFIGURATION DATA (BCD) ANALYSIS ===" -ForegroundColor Cyan
Write-Host "Analyzing current boot configuration" -ForegroundColor Yellow

Write-Host "`nRunning: bcdedit /enum" -ForegroundColor Green
$bcdOutput = bcdedit /enum 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host $bcdOutput -ForegroundColor White

    # Parse key information
    Write-Host "`nKey Boot Configuration:" -ForegroundColor Green
    $bcdLines = $bcdOutput -split "`n"

    $identifier = $bcdLines | Where-Object {$_ -match "identifier"}
    $device = $bcdLines | Where-Object {$_ -match "device"}
    $osDevice = $bcdLines | Where-Object {$_ -match "osdevice"}
    $path = $bcdLines | Where-Object {$_ -match "path"}

    if ($identifier) { Write-Host "  $($identifier[0])" -ForegroundColor White }
    if ($device) { Write-Host "  $($device[0])" -ForegroundColor White }
    if ($osDevice) { Write-Host "  $($osDevice[0])" -ForegroundColor White }
    if ($path) { Write-Host "  $($path[0])" -ForegroundColor White }
} else {
    Write-Host "  Error reading BCD: $bcdOutput" -ForegroundColor Red
}

# Get boot order
Write-Host "`nBoot Manager Display Order:" -ForegroundColor Green
$bootmgr = bcdedit /enum "{bootmgr}" 2>&1
$displayOrder = $bootmgr | Where-Object {$_ -match "displayorder"}
if ($displayOrder) {
    Write-Host "  $displayOrder" -ForegroundColor White
}

#endregion

#region BCD Management Commands

Write-Host "`n`n=== BCD MANAGEMENT COMMANDS ===" -ForegroundColor Cyan
Write-Host "Common bcdedit commands for boot configuration" -ForegroundColor Yellow

$bcdCommands = @"

BCDEdit Commands Reference:

VIEW CONFIGURATION:
- bcdedit /enum                      (display all boot entries)
- bcdedit /enum {current}            (display current OS entry)
- bcdedit /enum {bootmgr}            (display boot manager settings)
- bcdedit /enum /v                   (verbose display with GUIDs)

MODIFY BOOT OPTIONS:
- bcdedit /set {current} description "Windows Server 2022"
- bcdedit /set {current} bootmenupolicy Legacy (legacy F8 menu)
- bcdedit /set {current} bootmenupolicy Standard (Windows 8+ menu)
- bcdedit /set {current} safeboot minimal (enable safe mode)
- bcdedit /deletevalue {current} safeboot (disable safe mode)
- bcdedit /set {current} bootlog Yes (enable boot logging)

TIMEOUT SETTINGS:
- bcdedit /timeout 30                (set boot menu timeout to 30 seconds)
- bcdedit /set {bootmgr} timeout 10  (alternative syntax)

DEFAULT OS:
- bcdedit /default {GUID}            (set default OS entry)
- bcdedit /displayorder {GUID} /addlast (add entry to display order)

BACKUP AND RESTORE:
- bcdedit /export C:\BCD_Backup      (export BCD)
- bcdedit /import C:\BCD_Backup      (import BCD)

CREATE NEW ENTRY:
- bcdedit /create /d "Windows Server" /application osloader
- bcdedit /copy {current} /d "Windows Server Clone"

DELETE ENTRY:
- bcdedit /delete {GUID}             (delete specific entry)

ADVANCED OPTIONS:
- bcdedit /set {current} nx OptIn    (DEP settings)
- bcdedit /set {current} pae ForceEnable (PAE settings)
- bcdedit /set {current} detecthal Yes (HAL detection)
- bcdedit /set {current} ems Yes (Emergency Management Services)

"@

Write-Host $bcdCommands -ForegroundColor White

#endregion

#region Boot Recovery Commands

Write-Host "`n=== BOOT RECOVERY COMMANDS ===" -ForegroundColor Cyan
Write-Host "bootrec commands for boot repair" -ForegroundColor Yellow

$bootrecCommands = @"

BOOTREC Commands (Run from Windows RE or Installation Media):

1. SCAN FOR WINDOWS INSTALLATIONS:
   bootrec /scanos
   - Scans all disks for Windows installations
   - Displays installations not in BCD store

2. FIX MASTER BOOT RECORD (MBR):
   bootrec /fixmbr
   - Writes new MBR to system partition
   - Fixes: Missing or corrupt MBR
   - Safe: Does not overwrite existing partition table

3. FIX BOOT SECTOR:
   bootrec /fixboot
   - Writes new boot sector to system partition
   - Fixes: Corrupt or missing boot sector
   - Use: When boot files are damaged

4. REBUILD BCD STORE:
   bootrec /rebuildbcd
   - Scans for Windows installations
   - Adds missing entries to BCD
   - Prompts to add each installation
   - Use: When BCD is corrupt or missing entries

5. REBUILD BCD COMPLETELY:
   bootrec /rebuildbcd
   If above fails:
   - attrib -h -s C:\boot\bcd
   - ren C:\boot\bcd bcd.old
   - bootrec /rebuildbcd

COMPLETE BOOT REPAIR SEQUENCE (Windows RE):
1. bootrec /fixmbr
2. bootrec /fixboot
3. bootrec /scanos
4. bootrec /rebuildbcd

MBR vs GPT SYSTEMS:
- MBR Systems: Use bootrec /fixmbr and /fixboot
- GPT/UEFI Systems: May need bcdboot instead:
  bcdboot C:\Windows /s S: /f UEFI

"@

Write-Host $bootrecCommands -ForegroundColor White

#endregion

#region Safe Mode and Advanced Boot Options

Write-Host "`n=== SAFE MODE AND ADVANCED BOOT OPTIONS ===" -ForegroundColor Cyan
Write-Host "Configuring advanced boot options" -ForegroundColor Yellow

# Check current safe mode status
Write-Host "`nCurrent Safe Mode Status:" -ForegroundColor Green
$safeBootOption = bcdedit /enum {current} 2>&1 | Where-Object {$_ -match "safeboot"}

if ($safeBootOption) {
    Write-Host "  Safe Mode: ENABLED" -ForegroundColor Yellow
    Write-Host "  $safeBootOption" -ForegroundColor White
    Write-Host "  To disable: bcdedit /deletevalue {current} safeboot" -ForegroundColor Gray
    Write-Host "             msconfig -> Boot -> uncheck Safe boot" -ForegroundColor Gray
} else {
    Write-Host "  Safe Mode: DISABLED (Normal boot)" -ForegroundColor Green
}

$advancedBootOptions = @"

Safe Mode and Advanced Boot Options:

ENABLE SAFE MODE:
- Safe Mode Minimal:
  bcdedit /set {current} safeboot minimal

- Safe Mode with Networking:
  bcdedit /set {current} safeboot network

- Safe Mode with Command Prompt:
  bcdedit /set {current} safeboot minimal
  bcdedit /set {current} safebootalternateshell yes

DISABLE SAFE MODE:
  bcdedit /deletevalue {current} safeboot
  bcdedit /deletevalue {current} safebootalternateshell

ACCESS ADVANCED BOOT OPTIONS:
Method 1 - F8 Key (Windows Server 2012 and later):
  bcdedit /set {current} bootmenupolicy Legacy
  (Reboot and press F8)

Method 2 - Shift+Restart:
  - Click Start -> Power -> Hold Shift + click Restart
  - Select: Troubleshoot -> Advanced Options

Method 3 - Force Boot Menu:
  bcdedit /set {bootmgr} displaybootmenu yes

Method 4 - Command Line:
  shutdown /r /o /f /t 0
  (Restart to advanced boot options)

BOOT LOGGING:
Enable:
  bcdedit /set {current} bootlog yes

Log Location:
  C:\Windows\ntbtlog.txt

View Boot Log:
  Get-Content C:\Windows\ntbtlog.txt

Disable:
  bcdedit /deletevalue {current} bootlog

DISABLE DRIVER SIGNATURE ENFORCEMENT:
  bcdedit /set {current} nointegritychecks on
  (Use only for troubleshooting!)

DISABLE EARLY LAUNCH ANTI-MALWARE:
  bcdedit /set {current} disableelamdrivers yes

"@

Write-Host $advancedBootOptions -ForegroundColor White

#endregion

#region Boot Log Analysis

Write-Host "`n=== BOOT LOG ANALYSIS ===" -ForegroundColor Cyan
Write-Host "Analyzing boot logs for failures" -ForegroundColor Yellow

# Check for boot log
$bootLog = "$env:SystemRoot\ntbtlog.txt"
if (Test-Path $bootLog) {
    $bootLogFile = Get-Item $bootLog
    Write-Host "`nBoot Log Found:" -ForegroundColor Green
    Write-Host "  Location: $bootLog" -ForegroundColor White
    Write-Host "  Size: $([math]::Round($bootLogFile.Length/1KB, 2)) KB" -ForegroundColor White
    Write-Host "  Last Modified: $($bootLogFile.LastWriteTime)" -ForegroundColor White

    # Read last entries
    $bootLogContent = Get-Content $bootLog -Tail 30
    Write-Host "`n  Last 30 Boot Log Entries:" -ForegroundColor White
    $bootLogContent | Select-Object -Last 10 | ForEach-Object {
        if ($_ -match "Did not load driver") {
            Write-Host "    $_" -ForegroundColor Red
        } elseif ($_ -match "Loaded driver") {
            Write-Host "    $_" -ForegroundColor Green
        } else {
            Write-Host "    $_" -ForegroundColor Gray
        }
    }

    # Count failed drivers
    $failedDrivers = $bootLogContent | Where-Object {$_ -match "Did not load driver"}
    if ($failedDrivers) {
        Write-Host "`n  Failed Drivers: $($failedDrivers.Count)" -ForegroundColor Yellow
    }
} else {
    Write-Host "`nBoot Log Not Found" -ForegroundColor Yellow
    Write-Host "  Enable boot logging with: bcdedit /set {current} bootlog yes" -ForegroundColor Gray
}

# Check System event log for boot events
Write-Host "`nRecent Boot-Related Events:" -ForegroundColor Green
try {
    $bootEvents = Get-WinEvent -FilterHashtable @{
        LogName = 'System'
        ID = 6005, 6006, 6008, 6009, 1074, 41
    } -MaxEvents 10 -ErrorAction Stop

    $bootEvents | ForEach-Object {
        $eventColor = switch ($_.Id) {
            6005 { "Green" }   # Event Log service started (boot)
            6006 { "Yellow" }  # Event Log service stopped (shutdown)
            6008 { "Red" }     # Unexpected shutdown
            6009 { "Green" }   # OS version at boot
            1074 { "Yellow" }  # System restart/shutdown
            41 { "Red" }       # System rebooted without cleanly shutting down
            default { "White" }
        }

        $eventDescription = switch ($_.Id) {
            6005 { "System Boot" }
            6006 { "Clean Shutdown" }
            6008 { "Unexpected Shutdown/Crash" }
            6009 { "OS Version Info" }
            1074 { "Planned Restart/Shutdown" }
            41 { "Kernel Power - Unexpected Reboot" }
            default { "Event $($_.Id)" }
        }

        Write-Host "`n  Time: $($_.TimeCreated)" -ForegroundColor Gray
        Write-Host "  Event: $eventDescription (ID $($_.Id))" -ForegroundColor $eventColor
        Write-Host "  Message: $($_.Message.Substring(0, [Math]::Min(100, $_.Message.Length)))..." -ForegroundColor White
    }
} catch {
    Write-Host "  Could not retrieve boot events: $($_.Exception.Message)" -ForegroundColor Yellow
}

#endregion

#region Startup Repair and Recovery

Write-Host "`n`n=== STARTUP REPAIR AND RECOVERY ===" -ForegroundColor Cyan
Write-Host "Windows Recovery Environment (WinRE) procedures" -ForegroundColor Yellow

$recoveryProcedures = @"

Windows Recovery Environment (WinRE) Access:

METHOD 1 - Boot from Installation Media:
1. Boot from Windows Server installation USB/DVD
2. Select language and keyboard
3. Click "Repair your computer"
4. Select "Troubleshoot" -> "Advanced options"

METHOD 2 - F8 Boot Menu (if enabled):
1. bcdedit /set {current} bootmenupolicy Legacy
2. Restart and press F8
3. Select "Repair Your Computer"

METHOD 3 - Force WinRE (3 failed boots):
1. Power on system
2. Force power off during Windows logo (hold power button)
3. Repeat 2-3 times
4. Windows will automatically boot to WinRE

STARTUP REPAIR AUTOMATIC:
- In WinRE: Troubleshoot -> Advanced Options -> Startup Repair
- Automatically fixes: MBR, boot sector, BCD, boot files
- Log: C:\Windows\System32\LogFiles\Srt\SrtTrail.txt

COMMAND PROMPT MANUAL REPAIR:
From WinRE Command Prompt:

1. Identify Windows partition:
   diskpart
   list volume
   (Note drive letter of Windows installation)
   exit

2. Repair boot files:
   bcdboot C:\Windows /s S:
   (C: = Windows, S: = System/EFI partition)

3. Fix bootloader (MBR):
   bootrec /fixmbr
   bootrec /fixboot

4. Rebuild BCD:
   bootrec /scanos
   bootrec /rebuildbcd

5. System File Check:
   sfc /scannow /offbootdir=C:\ /offwindir=C:\Windows

6. DISM Repair (if Windows RE has internet):
   DISM /Image:C:\ /Cleanup-Image /RestoreHealth

SAFE MODE FROM WINRE:
1. Troubleshoot -> Advanced Options -> Startup Settings
2. Click Restart
3. Press 4 for Safe Mode (or 5 for Safe Mode with Networking)

LAST KNOWN GOOD CONFIGURATION:
- Removed in Windows 8/Server 2012+
- Alternative: System Restore from WinRE

SYSTEM RESTORE:
- Troubleshoot -> Advanced Options -> System Restore
- Select restore point before issues began

"@

Write-Host $recoveryProcedures -ForegroundColor White

#endregion

#region Troubleshooting Guide

Write-Host "`n=== BOOT TROUBLESHOOTING GUIDE ===" -ForegroundColor Cyan

$bootTroubleshooting = @"

Common Boot Failures and Solutions:

1. "BOOTMGR IS MISSING"
   - Cause: Boot sector corruption, wrong boot order, failed disk
   - From WinRE: bootrec /fixmbr
                 bootrec /fixboot
                 bootrec /rebuildbcd
   - Check BIOS boot order

2. "WINLOAD.EXE IS MISSING OR CORRUPT"
   - Cause: Corrupt boot files
   - From WinRE: bcdboot C:\Windows /s S:
   - Or: bootrec /rebuildbcd

3. "BCD ERROR" or "BCD IS CORRUPT"
   - From WinRE: bootrec /rebuildbcd
   - If fails: ren C:\boot\bcd bcd.old
               bootrec /rebuildbcd

4. BLUE SCREEN ON BOOT (BSOD)
   - Boot to Safe Mode
   - Check: C:\Windows\Minidump\*.dmp files
   - Recent changes? Uninstall driver/update
   - Run: sfc /scannow

5. BOOT LOOP / CONTINUOUS RESTART
   - Disable automatic restart: bcdedit /set {current} bootstatuspolicy displayallfailures
   - Boot Safe Mode, check Event Viewer
   - System Restore to before issue

6. STUCK ON WINDOWS LOGO
   - Enable boot logging: bcdedit /set {current} bootlog yes
   - Check: C:\Windows\ntbtlog.txt for failed driver
   - Boot Safe Mode, disable problematic driver

7. NO BOOTABLE DEVICE
   - Check BIOS/UEFI boot order
   - Verify disk is detected in BIOS
   - Check disk connections (physical server)
   - Use bootrec /fixmbr and /fixboot

DIAGNOSTIC COMMANDS:
- bcdedit /enum (view boot configuration)
- bootrec /scanos (scan for Windows installations)
- chkdsk C: /f /r (check disk for errors)
- sfc /scannow (scan system files)
- Get-WinEvent -FilterHashtable @{LogName='System'; ID=41} (unexpected shutdowns)

PREVENTION:
- Regular backups (system state, full system image)
- Export BCD: bcdedit /export C:\BCD_Backup
- Document working configuration
- Test updates in non-production first
- Monitor disk health: Get-PhysicalDisk | Get-StorageReliabilityCounter

"@

Write-Host $bootTroubleshooting -ForegroundColor White

#endregion

Write-Host "`n=== BOOT TROUBLESHOOTING COMPLETE ===" -ForegroundColor Green
Write-Host "Review the diagnostic information above`n" -ForegroundColor Yellow
Write-Host "Note: Many boot repair commands require Windows Recovery Environment (WinRE)`n" -ForegroundColor Cyan
