<#
.SYNOPSIS
    AZ-801 Module 24 Task 5 - Troubleshoot Server Deployment

.DESCRIPTION
    This script demonstrates Windows Server deployment troubleshooting techniques.
    It covers DISM image operations, Windows Image (WIM) management, setup log analysis,
    Sysprep troubleshooting, and deployment error diagnostics.

.NOTES
    Module: 24 - Troubleshoot Core Services
    Task: 24.5 - Troubleshoot Server Deployment
    Exam: AZ-801 - Configuring Windows Server Hybrid Advanced Services

.LINK
    https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/
#>

#Requires -RunAsAdministrator

#region Current System Information

Write-Host "`n=== SYSTEM DEPLOYMENT INFORMATION ===" -ForegroundColor Cyan
Write-Host "Gathering current system configuration" -ForegroundColor Yellow

$os = Get-CimInstance Win32_OperatingSystem
$cs = Get-CimInstance Win32_ComputerSystem

Write-Host "`nOperating System:" -ForegroundColor Green
Write-Host "  Caption: $($os.Caption)" -ForegroundColor White
Write-Host "  Version: $($os.Version)" -ForegroundColor White
Write-Host "  Build Number: $($os.BuildNumber)" -ForegroundColor White
Write-Host "  Install Date: $($os.InstallDate)" -ForegroundColor White
Write-Host "  Last Boot: $($os.LastBootUpTime)" -ForegroundColor White

Write-Host "`nComputer System:" -ForegroundColor Green
Write-Host "  Name: $($cs.Name)" -ForegroundColor White
Write-Host "  Domain/Workgroup: $($cs.Domain)" -ForegroundColor White
Write-Host "  Model: $($cs.Model)" -ForegroundColor White
Write-Host "  Manufacturer: $($cs.Manufacturer)" -ForegroundColor White

# Check if system was sysprepped
$sysprepRegPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Setup\State"
if (Test-Path $sysprepRegPath) {
    $imageState = Get-ItemProperty -Path $sysprepRegPath -Name "ImageState" -ErrorAction SilentlyContinue
    if ($imageState) {
        Write-Host "`nSysprep Status:" -ForegroundColor Green
        Write-Host "  Image State: $($imageState.ImageState)" -ForegroundColor White
    }
}

#endregion

#region Windows Image Management

Write-Host "`n`n=== WINDOWS IMAGE OPERATIONS ===" -ForegroundColor Cyan
Write-Host "DISM commands for image management" -ForegroundColor Yellow

$dismCommands = @"

DISM Image Information Commands:

1. GET ONLINE IMAGE INFO:
   DISM /Online /Get-CurrentEdition
   DISM /Online /Get-TargetEdition (shows available upgrade editions)

   PowerShell:
   Get-WindowsEdition -Online
   Get-WindowsImage -Online

2. GET WIM/ESD FILE INFO:
   DISM /Get-ImageInfo /ImageFile:C:\Images\install.wim
   DISM /Get-ImageInfo /ImageFile:C:\Images\install.wim /Index:1

   PowerShell:
   Get-WindowsImage -ImagePath "C:\Images\install.wim"

3. MOUNT IMAGE FOR SERVICING:
   DISM /Mount-Image /ImageFile:C:\Images\install.wim /Index:1 /MountDir:C:\Mount

   PowerShell:
   Mount-WindowsImage -ImagePath "C:\Images\install.wim" -Index 1 -Path "C:\Mount"

4. GET MOUNTED IMAGE INFO:
   DISM /Get-MountedImageInfo

   PowerShell:
   Get-WindowsImage -Mounted

5. APPLY IMAGE TO DISK:
   DISM /Apply-Image /ImageFile:C:\Images\install.wim /Index:1 /ApplyDir:D:\

   PowerShell:
   Expand-WindowsImage -ImagePath "C:\Images\install.wim" -Index 1 -ApplyPath "D:\"

6. UNMOUNT IMAGE:
   DISM /Unmount-Image /MountDir:C:\Mount /Commit (save changes)
   DISM /Unmount-Image /MountDir:C:\Mount /Discard (discard changes)

   PowerShell:
   Dismount-WindowsImage -Path "C:\Mount" -Save
   Dismount-WindowsImage -Path "C:\Mount" -Discard

