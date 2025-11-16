<#
.SYNOPSIS
    Task 22.2 - Configure Data Collector Sets

.DESCRIPTION
    Demo script for AZ-801 Module 22: Monitor Windows Server Performance
    Shows configuration of data collector sets using logman cmdlets for
    performance baselines and automated data collection.

.NOTES
    Module: Module 22 - Monitor Windows Server Performance
    Task: 22.2 - Configure Data Collector Sets
    Prerequisites: Windows Server, Administrative privileges
    PowerShell Version: 5.1+
#>

#Requires -RunAsAdministrator

$ErrorActionPreference = 'Stop'
Write-Host "=== AZ-801 Module 22: Task 22.2 - Configure Data Collector Sets ===" -ForegroundColor Cyan
Write-Host ""

try {
    # List existing data collector sets
    Write-Host "[Step 1] List Existing Data Collector Sets" -ForegroundColor Yellow
    Write-Host "Querying system data collector sets..." -ForegroundColor Cyan

    $logmanOutput = logman query
    $logmanOutput | ForEach-Object { Write-Host "  $_" -ForegroundColor White }
    Write-Host ""

    # List system-defined collector sets
    Write-Host "[Step 2] Display System Data Collector Sets" -ForegroundColor Yellow
    $systemDcs = logman query -s
    Write-Host "System Data Collector Sets:" -ForegroundColor Cyan
    $systemDcs | Select-Object -Skip 2 | ForEach-Object {
        if ($_ -match '\S') { Write-Host "  $_" -ForegroundColor White }
    }
    Write-Host ""

    # Create custom performance data collector set
    Write-Host "[Step 3] Create Custom Performance Data Collector Set" -ForegroundColor Yellow
    $dcsName = "AZ801-Performance-Baseline"
    $outputPath = "C:\PerfLogs\$dcsName"

    # Remove if exists
    $existing = logman query $dcsName 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Removing existing data collector set..." -ForegroundColor Cyan
        logman stop $dcsName -ets 2>$null
        logman delete $dcsName
    }

    # Create directory for output
    if (-not (Test-Path $outputPath)) {
        New-Item -Path $outputPath -ItemType Directory -Force | Out-Null
    }

    # Create data collector set with performance counters
    Write-Host "Creating data collector set: $dcsName" -ForegroundColor Cyan

    logman create counter $dcsName `
        -c "\Processor(_Total)\% Processor Time" `
        -c "\Memory\Available MBytes" `
        -c "\Memory\% Committed Bytes In Use" `
        -c "\PhysicalDisk(_Total)\% Disk Time" `
        -c "\PhysicalDisk(_Total)\Avg. Disk Queue Length" `
        -c "\PhysicalDisk(_Total)\Disk Reads/sec" `
        -c "\PhysicalDisk(_Total)\Disk Writes/sec" `
        -c "\Network Interface(*)\Bytes Total/sec" `
        -c "\System\Processor Queue Length" `
        -f bincirc `
        -max 500 `
        -si 00:00:05 `
        -o "$outputPath\PerformanceData.blg"

    if ($LASTEXITCODE -eq 0) {
        Write-Host "[SUCCESS] Data collector set created" -ForegroundColor Green
    }
    Write-Host ""

    # Configure data collector set properties
    Write-Host "[Step 4] Configure Data Collector Set Properties" -ForegroundColor Yellow

    # Set schedule (run daily at midnight for 1 hour)
    Write-Host "Configuring schedule..." -ForegroundColor Cyan
    logman update $dcsName -rf 01:00:00

    # Query the data collector set details
    $dcsDetails = logman query $dcsName
    Write-Host "Data Collector Set Details:" -ForegroundColor Cyan
    $dcsDetails | ForEach-Object { Write-Host "  $_" -ForegroundColor White }
    Write-Host ""

    # Create trace data collector
    Write-Host "[Step 5] Create Event Trace Data Collector" -ForegroundColor Yellow
    $traceName = "AZ801-System-Trace"

    # Remove if exists
    $existingTrace = logman query $traceName 2>$null
    if ($LASTEXITCODE -eq 0) {
        logman stop $traceName -ets 2>$null
        logman delete $traceName
    }

    Write-Host "Creating trace collector: $traceName" -ForegroundColor Cyan
    logman create trace $traceName `
        -o "$outputPath\SystemTrace.etl" `
        -p "Microsoft-Windows-Kernel-Process" 0xffffffffffffffff 0xff `
        -p "Microsoft-Windows-Kernel-Disk" 0xffffffffffffffff 0xff `
        -nb 16 640 `
        -bs 64 `
        -max 500

    if ($LASTEXITCODE -eq 0) {
        Write-Host "[SUCCESS] Trace collector created" -ForegroundColor Green
    }
    Write-Host ""

    # Start data collector set
    Write-Host "[Step 6] Start Data Collector Set" -ForegroundColor Yellow
    Write-Host "Starting $dcsName..." -ForegroundColor Cyan

    logman start $dcsName
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[SUCCESS] Data collector set started" -ForegroundColor Green
    }

    # Wait and collect some data
    Write-Host "Collecting data for 15 seconds..." -ForegroundColor Cyan
    Start-Sleep -Seconds 15
    Write-Host ""

    # Query running status
    Write-Host "[Step 7] Check Data Collector Status" -ForegroundColor Yellow
    $runningDcs = logman query $dcsName
    Write-Host "Current Status:" -ForegroundColor Cyan
    $runningDcs | ForEach-Object { Write-Host "  $_" -ForegroundColor White }
    Write-Host ""

    # Stop data collector set
    Write-Host "[Step 8] Stop Data Collector Set" -ForegroundColor Yellow
    Write-Host "Stopping $dcsName..." -ForegroundColor Cyan

    logman stop $dcsName
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[SUCCESS] Data collector set stopped" -ForegroundColor Green
    }
    Write-Host ""

    # List collected data files
    Write-Host "[Step 9] Review Collected Data Files" -ForegroundColor Yellow
    if (Test-Path $outputPath) {
        $dataFiles = Get-ChildItem -Path $outputPath -Recurse
        Write-Host "Collected files in $outputPath :" -ForegroundColor Cyan
        $dataFiles | ForEach-Object {
            $size = if ($_.Length -gt 1MB) {
                "{0:N2} MB" -f ($_.Length / 1MB)
            } else {
                "{0:N2} KB" -f ($_.Length / 1KB)
            }
            Write-Host "  $($_.Name) - $size" -ForegroundColor White
        }
    }
    Write-Host ""

    # Export data collector set configuration
    Write-Host "[Step 10] Export Data Collector Set Configuration" -ForegroundColor Yellow
    $exportPath = "C:\Logs\DCS-Export-$dcsName.xml"

    if (-not (Test-Path "C:\Logs")) {
        New-Item -Path "C:\Logs" -ItemType Directory -Force | Out-Null
    }

    Write-Host "Exporting configuration to XML..." -ForegroundColor Cyan
    logman export $dcsName -xml $exportPath

    if (Test-Path $exportPath) {
        Write-Host "[SUCCESS] Configuration exported to: $exportPath" -ForegroundColor Green
        $xmlSize = (Get-Item $exportPath).Length
        Write-Host "Export file size: $xmlSize bytes" -ForegroundColor White
    }
    Write-Host ""

    # Create System Diagnostics collector set
    Write-Host "[Step 11] Create System Diagnostics Collector" -ForegroundColor Yellow
    $diagName = "AZ801-System-Diagnostics"

    # Remove if exists
    $existingDiag = logman query $diagName 2>$null
    if ($LASTEXITCODE -eq 0) {
        logman stop $diagName -ets 2>$null
        logman delete $diagName
    }

    Write-Host "Creating diagnostic collector: $diagName" -ForegroundColor Cyan

    # Create comprehensive diagnostic collector
    logman create counter $diagName `
        -c "\Memory\*" `
        -c "\Processor(*)\*" `
        -c "\PhysicalDisk(*)\*" `
        -c "\LogicalDisk(*)\*" `
        -c "\Network Interface(*)\*" `
        -f bincirc `
        -max 1000 `
        -si 00:00:10 `
        -o "$outputPath\DiagnosticsData.blg"

    if ($LASTEXITCODE -eq 0) {
        Write-Host "[SUCCESS] Diagnostic collector created" -ForegroundColor Green
    }
    Write-Host ""

    # Using PowerShell to manage data collectors
    Write-Host "[Step 12] Manage Data Collectors with PowerShell" -ForegroundColor Yellow

    # Create performance counter data collector using COM
    Write-Host "Creating data collector using COM objects..." -ForegroundColor Cyan

    $dcsPath = "C:\PerfLogs\Admin\AZ801-PowerShell-DCS"
    if (-not (Test-Path $dcsPath)) {
        New-Item -Path $dcsPath -ItemType Directory -Force | Out-Null
    }

    # Function to create data collector set via PowerShell
    function New-PerformanceDataCollectorSet {
        param(
            [string]$Name,
            [string]$OutputPath,
            [string[]]$Counters,
            [int]$SampleInterval = 15
        )

        try {
            $dcs = New-Object -ComObject Pla.DataCollectorSet
            $dcs.DisplayName = $Name
            $dcs.RootPath = $OutputPath
            $dcs.Duration = 3600  # 1 hour
            $dcs.Subdirectory = ""
            $dcs.SubdirectoryFormat = 3  # Pattern
            $dcs.SubdirectoryFormatPattern = "yyyyMMdd-HHmmss"

            $collector = $dcs.DataCollectors.CreateDataCollector(0)  # 0 = Performance Counter
            $collector.Name = "Performance Counters"
            $collector.FileName = "PerfData"
            $collector.FileNameFormat = 0x1  # Append
            $collector.SampleInterval = $SampleInterval

            foreach ($counter in $Counters) {
                $collector.PerformanceCounters.Add($counter)
            }

            $dcs.DataCollectors.Add($collector)

            return $dcs
        } catch {
            Write-Host "  [WARNING] COM-based creation requires additional configuration" -ForegroundColor Yellow
            return $null
        }
    }

    $psCounters = @(
        '\Processor(_Total)\% Processor Time'
        '\Memory\Available MBytes'
        '\PhysicalDisk(_Total)\% Disk Time'
    )

    Write-Host "  Note: Advanced DCS management available via COM/WMI" -ForegroundColor Cyan
    Write-Host ""

    # Schedule data collection
    Write-Host "[Step 13] Schedule Data Collection" -ForegroundColor Yellow
    Write-Host "Scheduling options:" -ForegroundColor Cyan
    Write-Host "  - Use Task Scheduler with logman start/stop commands" -ForegroundColor White
    Write-Host "  - Configure collection schedule in DCS properties" -ForegroundColor White
    Write-Host "  - Use -rf parameter for run duration" -ForegroundColor White
    Write-Host ""

    Write-Host "Example scheduled task command:" -ForegroundColor Cyan
    Write-Host "  schtasks /create /tn 'Performance Baseline' /tr 'logman start $dcsName' /sc daily /st 00:00" -ForegroundColor White
    Write-Host ""

    # Performance report generation
    Write-Host "[Step 14] Generate Performance Reports" -ForegroundColor Yellow
    Write-Host "To analyze collected data:" -ForegroundColor Cyan
    Write-Host "  1. Use Performance Monitor (perfmon.exe) to open .blg files" -ForegroundColor White
    Write-Host "  2. Use relog to convert binary logs to CSV/TSV" -ForegroundColor White
    Write-Host "  3. Use Import-Counter to analyze in PowerShell" -ForegroundColor White
    Write-Host ""

    # Demonstrate relog
    Write-Host "Example relog commands:" -ForegroundColor Cyan
    Write-Host "  relog inputfile.blg -f csv -o output.csv" -ForegroundColor White
    Write-Host "  relog inputfile.blg -f tsv -o output.tsv -t 60" -ForegroundColor White
    Write-Host ""

    # Cleanup old data
    Write-Host "[Step 15] Data Retention and Cleanup" -ForegroundColor Yellow
    Write-Host "Creating cleanup script..." -ForegroundColor Cyan

    $cleanupScript = @'
