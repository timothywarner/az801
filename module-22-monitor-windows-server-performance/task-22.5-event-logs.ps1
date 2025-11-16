<#
.SYNOPSIS
    Task 22.5 - Analyze Event Logs

.DESCRIPTION
    Demo script for AZ-801 Module 22: Monitor Windows Server Performance
    Demonstrates event log analysis using Get-EventLog, Get-WinEvent, filtering,
    and log management for troubleshooting.

.NOTES
    Module: Module 22 - Monitor Windows Server Performance
    Task: 22.5 - Analyze Event Logs
    Prerequisites: Windows Server, Administrative privileges
    PowerShell Version: 5.1+
#>

#Requires -RunAsAdministrator

$ErrorActionPreference = 'Stop'
Write-Host "=== AZ-801 Module 22: Task 22.5 - Analyze Event Logs ===" -ForegroundColor Cyan
Write-Host ""

try {
    # List available event logs
    Write-Host "[Step 1] List Available Event Logs" -ForegroundColor Yellow

    $allLogs = Get-EventLog -List | Sort-Object Log
    Write-Host "Classic Event Logs:" -ForegroundColor Cyan
    $allLogs | Format-Table Log,
        @{Name='MaxKB';Expression={$_.MaximumKilobytes}},
        @{Name='Retention';Expression={$_.MinimumRetentionDays}},
        @{Name='Entries';Expression={$_.Entries.Count}} -AutoSize
    Write-Host ""

    # Get recent system errors
    Write-Host "[Step 2] Analyze Recent System Errors" -ForegroundColor Yellow

    $systemErrors = Get-EventLog -LogName System -EntryType Error -Newest 10
    if ($systemErrors) {
        Write-Host "Recent System Errors (Last 10):" -ForegroundColor Cyan
        $systemErrors | Format-Table TimeGenerated,
            Source,
            EventID,
            @{Name='Message';Expression={$_.Message.Substring(0,[Math]::Min(60,$_.Message.Length))}} -AutoSize
    } else {
        Write-Host "[OK] No recent system errors found" -ForegroundColor Green
    }
    Write-Host ""

    # Using Get-WinEvent for modern event logs
    Write-Host "[Step 3] Query Event Logs with Get-WinEvent" -ForegroundColor Yellow

    $winLogs = Get-WinEvent -ListLog * | Where-Object { $_.RecordCount -gt 0 } |
        Sort-Object RecordCount -Descending |
        Select-Object -First 10 LogName,
            RecordCount,
            @{Name='Size_MB';Expression={[math]::Round($_.FileSize / 1MB, 2)}},
            IsEnabled

    Write-Host "Top 10 Event Logs by Record Count:" -ForegroundColor Cyan
    $winLogs | Format-Table -AutoSize
    Write-Host ""

    # Filter events by level
    Write-Host "[Step 4] Filter Events by Severity Level" -ForegroundColor Yellow

    $last24Hours = (Get-Date).AddHours(-24)

    # Critical and Error events
    $criticalEvents = Get-WinEvent -FilterHashtable @{
        LogName = 'System', 'Application'
        Level = 1, 2  # 1=Critical, 2=Error
        StartTime = $last24Hours
    } -MaxEvents 20 -ErrorAction SilentlyContinue

    if ($criticalEvents) {
        Write-Host "Critical/Error Events (Last 24 hours):" -ForegroundColor Cyan
        $criticalEvents | Select-Object TimeCreated,
            LogName,
            LevelDisplayName,
            Id,
            ProviderName |
        Format-Table -AutoSize
    } else {
        Write-Host "[OK] No critical/error events in the last 24 hours" -ForegroundColor Green
    }
    Write-Host ""

    # Filter events by Event ID
    Write-Host "[Step 5] Filter Events by Event ID" -ForegroundColor Yellow

    # Common important Event IDs
    $importantEvents = @{
        1074 = "System shutdown/restart"
        1076 = "Shutdown reason"
        6005 = "Event Log service started"
        6006 = "Event Log service stopped"
        6008 = "Unexpected shutdown"
        6009 = "System startup"
    }

    Write-Host "Searching for important system events..." -ForegroundColor Cyan

    $eventIds = $importantEvents.Keys
    $foundEvents = Get-WinEvent -FilterHashtable @{
        LogName = 'System'
        Id = $eventIds
    } -MaxEvents 10 -ErrorAction SilentlyContinue

    if ($foundEvents) {
        $foundEvents | ForEach-Object {
            $description = $importantEvents[$_.Id]
            [PSCustomObject]@{
                Time = $_.TimeCreated
                EventID = $_.Id
                Description = $description
                Message = $_.Message.Substring(0, [Math]::Min(80, $_.Message.Length))
            }
        } | Format-Table -AutoSize -Wrap
    }
    Write-Host ""

    # Filter by provider/source
    Write-Host "[Step 6] Filter Events by Provider" -ForegroundColor Yellow

    $diskEvents = Get-WinEvent -FilterHashtable @{
        ProviderName = 'Microsoft-Windows-Disk'
        StartTime = $last24Hours
    } -MaxEvents 10 -ErrorAction SilentlyContinue

    if ($diskEvents) {
        Write-Host "Recent Disk Events:" -ForegroundColor Cyan
        $diskEvents | Select-Object TimeCreated, Id, LevelDisplayName, Message |
            Format-List
    } else {
        Write-Host "[INFO] No recent disk events found" -ForegroundColor Cyan
    }
    Write-Host ""

    # Using XPath queries
    Write-Host "[Step 7] Advanced Filtering with XPath" -ForegroundColor Yellow

    $xpathQuery = @"
*[System[(Level=1 or Level=2) and
TimeCreated[timediff(@SystemTime) <= 86400000]]]
"@

    Write-Host "XPath Query for Critical/Error events in last 24 hours:" -ForegroundColor Cyan
    Write-Host $xpathQuery -ForegroundColor Gray

    $xpathEvents = Get-WinEvent -LogName Application -FilterXPath $xpathQuery -MaxEvents 5 -ErrorAction SilentlyContinue

    if ($xpathEvents) {
        Write-Host "`nResults:" -ForegroundColor Cyan
        $xpathEvents | Select-Object TimeCreated, Id, LevelDisplayName, ProviderName |
            Format-Table -AutoSize
    }
    Write-Host ""

    # Event log statistics
    Write-Host "[Step 8] Event Log Statistics" -ForegroundColor Yellow

    function Get-EventLogStatistics {
        param([string]$LogName, [int]$Hours = 24)

        $startTime = (Get-Date).AddHours(-$Hours)
        $events = Get-WinEvent -FilterHashtable @{
            LogName = $LogName
            StartTime = $startTime
        } -ErrorAction SilentlyContinue

        if ($events) {
            $stats = $events | Group-Object LevelDisplayName | ForEach-Object {
                [PSCustomObject]@{
                    Level = $_.Name
                    Count = $_.Count
                }
            }

            [PSCustomObject]@{
                LogName = $LogName
                TimeRange = "$Hours hours"
                TotalEvents = $events.Count
                Statistics = $stats
            }
        }
    }

    $systemStats = Get-EventLogStatistics -LogName 'System' -Hours 24
    if ($systemStats) {
        Write-Host "System Log Statistics (Last 24 hours):" -ForegroundColor Cyan
        Write-Host "Total Events: $($systemStats.TotalEvents)" -ForegroundColor White
        $systemStats.Statistics | Format-Table -AutoSize
    }
    Write-Host ""

    # Export event logs
    Write-Host "[Step 9] Export Event Logs" -ForegroundColor Yellow

    $exportPath = "C:\Logs\EventLog-Export-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    if (-not (Test-Path $exportPath)) {
        New-Item -Path $exportPath -ItemType Directory -Force | Out-Null
    }

    # Export to CSV
    $csvFile = "$exportPath\SystemErrors.csv"
    Get-EventLog -LogName System -EntryType Error -Newest 100 |
        Select-Object TimeGenerated, Source, EventID, Message |
        Export-Csv -Path $csvFile -NoTypeInformation

    Write-Host "[SUCCESS] Exported system errors to: $csvFile" -ForegroundColor Green

    # Export to XML
    $xmlFile = "$exportPath\ApplicationEvents.xml"
    Get-WinEvent -FilterHashtable @{
        LogName = 'Application'
        Level = 1, 2, 3
        StartTime = $last24Hours
    } -MaxEvents 100 -ErrorAction SilentlyContinue |
        Export-Clixml -Path $xmlFile

    if (Test-Path $xmlFile) {
        Write-Host "[SUCCESS] Exported application events to: $xmlFile" -ForegroundColor Green
    }
    Write-Host ""

    # Create custom event log
    Write-Host "[Step 10] Create Custom Event Log" -ForegroundColor Yellow

    $customLog = "AZ801-CustomApp"
    $customSource = "AZ801-Demo"

    if (-not [System.Diagnostics.EventLog]::SourceExists($customSource)) {
        New-EventLog -LogName $customLog -Source $customSource
        Write-Host "[SUCCESS] Created custom event log: $customLog" -ForegroundColor Green
    } else {
        Write-Host "[INFO] Custom event log already exists: $customLog" -ForegroundColor Cyan
    }

    # Write test events
    Write-EventLog -LogName $customLog -Source $customSource -EventId 1001 -EntryType Information -Message "Test information event"
    Write-EventLog -LogName $customLog -Source $customSource -EventId 2001 -EntryType Warning -Message "Test warning event"

    Write-Host "Test events written to custom log" -ForegroundColor White

    # Read custom events
    $customEvents = Get-EventLog -LogName $customLog -Newest 5
    Write-Host "`nRecent custom events:" -ForegroundColor Cyan
    $customEvents | Format-Table TimeGenerated, EntryType, EventID, Message -AutoSize
    Write-Host ""

    # Event log management
    Write-Host "[Step 11] Event Log Management" -ForegroundColor Yellow

    Write-Host "Configure log size and retention:" -ForegroundColor Cyan
    Write-Host "  Limit-EventLog -LogName Application -MaximumSize 512MB -OverflowAction OverwriteAsNeeded" -ForegroundColor White
    Write-Host ""

    Write-Host "Clear event log:" -ForegroundColor Cyan
    Write-Host "  Clear-EventLog -LogName Application" -ForegroundColor White
    Write-Host ""

    Write-Host "Backup event log:" -ForegroundColor Cyan
    $backupPath = "$exportPath\System-Backup.evtx"
    Write-Host "  wevtutil epl System `"$backupPath`"" -ForegroundColor White

    # Actually create backup
    $backupCmd = "wevtutil epl System `"$backupPath`""
    Invoke-Expression $backupCmd

    if (Test-Path $backupPath) {
        $backupSize = (Get-Item $backupPath).Length / 1MB
        Write-Host "[SUCCESS] System log backed up: $backupPath ($([math]::Round($backupSize, 2)) MB)" -ForegroundColor Green
    }
    Write-Host ""

    # Monitoring specific applications
    Write-Host "[Step 12] Monitor Application-Specific Events" -ForegroundColor Yellow

    # Monitor Windows Update events
    $updateEvents = Get-WinEvent -FilterHashtable @{
        LogName = 'System'
        ProviderName = 'Microsoft-Windows-WindowsUpdateClient'
        StartTime = $last24Hours
    } -MaxEvents 10 -ErrorAction SilentlyContinue

    if ($updateEvents) {
        Write-Host "Recent Windows Update Events:" -ForegroundColor Cyan
        $updateEvents | Select-Object TimeCreated, Id, LevelDisplayName |
            Format-Table -AutoSize
    } else {
        Write-Host "[INFO] No recent Windows Update events" -ForegroundColor Cyan
    }
    Write-Host ""

    # Event log forwarding
    Write-Host "[Step 13] Event Log Forwarding Configuration" -ForegroundColor Yellow

    Write-Host "Configure event collector:" -ForegroundColor Cyan
    Write-Host "  wecutil qc" -ForegroundColor White
    Write-Host ""

    Write-Host "Create subscription:" -ForegroundColor Cyan
    Write-Host "  wecutil cs subscription.xml" -ForegroundColor White
    Write-Host ""

    Write-Host "List subscriptions:" -ForegroundColor Cyan
    Write-Host "  wecutil es" -ForegroundColor White
    Write-Host ""

    # Real-time event monitoring
    Write-Host "[Step 14] Real-Time Event Monitoring Example" -ForegroundColor Yellow

    Write-Host "Monitor events in real-time (example code):" -ForegroundColor Cyan

    $monitorScript = @'
