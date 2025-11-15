#requires -Version 5.1
#requires -RunAsAdministrator

<#
.SYNOPSIS
    AZ-801 Lesson 22: Monitor Windows Server Performance - Live Demo Script
.DESCRIPTION
    Demonstrates Performance Monitor, Data Collector Sets, System Insights, and Event Viewer
    on dc01.corp.techtrainertim.com with click-by-click GUI paths and PowerShell commands
    Includes artificial load generation for realistic performance monitoring

    Runtime: ~12 minutes with narration
    Prerequisites: Windows Server 2019+ for System Insights, DNS Server role for demo events
.NOTES
    Author: Tim Warner
    Course: AZ-801 Configuring Windows Server Hybrid Advanced Services 2E
    Tested: PowerShell 5.1 on Windows Server 2025
#>

#region Setup and Introduction
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "AZ-801 Lesson 22: Performance Monitoring Demo" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Pause between sections for narration
function Pause-Demo {
  Write-Host ""
  Write-Host "Press any key to continue..." -ForegroundColor Yellow
  $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
  Write-Host ""
}

# Function to generate CPU load
function Start-CPULoad {
  param([int]$DurationSeconds = 30)

  Write-Host "Generating artificial CPU load for $DurationSeconds seconds..." -ForegroundColor Yellow

  $job = Start-Job -ScriptBlock {
    param($Duration)
    $endTime = (Get-Date).AddSeconds($Duration)
    while ((Get-Date) -lt $endTime) {
      $result = 1..1000 | ForEach-Object { Get-Random } | Measure-Object -Sum
    }
  } -ArgumentList $DurationSeconds

  return $job
}

# Function to generate memory pressure
function Start-MemoryLoad {
  param([int]$SizeMB = 500)

  Write-Host "Allocating $SizeMB MB of memory for demonstration..." -ForegroundColor Yellow

  $script:memoryArray = New-Object byte[] ($SizeMB * 1MB)
  [System.GC]::Collect()

  Write-Host "Memory allocated. Will be released at end of demo." -ForegroundColor Green
}

# Function to generate disk I/O
function Start-DiskLoad {
  param([int]$DurationSeconds = 20)

  Write-Host "Generating disk I/O load for $DurationSeconds seconds..." -ForegroundColor Yellow

  $job = Start-Job -ScriptBlock {
    param($Duration)
    $endTime = (Get-Date).AddSeconds($Duration)
    $tempFile = "$env:TEMP\perftest_$(Get-Random).tmp"

    while ((Get-Date) -lt $endTime) {
      # Write 10MB chunks
      $data = New-Object byte[] (10MB)
      [System.IO.File]::WriteAllBytes($tempFile, $data)
      $null = Get-Content $tempFile -Raw
    }

    Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
  } -ArgumentList $DurationSeconds

  return $job
}
#endregion

#region 22.1 - Performance Monitor Basics
Write-Host "=== 22.1 Performance Monitor: Real-Time Monitoring ===" -ForegroundColor Green
Write-Host ""

Write-Host "[GUI Demo] Opening Performance Monitor..." -ForegroundColor Cyan
Write-Host "Click: Start > Run > perfmon.msc > OK" -ForegroundColor Yellow
Write-Host "(Demo paused for GUI interaction)" -ForegroundColor DarkGray
Write-Host ""

# Get baseline performance before load
Write-Host "[PowerShell] Getting baseline system performance..." -ForegroundColor Cyan
$BaselineCPU = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples.CookedValue
$BaselineMemory = (Get-Counter '\Memory\Available MBytes').CounterSamples.CookedValue
$BaselineDiskQueue = (Get-Counter '\PhysicalDisk(_Total)\Avg. Disk Queue Length').CounterSamples.CookedValue

Write-Host ""
Write-Host "Baseline Performance Metrics:" -ForegroundColor Green
Write-Host "  CPU Usage: $([math]::Round($BaselineCPU, 2))%" -ForegroundColor White
Write-Host "  Available Memory: $([math]::Round($BaselineMemory, 2)) MB" -ForegroundColor White
Write-Host "  Disk Queue Length: $([math]::Round($BaselineDiskQueue, 4))" -ForegroundColor White

# Generate artificial load
Write-Host ""
Write-Host "[Demo] Generating artificial workload for monitoring..." -ForegroundColor Cyan
$cpuJob = Start-CPULoad -DurationSeconds 20
$diskJob = Start-DiskLoad -DurationSeconds 20

Write-Host ""
Write-Host "Workload running... wait 5 seconds for metrics to show impact..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# Get performance during load
Write-Host ""
Write-Host "[PowerShell] Getting performance during artificial load..." -ForegroundColor Cyan
$LoadCPU = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples.CookedValue
$LoadMemory = (Get-Counter '\Memory\Available MBytes').CounterSamples.CookedValue
$LoadDiskQueue = (Get-Counter '\PhysicalDisk(_Total)\Avg. Disk Queue Length').CounterSamples.CookedValue
$NetworkBytes = (Get-Counter '\Network Interface(*)\Bytes Total/sec').CounterSamples.CookedValue | Measure-Object -Sum | Select-Object -ExpandProperty Sum

Write-Host ""
Write-Host "Performance Under Load:" -ForegroundColor Yellow
Write-Host "  CPU Usage: $([math]::Round($LoadCPU, 2))% (was $([math]::Round($BaselineCPU, 2))%)" -ForegroundColor White
Write-Host "  Available Memory: $([math]::Round($LoadMemory, 2)) MB" -ForegroundColor White
Write-Host "  Disk Queue Length: $([math]::Round($LoadDiskQueue, 4)) (was $([math]::Round($BaselineDiskQueue, 4)))" -ForegroundColor White
Write-Host "  Network Throughput: $([math]::Round($NetworkBytes / 1MB, 2)) MB/sec" -ForegroundColor White

# Cleanup background jobs
Write-Host ""
Write-Host "Stopping artificial workload..." -ForegroundColor Cyan
Stop-Job -Job $cpuJob -ErrorAction SilentlyContinue
Stop-Job -Job $diskJob -ErrorAction SilentlyContinue
Remove-Job -Job $cpuJob -Force -ErrorAction SilentlyContinue
Remove-Job -Job $diskJob -Force -ErrorAction SilentlyContinue
Write-Host "Workload stopped." -ForegroundColor Green

Write-Host ""
Write-Host "[GUI Demo] Adding custom performance counters..." -ForegroundColor Cyan
Write-Host "In Performance Monitor window:" -ForegroundColor Yellow
Write-Host "  1. Expand Monitoring Tools > Performance Monitor" -ForegroundColor Yellow
Write-Host "  2. Click green plus icon (Add Counters)" -ForegroundColor Yellow
Write-Host "  3. Add these counters:" -ForegroundColor Yellow
Write-Host "     - Processor(_Total) > % Processor Time" -ForegroundColor White
Write-Host "     - Memory > Available MBytes" -ForegroundColor White
Write-Host "     - PhysicalDisk(_Total) > Avg. Disk Queue Length" -ForegroundColor White
Write-Host "     - Network Interface(*) > Bytes Total/sec" -ForegroundColor White
Write-Host "  4. Click Add > OK" -ForegroundColor Yellow
Write-Host "  5. Observe real-time graph updating every second" -ForegroundColor Yellow
Write-Host "  6. Generate load again to see graph response" -ForegroundColor Yellow

