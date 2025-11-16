<#
.SYNOPSIS
    AZ-801 Module 24 Task 4 - Troubleshoot Time Synchronization

.DESCRIPTION
    This script demonstrates time service (W32Time) troubleshooting for Windows Server.
    It covers w32tm commands, NTP configuration, registry settings, and event log analysis
    to diagnose and resolve time synchronization issues.

.NOTES
    Module: 24 - Troubleshoot Core Services
    Task: 24.4 - Troubleshoot Time Synchronization
    Exam: AZ-801 - Configuring Windows Server Hybrid Advanced Services

.LINK
    https://learn.microsoft.com/en-us/windows-server/networking/windows-time-service/
#>

#Requires -RunAsAdministrator

#region Time Service Status

Write-Host "`n=== WINDOWS TIME SERVICE STATUS ===" -ForegroundColor Cyan
Write-Host "Checking W32Time service configuration" -ForegroundColor Yellow

# Check W32Time service
$timeService = Get-Service W32Time

Write-Host "`nService Status:" -ForegroundColor Green
Write-Host "  Service Name: $($timeService.Name)" -ForegroundColor White
Write-Host "  Display Name: $($timeService.DisplayName)" -ForegroundColor White
Write-Host "  Status: $($timeService.Status)" -ForegroundColor $(if($timeService.Status -eq 'Running'){'Green'}else{'Red'})
Write-Host "  Start Type: $($timeService.StartType)" -ForegroundColor White

if ($timeService.Status -ne 'Running') {
    Write-Host "  WARNING: Time service is not running!" -ForegroundColor Yellow
    Write-Host "  Start with: Start-Service W32Time" -ForegroundColor Gray
}

# Check current time
Write-Host "`nCurrent System Time:" -ForegroundColor Green
$currentTime = Get-Date
Write-Host "  Local Time: $currentTime" -ForegroundColor White
Write-Host "  UTC Time: $($currentTime.ToUniversalTime())" -ForegroundColor White
Write-Host "  Time Zone: $([TimeZoneInfo]::Local.DisplayName)" -ForegroundColor White

#endregion

#region W32tm Query Status

Write-Host "`n`n=== W32TM STATUS QUERY ===" -ForegroundColor Cyan
Write-Host "Querying detailed time service status" -ForegroundColor Yellow

Write-Host "`nRunning: w32tm /query /status" -ForegroundColor Green
$w32status = w32tm /query /status 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host $w32status -ForegroundColor White
} else {
    Write-Host "  Error querying time service status" -ForegroundColor Red
    Write-Host $w32status -ForegroundColor Yellow
}

# Parse key information
Write-Host "`nKey Status Information:" -ForegroundColor Green
$statusLines = $w32status -split "`n"
$sourceMatch = $statusLines | Where-Object {$_ -match "Source:"}
$lastSyncMatch = $statusLines | Where-Object {$_ -match "Last Successful Sync Time:"}
$stratumMatch = $statusLines | Where-Object {$_ -match "Stratum:"}

if ($sourceMatch) { Write-Host "  $sourceMatch" -ForegroundColor White }
if ($lastSyncMatch) { Write-Host "  $lastSyncMatch" -ForegroundColor White }
if ($stratumMatch) { Write-Host "  $stratumMatch" -ForegroundColor White }

#endregion

#region NTP Configuration

Write-Host "`n`n=== NTP CONFIGURATION ===" -ForegroundColor Cyan
Write-Host "Analyzing NTP client/server configuration" -ForegroundColor Yellow

# Query configuration
Write-Host "`nRunning: w32tm /query /configuration" -ForegroundColor Green
$w32config = w32tm /query /configuration 2>&1

if ($LASTEXITCODE -eq 0) {
    $configLines = $w32config -split "`n"

    # Extract key configuration items
    Write-Host "`nTime Configuration:" -ForegroundColor White
    $configLines | Where-Object {
        $_ -match "Type:" -or
        $_ -match "NtpServer:" -or
        $_ -match "AnnounceFlags:" -or
        $_ -match "MaxPosPhaseCorrection:" -or
        $_ -match "MaxNegPhaseCorrection:"
    } | ForEach-Object {
        Write-Host "  $_" -ForegroundColor Gray
    }
} else {
    Write-Host "  Error querying configuration" -ForegroundColor Red
}