# Monitor System log for errors in real-time
$query = @{
    LogName = 'System'
    Level = 1,2  # Critical and Error
}

Register-ObjectEvent -InputObject (Get-WinEvent -FilterHashtable $query -MaxEvents 1) `
    -EventName EntryWritten `
    -Action {
        $event = $Event.SourceEventArgs.Entry
        Write-Host "[$($event.TimeGenerated)] ERROR: $($event.Message)"
    }

# Wait for events (Ctrl+C to stop)
Wait-Event
'@

    Write-Host $monitorScript -ForegroundColor Gray
    Write-Host ""

    # Common troubleshooting queries
    Write-Host "[Step 15] Common Troubleshooting Queries" -ForegroundColor Yellow

    Write-Host "1. Find application crashes:" -ForegroundColor Cyan
    Write-Host "   Get-WinEvent -FilterHashtable @{LogName='Application'; ProviderName='Application Error'}" -ForegroundColor White
    Write-Host ""

    Write-Host "2. Find service failures:" -ForegroundColor Cyan
    Write-Host "   Get-WinEvent -FilterHashtable @{LogName='System'; ProviderName='Service Control Manager'; Level=2}" -ForegroundColor White
    Write-Host ""

    Write-Host "3. Find security logon failures:" -ForegroundColor Cyan
    Write-Host "   Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4625}" -ForegroundColor White
    Write-Host ""

    Write-Host "4. Find disk errors:" -ForegroundColor Cyan
    Write-Host "   Get-WinEvent -FilterHashtable @{LogName='System'; ProviderName='disk'; Level=2}" -ForegroundColor White
    Write-Host ""

    Write-Host "5. Find Group Policy errors:" -ForegroundColor Cyan
    Write-Host "   Get-WinEvent -FilterHashtable @{LogName='System'; ProviderName='Microsoft-Windows-GroupPolicy'; Level=2}" -ForegroundColor White
    Write-Host ""

    # Event correlation
    Write-Host "[Step 16] Event Correlation Analysis" -ForegroundColor Yellow

    function Find-CorrelatedEvents {
        param(
            [int]$EventId,
            [string]$LogName = 'System',
            [int]$WindowMinutes = 5
        )

        $baseEvents = Get-WinEvent -FilterHashtable @{
            LogName = $LogName
            Id = $EventId
        } -MaxEvents 1 -ErrorAction SilentlyContinue

        if ($baseEvents) {
            $baseTime = $baseEvents[0].TimeCreated
            $startTime = $baseTime.AddMinutes(-$WindowMinutes)
            $endTime = $baseTime.AddMinutes($WindowMinutes)

            Get-WinEvent -FilterHashtable @{
                LogName = $LogName
                StartTime = $startTime
                EndTime = $endTime
            } -ErrorAction SilentlyContinue
        }
    }

    Write-Host "Event correlation example - find events near system startup:" -ForegroundColor Cyan
    Write-Host "  Find-CorrelatedEvents -EventId 6005 -WindowMinutes 5" -ForegroundColor White
    Write-Host ""

    Write-Host "[INFO] Event Log Best Practices:" -ForegroundColor Cyan
    Write-Host "  - Configure appropriate log sizes based on event volume" -ForegroundColor White
    Write-Host "  - Use event log forwarding for centralized collection" -ForegroundColor White
    Write-Host "  - Regularly backup critical event logs" -ForegroundColor White
    Write-Host "  - Set up alerts for critical events" -ForegroundColor White
    Write-Host "  - Use filtering to focus on relevant events" -ForegroundColor White
    Write-Host "  - Correlate events across multiple logs for troubleshooting" -ForegroundColor White
    Write-Host "  - Archive old logs for compliance and historical analysis" -ForegroundColor White
    Write-Host "  - Monitor log size to prevent disk space issues" -ForegroundColor White
    Write-Host ""

} catch {
    Write-Host "[ERROR] $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

Write-Host "Demo completed successfully!" -ForegroundColor Green
Write-Host "Next Steps: Configure event log forwarding and set up automated monitoring" -ForegroundColor Yellow