Write-Host ""
Write-Host "EXAM TIP: CPU > 80% sustained = pressure. Disk Queue > 2/spindle = I/O bottleneck. Memory < 10% available = memory pressure" -ForegroundColor Yellow

Pause-Demo
#endregion

#region 22.2 - Data Collector Sets
Write-Host "=== 22.2 Data Collector Sets: Automated Collection ===" -ForegroundColor Green
Write-Host ""

Write-Host "[GUI Demo] Creating custom Data Collector Set..." -ForegroundColor Cyan
Write-Host "In Performance Monitor window:" -ForegroundColor Yellow
Write-Host "  1. Expand Data Collector Sets > User Defined" -ForegroundColor Yellow
Write-Host "  2. Right-click User Defined > New > Data Collector Set" -ForegroundColor Yellow
Write-Host "  3. Name: 'AZ-801-Performance-Baseline'" -ForegroundColor Yellow
Write-Host "  4. Select 'Create manually (Advanced)' > Next" -ForegroundColor Yellow
Write-Host "  5. Check 'Performance counter' > Next" -ForegroundColor Yellow
Write-Host "  6. Sample interval: 15 seconds > Next" -ForegroundColor Yellow
Write-Host "  7. Add counters:" -ForegroundColor Yellow
Write-Host "     - Processor(_Total) > % Processor Time" -ForegroundColor White
Write-Host "     - Memory > Available MBytes" -ForegroundColor White
Write-Host "     - PhysicalDisk(_Total) > % Disk Time" -ForegroundColor White
Write-Host "     - System > Processor Queue Length" -ForegroundColor White
Write-Host "  8. Next > Save and Close" -ForegroundColor Yellow

Write-Host ""
Write-Host "[GUI Demo] Configuring Data Collector Set schedule..." -ForegroundColor Cyan
Write-Host "  1. Right-click 'AZ-801-Performance-Baseline' > Properties" -ForegroundColor Yellow
Write-Host "  2. Go to Schedule tab > Click Add" -ForegroundColor Yellow
Write-Host "  3. Set Beginning date: Today" -ForegroundColor Yellow
Write-Host "  4. Set Start time: 01:00:00 (1 AM)" -ForegroundColor Yellow
Write-Host "  5. Check 'Expire after' and set to 7 days from today" -ForegroundColor Yellow
Write-Host "  6. Go to Stop Condition tab" -ForegroundColor Yellow
Write-Host "  7. Set 'Overall duration': 1 hour" -ForegroundColor Yellow
Write-Host "  8. Click OK" -ForegroundColor Yellow

# Start Data Collector Set via PowerShell for demo
Write-Host ""
Write-Host "[PowerShell] Starting Data Collector Set for demo collection..." -ForegroundColor Cyan
$DCSName = "System Performance"  # Using built-in DCS for demo

Write-Host "Starting '$DCSName' Data Collector Set..." -ForegroundColor Green
Write-Host ""

# Generate load during collection
Write-Host "[Demo] Starting 30-second collection with artificial load..." -ForegroundColor Cyan
logman start "$DCSName" -ets

Write-Host "Collection started. Generating workload..." -ForegroundColor Yellow
$cpuJob = Start-CPULoad -DurationSeconds 25
Start-Sleep -Seconds 5

Write-Host "Collecting performance data..." -ForegroundColor Cyan
for ($i = 25; $i -gt 0; $i -= 5) {
  Write-Host "  $i seconds remaining..." -ForegroundColor White
  Start-Sleep -Seconds 5
}

logman stop "$DCSName" -ets
Stop-Job -Job $cpuJob -ErrorAction SilentlyContinue
Remove-Job -Job $cpuJob -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "Data collection stopped." -ForegroundColor Green
Write-Host "Check C:\PerfLogs\Admin\System Performance\ for .blg data files" -ForegroundColor Cyan

Write-Host ""
Write-Host "[GUI Demo] Viewing Data Collector Set reports..." -ForegroundColor Cyan
Write-Host "  1. Expand Reports > System > System Performance" -ForegroundColor Yellow
Write-Host "  2. Click latest report (shows timestamp)" -ForegroundColor Yellow
Write-Host "  3. Review HTML report showing:" -ForegroundColor Yellow
Write-Host "     - Summary statistics for each counter" -ForegroundColor White
Write-Host "     - Peak CPU values during our artificial load" -ForegroundColor White
Write-Host "     - Performance graphs over 30-second collection period" -ForegroundColor White

Write-Host ""
Write-Host "EXAM TIP: DCS data saved to C:\PerfLogs\Admin\{DCS-Name}\. Schedule tab = auto-start. Stop Condition = prevents infinite logs" -ForegroundColor Yellow

Pause-Demo
#endregion

#region 22.3 - Windows Admin Center (Conceptual)
Write-Host "=== 22.3 Windows Admin Center: Centralized Monitoring ===" -ForegroundColor Green
Write-Host ""

Write-Host "[Info] Windows Admin Center provides web-based centralized monitoring" -ForegroundColor Cyan
Write-Host "Installation and configuration (not performed in this demo):" -ForegroundColor Yellow
Write-Host ""

Write-Host "[Installation Steps]" -ForegroundColor Cyan
Write-Host "  1. Download WindowsAdminCenter.msi from microsoft.com/windowsadmincenter" -ForegroundColor White
Write-Host "  2. Run installer on management server or Windows 10/11 client" -ForegroundColor White
Write-Host "  3. Choose port (default 443) and certificate" -ForegroundColor White
Write-Host "  4. Complete installation > launch https://localhost" -ForegroundColor White

Write-Host ""
Write-Host "[Adding Servers to WAC]" -ForegroundColor Cyan
Write-Host "  1. In WAC, click 'Add' > Server" -ForegroundColor Yellow
Write-Host "  2. Enter server name: dc01.corp.techtrainertim.com" -ForegroundColor Yellow
Write-Host "  3. Click 'Add' (uses current credentials)" -ForegroundColor Yellow
Write-Host "  4. Repeat for additional servers" -ForegroundColor Yellow

Write-Host ""
Write-Host "[Configuring Email Alerts in WAC]" -ForegroundColor Cyan
Write-Host "  1. Click Settings (gear icon, bottom-left)" -ForegroundColor Yellow
Write-Host "  2. Select 'Alerts' > 'Email settings'" -ForegroundColor Yellow
Write-Host "  3. Configure SMTP server: smtp.office365.com:587" -ForegroundColor Yellow
Write-Host "  4. Enter from address: alerts@corp.techtrainertim.com" -ForegroundColor Yellow
Write-Host "  5. Enter authentication credentials" -ForegroundColor Yellow
Write-Host "  6. Test email > Save" -ForegroundColor Yellow