"@

Write-Host $dismCommands -ForegroundColor White

# Check for mounted images
Write-Host "`nChecking for currently mounted images:" -ForegroundColor Green
try {
    $mountedImages = Get-WindowsImage -Mounted -ErrorAction Stop
    if ($mountedImages) {
        Write-Host "  Found $($mountedImages.Count) mounted image(s)" -ForegroundColor Yellow
        $mountedImages | ForEach-Object {
            Write-Host "    Path: $($_.Path)" -ForegroundColor White
            Write-Host "    Image Path: $($_.ImagePath)" -ForegroundColor Gray
        }
    } else {
        Write-Host "  No mounted images found" -ForegroundColor White
    }
} catch {
    Write-Host "  Could not query mounted images: $($_.Exception.Message)" -ForegroundColor Yellow
}

#endregion

#region Setup Log Analysis

Write-Host "`n`n=== WINDOWS SETUP LOG ANALYSIS ===" -ForegroundColor Cyan
Write-Host "Analyzing deployment and setup logs" -ForegroundColor Yellow

$setupLogs = @{
    "Panther (Current Setup)" = "$env:SystemRoot\Panther\setuperr.log"
    "Panther Setup Actions" = "$env:SystemRoot\Panther\setupact.log"
    "Panther Unattend" = "$env:SystemRoot\Panther\unattend.xml"
    "System32 Sysprep" = "$env:SystemRoot\System32\Sysprep\Panther\setuperr.log"
    "Windows Setup Log" = "$env:SystemRoot\Logs\DPX\setuperr.log"
}

Write-Host "`nSetup Log Locations:" -ForegroundColor Green
foreach ($logName in $setupLogs.Keys) {
    $logPath = $setupLogs[$logName]

    if (Test-Path $logPath) {
        $logFile = Get-Item $logPath
        Write-Host "`n  $logName" -ForegroundColor White
        Write-Host "    Path: $logPath" -ForegroundColor Gray
        Write-Host "    Size: $([math]::Round($logFile.Length/1KB, 2)) KB" -ForegroundColor Gray
        Write-Host "    Last Modified: $($logFile.LastWriteTime)" -ForegroundColor Gray
        Write-Host "    Status: EXISTS" -ForegroundColor Green

        # Read last few lines for errors
        $content = Get-Content $logPath -Tail 10 -ErrorAction SilentlyContinue
        if ($content) {
            $errors = $content | Where-Object {$_ -match "error|fail|0x8"}
            if ($errors) {
                Write-Host "    Recent Errors Found:" -ForegroundColor Red
                $errors | ForEach-Object {
                    Write-Host "      $_" -ForegroundColor Yellow
                }
            }
        }
    } else {
        Write-Host "`n  $logName" -ForegroundColor White
        Write-Host "    Path: $logPath" -ForegroundColor Gray
        Write-Host "    Status: NOT FOUND" -ForegroundColor Yellow
    }
}

# CBS (Component-Based Servicing) logs
Write-Host "`n`nComponent-Based Servicing Logs:" -ForegroundColor Green
$cbsLog = "$env:SystemRoot\Logs\CBS\CBS.log"
if (Test-Path $cbsLog) {
    $cbsFile = Get-Item $cbsLog
    Write-Host "  CBS Log: $cbsLog" -ForegroundColor White
    Write-Host "  Size: $([math]::Round($cbsFile.Length/1MB, 2)) MB" -ForegroundColor Gray
    Write-Host "  Last Modified: $($cbsFile.LastWriteTime)" -ForegroundColor Gray
} else {
    Write-Host "  CBS.log not found" -ForegroundColor Yellow
}

#endregion

#region Sysprep Troubleshooting

Write-Host "`n`n=== SYSPREP TROUBLESHOOTING ===" -ForegroundColor Cyan
Write-Host "System preparation diagnostic information" -ForegroundColor Yellow

# Check Sysprep logs
$sysprepLogPaths = @(
    "$env:SystemRoot\System32\Sysprep\Panther\setuperr.log"
    "$env:SystemRoot\System32\Sysprep\Panther\setupact.log"
    "$env:SystemRoot\Panther\setuperr.log"
)

