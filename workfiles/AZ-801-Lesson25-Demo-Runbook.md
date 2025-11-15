# AZ-801 Lesson 25: Troubleshoot Advanced Issues Demo Runbook

## Pre-Demo Setup
```powershell
# Ensure Arc is installed on your server
# If not Arc-enabled, demo still works - just skip Arc sections
$arcInstalled = Get-Service -Name himds -ErrorAction SilentlyContinue
if (!$arcInstalled) {
    Write-Host "Arc not installed - will skip extension troubleshooting"
}
```

## Demo Flow

### 1. Performance Baseline Collection (2 min)
```powershell
# Create Data Collector Set for baseline
logman create counter PerfBaseline -c "\Processor(_Total)\% Processor Time" "\Memory\Available MBytes" "\PhysicalDisk(_Total)\Disk Bytes/sec" "\PhysicalDisk(_Total)\Avg. Disk sec/Read" "\Network Interface(*)\Bytes Total/sec" -f bin -si 15 -v mmddhhmm -o "C:\PerfLogs\Baseline"

# Start collection
logman start PerfBaseline
Write-Host "Collecting 30-second baseline..." -ForegroundColor Yellow
Start-Sleep -Seconds 30
logman stop PerfBaseline

# Show the file
Get-Item C:\PerfLogs\*.blg
```
**SAY:** "Baselines are critical. Exam tests these 5 counters specifically."

### 2. Arc Extension Diagnostics (2 min)
```powershell
# Check Arc agent health
azcmagent show

# View extension status
azcmagent extension list

# Check logs location
Get-ChildItem "C:\ProgramData\GuestConfig\arc_policy_logs" -ErrorAction SilentlyContinue
Get-ChildItem "C:\WindowsAzure\Logs\Plugins" -ErrorAction SilentlyContinue

# Show service status
Get-Service -Name himds, gcaarcservice, extensionservice | Format-Table Name, Status, StartType
```
**EXAM TIP:** "Know these three services: himds (identity), gcaarcservice (guest config), extensionservice (extensions)"

### 3. Simulate Extension Failure (2 min)
```powershell
# Stop extension service to simulate issue
Stop-Service extensionservice -Force
Write-Host "Extension service stopped - simulating failure" -ForegroundColor Red

# Try to run extension command (will fail)
azcmagent extension list

# Diagnose
Get-EventLog -LogName System -Source "Service Control Manager" -Newest 5
Get-Content "C:\ProgramData\AzureConnectedMachineAgent\Log\azcmagent.log" -Tail 20

# Fix
Start-Service extensionservice
Write-Host "Service restarted - issue resolved" -ForegroundColor Green
```
**SAY:** "Exam pattern: symptom → logs → fix. Never skip diagnostics."

### 4. BitLocker Status Check (2 min)
```powershell
# Check encryption status
manage-bde -status C:

# If encrypted, show protectors
manage-bde -protectors -get C:

# Check for recovery keys in AD
Get-ADObject -Filter {objectclass -eq 'msFVE-RecoveryInformation'} -Properties * |
    Select-Object DistinguishedName, whenCreated |
    Format-Table -AutoSize
```
**EXAM POINTS:**
- Know protector types: TPM, PIN, recovery key, password
- AD backup = msFVE-RecoveryInformation objects
- Used space only vs full encryption modes

### 5. Storage Spaces Direct Quick Check (2 min)
```powershell
# Check S2D health (if available)
Get-StorageSubSystem -FriendlyName "Clustered*" -ErrorAction SilentlyContinue |
    Get-StorageHealthReport

# Show physical disk health
Get-PhysicalDisk |
    Select-Object FriendlyName, Size, MediaType, HealthStatus, OperationalStatus |
    Format-Table -AutoSize

# Check for storage issues in event log
Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-Storage-Spaces-Driver/Operational'; Level=2,3} -MaxEvents 10 -ErrorAction SilentlyContinue
```
**SAY:** "S2D troubleshooting: Health first, then physical disks, then event logs"

## Performance Analysis Wrap-up (30 sec)
```powershell
# Quick counter check
Get-Counter "\Processor(_Total)\% Processor Time", "\Memory\Available MBytes" |
    Select-Object -ExpandProperty CounterSamples |
    Format-Table Path, CookedValue -AutoSize
```
**THRESHOLDS FOR EXAM:**
- CPU: <80% healthy, >90% critical
- Memory: >500MB available healthy
- Disk latency: <15ms healthy, >50ms critical

## Cleanup
```powershell
logman delete PerfBaseline -y
Remove-Item C:\PerfLogs\*.blg -ErrorAction SilentlyContinue
```

## Time Breakdown
- Performance baseline: 2 min
- Arc diagnostics: 2 min
- Extension failure: 2 min
- BitLocker: 2 min
- S2D check: 2 min
- **Total: 10 minutes**

## Key Exam Facts

**Performance Counters (know all 5):**
- Processor\% Processor Time
- Memory\Available MBytes
- PhysicalDisk\Avg. Disk sec/Read
- PhysicalDisk\Disk Bytes/sec
- Network Interface\Bytes Total/sec

**Arc Extension Logs:**
- Agent: `C:\ProgramData\AzureConnectedMachineAgent\Log\`
- Extensions: `C:\WindowsAzure\Logs\Plugins\`
- Guest Config: `C:\ProgramData\GuestConfig\arc_policy_logs\`

**BitLocker Protector IDs:**
- 0 = Recovery Password
- 1 = External Key
- 2 = Numerical Password
- 3 = TPM
- 4 = TPM + PIN
- 5 = TPM + Startup Key

**S2D Health States:**
- 0 = Healthy
- 1 = Warning
- 2 = Unhealthy

---