Write-Host ""
Write-Host "[Creating Alert Rule]" -ForegroundColor Cyan
Write-Host "  1. Connect to server > Tools > Alerts" -ForegroundColor Yellow
Write-Host "  2. Click 'Add rule'" -ForegroundColor Yellow
Write-Host "  3. Rule name: 'High CPU Alert'" -ForegroundColor Yellow
Write-Host "  4. Select counter: Processor(_Total) > % Processor Time" -ForegroundColor Yellow
Write-Host "  5. Condition: Greater than 80" -ForegroundColor Yellow
Write-Host "  6. Duration: 10 minutes" -ForegroundColor Yellow
Write-Host "  7. Recipients: ops-team@corp.techtrainertim.com" -ForegroundColor Yellow
Write-Host "  8. Click 'Create'" -ForegroundColor Yellow

# Check WinRM prerequisite for WAC connectivity
Write-Host ""
Write-Host "[PowerShell] Verifying WinRM is enabled (WAC prerequisite)..." -ForegroundColor Cyan
$WinRMService = Get-Service -Name WinRM
Write-Host "WinRM Service Status: $($WinRMService.Status)" -ForegroundColor $(if ($WinRMService.Status -eq 'Running') { 'Green' }else { 'Yellow' })
Write-Host "WinRM Service StartType: $($WinRMService.StartType)" -ForegroundColor White

if ($WinRMService.Status -ne 'Running') {
  Write-Host "To enable WinRM for WAC connectivity: winrm quickconfig -quiet" -ForegroundColor Yellow
}

# Show WinRM listener configuration
Write-Host ""
Write-Host "[PowerShell] Checking WinRM listeners..." -ForegroundColor Cyan
winrm enumerate winrm/config/listener

Write-Host ""
Write-Host "EXAM TIP: WAC requires WinRM enabled on managed servers (port 5985 HTTP or 5986 HTTPS). Use 'winrm quickconfig' to enable quickly" -ForegroundColor Yellow

Pause-Demo
#endregion

#region 22.4 - System Insights
Write-Host "=== 22.4 System Insights: Predictive Analytics ===" -ForegroundColor Green
Write-Host ""

Write-Host "[PowerShell] Checking System Insights availability..." -ForegroundColor Cyan
$OSVersion = [System.Environment]::OSVersion.Version
if ($OSVersion.Build -ge 17763) {
  Write-Host "Windows Server 2019+ detected - System Insights available" -ForegroundColor Green

  # Check if System Insights feature is installed
  Write-Host ""
  Write-Host "[PowerShell] Checking System Insights installation..." -ForegroundColor Cyan
  $SIFeature = Get-WindowsFeature -Name System-Insights -ErrorAction SilentlyContinue

  if ($SIFeature -and $SIFeature.Installed) {
    Write-Host "System Insights feature is installed" -ForegroundColor Green

    # List available capabilities
    Write-Host ""
    Write-Host "[PowerShell] Listing System Insights capabilities..." -ForegroundColor Cyan
    try {
      Get-InsightsCapability | Select-Object Name, State, @{N = 'LastUpdated'; E = { $_.LastUpdatedTime } } | Format-Table -AutoSize
    }
    catch {
      Write-Host "System Insights cmdlets not available" -ForegroundColor Yellow
    }

    # Enable volume capacity forecasting (most commonly used)
    Write-Host ""
    Write-Host "[PowerShell] Enabling volume capacity forecasting..." -ForegroundColor Cyan
    try {
      Enable-InsightsCapability -Name "Volume capacity forecasting" -ErrorAction SilentlyContinue
      Write-Host "Volume capacity forecasting enabled" -ForegroundColor Green

      # Get prediction result
      Write-Host ""
      Write-Host "[PowerShell] Getting volume capacity prediction..." -ForegroundColor Cyan
      Write-Host "(Note: Requires several days of historical data for accurate prediction)" -ForegroundColor Yellow

      $Prediction = Get-InsightsCapabilityResult -Name "Volume capacity forecasting"
      if ($Prediction) {
        Write-Host ""
        Write-Host "Prediction Results:" -ForegroundColor Green
        Write-Host "Status: $($Prediction.Status)" -ForegroundColor White
        Write-Host "Description: $($Prediction.Description)" -ForegroundColor White
      }
      else {
        Write-Host "Insufficient historical data for prediction (requires 7+ days)" -ForegroundColor Yellow
      }

      # Show capability schedule
      Write-Host ""
      Write-Host "[PowerShell] Checking prediction schedule..." -ForegroundColor Cyan
      Get-InsightsCapabilitySchedule -Name "Volume capacity forecasting" | Format-List

    }
    catch {
      Write-Host "System Insights operations require sufficient historical data" -ForegroundColor Yellow
    }

  }
  else {
    Write-Host "System Insights feature not installed" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To install: Install-WindowsFeature -Name System-Insights -IncludeManagementTools" -ForegroundColor Cyan
  }

}
else {
  Write-Host "System Insights requires Windows Server 2019 or later (Build 17763+)" -ForegroundColor Yellow
  Write-Host "Current version: $($OSVersion.Major).$($OSVersion.Minor) (Build $($OSVersion.Build))" -ForegroundColor White
}

Write-Host ""
Write-Host "[GUI Demo] Viewing System Insights in Windows Admin Center..." -ForegroundColor Cyan
Write-Host "  1. In WAC, connect to server running Server 2019+" -ForegroundColor Yellow
Write-Host "  2. Tools menu > System Insights" -ForegroundColor Yellow
Write-Host "  3. View enabled capabilities and their predictions:" -ForegroundColor Yellow
Write-Host "     - Volume capacity forecasting: Shows days until disk full" -ForegroundColor White
Write-Host "     - CPU capacity forecasting: Shows future CPU utilization" -ForegroundColor White
Write-Host "     - Network capacity forecasting: Predicts network saturation" -ForegroundColor White
Write-Host "  4. Click capability to see detailed prediction timeline" -ForegroundColor Yellow
Write-Host "  5. Review confidence score (higher = more reliable)" -ForegroundColor Yellow

Write-Host ""
Write-Host "EXAM TIP: Get-InsightsCapability lists predictions. Enable-InsightsCapability activates forecasting. Requires Server 2019+ and several days data" -ForegroundColor Yellow

Pause-Demo
#endregion

#region 22.5 - Event Logs
Write-Host "=== 22.5 Event Logs: Troubleshooting and Auditing ===" -ForegroundColor Green
Write-Host ""

# Show classic Event Viewer navigation
Write-Host "[GUI Demo] Opening Event Viewer..." -ForegroundColor Cyan
Write-Host "Click: Start > Run > eventvwr.msc > OK" -ForegroundColor Yellow
Write-Host "(Demo paused for GUI interaction)" -ForegroundColor DarkGray
Write-Host ""

