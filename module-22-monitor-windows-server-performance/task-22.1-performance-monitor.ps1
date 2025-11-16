<#
.SYNOPSIS
    Task 22.1 - Use Performance Monitor

.DESCRIPTION
    Demo script for AZ-801 Module 22: Monitor Windows Server Performance
    Demonstrates Performance Monitor using Get-Counter, typeperf, and perfmon for
    real-time and historical performance analysis.

.NOTES
    Module: Module 22 - Monitor Windows Server Performance
    Task: 22.1 - Use Performance Monitor
    Prerequisites: Windows Server, Administrative privileges
    PowerShell Version: 5.1+
#>

#Requires -RunAsAdministrator

$ErrorActionPreference = 'Stop'
Write-Host "=== AZ-801 Module 22: Task 22.1 - Use Performance Monitor ===" -ForegroundColor Cyan
Write-Host ""

try {
    # Display available counter sets
    Write-Host "[Step 1] Display Available Performance Counter Sets" -ForegroundColor Yellow
    $counterSets = Get-Counter -ListSet * | Select-Object -First 10 CounterSetName, Description
    $counterSets | Format-Table -AutoSize
    Write-Host "Total counter sets available: $((Get-Counter -ListSet *).Count)" -ForegroundColor Cyan
    Write-Host ""

    # Get critical system counters
    Write-Host "[Step 2] Collect Critical System Performance Metrics" -ForegroundColor Yellow
    $criticalCounters = @(
        '\Processor(_Total)\% Processor Time'
        '\Memory\Available MBytes'
        '\Memory\% Committed Bytes In Use'
        '\PhysicalDisk(_Total)\% Disk Time'
        '\PhysicalDisk(_Total)\Avg. Disk Queue Length'
        '\PhysicalDisk(_Total)\Disk Reads/sec'
        '\PhysicalDisk(_Total)\Disk Writes/sec'
        '\Network Interface(*)\Bytes Total/sec'
        '\System\Processor Queue Length'
    )

    $perfData = Get-Counter -Counter $criticalCounters -SampleInterval 1 -MaxSamples 3

    foreach ($sample in $perfData) {
        Write-Host "Sample Time: $($sample.Timestamp)" -ForegroundColor Cyan
        foreach ($counter in $sample.CounterSamples) {
            $value = [math]::Round($counter.CookedValue, 2)
            Write-Host "  $($counter.Path): $value" -ForegroundColor White
        }
        Write-Host ""
    }

    # Analyze specific counter set in detail
    Write-Host "[Step 3] Analyze Processor Performance" -ForegroundColor Yellow
    $processorCounters = Get-Counter -ListSet Processor
    Write-Host "Counter Set: $($processorCounters.CounterSetName)" -ForegroundColor Cyan
    Write-Host "Description: $($processorCounters.Description)" -ForegroundColor White
    Write-Host "Available Counters: $($processorCounters.Counter.Count)" -ForegroundColor White

    # Get per-processor stats
    $cpuCounters = Get-Counter '\Processor(*)\% Processor Time'
    Write-Host "`nCurrent CPU Utilization:" -ForegroundColor Cyan
    foreach ($cpu in $cpuCounters.CounterSamples) {
        $value = [math]::Round($cpu.CookedValue, 2)
        $instance = $cpu.InstanceName
        Write-Host "  CPU $instance : $value%" -ForegroundColor White
    }
    Write-Host ""

    # Memory analysis
    Write-Host "[Step 4] Analyze Memory Performance" -ForegroundColor Yellow
    $memoryCounters = @(
        '\Memory\Available MBytes'
        '\Memory\Committed Bytes'
        '\Memory\Cache Bytes'
        '\Memory\Pool Nonpaged Bytes'
        '\Memory\Pool Paged Bytes'
        '\Memory\Pages/sec'
    )

    $memData = Get-Counter -Counter $memoryCounters
    Write-Host "Memory Performance Metrics:" -ForegroundColor Cyan
    foreach ($counter in $memData.CounterSamples) {
        $value = [math]::Round($counter.CookedValue, 2)
        $counterName = ($counter.Path -split '\\')[-1]
        Write-Host "  $counterName : $value" -ForegroundColor White
    }
    Write-Host ""

    # Disk performance
    Write-Host "[Step 5] Analyze Disk Performance" -ForegroundColor Yellow
    $diskCounters = @(
        '\PhysicalDisk(_Total)\% Disk Time'
        '\PhysicalDisk(_Total)\Avg. Disk sec/Read'
        '\PhysicalDisk(_Total)\Avg. Disk sec/Write'
        '\PhysicalDisk(_Total)\Current Disk Queue Length'
    )

    $diskData = Get-Counter -Counter $diskCounters
    Write-Host "Disk Performance Metrics:" -ForegroundColor Cyan
    foreach ($counter in $diskData.CounterSamples) {
        $value = [math]::Round($counter.CookedValue, 4)
        $counterName = ($counter.Path -split '\\')[-1]
        Write-Host "  $counterName : $value" -ForegroundColor White
    }
    Write-Host ""

    # Export performance data to file
    Write-Host "[Step 6] Export Performance Data to CSV" -ForegroundColor Yellow
    $exportPath = "C:\Logs\PerfMon-Export-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"

    if (-not (Test-Path "C:\Logs")) {
        New-Item -Path "C:\Logs" -ItemType Directory -Force | Out-Null
    }

    # Collect continuous samples and export
    Write-Host "Collecting 10 samples at 2-second intervals..." -ForegroundColor Cyan
    Get-Counter -Counter $criticalCounters -SampleInterval 2 -MaxSamples 10 |
        Export-Counter -Path $exportPath -FileFormat CSV -Force

    Write-Host "[SUCCESS] Performance data exported to: $exportPath" -ForegroundColor Green
    Write-Host ""

    # Using typeperf for command-line monitoring
    Write-Host "[Step 7] Demonstrate typeperf Command" -ForegroundColor Yellow
    $typeperfOutput = "C:\Logs\TypePerf-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"

    Write-Host "Starting typeperf collection (5 samples)..." -ForegroundColor Cyan
    $typeperfCmd = "typeperf `"\Processor(_Total)\% Processor Time`" `"\Memory\Available MBytes`" -sc 5 -si 1 -o `"$typeperfOutput`""
    Write-Host "Command: $typeperfCmd" -ForegroundColor White
    Invoke-Expression $typeperfCmd | Out-Null

    if (Test-Path $typeperfOutput) {
        Write-Host "[SUCCESS] Typeperf data saved to: $typeperfOutput" -ForegroundColor Green
        $content = Get-Content $typeperfOutput -TotalCount 5
        Write-Host "Sample output:" -ForegroundColor Cyan
        $content | ForEach-Object { Write-Host "  $_" -ForegroundColor White }
    }
    Write-Host ""

    # Create custom performance monitoring function
    Write-Host "[Step 8] Create Custom Performance Monitoring Function" -ForegroundColor Yellow

    function Get-SystemPerformanceSummary {
        param(
            [int]$Samples = 3,
            [int]$Interval = 2
        )

        $counters = @(
            '\Processor(_Total)\% Processor Time'
            '\Memory\Available MBytes'
            '\PhysicalDisk(_Total)\% Disk Time'
        )

        $results = @()

        for ($i = 1; $i -le $Samples; $i++) {
            $data = Get-Counter -Counter $counters
            $result = [PSCustomObject]@{
                Timestamp = $data.Timestamp
                CPU_Percent = [math]::Round(($data.CounterSamples | Where-Object Path -like '*Processor*').CookedValue, 2)
                Memory_Available_MB = [math]::Round(($data.CounterSamples | Where-Object Path -like '*Available MBytes*').CookedValue, 2)
                Disk_Percent = [math]::Round(($data.CounterSamples | Where-Object Path -like '*Disk Time*').CookedValue, 2)
            }
            $results += $result

            if ($i -lt $Samples) {
                Start-Sleep -Seconds $Interval
            }
        }

        return $results
    }

    $summary = Get-SystemPerformanceSummary -Samples 3 -Interval 1
    Write-Host "System Performance Summary:" -ForegroundColor Cyan
    $summary | Format-Table -AutoSize
    Write-Host ""

    # Performance baseline calculation
    Write-Host "[Step 9] Calculate Performance Baseline" -ForegroundColor Yellow
    $cpuAvg = ($summary | Measure-Object -Property CPU_Percent -Average).Average
    $memAvg = ($summary | Measure-Object -Property Memory_Available_MB -Average).Average
    $diskAvg = ($summary | Measure-Object -Property Disk_Percent -Average).Average

    Write-Host "Performance Baseline (Average):" -ForegroundColor Cyan
    Write-Host "  CPU Usage: $([math]::Round($cpuAvg, 2))%" -ForegroundColor White
    Write-Host "  Available Memory: $([math]::Round($memAvg, 2)) MB" -ForegroundColor White
    Write-Host "  Disk Usage: $([math]::Round($diskAvg, 2))%" -ForegroundColor White
    Write-Host ""

    # Performance thresholds and alerts
    Write-Host "[Step 10] Check Performance Thresholds" -ForegroundColor Yellow
    $thresholds = @{
        CPU_Warning = 80
        CPU_Critical = 95
        Memory_Warning = 500
        Memory_Critical = 200
        Disk_Warning = 80
        Disk_Critical = 95
    }

    Write-Host "Checking against thresholds:" -ForegroundColor Cyan

    if ($cpuAvg -gt $thresholds.CPU_Critical) {
        Write-Host "  [CRITICAL] CPU usage is critically high: $([math]::Round($cpuAvg, 2))%" -ForegroundColor Red
    } elseif ($cpuAvg -gt $thresholds.CPU_Warning) {
        Write-Host "  [WARNING] CPU usage is high: $([math]::Round($cpuAvg, 2))%" -ForegroundColor Yellow
    } else {
        Write-Host "  [OK] CPU usage is normal: $([math]::Round($cpuAvg, 2))%" -ForegroundColor Green
    }

    if ($memAvg -lt $thresholds.Memory_Critical) {
        Write-Host "  [CRITICAL] Available memory is critically low: $([math]::Round($memAvg, 2)) MB" -ForegroundColor Red
    } elseif ($memAvg -lt $thresholds.Memory_Warning) {
        Write-Host "  [WARNING] Available memory is low: $([math]::Round($memAvg, 2)) MB" -ForegroundColor Yellow
    } else {
        Write-Host "  [OK] Available memory is sufficient: $([math]::Round($memAvg, 2)) MB" -ForegroundColor Green
    }

    if ($diskAvg -gt $thresholds.Disk_Critical) {
        Write-Host "  [CRITICAL] Disk usage is critically high: $([math]::Round($diskAvg, 2))%" -ForegroundColor Red
    } elseif ($diskAvg -gt $thresholds.Disk_Warning) {
        Write-Host "  [WARNING] Disk usage is high: $([math]::Round($diskAvg, 2))%" -ForegroundColor Yellow
    } else {
        Write-Host "  [OK] Disk usage is normal: $([math]::Round($diskAvg, 2))%" -ForegroundColor Green
    }
    Write-Host ""

    # Launch Performance Monitor GUI
    Write-Host "[Step 11] Performance Monitor GUI Commands" -ForegroundColor Yellow
    Write-Host "To launch Performance Monitor GUI:" -ForegroundColor Cyan
    Write-Host "  perfmon.exe           - Full Performance Monitor" -ForegroundColor White
    Write-Host "  perfmon /res          - Resource Monitor" -ForegroundColor White
    Write-Host "  perfmon /rel          - Reliability Monitor" -ForegroundColor White
    Write-Host "  resmon.exe            - Resource Monitor directly" -ForegroundColor White
    Write-Host ""

    Write-Host "[INFO] Performance Monitoring Best Practices:" -ForegroundColor Cyan
    Write-Host "  - Establish baseline metrics during normal operations" -ForegroundColor White
    Write-Host "  - Monitor trends over time, not just snapshots" -ForegroundColor White
    Write-Host "  - Set appropriate thresholds for your workloads" -ForegroundColor White
    Write-Host "  - Use Data Collector Sets for automated collection" -ForegroundColor White
    Write-Host "  - Correlate performance with event logs" -ForegroundColor White
    Write-Host "  - Archive performance data for capacity planning" -ForegroundColor White
    Write-Host ""

} catch {
    Write-Host "[ERROR] $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

Write-Host "Demo completed successfully!" -ForegroundColor Green
Write-Host "Next Steps: Set up Data Collector Sets for continuous monitoring" -ForegroundColor Yellow