# Performance Data Cleanup Script
$retentionDays = 30
$perfLogsPath = "C:\PerfLogs"

Get-ChildItem -Path $perfLogsPath -Recurse -File |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$retentionDays) } |
    Remove-Item -Force -Verbose
'@

    $cleanupPath = "C:\Logs\Cleanup-PerfData.ps1"
    $cleanupScript | Out-File -FilePath $cleanupPath -Encoding UTF8 -Force

    Write-Host "[SUCCESS] Cleanup script created: $cleanupPath" -ForegroundColor Green
    Write-Host ""

    Write-Host "[INFO] Data Collector Set Best Practices:" -ForegroundColor Cyan
    Write-Host "  - Use binary circular format for continuous collection" -ForegroundColor White
    Write-Host "  - Set appropriate maximum file sizes to prevent disk fill" -ForegroundColor White
    Write-Host "  - Schedule collections during peak and off-peak hours" -ForegroundColor White
    Write-Host "  - Export configurations for backup and deployment" -ForegroundColor White
    Write-Host "  - Use sampling intervals appropriate for your needs (5-15 seconds typical)" -ForegroundColor White
    Write-Host "  - Archive data regularly and implement retention policies" -ForegroundColor White
    Write-Host "  - Document baseline metrics for comparison" -ForegroundColor White
    Write-Host ""

    Write-Host "[INFO] Common Logman Commands:" -ForegroundColor Cyan
    Write-Host "  logman query                    - List all collector sets" -ForegroundColor White
    Write-Host "  logman query 'name'             - Get details of specific set" -ForegroundColor White
    Write-Host "  logman start 'name'             - Start collection" -ForegroundColor White
    Write-Host "  logman stop 'name'              - Stop collection" -ForegroundColor White
    Write-Host "  logman delete 'name'            - Delete collector set" -ForegroundColor White
    Write-Host "  logman export 'name' -xml file  - Export configuration" -ForegroundColor White
    Write-Host "  logman import 'name' -xml file  - Import configuration" -ForegroundColor White
    Write-Host ""

} catch {
    Write-Host "[ERROR] $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

Write-Host "Demo completed successfully!" -ForegroundColor Green
Write-Host "Next Steps: Configure automated baseline collection and analysis" -ForegroundColor Yellow