# Query recent system events via PowerShell
Write-Host "[PowerShell] Querying recent System log events..." -ForegroundColor Cyan
Get-WinEvent -FilterHashtable @{
  LogName = 'System'
  Level   = 2, 3  # Error and Warning
} -MaxEvents 10 | Select-Object TimeCreated, Id, LevelDisplayName, Message | Format-Table -Wrap -AutoSize

# Query security log for authentication events
Write-Host ""
Write-Host "[PowerShell] Querying recent authentication events..." -ForegroundColor Cyan
Write-Host "(Looking for logon events - Event ID 4624 and failures - 4625)" -ForegroundColor Yellow
Get-WinEvent -FilterHashtable @{
  LogName = 'Security'
  ID      = 4624, 4625
} -MaxEvents 5 -ErrorAction SilentlyContinue | Select-Object TimeCreated, Id, @{N = 'Type'; E = { if ($_.Id -eq 4624) { 'Success' }else { 'Failure' } } }, Message | Format-Table -Wrap

# Show DNS server log if DNS role installed
Write-Host ""
Write-Host "[PowerShell] Checking DNS Server event log..." -ForegroundColor Cyan
try {
  $DNSEvents = Get-WinEvent -LogName "DNS Server" -MaxEvents 5 -ErrorAction Stop
  Write-Host "Recent DNS Server events:" -ForegroundColor Green
  $DNSEvents | Select-Object TimeCreated, Id, LevelDisplayName, Message | Format-Table -Wrap -AutoSize
}
catch {
  Write-Host "DNS Server log not available (DNS Server role not installed)" -ForegroundColor Yellow
}

# Create custom Event Viewer view (GUI steps)
Write-Host ""
Write-Host "[GUI Demo] Creating custom Event Viewer view..." -ForegroundColor Cyan
Write-Host "In Event Viewer window:" -ForegroundColor Yellow
Write-Host "  1. Right-click 'Custom Views' > Create Custom View" -ForegroundColor Yellow
Write-Host "  2. Filter configuration:" -ForegroundColor Yellow
Write-Host "     - Logged: Last 24 hours" -ForegroundColor White
Write-Host "     - Event level: Check 'Critical' and 'Error'" -ForegroundColor White
Write-Host "     - By log: Check 'Windows Logs' > System, Application, Security" -ForegroundColor White
Write-Host "  3. Click OK" -ForegroundColor Yellow
Write-Host "  4. Name: 'Critical Errors - Last 24 Hours'" -ForegroundColor Yellow
Write-Host "  5. Click OK" -ForegroundColor Yellow
Write-Host "  6. New custom view appears under Custom Views" -ForegroundColor Yellow

# Demonstrate event log forwarding configuration
Write-Host ""
Write-Host "[GUI Demo] Configuring Event Log Forwarding (Collector side)..." -ForegroundColor Cyan
Write-Host "On COLLECTOR server:" -ForegroundColor Yellow
Write-Host "  1. Run: wecutil qc" -ForegroundColor White
Write-Host "     (Configures Windows Event Collector service)" -ForegroundColor DarkGray
Write-Host "  2. In Event Viewer, right-click 'Subscriptions' > Create Subscription" -ForegroundColor Yellow
Write-Host "  3. Subscription name: 'AD-Security-Events'" -ForegroundColor Yellow
Write-Host "  4. Destination log: Forwarded Events" -ForegroundColor Yellow
Write-Host "  5. Click 'Select Computers' > Add Domain Computers" -ForegroundColor Yellow
Write-Host "     - Add: dc01.corp.techtrainertim.com" -ForegroundColor White
Write-Host "  6. Click 'Select Events' > By log: Security" -ForegroundColor Yellow
Write-Host "  7. Event IDs: 4624, 4625, 4720, 4740" -ForegroundColor Yellow
Write-Host "     (Logon success, logon failure, user created, user locked)" -ForegroundColor DarkGray
Write-Host "  8. Click OK > OK" -ForegroundColor Yellow

Write-Host ""
Write-Host "[GUI Demo] Configuring Event Log Forwarding (Source side)..." -ForegroundColor Cyan
Write-Host "On SOURCE servers:" -ForegroundColor Yellow
Write-Host "  1. Run: winrm quickconfig" -ForegroundColor White
Write-Host "     (Enables WinRM for event forwarding)" -ForegroundColor DarkGray
Write-Host "  2. Run: wevtutil sl Security /ca:O:BAG:SYD:(A;;0xf0005;;;SY)(A;;0x5;;;BA)(A;;0x1;;;S-1-5-32-573)(A;;0x1;;;NS)" -ForegroundColor White
Write-Host "     (Grants Network Service read access to Security log)" -ForegroundColor DarkGray

# Show critical Event IDs
Write-Host ""
Write-Host "[Reference] Critical Event IDs for AZ-801 Exam:" -ForegroundColor Cyan
Write-Host ""
Write-Host "SYSTEM Log:" -ForegroundColor Green
Write-Host "  1074  - Initiated shutdown (clean)" -ForegroundColor White
Write-Host "  6005  - Event Log service started (system boot)" -ForegroundColor White
Write-Host "  6008  - Unexpected shutdown (crash)" -ForegroundColor White
Write-Host "  7000  - Service failed to start" -ForegroundColor White
Write-Host "  7023  - Service terminated with error" -ForegroundColor White

Write-Host ""
Write-Host "SECURITY Log:" -ForegroundColor Green
Write-Host "  4624  - Successful logon" -ForegroundColor White
Write-Host "  4625  - Failed logon attempt" -ForegroundColor White
Write-Host "  4648  - Logon using explicit credentials (RunAs)" -ForegroundColor White
Write-Host "  4720  - User account created" -ForegroundColor White
Write-Host "  4740  - User account locked out" -ForegroundColor White
Write-Host "  4771  - Kerberos pre-authentication failed" -ForegroundColor White
Write-Host "  4776  - NTLM authentication attempt" -ForegroundColor White

Write-Host ""
Write-Host "APPLICATION Log:" -ForegroundColor Green
Write-Host "  1000  - Application error" -ForegroundColor White
Write-Host "  1001  - Windows Error Reporting" -ForegroundColor White

Write-Host ""
Write-Host "DNS Server Log:" -ForegroundColor Green
Write-Host "  4015  - DNS query failure" -ForegroundColor White

Write-Host ""
Write-Host "DHCP Server Log:" -ForegroundColor Green
Write-Host "  1342  - DHCP database full" -ForegroundColor White
Write-Host "  1046  - DHCP server IP address conflict" -ForegroundColor White

# Query specific Event ID for demo
Write-Host ""
Write-Host "[PowerShell] Querying specific Event ID (System Event ID 1074 - shutdowns)..." -ForegroundColor Cyan
$ShutdownEvents = Get-WinEvent -FilterHashtable @{
  LogName = 'System'
  ID      = 1074
} -MaxEvents 5 -ErrorAction SilentlyContinue

