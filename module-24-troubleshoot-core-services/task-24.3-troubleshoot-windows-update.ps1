<#
.SYNOPSIS
    AZ-801 Module 24 Task 3 - Troubleshoot Windows Update

.DESCRIPTION
    This script demonstrates Windows Update troubleshooting techniques for Windows Server.
    It covers update service status, log analysis, component reset, and using DISM/SFC
    to repair Windows Update issues.

.NOTES
    Module: 24 - Troubleshoot Core Services
    Task: 24.3 - Troubleshoot Windows Update
    Exam: AZ-801 - Configuring Windows Server Hybrid Advanced Services

.LINK
    https://learn.microsoft.com/en-us/windows/deployment/update/
#>

#Requires -RunAsAdministrator

#region Windows Update Service Status

Write-Host "`n=== WINDOWS UPDATE SERVICE STATUS ===" -ForegroundColor Cyan
Write-Host "Checking Windows Update services" -ForegroundColor Yellow

$updateServices = @(
    "wuauserv",     # Windows Update
    "BITS",         # Background Intelligent Transfer Service
    "CryptSvc",     # Cryptographic Services
    "TrustedInstaller" # Windows Modules Installer
)

foreach ($serviceName in $updateServices) {
    $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue

    if ($service) {
        Write-Host "`nService: $($service.DisplayName)" -ForegroundColor Green
        Write-Host "  Name: $serviceName" -ForegroundColor White
        Write-Host "  Status: $($service.Status)" -ForegroundColor $(if($service.Status -eq 'Running'){'Green'}else{'Yellow'})
        Write-Host "  Start Type: $($service.StartType)" -ForegroundColor White

        # Check if service can be started
        if ($service.Status -ne 'Running') {
            Write-Host "  Action: Service not running - may need to be started" -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "`nService: $serviceName" -ForegroundColor Red
        Write-Host "  Status: NOT FOUND" -ForegroundColor Red
    }
}

#endregion

#region Windows Update History

Write-Host "`n`n=== WINDOWS UPDATE HISTORY ===" -ForegroundColor Cyan
Write-Host "Retrieving recent update history" -ForegroundColor Yellow

try {
    # Get update session
    $session = New-Object -ComObject Microsoft.Update.Session
    $searcher = $session.CreateUpdateSearcher()
    $historyCount = $searcher.GetTotalHistoryCount()

    Write-Host "`nTotal Updates in History: $historyCount" -ForegroundColor White

    if ($historyCount -gt 0) {
        $history = $searcher.QueryHistory(0, [Math]::Min(10, $historyCount))

        Write-Host "`nLast 10 Updates:" -ForegroundColor Green
        foreach ($update in $history) {
            $resultCode = switch ($update.ResultCode) {
                0 { "Not Started" }
                1 { "In Progress" }
                2 { "Succeeded" }
                3 { "Succeeded with Errors" }
                4 { "Failed" }
                5 { "Aborted" }
                default { "Unknown" }
            }

            $color = switch ($update.ResultCode) {
                2 { "Green" }
                3 { "Yellow" }
                4 { "Red" }
                default { "White" }
            }

            Write-Host "`n  Title: $($update.Title)" -ForegroundColor White
            Write-Host "  Date: $($update.Date)" -ForegroundColor Gray
            Write-Host "  Result: $resultCode" -ForegroundColor $color
            Write-Host "  KB Article: $($update.Title -replace '.*\(KB(\d+)\).*', 'KB$1')" -ForegroundColor Gray
        }
    }
}
catch {
    Write-Host "  Error retrieving update history: $($_.Exception.Message)" -ForegroundColor Red
}

#endregion

#region Windows Update Log Analysis

Write-Host "`n`n=== WINDOWS UPDATE LOG ANALYSIS ===" -ForegroundColor Cyan
Write-Host "Analyzing Windows Update logs" -ForegroundColor Yellow

# Generate Windows Update log (Windows 10/Server 2016+)
Write-Host "`nGenerating Windows Update log..." -ForegroundColor Green
Write-Host "Command: Get-WindowsUpdateLog" -ForegroundColor White

$logPath = "$env:USERPROFILE\Desktop\WindowsUpdate.log"
Write-Host "This will create log at: $logPath" -ForegroundColor Gray
Write-Host "(Skipping actual generation - can take several minutes)" -ForegroundColor Yellow

# Check Windows Update event log
Write-Host "`nChecking Windows Update Event Log:" -ForegroundColor Green
try {
    $updateEvents = Get-WinEvent -LogName "System" -MaxEvents 20 |
        Where-Object {$_.ProviderName -like "*WindowsUpdateClient*"}

    if ($updateEvents) {
        Write-Host "Recent Windows Update Events:" -ForegroundColor White
        $updateEvents | Select-Object -First 5 | ForEach-Object {
            $levelColor = switch ($_.Level) {
                1 { "Red" }      # Critical
                2 { "Red" }      # Error
                3 { "Yellow" }   # Warning
                4 { "Green" }    # Information
                default { "White" }
            }

            Write-Host "`n  Time: $($_.TimeCreated)" -ForegroundColor Gray
            Write-Host "  Level: $($_.LevelDisplayName)" -ForegroundColor $levelColor
            Write-Host "  Message: $($_.Message.Substring(0, [Math]::Min(100, $_.Message.Length)))..." -ForegroundColor White
        }
    }
    else {
        Write-Host "  No recent Windows Update events found" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "  Error accessing event log: $($_.Exception.Message)" -ForegroundColor Red
}

#endregion

#region UsoClient Commands

Write-Host "`n`n=== USOCLIENT COMMANDS ===" -ForegroundColor Cyan
Write-Host "Update Session Orchestrator (UsoClient) commands" -ForegroundColor Yellow

$usoCommands = @"

UsoClient.exe Commands for Windows Update:

1. START SCAN FOR UPDATES:
   UsoClient StartScan
   - Initiates scan for available updates

2. START DOWNLOAD:
   UsoClient StartDownload
   - Downloads available updates

3. START INSTALL:
   UsoClient StartInstall
   - Installs downloaded updates

4. START INTERACTIVE INSTALL:
   UsoClient StartInteractiveScan
   - Starts interactive update scan

5. REFRESH SETTINGS:
   UsoClient RefreshSettings
   - Refreshes Windows Update settings

6. RESUME UPDATE:
   UsoClient ResumeUpdate
   - Resumes paused update installation

Example Usage:
  Start-Process -FilePath "UsoClient.exe" -ArgumentList "StartScan" -NoNewWindow -Wait

Note: UsoClient replaced the older wuauclt.exe in Windows 10/Server 2016+

"@

Write-Host $usoCommands -ForegroundColor White

#endregion

#region DISM Health Check

Write-Host "`n=== DISM COMPONENT HEALTH CHECK ===" -ForegroundColor Cyan
Write-Host "Checking Windows component store health" -ForegroundColor Yellow

Write-Host "`nRunning DISM ScanHealth..." -ForegroundColor Green
Write-Host "Command: DISM /Online /Cleanup-Image /ScanHealth" -ForegroundColor White

# Note: Actual DISM commands can take a long time
Write-Host "`nDISM Health Check Commands:" -ForegroundColor White
Write-Host "  1. Check Health (quick):  DISM /Online /Cleanup-Image /CheckHealth" -ForegroundColor Gray
Write-Host "  2. Scan Health (thorough): DISM /Online /Cleanup-Image /ScanHealth" -ForegroundColor Gray
Write-Host "  3. Restore Health (repair): DISM /Online /Cleanup-Image /RestoreHealth" -ForegroundColor Gray
Write-Host "`n(Not executing - these commands can take 15-30 minutes)" -ForegroundColor Yellow

# Check if component store is healthy using registry
Write-Host "`nChecking component store status..." -ForegroundColor Green
try {
    $dismInfo = Repair-WindowsImage -Online -CheckHealth
    Write-Host "  Image Health State: $($dismInfo.ImageHealthState)" -ForegroundColor $(
        if ($dismInfo.ImageHealthState -eq 'Healthy') {'Green'} else {'Red'}
    )
}
catch {
    Write-Host "  Could not check image health: $($_.Exception.Message)" -ForegroundColor Yellow
}

#endregion

#region System File Checker

Write-Host "`n`n=== SYSTEM FILE CHECKER (SFC) ===" -ForegroundColor Cyan
Write-Host "System file integrity verification" -ForegroundColor Yellow

Write-Host "`nSystem File Checker Commands:" -ForegroundColor White
Write-Host "  1. Scan and repair:    sfc /scannow" -ForegroundColor Gray
Write-Host "  2. Scan only:          sfc /verifyonly" -ForegroundColor Gray
Write-Host "  3. Scan specific file: sfc /scanfile=C:\Windows\System32\file.dll" -ForegroundColor Gray
Write-Host "`n(Not executing - SFC can take 15-30 minutes)" -ForegroundColor Yellow

# Check SFC log
$sfcLog = "$env:SystemRoot\Logs\CBS\CBS.log"
if (Test-Path $sfcLog) {
    Write-Host "`nSFC Log Location: $sfcLog" -ForegroundColor Green
    Write-Host "  Last Modified: $((Get-Item $sfcLog).LastWriteTime)" -ForegroundColor White

    # Get last few lines
    $lastLines = Get-Content $sfcLog -Tail 5 -ErrorAction SilentlyContinue
    if ($lastLines) {
        Write-Host "`n  Last log entries:" -ForegroundColor White
        $lastLines | ForEach-Object {
            Write-Host "    $_" -ForegroundColor Gray
        }
    }
}

#endregion

#region Windows Update Component Reset

Write-Host "`n`n=== WINDOWS UPDATE COMPONENT RESET ===" -ForegroundColor Cyan
Write-Host "Procedures to reset Windows Update components" -ForegroundColor Yellow

$resetProcedure = @"

Windows Update Component Reset Procedure:

MANUAL RESET STEPS (use when updates consistently fail):

1. STOP WINDOWS UPDATE SERVICES:
   net stop wuauserv
   net stop cryptSvc
   net stop bits
   net stop msiserver

2. RENAME SOFTWARE DISTRIBUTION FOLDERS:
   ren C:\Windows\SoftwareDistribution SoftwareDistribution.old
   ren C:\Windows\System32\catroot2 catroot2.old

3. START WINDOWS UPDATE SERVICES:
   net start wuauserv
   net start cryptSvc
   net start bits
   net start msiserver

4. RUN WINDOWS UPDATE:
   UsoClient StartScan

POWERSHELL AUTOMATED RESET:
   `$services = 'wuauserv','cryptSvc','bits','msiserver'
   `$services | ForEach-Object { Stop-Service `$_ -Force }
   Rename-Item C:\Windows\SoftwareDistribution SoftwareDistribution.old -Force
   Rename-Item C:\Windows\System32\catroot2 catroot2.old -Force
   `$services | ForEach-Object { Start-Service `$_ }

WARNING: Only perform reset if:
- Updates consistently fail
- Update errors persist after troubleshooting
- Approved by change management
- System state is backed up

"@

Write-Host $resetProcedure -ForegroundColor White

#endregion

#region Troubleshooting Recommendations

Write-Host "`n=== TROUBLESHOOTING GUIDE ===" -ForegroundColor Cyan

$troubleshooting = @"

Common Windows Update Issues and Solutions:

1. UPDATES FAIL TO INSTALL (0x80070002, 0x80073712)
   - Run: DISM /Online /Cleanup-Image /RestoreHealth
   - Run: sfc /scannow
   - Clear update cache: net stop wuauserv; del C:\Windows\SoftwareDistribution\* /Q /S
   - Restart: net start wuauserv

2. UPDATE SERVICE NOT RUNNING
   - Check service: Get-Service wuauserv
   - Start service: Start-Service wuauserv
   - Set automatic: Set-Service wuauserv -StartupType Automatic

3. SLOW UPDATE DOWNLOADS (BITS issues)
   - Check BITS: Get-Service BITS
   - Clear BITS queue: bitsadmin /reset /allusers
   - Restart BITS: Restart-Service BITS

4. SPECIFIC UPDATE FAILS
   - Review CBS.log: C:\Windows\Logs\CBS\CBS.log
   - Check event logs: Get-WinEvent -LogName System | Where ProviderName -like "*Update*"
   - Download manually from Microsoft Update Catalog

5. WINDOWS UPDATE STUCK
   - Stop services: wuauserv, bits, cryptsvc
   - Delete: C:\Windows\SoftwareDistribution\Download\*
   - Restart services and rescan

6. DISK SPACE ISSUES
   - Check space: Get-PSDrive C
   - Clean old updates: DISM /Online /Cleanup-Image /StartComponentCleanup
   - Disk cleanup: cleanmgr /sageset:1

USEFUL DIAGNOSTIC COMMANDS:
- Get-WindowsUpdateLog (generates ETW log to desktop)
- Get-HotFix (list installed updates)
- Get-WmiObject -Class Win32_QuickFixEngineering
- UsoClient StartScan (trigger update scan)
- Get-WinEvent -LogName System -MaxEvents 50 | Where ProviderName -like "*Update*"

"@

Write-Host $troubleshooting -ForegroundColor White

#endregion

Write-Host "`n=== WINDOWS UPDATE TROUBLESHOOTING COMPLETE ===" -ForegroundColor Green
Write-Host "Review the diagnostic information above`n" -ForegroundColor Yellow