Write-Host "`nSysprep Log Analysis:" -ForegroundColor Green
foreach ($sysprepLog in $sysprepLogPaths) {
    if (Test-Path $sysprepLog) {
        Write-Host "`n  Log: $sysprepLog" -ForegroundColor White
        $content = Get-Content $sysprepLog -Tail 20 -ErrorAction SilentlyContinue

        if ($content) {
            $criticalErrors = $content | Where-Object {$_ -match "error|fail|fatal"}
            if ($criticalErrors) {
                Write-Host "    Recent Errors:" -ForegroundColor Red
                $criticalErrors | Select-Object -First 5 | ForEach-Object {
                    Write-Host "      $_" -ForegroundColor Yellow
                }
            } else {
                Write-Host "    No recent errors found" -ForegroundColor Green
            }
        }
    }
}

# Sysprep state registry
Write-Host "`nSysprep Registry State:" -ForegroundColor Green
$sysprepState = @{
    "State" = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Setup\State"
    "Sysprep" = "HKLM:\SYSTEM\Setup\Status\SysprepStatus"
}

foreach ($regName in $sysprepState.Keys) {
    $regPath = $sysprepState[$regName]
    if (Test-Path $regPath) {
        Write-Host "`n  $regName Path: $regPath" -ForegroundColor White
        Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue | Format-List
    }
}

$sysprepGuide = @"

Sysprep Common Issues and Solutions:

1. SYSPREP FAILS WITH "CANNOT SYSPREP IMAGE"
   - Error: Windows Store apps causing issues
   - Solution: Remove provisioned apps before sysprep
   - Command: Get-AppxProvisionedPackage -Online | Remove-AppxProvisionedPackage -Online
   - Or: DISM /Online /Cleanup-Image /StartComponentCleanup /ResetBase

2. SYSPREP FAILS AFTER WINDOWS UPDATE
   - Error: Update cleanup required
   - Solution: Run DISM cleanup before sysprep
   - Command: DISM /Online /Cleanup-Image /StartComponentCleanup

3. SYSPREP HAS BEEN RUN TOO MANY TIMES
   - Error: Sysprep limit reached (default 3 times)
   - Solution: Reset skip rearm counter (not recommended for production)
   - Registry: HKLM:\SYSTEM\Setup\Status\SysprepStatus
   - Set GeneralizationState to 7

4. SYSPREP FAILS WITH APP PACKAGE ERROR
   - Check log: C:\Windows\System32\Sysprep\Panther\setuperr.log
   - Find problematic package name
   - Remove: Get-AppxPackage -Name PACKAGENAME | Remove-AppxPackage

SYSPREP COMMANDS:
- Generalize and shutdown: sysprep /generalize /shutdown /oobe
- Audit mode: sysprep /audit /reboot
- OOBE mode: sysprep /oobe /reboot
- With answer file: sysprep /generalize /oobe /shutdown /unattend:C:\unattend.xml

"@

Write-Host $sysprepGuide -ForegroundColor White

#endregion

#region Driver and Update Issues

Write-Host "`n=== DRIVER AND UPDATE DIAGNOSTICS ===" -ForegroundColor Cyan
Write-Host "Checking for driver and update issues" -ForegroundColor Yellow

# Check for unsigned drivers
Write-Host "`nChecking for unsigned drivers:" -ForegroundColor Green
$drivers = Get-WindowsDriver -Online -ErrorAction SilentlyContinue
if ($drivers) {
    $unsignedDrivers = $drivers | Where-Object {$_.DriverSignature -ne "Signed"}
    if ($unsignedDrivers) {
        Write-Host "  Found $($unsignedDrivers.Count) unsigned driver(s):" -ForegroundColor Yellow
        $unsignedDrivers | Select-Object -First 5 | ForEach-Object {
            Write-Host "    Driver: $($_.Driver)" -ForegroundColor White
            Write-Host "    Provider: $($_.ProviderName)" -ForegroundColor Gray
        }
    } else {
        Write-Host "  All drivers are signed" -ForegroundColor Green
    }
}