if ($ShutdownEvents) {
  Write-Host "Recent system shutdown events:" -ForegroundColor Green
  $ShutdownEvents | Select-Object TimeCreated, Message | Format-List
}
else {
  Write-Host "No recent shutdown events found (system stable)" -ForegroundColor Green
}

Write-Host ""
Write-Host "EXAM TIP: Event ID 4625 repeated = brute force attack. Event ID 6008 = crash investigate. winrm quickconfig enables event forwarding" -ForegroundColor Yellow

Pause-Demo
#endregion

#region Summary and Exam Tips
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Demo Complete - Key Exam Takeaways" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

Write-Host ""
Write-Host "[Performance Monitor]" -ForegroundColor Green
Write-Host "  • Real-time and historical counter collection"
Write-Host "  • CPU > 80%, Queue Length > 2/core = bottleneck"
Write-Host "  • perfmon.msc with Add Counters for custom views"

Write-Host ""
Write-Host "[Data Collector Sets]" -ForegroundColor Green
Write-Host "  • Automate collection with schedules and templates"
Write-Host "  • Set Stop Condition to prevent infinite logs"
Write-Host "  • Reports in C:\PerfLogs\Admin\"

Write-Host ""
Write-Host "[Windows Admin Center]" -ForegroundColor Green
Write-Host "  • Centralized web-based monitoring dashboard"
Write-Host "  • Requires WinRM enabled (winrm quickconfig)"
Write-Host "  • Email alerts for threshold violations"
Write-Host "  • Port 5985 (HTTP) or 5986 (HTTPS) for connectivity"

Write-Host ""
Write-Host "[System Insights]" -ForegroundColor Green
Write-Host "  • Server 2019+ only, requires 7+ days historical data"
Write-Host "  • Get-InsightsCapability, Enable-InsightsCapability"
Write-Host "  • Volume capacity forecasting most commonly used"
Write-Host "  • View predictions in WAC with confidence scores"

Write-Host ""
Write-Host "[Event Logs]" -ForegroundColor Green
Write-Host "  • Event ID 4624 = logon success, 4625 = logon failure"
Write-Host "  • Event ID 1074 = clean shutdown, 6008 = crash"
Write-Host "  • Event ID 4720 = user created, 4740 = user locked"
Write-Host "  • Custom Views filter by level, log, Event ID, keywords"
Write-Host "  • Event forwarding requires winrm quickconfig on sources"

Write-Host ""
Write-Host "[Hybrid Integration]" -ForegroundColor Green
Write-Host "  • WAC integrates with Azure Monitor for centralized visibility"
Write-Host "  • System Insights data can forward to Azure Monitor"
Write-Host "  • Event Viewer forwards to Azure Log Analytics workspaces"
Write-Host "  • Azure Arc enables Azure management of on-premises servers"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Visit go.techtrainertim.com/az801-labs" -ForegroundColor Yellow
Write-Host "for additional performance monitoring scenarios" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Cleanup any remaining memory allocation
if ($script:memoryArray) {
  $script:memoryArray = $null
  [System.GC]::Collect()
}
#endregion
$PerfData = @{
  CPUPercent         = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples.CookedValue
  MemoryAvailMB      = (Get-Counter '\Memory\Available MBytes').CounterSamples.CookedValue
  DiskQueueLength    = (Get-Counter '\PhysicalDisk(_Total)\Avg. Disk Queue Length').CounterSamples.CookedValue
  NetworkBytesPerSec = (Get-Counter '\Network Interface(*)\Bytes Total/sec').CounterSamples.CookedValue | Measure-Object -Sum | Select-Object -ExpandProperty Sum
}

Write-Host "`nCurrent Performance Metrics:" -ForegroundColor Green
Write-Host "  CPU Usage: $([math]::Round($PerfData.CPUPercent, 2))%" -ForegroundColor White
Write-Host "  Available Memory: $([math]::Round($PerfData.MemoryAvailMB, 2)) MB" -ForegroundColor White
Write-Host "  Disk Queue Length: $([math]::Round($PerfData.DiskQueueLength, 4))" -ForegroundColor White
Write-Host "  Network Throughput: $([math]::Round($PerfData.NetworkBytesPerSec / 1MB, 2)) MB/sec" -ForegroundColor White

Write-Host "`n[GUI Demo] Adding custom performance counters..." -ForegroundColor Cyan
Write-Host "In Performance Monitor window:" -ForegroundColor Yellow
Write-Host "  1. Expand Monitoring Tools > Performance Monitor" -ForegroundColor Yellow
Write-Host "  2. Click green plus icon (Add Counters)" -ForegroundColor Yellow
Write-Host "  3. Add these counters:" -ForegroundColor Yellow
Write-Host "     - Processor(_Total) > % Processor Time" -ForegroundColor White
Write-Host "     - Memory > Available MBytes" -ForegroundColor White
Write-Host "     - PhysicalDisk(_Total) > Avg. Disk Queue Length" -ForegroundColor White
Write-Host "     - Network Interface(*) > Bytes Total/sec" -ForegroundColor White
Write-Host "  4. Click Add > OK" -ForegroundColor Yellow
Write-Host "  5. Observe real-time graph updating every second" -ForegroundColor Yellow

Write-Host "`nEXAM TIP: CPU > 80% sustained = pressure. Disk Queue > 2/spindle = I/O bottleneck. Memory < 10% available = memory pressure" -ForegroundColor Yellow

Pause-Demo
#endregion

#region 22.2 - Data Collector Sets
Write-Host "=== 22.2 Data Collector Sets: Automated Collection ===" -ForegroundColor Green

Write-Host "`n[GUI Demo] Creating custom Data Collector Set..." -ForegroundColor Cyan
Write-Host "In Performance Monitor window:" -ForegroundColor Yellow
Write-Host "  1. Expand Data Collector Sets > User Defined" -ForegroundColor Yellow
Write-Host "  2. Right-click User Defined > New > Data Collector Set" -ForegroundColor Yellow
Write-Host "  3. Name: 'AZ-801-Performance-Baseline'" -ForegroundColor Yellow
Write-Host "  4. Select 'Create manually (Advanced)' > Next" -ForegroundColor Yellow
Write-Host "  5. Check 'Performance counter' > Next" -ForegroundColor Yellow
Write-Host "  6. Sample interval: 15 seconds > Next" -ForegroundColor Yellow
Write-Host "  7. Add counters:" -ForegroundColor Yellow
Write-Host "     - Processor(_Total) > % Processor Time" -ForegroundColor White
Write-Host "     - Memory > Available MBytes" -ForegroundColor White
Write-Host "     - PhysicalDisk(_Total) > % Disk Time" -ForegroundColor White
Write-Host "     - System > Processor Queue Length" -ForegroundColor White
Write-Host "  8. Next > Save and Close" -ForegroundColor Yellow

