<#
.SYNOPSIS
    AZ-801 Module 25 Task 1 - Troubleshoot Performance Issues

.DESCRIPTION
    This script demonstrates comprehensive performance troubleshooting for Windows Server.
    It covers Get-Counter for monitoring, Get-Process analysis, Resource Monitor techniques,
    performance methodology, and memory leak detection.

.NOTES
    Module: 25 - Troubleshoot Advanced Issues
    Task: 25.1 - Troubleshoot Performance Issues
    Exam: AZ-801 - Configuring Windows Server Hybrid Advanced Services
#>

#Requires -RunAsAdministrator

#region System Performance Overview

Write-Host "`n=== SYSTEM PERFORMANCE OVERVIEW ===" -ForegroundColor Cyan

$os = Get-CimInstance Win32_OperatingSystem
$cpu = Get-CimInstance Win32_Processor
$mem = Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum

Write-Host "`nSystem Information:" -ForegroundColor Green
Write-Host "  OS: $($os.Caption)" -ForegroundColor White
Write-Host "  Version: $($os.Version)" -ForegroundColor White
Write-Host "  CPU: $($cpu.Name)" -ForegroundColor White
Write-Host "  CPU Cores: $($cpu.NumberOfCores)" -ForegroundColor White
Write-Host "  Logical Processors: $($cpu.NumberOfLogicalProcessors)" -ForegroundColor White
Write-Host "  Total RAM: $([math]::Round($mem.Sum/1GB, 2)) GB" -ForegroundColor White
Write-Host "  Last Boot: $($os.LastBootUpTime)" -ForegroundColor White

#endregion

#region CPU Performance

Write-Host "`n`n=== CPU PERFORMANCE ANALYSIS ===" -ForegroundColor Cyan

Write-Host "`nCurrent CPU Usage:" -ForegroundColor Green
$cpuCounter = Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 1 -MaxSamples 5
$avgCPU = ($cpuCounter.CounterSamples | Measure-Object -Property CookedValue -Average).Average

Write-Host "  Average CPU: $([math]::Round($avgCPU, 2))%" -ForegroundColor $(
    if ($avgCPU -gt 80) {'Red'} elseif ($avgCPU -gt 50) {'Yellow'} else {'Green'}
)

Write-Host "`nTop 10 Processes by CPU:" -ForegroundColor Green
Get-Process | Sort-Object CPU -Descending | Select-Object -First 10 Name, CPU, 
    @{Name='CPUTime';Expression={[math]::Round($_.CPU, 2)}},
    @{Name='Memory(MB)';Expression={[math]::Round($_.WorkingSet64/1MB, 2)}} |
    Format-Table -AutoSize

#endregion

#region Memory Performance

Write-Host "`n=== MEMORY PERFORMANCE ANALYSIS ===" -ForegroundColor Cyan

Write-Host "`nMemory Statistics:" -ForegroundColor Green
$memAvailable = Get-Counter '\Memory\Available MBytes'
$memCommitted = Get-Counter '\Memory\Committed Bytes'
$memoryUsagePercent = (1 - ($memAvailable.CounterSamples[0].CookedValue / ($mem.Sum/1MB))) * 100

Write-Host "  Total Physical Memory: $([math]::Round($mem.Sum/1GB, 2)) GB" -ForegroundColor White
Write-Host "  Available Memory: $([math]::Round($memAvailable.CounterSamples[0].CookedValue/1KB, 2)) GB" -ForegroundColor White
Write-Host "  Memory Usage: $([math]::Round($memoryUsagePercent, 2))%" -ForegroundColor $(
    if ($memoryUsagePercent -gt 90) {'Red'} elseif ($memoryUsagePercent -gt 75) {'Yellow'} else {'Green'}
)

Write-Host "`nTop 10 Processes by Memory:" -ForegroundColor Green
Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 10 Name,
    @{Name='Memory(MB)';Expression={[math]::Round($_.WorkingSet64/1MB, 2)}},
    @{Name='PeakMemory(MB)';Expression={[math]::Round($_.PeakWorkingSet64/1MB, 2)}},
    Handles |
    Format-Table -AutoSize

#endregion

#region Disk Performance

Write-Host "`n=== DISK PERFORMANCE ANALYSIS ===" -ForegroundColor Cyan