# Check pending reboot
Write-Host "`nPending Reboot Status:" -ForegroundColor Green
$rebootRequired = $false

$rebootChecks = @{
    "Component Based Servicing" = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending"
    "Windows Update" = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired"
    "Pending File Rename" = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager"
}

foreach ($checkName in $rebootChecks.Keys) {
    $regPath = $rebootChecks[$checkName]
    if (Test-Path $regPath) {
        if ($checkName -eq "Pending File Rename") {
            $pendingFileRename = Get-ItemProperty -Path $regPath -Name "PendingFileRenameOperations" -ErrorAction SilentlyContinue
            if ($pendingFileRename) {
                Write-Host "  $checkName : YES" -ForegroundColor Yellow
                $rebootRequired = $true
            }
        } else {
            Write-Host "  $checkName : YES" -ForegroundColor Yellow
            $rebootRequired = $true
        }
    }
}

if (-not $rebootRequired) {
    Write-Host "  No pending reboot detected" -ForegroundColor Green
}

#endregion

#region Troubleshooting Guide

Write-Host "`n`n=== DEPLOYMENT TROUBLESHOOTING GUIDE ===" -ForegroundColor Cyan

$deploymentGuide = @"

Common Deployment Issues and Solutions:

1. IMAGE APPLY FAILS
   - Verify WIM file integrity: DISM /Get-ImageInfo /ImageFile:install.wim
   - Check disk space: Get-PSDrive
   - Verify partition format: Get-Partition
   - Try: DISM /Cleanup-Wim (cleanup temp files)

2. SETUP FAILS DURING WINDOWS INSTALLATION
   - Check: C:\Windows\Panther\setuperr.log
   - Review: C:\Windows\Panther\setupact.log
   - Common causes: Hardware incompatibility, corrupt media, insufficient disk space

3. UNATTEND.XML NOT APPLIED
   - Verify XML syntax: Test with Windows System Image Manager (WSIM)
   - Check placement: Should be in media root or C:\Windows\Panther\unattend
   - Validate: DISM /Image:C:\Mount /Get-CurrentEdition

4. DRIVER ISSUES POST-DEPLOYMENT
   - Export drivers: DISM /Online /Export-Driver /Destination:C:\Drivers
   - Inject drivers: DISM /Image:C:\Mount /Add-Driver /Driver:C:\Drivers /Recurse
   - Check unsigned: Get-WindowsDriver -Online | Where DriverSignature -ne "Signed"

5. WINDOWS UPDATE FAILS POST-DEPLOYMENT
   - Run: DISM /Online /Cleanup-Image /RestoreHealth
   - Reset: net stop wuauserv; ren C:\Windows\SoftwareDistribution SoftwareDistribution.old; net start wuauserv

6. GENERALIZATION FAILS
   - Remove apps: Get-AppxPackage -AllUsers | Remove-AppxPackage
   - Cleanup: DISM /Online /Cleanup-Image /StartComponentCleanup /ResetBase
   - Check audit mode: sysprep /audit /reboot (fix issues, then generalize)

KEY LOG LOCATIONS:
- C:\Windows\Panther\setuperr.log (setup errors)
- C:\Windows\Panther\setupact.log (setup actions)
- C:\Windows\System32\Sysprep\Panther\setuperr.log (sysprep errors)
- C:\Windows\Logs\CBS\CBS.log (servicing)
- C:\Windows\Logs\DISM\dism.log (DISM operations)

USEFUL COMMANDS:
- Get-WindowsImage -ImagePath "install.wim"
- Mount-WindowsImage -ImagePath "install.wim" -Index 1 -Path "C:\Mount"
- Get-WindowsDriver -Online
- Get-WindowsPackage -Online
- Repair-WindowsImage -Online -RestoreHealth
- Get-AppxProvisionedPackage -Online
- DISM /Online /Cleanup-Image /AnalyzeComponentStore

"@

Write-Host $deploymentGuide -ForegroundColor White

#endregion

Write-Host "`n=== DEPLOYMENT TROUBLESHOOTING COMPLETE ===" -ForegroundColor Green
Write-Host "Review the diagnostic information above`n" -ForegroundColor Yellow