# Check registry settings
Write-Host "`nRegistry Time Settings:" -ForegroundColor Green
$timeRegPath = "HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Parameters"
if (Test-Path $timeRegPath) {
    $ntpServer = Get-ItemProperty -Path $timeRegPath -Name "NtpServer" -ErrorAction SilentlyContinue
    $type = Get-ItemProperty -Path $timeRegPath -Name "Type" -ErrorAction SilentlyContinue

    if ($ntpServer) {
        Write-Host "  NTP Server: $($ntpServer.NtpServer)" -ForegroundColor White
    }
    if ($type) {
        $typeDescription = switch ($type.Type) {
            "NoSync" { "NoSync - Do not synchronize" }
            "NTP" { "NTP - Use external NTP servers" }
            "NT5DS" { "NT5DS - Sync from domain hierarchy" }
            "AllSync" { "AllSync - Use all available sources" }
            default { $type.Type }
        }
        Write-Host "  Type: $typeDescription" -ForegroundColor White
    }
}

#endregion

#region Time Source Testing

Write-Host "`n`n=== TIME SOURCE TESTING ===" -ForegroundColor Cyan
Write-Host "Testing connectivity to time sources" -ForegroundColor Yellow

# Get configured NTP servers
$configuredServers = @()
if ($ntpServer) {
    $configuredServers = $ntpServer.NtpServer -split "," | ForEach-Object {
        $_ -replace ",0x[0-9a-fA-F]+", "" -replace " ", ""
    }
}

if ($configuredServers.Count -eq 0) {
    $configuredServers = @("time.windows.com", "pool.ntp.org")
    Write-Host "`nNo configured servers found, testing default servers" -ForegroundColor Yellow
}

foreach ($server in $configuredServers) {
    if ($server) {
        Write-Host "`nTesting: $server" -ForegroundColor Green

        # Test network connectivity
        $portTest = Test-NetConnection -ComputerName $server -Port 123 -WarningAction SilentlyContinue -ErrorAction SilentlyContinue

        if ($portTest.TcpTestSucceeded) {
            Write-Host "  Port 123 (NTP): REACHABLE" -ForegroundColor Green
        } else {
            Write-Host "  Port 123 (NTP): UNREACHABLE" -ForegroundColor Red
        }

        # Stripchart shows time offset
        Write-Host "  Running stripchart (3 samples)..." -ForegroundColor Gray
        $stripchart = w32tm /stripchart /computer:$server /samples:3 /dataonly 2>&1

        if ($LASTEXITCODE -eq 0) {
            $offsetLines = $stripchart | Where-Object {$_ -match "Offset:"}
            if ($offsetLines) {
                Write-Host "  $($offsetLines | Select-Object -Last 1)" -ForegroundColor White
            }
        } else {
            Write-Host "  Stripchart failed: Server may be unreachable or not responding" -ForegroundColor Yellow
        }
    }
}

#endregion

#region Force Time Sync

Write-Host "`n`n=== TIME SYNCHRONIZATION ===" -ForegroundColor Cyan
Write-Host "Testing manual time synchronization" -ForegroundColor Yellow

Write-Host "`nForcing time resync..." -ForegroundColor Green
Write-Host "Running: w32tm /resync" -ForegroundColor White

$resync = w32tm /resync 2>&1
Write-Host $resync -ForegroundColor $(if($LASTEXITCODE -eq 0){'Green'}else{'Yellow'})

if ($LASTEXITCODE -eq 0) {
    Write-Host "`nSync Status: SUCCESS" -ForegroundColor Green
} else {
    Write-Host "`nSync Status: FAILED or PENDING" -ForegroundColor Yellow
    Write-Host "This is normal if time is already in sync or service recently started" -ForegroundColor Gray
}

#endregion

#region Event Log Analysis

Write-Host "`n`n=== TIME SERVICE EVENT LOGS ===" -ForegroundColor Cyan
Write-Host "Analyzing time service events" -ForegroundColor Yellow