Write-Host "`nLogical Disk Statistics:" -ForegroundColor Green
Get-Volume | Where-Object {$_.DriveLetter} | ForEach-Object {
    $drive = $_.DriveLetter
    Write-Host "`nDrive $($drive):" -ForegroundColor White
    Write-Host "  Size: $([math]::Round($_.Size/1GB, 2)) GB" -ForegroundColor Gray
    Write-Host "  Free: $([math]::Round($_.SizeRemaining/1GB, 2)) GB" -ForegroundColor Gray
    Write-Host "  Used: $([math]::Round(($_.Size - $_.SizeRemaining)/$_.Size * 100, 2))%" -ForegroundColor $(
        if ((($_.Size - $_.SizeRemaining)/$_.Size) -gt 0.9) {'Red'} 
        elseif ((($_.Size - $_.SizeRemaining)/$_.Size) -gt 0.75) {'Yellow'} 
        else {'Green'}
    )
}

Write-Host "`nDisk I/O Performance:" -ForegroundColor Green
$diskCounters = Get-Counter '\PhysicalDisk(*)\*' | Select-Object -ExpandProperty CounterSamples |
    Where-Object {$_.Path -like '*_Total*'} | Select-Object -First 5
$diskCounters | Format-Table Path, CookedValue -AutoSize

#endregion

#region Network Performance

Write-Host "`n=== NETWORK PERFORMANCE ANALYSIS ===" -ForegroundColor Cyan

Write-Host "`nNetwork Adapter Statistics:" -ForegroundColor Green
Get-NetAdapter | Where-Object {$_.Status -eq 'Up'} | ForEach-Object {
    Write-Host "`nAdapter: $($_.Name)" -ForegroundColor White
    Write-Host "  Status: $($_.Status)" -ForegroundColor Green
    Write-Host "  Link Speed: $($_.LinkSpeed)" -ForegroundColor White

    $stats = Get-NetAdapterStatistics -Name $_.Name
    Write-Host "  Received: $([math]::Round($stats.ReceivedBytes/1MB, 2)) MB" -ForegroundColor Gray
    Write-Host "  Sent: $([math]::Round($stats.SentBytes/1MB, 2)) MB" -ForegroundColor Gray
}

#endregion

#region Performance Monitoring Commands

Write-Host "`n`n=== PERFORMANCE MONITORING COMMANDS ===" -ForegroundColor Cyan

$perfCommands = @"

Performance Counter Examples:

CPU MONITORING:
- Current CPU: Get-Counter '\Processor(_Total)\% Processor Time'
- Per-core: Get-Counter '\Processor(*)\% Processor Time'
- Queue length: Get-Counter '\System\Processor Queue Length'

MEMORY MONITORING:
- Available: Get-Counter '\Memory\Available MBytes'
- Pages/sec: Get-Counter '\Memory\Pages/sec'
- Committed: Get-Counter '\Memory\% Committed Bytes In Use'

DISK MONITORING:
- Disk time: Get-Counter '\PhysicalDisk(*)\% Disk Time'
- Queue: Get-Counter '\PhysicalDisk(*)\Avg. Disk Queue Length'
- Transfers: Get-Counter '\PhysicalDisk(*)\Disk Transfers/sec'

NETWORK MONITORING:
- Bytes/sec: Get-Counter '\Network Interface(*)\Bytes Total/sec'
- Current bandwidth: Get-Counter '\Network Interface(*)\Current Bandwidth'

CONTINUOUS MONITORING:
Get-Counter -Counter @(
    '\Processor(_Total)\% Processor Time',
    '\Memory\Available MBytes',
    '\PhysicalDisk(_Total)\% Disk Time',
    '\Network Interface(*)\Bytes Total/sec'
) -SampleInterval 5 -MaxSamples 60

TROUBLESHOOTING:
- High CPU: Get-Process | Sort CPU -Desc | Select -First 20
- Memory leaks: Get-Process | Sort WS -Desc | Select Name, WS, PM
- Handle leaks: Get-Process | Sort Handles -Desc | Select Name, Handles
- Thread count: Get-Process | Sort Threads -Desc | Select Name, Threads

"@

Write-Host $perfCommands -ForegroundColor White

#endregion

#region Resource Monitor Techniques

Write-Host "`n=== RESOURCE MONITOR TECHNIQUES ===" -ForegroundColor Cyan

$resmonGuide = @"

Resource Monitor (resmon.exe) Analysis:

CPU TAB:
- Identify processes consuming CPU cycles
- Check: Average CPU percentage
- Look for: Sustained high CPU (>80% for extended periods)
- Check: Services vs Applications

MEMORY TAB:
- Working Set: Currently used RAM
- Commit: Reserved memory (can exceed physical)
- Hard Faults: Memory paging to disk (should be minimal)
- Check for: Memory leaks (constantly growing working set)