Write-Host "`n[GUI Demo] Configuring Data Collector Set schedule..." -ForegroundColor Cyan
Write-Host "  1. Right-click 'AZ-801-Performance-Baseline' > Properties" -ForegroundColor Yellow
Write-Host "  2. Go to Schedule tab > Click Add" -ForegroundColor Yellow
Write-Host "  3. Set Beginning date: Today" -ForegroundColor Yellow
Write-Host "  4. Set Start time: 01:00:00 (1 AM)" -ForegroundColor Yellow
Write-Host "  5. Check 'Expire after' and set to 7 days from today" -ForegroundColor Yellow
Write-Host "  6. Go to Stop Condition tab" -ForegroundColor Yellow
Write-Host "  7. Set 'Overall duration': 1 hour" -ForegroundColor Yellow
Write-Host "  8. Click OK" -ForegroundColor Yellow

# Start Data Collector Set via PowerShell for demo
Write-Host "`n[PowerShell] Starting Data Collector Set for demo (30 second collection)..." -ForegroundColor Cyan
$DCSName = "System Performance"  # Using built-in DCS for demo

try {
  # Check if DCS exists
  $DCS = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Perflib\_V2Providers" -ErrorAction SilentlyContinue

  Write-Host "Starting '$DCSName' Data Collector Set..." -ForegroundColor Green
  logman start "$DCSName" -ets

  Write-Host "Collecting performance data for 30 seconds..." -ForegroundColor Cyan
  Start-Sleep -Seconds 30

  logman stop "$DCSName" -ets
  Write-Host "Data collection stopped. Check %SystemDrive%\PerfLogs\Admin\ for results" -ForegroundColor Green

}
catch {
  Write-Host "Built-in System Performance DCS not available - demo with manual DCS creation in GUI" -ForegroundColor Yellow
}

Write-Host "`n[GUI Demo] Viewing Data Collector Set reports..." -ForegroundColor Cyan
Write-Host "  1. Expand Reports > User Defined > AZ-801-Performance-Baseline" -ForegroundColor Yellow
Write-Host "  2. Click latest report (shows timestamp)" -ForegroundColor Yellow
Write-Host "  3. Review HTML report showing:" -ForegroundColor Yellow
Write-Host "     - Summary statistics for each counter" -ForegroundColor White
Write-Host "     - Peak values and timestamps" -ForegroundColor White
Write-Host "     - Performance graphs over collection period" -ForegroundColor White

Write-Host "`nEXAM TIP: DCS data saved to %SystemDrive%\PerfLogs\Admin\{DCS-Name}\. Schedule tab = auto-start. Stop Condition = prevents infinite logs" -ForegroundColor Yellow

Pause-Demo
#endregion

#region 22.3 - Windows Admin Center (Conceptual)
Write-Host "=== 22.3 Windows Admin Center: Centralized Monitoring ===" -ForegroundColor Green

Write-Host "`n[Info] Windows Admin Center provides web-based centralized monitoring" -ForegroundColor Cyan
Write-Host "Installation and configuration (not performed in this demo):`n" -ForegroundColor Yellow

Write-Host "[Installation Steps]" -ForegroundColor Cyan
Write-Host "  1. Download WindowsAdminCenter.msi from microsoft.com/windowsadmincenter" -ForegroundColor White
Write-Host "  2. Run installer on management server or Windows 10/11 client" -ForegroundColor White
Write-Host "  3. Choose port (default 443) and certificate" -ForegroundColor White
Write-Host "  4. Complete installation > launch https://localhost" -ForegroundColor White

Write-Host "`n[Adding Servers to WAC]" -ForegroundColor Cyan
Write-Host "  1. In WAC, click 'Add' > Server" -ForegroundColor Yellow
Write-Host "  2. Enter server name: dc01.corp.techtrainertim.com" -ForegroundColor Yellow
Write-Host "  3. Click 'Add' (uses current credentials)" -ForegroundColor Yellow
Write-Host "  4. Repeat for additional servers" -ForegroundColor Yellow

Write-Host "`n[Configuring Email Alerts in WAC]" -ForegroundColor Cyan
Write-Host "  1. Click Settings (gear icon, bottom-left)" -ForegroundColor Yellow
Write-Host "  2. Select 'Alerts' > 'Email settings'" -ForegroundColor Yellow
Write-Host "  3. Configure SMTP server: smtp.office365.com:587" -ForegroundColor Yellow
Write-Host "  4. Enter from address: alerts@corp.techtrainertim.com" -ForegroundColor Yellow
Write-Host "  5. Enter authentication credentials" -ForegroundColor Yellow
Write-Host "  6. Test email > Save" -ForegroundColor Yellow

Write-Host "`n[Creating Alert Rule]" -ForegroundColor Cyan
Write-Host "  1. Connect to server > Tools > Alerts" -ForegroundColor Yellow
Write-Host "  2. Click 'Add rule'" -ForegroundColor Yellow
Write-Host "  3. Rule name: 'High CPU Alert'" -ForegroundColor Yellow
Write-Host "  4. Select counter: Processor(_Total) > % Processor Time" -ForegroundColor Yellow
Write-Host "  5. Condition: Greater than 80" -ForegroundColor Yellow
Write-Host "  6. Duration: 10 minutes" -ForegroundColor Yellow
Write-Host "  7. Recipients: ops-team@corp.techtrainertim.com" -ForegroundColor Yellow
Write-Host "  8. Click 'Create'" -ForegroundColor Yellow

# Check WinRM prerequisite for WAC connectivity
Write-Host "`n[PowerShell] Verifying WinRM is enabled (WAC prerequisite)..." -ForegroundColor Cyan
$WinRMService = Get-Service -Name WinRM
Write-Host "WinRM Service Status: $($WinRMService.Status)" -ForegroundColor $(if ($WinRMService.Status -eq 'Running') { 'Green' }else { 'Yellow' })
Write-Host "WinRM Service StartType: $($WinRMService.StartType)" -ForegroundColor White

if ($WinRMService.Status -ne 'Running') {
  Write-Host "To enable WinRM for WAC connectivity: winrm quickconfig -quiet" -ForegroundColor Yellow
}

# Show WinRM listener configuration
Write-Host "`n[PowerShell] Checking WinRM listeners..." -ForegroundColor Cyan
winrm enumerate winrm/config/listener

Write-Host "`nEXAM TIP: WAC requires WinRM enabled on managed servers (port 5985 HTTP or 5986 HTTPS). Use 'winrm quickconfig' to enable quickly" -ForegroundColor Yellow

Pause-Demo
#endregion

#region 22.4 - System Insights
Write-Host "=== 22.4 System Insights: Predictive Analytics ===" -ForegroundColor Green