try {
    $timeEvents = Get-WinEvent -LogName System -MaxEvents 50 -ErrorAction Stop |
        Where-Object {$_.ProviderName -eq "Microsoft-Windows-Time-Service"}

    if ($timeEvents) {
        Write-Host "`nRecent Time Service Events:" -ForegroundColor Green

        $timeEvents | Select-Object -First 10 | ForEach-Object {
            $levelColor = switch ($_.Level) {
                1 { "Red" }      # Critical
                2 { "Red" }      # Error
                3 { "Yellow" }   # Warning
                4 { "White" }    # Information
                default { "Gray" }
            }

            Write-Host "`n  Time: $($_.TimeCreated)" -ForegroundColor Gray
            Write-Host "  Event ID: $($_.Id)" -ForegroundColor White
            Write-Host "  Level: $($_.LevelDisplayName)" -ForegroundColor $levelColor
            Write-Host "  Message: $($_.Message.Substring(0, [Math]::Min(150, $_.Message.Length)))..." -ForegroundColor $levelColor
        }

        # Common event IDs
        Write-Host "`n`nCommon Time Service Event IDs:" -ForegroundColor Green
        $eventGroups = $timeEvents | Group-Object Id | Sort-Object Count -Descending | Select-Object -First 5

        foreach ($group in $eventGroups) {
            $eventName = switch ($group.Name) {
                "35" { "Time sync successful" }
                "37" { "Time provider stopped" }
                "47" { "Time service configured to use time sources" }
                "129" { "NtpClient unable to contact source" }
                "134" { "Time source reachability" }
                default { "Event ID $($group.Name)" }
            }

            Write-Host "  Event $($group.Name) - $eventName : $($group.Count) occurrences" -ForegroundColor White
        }
    } else {
        Write-Host "  No recent time service events found" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "  Error accessing event log: $($_.Exception.Message)" -ForegroundColor Red
}

#endregion

#region Troubleshooting Guide

Write-Host "`n`n=== TROUBLESHOOTING GUIDE ===" -ForegroundColor Cyan

$troubleshooting = @"

Common Time Synchronization Issues and Solutions:

1. TIME SERVICE NOT RUNNING
   - Start service: Start-Service W32Time
   - Set automatic: Set-Service W32Time -StartupType Automatic
   - Register service: w32tm /register

2. CANNOT SYNC TIME (Event ID 129)
   - Check NTP server reachability: Test-NetConnection time.windows.com -Port 123
   - Verify firewall allows UDP 123 outbound
   - Test stripchart: w32tm /stripchart /computer:time.windows.com /samples:5
   - Change NTP server: w32tm /config /manualpeerlist:"time.windows.com" /syncfromflags:manual /update

3. TIME DRIFT ISSUES
   - Check current offset: w32tm /stripchart /computer:time.windows.com /samples:1
   - Increase sync frequency: w32tm /config /update /SpecialPollInterval:900
   - Force immediate sync: w32tm /resync /force
   - Check Event ID 35 for successful syncs

4. DOMAIN CONTROLLER TIME ISSUES
   - PDC emulator should sync to external source (NTP)
   - Other DCs sync from domain hierarchy (NT5DS)
   - Configure PDC: w32tm /config /manualpeerlist:"time.windows.com,0x8" /syncfromflags:manual /reliable:yes /update
   - Non-PDC DCs: w32tm /config /syncfromflags:domhier /update

5. LARGE TIME OFFSET
   - If offset > 15 hours, auto-sync may fail
   - Stop service: Stop-Service W32Time
   - Set time manually: Set-Date -Date "MM/DD/YYYY HH:MM:SS"
   - Start service: Start-Service W32Time
   - Force sync: w32tm /resync

USEFUL W32TM COMMANDS:
- w32tm /query /status (check sync status)
- w32tm /query /configuration (view configuration)
- w32tm /query /peers (list time sources)
- w32tm /resync (force synchronization)
- w32tm /stripchart /computer:SERVER /samples:5 (test time source)
- w32tm /config /update (apply configuration changes)
- w32tm /debug /enable /file:C:\temp\w32tm.log /size:10000000 (enable debug logging)

NTP SERVER CONFIGURATION:
# Configure as NTP server
w32tm /config /manualpeerlist:"time.windows.com,0x8" /syncfromflags:manual /reliable:yes /update

# Allow clients to sync
Set-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\TimeProviders\NtpServer -Name Enabled -Value 1

# Open firewall
New-NetFirewallRule -DisplayName "NTP Server" -Direction Inbound -LocalPort 123 -Protocol UDP -Action Allow

# Restart service
Restart-Service W32Time

REGISTRY SETTINGS:
- HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Config
  - MaxPosPhaseCorrection (max forward correction in seconds, default 172800 = 48h)
  - MaxNegPhaseCorrection (max backward correction in seconds, default 172800 = 48h)

- HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Parameters
  - Type (NT5DS=domain, NTP=external)
  - NtpServer (comma-separated list of servers)

- HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\TimeProviders\NtpClient
  - SpecialPollInterval (sync frequency in seconds, default 3600)

"@

Write-Host $troubleshooting -ForegroundColor White

#endregion

Write-Host "`n=== TIME SYNCHRONIZATION TROUBLESHOOTING COMPLETE ===" -ForegroundColor Green
Write-Host "Review the results above for any time sync issues`n" -ForegroundColor Yellow