DISK TAB:
- Disk Activity: Which processes are reading/writing
- Response Time: Should be <20ms typically
- Queue Length: Should be <2 typically
- Check for: High queue length = disk bottleneck

NETWORK TAB:
- Active Connections: Which processes using network
- Bytes Sent/Received
- Check for: Unexpected network activity
- TCP Connections: Look for unusual connections

PowerShell Equivalents:
- CPU intensive: Get-Process | Where {$_.CPU -gt 100} | Sort CPU -Desc
- Memory intensive: Get-Process | Where {$_.WS -gt 500MB} | Sort WS -Desc
- Disk activity: Get-Counter '\Process(*)\IO Data Bytes/sec' | Select -Expand CounterSamples | Sort CookedValue -Desc
- Network: Get-NetTCPConnection | Group-Object State | Select Name, Count

"@

Write-Host $resmonGuide -ForegroundColor White

#endregion

#region Memory Leak Detection

Write-Host "`n=== MEMORY LEAK DETECTION ===" -ForegroundColor Cyan

$memLeakGuide = @"

Memory Leak Detection Methodology:

1. IDENTIFY GROWING PROCESSES:
   # Monitor over time
   $process = "processname"
   while ($true) {
       $p = Get-Process $process
       "$((Get-Date).ToString('HH:mm:ss')) - WS: $([math]::Round($p.WS/1MB,2))MB, PM: $([math]::Round($p.PM/1MB,2))MB"
       Start-Sleep 60
   }

2. CHECK HANDLE LEAKS:
   Get-Process | Sort-Object Handles -Descending | Select-Object -First 20 Name, Handles, WS

3. MONITOR SPECIFIC PROCESS:
   Get-Counter "\Process(processname)\*" -Continuous

4. USE PERFORMANCE MONITOR:
   - perfmon.msc
   - Add: Process\Private Bytes
   - Add: Process\Handle Count
   - Add: Process\Thread Count
   - Monitor: Look for continuous growth

5. ANALYZE WITH PROCDUMP:
   - Download Sysinternals ProcDump
   - procdump -ma processname.exe crash.dmp
   - Analyze with WinDbg

SIGNS OF MEMORY LEAK:
- Working Set constantly growing
- Private Bytes increasing
- Handles increasing
- Performance degrades over time
- Requires periodic restart

MITIGATION:
- Restart service/application regularly
- Apply patches/updates
- Contact vendor
- Set memory limits if possible

"@

Write-Host $memLeakGuide -ForegroundColor White

#endregion

#region Troubleshooting Methodology

Write-Host "`n=== PERFORMANCE TROUBLESHOOTING METHODOLOGY ===" -ForegroundColor Cyan

$methodology = @"

Systematic Performance Troubleshooting:

STEP 1 - IDENTIFY THE BOTTLENECK:
- CPU: >80% sustained = CPU bottleneck
- Memory: <10% available = Memory bottleneck
- Disk: >20ms response time or >2 queue length = Disk bottleneck
- Network: Dropped packets or high utilization = Network bottleneck

STEP 2 - COLLECT BASELINE:
- Use Performance Monitor to create baseline
- Capture during normal operations
- Compare against problem state

STEP 3 - ANALYZE PROCESSES:
- Top CPU consumers: Get-Process | Sort CPU -Desc
- Top memory: Get-Process | Sort WS -Desc  
- Top handles: Get-Process | Sort Handles -Desc
- Top threads: Get-Process | Sort Threads -Desc

STEP 4 - CHECK SYSTEM RESOURCES:
- Disk space: Get-Volume
- Page file usage: Get-CimInstance Win32_PageFileUsage
- Services: Get-Service | Where Status -eq Running

STEP 5 - REVIEW EVENT LOGS:
- System log: Get-WinEvent -LogName System -MaxEvents 50
- Application: Get-WinEvent -LogName Application -MaxEvents 50
- Look for: Errors, warnings related to performance

STEP 6 - TEST AND VALIDATE:
- Apply fix (update, config change, add resources)
- Monitor performance
- Validate improvement
- Document changes

COMMON FIXES:
- CPU: Upgrade hardware, optimize code, limit processes
- Memory: Add RAM, fix memory leaks, adjust page file
- Disk: Faster disks (SSD), RAID, cleanup
- Network: Better NIC, check switches, optimize traffic

"@

Write-Host $methodology -ForegroundColor White

#endregion

Write-Host "`n=== PERFORMANCE TROUBLESHOOTING COMPLETE ===" -ForegroundColor Green
Write-Host "Use Resource Monitor (resmon.exe) and Performance Monitor (perfmon.msc) for detailed analysis`n" -ForegroundColor Yellow