Write-Host "`n[PowerShell] Checking System Insights availability..." -ForegroundColor Cyan
$OSVersion = [System.Environment]::OSVersion.Version
if ($OSVersion.Build -ge 17763) {
  Write-Host "Windows Server 2019+ detected - System Insights available" -ForegroundColor Green

  # Check if System Insights feature is installed
  Write-Host "`n[PowerShell] Checking System Insights installation..." -ForegroundColor Cyan
  $SIFeature = Get-WindowsFeature -Name System-Insights -ErrorAction SilentlyContinue

  if ($SIFeature -and $SIFeature.Installed) {
    Write-Host "System Insights feature is installed" -ForegroundColor Green

    # List available capabilities
    Write-Host "`n[PowerShell] Listing System Insights capabilities..." -ForegroundColor Cyan
    try {
      Get-InsightsCapability | Select-Object Name, State, @{N = 'LastUpdated'; E = { $_.LastUpdatedTime } } | Format-Table -AutoSize
    }
    catch {
      Write-Host "System Insights cmdlets not available" -ForegroundColor Yellow
    }

    # Enable volume capacity forecasting (most commonly used)
    Write-Host "`n[PowerShell] Enabling volume capacity forecasting..." -ForegroundColor Cyan
    try {
      Enable-InsightsCapability -Name "Volume capacity forecasting" -ErrorAction SilentlyContinue
      Write-Host "Volume capacity forecasting enabled" -ForegroundColor Green

      # Get prediction result
      Write-Host "`n[PowerShell] Getting volume capacity prediction..." -ForegroundColor Cyan
      Write-Host "(Note: Requires several days of historical data for accurate prediction)" -ForegroundColor Yellow

      $Prediction = Get-InsightsCapabilityResult -Name "Volume capacity forecasting"
      if ($Prediction) {
        Write-Host "`nPrediction Results:" -ForegroundColor Green
        Write-Host "Status: $($Prediction.Status)" -ForegroundColor White
        Write-Host "Description: $($Prediction.Description)" -ForegroundColor White
      }
      else {
        Write-Host "Insufficient historical data for prediction (requires 7+ days)" -ForegroundColor Yellow
      }

      # Show capability schedule
      Write-Host "`n[PowerShell] Checking prediction schedule..." -ForegroundColor Cyan
      Get-InsightsCapabilitySchedule -Name "Volume capacity forecasting" | Format-List

    }
    catch {
      Write-Host "System Insights operations require sufficient historical data" -ForegroundColor Yellow
    }

  }
  else {
    Write-Host "System Insights feature not installed" -ForegroundColor Yellow
    Write-Host "`nTo install: Install-WindowsFeature -Name System-Insights -IncludeManagementTools" -ForegroundColor Cyan
  }

}
else {
  Write-Host "System Insights requires Windows Server 2019 or later (Build 17763+)" -ForegroundColor Yellow
  Write-Host "Current version: $($OSVersion.Major).$($OSVersion.Minor) (Build $($OSVersion.Build))" -ForegroundColor White
}

Write-Host "`n[GUI Demo] Viewing System Insights in Windows Admin Center..." -ForegroundColor Cyan
Write-Host "  1. In WAC, connect to server running Server 2019+" -ForegroundColor Yellow
Write-Host "  2. Tools menu > System Insights" -ForegroundColor Yellow
Write-Host "  3. View enabled capabilities and their predictions:" -ForegroundColor Yellow
Write-Host "     - Volume capacity forecasting: Shows days until disk full" -ForegroundColor White
Write-Host "     - CPU capacity forecasting: Shows future CPU utilization" -ForegroundColor White
Write-Host "     - Network capacity forecasting: Predicts network saturation" -ForegroundColor White
Write-Host "  4. Click capability to see detailed prediction timeline" -ForegroundColor Yellow
Write-Host "  5. Review confidence score (higher = more reliable)" -ForegroundColor Yellow

Write-Host "`nEXAM TIP: Get-InsightsCapability lists predictions. Enable-InsightsCapability activates forecasting. Requires Server 2019+ and several days data" -ForegroundColor Yellow

Pause-Demo
#endregion

#region 22.5 - Event Logs
Write-Host "=== 22.5 Event Logs: Troubleshooting and Auditing ===" -ForegroundColor Green

# Show classic Event Viewer navigation
Write-Host "`n[GUI Demo] Opening Event Viewer..." -ForegroundColor Cyan
Write-Host "Click: Start > Run > eventvwr.msc > OK" -ForegroundColor Yellow
Write-Host "(Demo paused for GUI interaction)`n" -ForegroundColor DarkGray

# Query recent system events via PowerShell
Write-Host "[PowerShell] Querying recent System log events..." -ForegroundColor Cyan
Get-WinEvent -FilterHashtable @{
  LogName = 'System'
  Level   = 2, 3  # Error and Warning
} -MaxEvents 10 | Select-Object TimeCreated, Id, LevelDisplayName, Message | Format-Table -Wrap -AutoSize

# Query security log for authentication events
Write-Host "`n[PowerShell] Querying recent authentication events..." -ForegroundColor Cyan
Write-Host "(Looking for logon events - Event ID 4624 and failures - 4625)" -ForegroundColor Yellow
Get-WinEvent -FilterHashtable @{
  LogName = 'Security'
  ID      = 4624, 4625
} -MaxEvents 5 -ErrorAction SilentlyContinue | Select-Object TimeCreated, Id, @{N = 'Type'; E = { if ($_.Id -eq 4624) { 'Success' }else { 'Failure' } } }, Message | Format-Table -Wrap

# Show DNS server log if DNS role installed
Write-Host "`n[PowerShell] Checking DNS Server event log..." -ForegroundColor Cyan
try {
  $DNSEvents = Get-WinEvent -LogName "DNS Server" -MaxEvents 5 -ErrorAction Stop
  Write-Host "Recent DNS Server events:" -ForegroundColor Green
  $DNSEvents | Select-Object TimeCreated, Id, LevelDisplayName, Message | Format-Table -Wrap -AutoSize
}
catch {
  Write-Host "DNS Server log not available (DNS Server role not installed)" -ForegroundColor Yellow
}

# Create custom Event Viewer view (GUI steps)
Write-Host "`n[GUI Demo] Creating custom Event Viewer view..." -ForegroundColor Cyan
Write-Host "In Event Viewer window:" -ForegroundColor Yellow
Write-Host "  1. Right-click 'Custom Views' > Create Custom View" -ForegroundColor Yellow
Write-Host "  2. Filter configuration:" -ForegroundColor Yellow
Write-Host "     - Logged: Last 24 hours" -ForegroundColor White
Write-Host "     - Event level: Check 'Critical' and 'Error'" -ForegroundColor White
Write-Host "     - By log: Check 'Windows Logs' > System, Application, Security" -ForegroundColor White
Write-Host "  3. Click OK" -ForegroundColor Yellow
Write-Host "  4. Name: 'Critical Errors - Last 24 Hours'" -ForegroundColor Yellow
Write-Host "  5. Click OK" -ForegroundColor Yellow
Write-Host "  6. New custom view appears under Custom Views" -ForegroundColor Yellow

# Demonstrate event log forwarding configuration
Write-Host "`n[GUI Demo] Configuring Event Log Forwarding (Collector side)..." -ForegroundColor Cyan
Write-Host "On COLLECTOR server:" -ForegroundColor Yellow
Write-Host "  1. Run: wecutil qc" -ForegroundColor White
Write-Host "     (Configures Windows Event Collector service)" -ForegroundColor DarkGray
Write-Host "  2. In Event Viewer, right-click 'Subscriptions' > Create Subscription" -ForegroundColor Yellow
Write-Host "  3. Subscription name: 'AD-Security-Events'" -ForegroundColor Yellow
Write-Host "  4. Destination log: Forwarded Events" -ForegroundColor Yellow
Write-Host "  5. Click 'Select Computers' > Add Domain Computers" -ForegroundColor Yellow
Write-Host "     - Add: dc01.corp.techtrainertim.com" -ForegroundColor White
Write-Host "  6. Click 'Select Events' > By log: Security" -ForegroundColor Yellow
Write-Host "  7. Event IDs: 4624, 4625, 4720, 4740" -ForegroundColor Yellow
Write-Host "     (Logon success, logon failure, user created, user locked)" -ForegroundColor DarkGray
Write-Host "  8. Click OK > OK" -ForegroundColor Yellow

Write-Host "`n[GUI Demo] Configuring Event Log Forwarding (Source side)..." -ForegroundColor Cyan
Write-Host "On SOURCE servers:" -ForegroundColor Yellow
Write-Host "  1. Run: winrm quickconfig" -ForegroundColor White
Write-Host "     (Enables WinRM for event forwarding)" -ForegroundColor DarkGray
Write-Host "  2. Run: wevtutil sl Security /ca:O:BAG:SYD:(A;;0xf0005;;;SY)(A;;0x5;;;BA)(A;;0x1;;;S-1-5-32-573)(A;;0x1;;;NS)" -ForegroundColor White
Write-Host "     (Grants Network Service read access to Security log)" -ForegroundColor DarkGray

# Show critical Event IDs
Write-Host "`n[Reference] Critical Event IDs for AZ-801 Exam:" -ForegroundColor Cyan
Write-Host "`nSYSTEM Log:" -ForegroundColor Green
Write-Host "  1074  - Initiated shutdown (clean)" -ForegroundColor White
Write-Host "  6005  - Event Log service started (system boot)" -ForegroundColor White
Write-Host "  6008  - Unexpected shutdown (crash)" -ForegroundColor White
Write-Host "  7000  - Service failed to start" -ForegroundColor White
Write-Host "  7023  - Service terminated with error" -ForegroundColor White

Write-Host "`nSECURITY Log:" -ForegroundColor Green
Write-Host "  4624  - Successful logon" -ForegroundColor White
Write-Host "  4625  - Failed logon attempt" -ForegroundColor White
Write-Host "  4648  - Logon using explicit credentials (RunAs)" -ForegroundColor White
Write-Host "  4720  - User account created" -ForegroundColor White
Write-Host "  4740  - User account locked out" -ForegroundColor White
Write-Host "  4771  - Kerberos pre-authentication failed" -ForegroundColor White
Write-Host "  4776  - NTLM authentication attempt" -ForegroundColor White

Write-Host "`nAPPLICATION Log:" -ForegroundColor Green
Write-Host "  1000  - Application error" -ForegroundColor White
Write-Host "  1001  - Windows Error Reporting" -ForegroundColor White

Write-Host "`nDNS Server Log:" -ForegroundColor Green
Write-Host "  4015  - DNS query failure" -ForegroundColor White

Write-Host "`nDHCP Server Log:" -ForegroundColor Green
Write-Host "  1342  - DHCP database full" -ForegroundColor White
Write-Host "  1046  - DHCP server IP address conflict" -ForegroundColor White

# Query specific Event ID for demo
Write-Host "`n[PowerShell] Querying specific Event ID (System Event ID 1074 - shutdowns)..." -ForegroundColor Cyan
$ShutdownEvents = Get-WinEvent -FilterHashtable @{
  LogName = 'System'
  ID      = 1074
} -MaxEvents 5 -ErrorAction SilentlyContinue

if ($ShutdownEvents) {
  Write-Host "Recent system shutdown events:" -ForegroundColor Green
  $ShutdownEvents | Select-Object TimeCreated, Message | Format-List
}
else {
  Write-Host "No recent shutdown events found (system stable)" -ForegroundColor Green
}

Write-Host "`nEXAM TIP: Event ID 4625 repeated = brute force attack. Event ID 6008 = crash investigate. winrm quickconfig enables event forwarding" -ForegroundColor Yellow

Pause-Demo
#endregion

#region Summary and Exam Tips
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Demo Complete - Key Exam Takeaways" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

Write-Host "`n[Performance Monitor]" -ForegroundColor Green
Write-Host "  • Real-time and historical counter collection"
Write-Host "  • CPU > 80%, Queue Length > 2/core = bottleneck"
Write-Host "  • perfmon.msc with Add Counters for custom views"

Write-Host "`n[Data Collector Sets]" -ForegroundColor Green
Write-Host "  • Automate collection with schedules and templates"
Write-Host "  • Set Stop Condition to prevent infinite logs"
Write-Host "  • Reports in %SystemDrive%\PerfLogs\Admin\"

Write-Host "`n[Windows Admin Center]" -ForegroundColor Green
Write-Host "  • Centralized web-based monitoring dashboard"
Write-Host "  • Requires WinRM enabled (winrm quickconfig)"
Write-Host "  • Email alerts for threshold violations"
Write-Host "  • Port 5985 (HTTP) or 5986 (HTTPS) for connectivity"

Write-Host "`n[System Insights]" -ForegroundColor Green
Write-Host "  • Server 2019+ only, requires 7+ days historical data"
Write-Host "  • Get-InsightsCapability, Enable-InsightsCapability"
Write-Host "  • Volume capacity forecasting most commonly used"
Write-Host "  • View predictions in WAC with confidence scores"

Write-Host "`n[Event Logs]" -ForegroundColor Green
Write-Host "  • Event ID 4624 = logon success, 4625 = logon failure"
Write-Host "  • Event ID 1074 = clean shutdown, 6008 = crash"
Write-Host "  • Event ID 4720 = user created, 4740 = user locked"
Write-Host "  • Custom Views filter by level, log, Event ID, keywords"
Write-Host "  • Event forwarding requires winrm quickconfig on sources"

Write-Host "`n[Hybrid Integration]" -ForegroundColor Green
Write-Host "  • WAC integrates with Azure Monitor for centralized visibility"
Write-Host "  • System Insights data can forward to Azure Monitor"
Write-Host "  • Event Viewer forwards to Azure Log Analytics workspaces"
Write-Host "  • Azure Arc enables Azure management of on-premises servers"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Visit go.techtrainertim.com/az801-labs" -ForegroundColor Yellow
Write-Host "for additional performance monitoring scenarios" -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Cyan
#endregion
