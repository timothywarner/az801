<#
.SYNOPSIS
    Task 22.3 - Monitor with Windows Admin Center

.DESCRIPTION
    Demo script for AZ-801 Module 22: Monitor Windows Server Performance
    Demonstrates performance monitoring using Windows Admin Center (WAC) concepts,
    remote management, and PowerShell integration.

.NOTES
    Module: Module 22 - Monitor Windows Server Performance
    Task: 22.3 - Monitor with Windows Admin Center
    Prerequisites: Windows Server, Administrative privileges
    PowerShell Version: 5.1+
#>

#Requires -RunAsAdministrator

$ErrorActionPreference = 'Stop'
Write-Host "=== AZ-801 Module 22: Task 22.3 - Monitor with Windows Admin Center ===" -ForegroundColor Cyan
Write-Host ""

try {
    # Check WinRM for remote management
    Write-Host "[Step 1] Verify Remote Management Prerequisites" -ForegroundColor Yellow
    $winrm = Get-Service -Name WinRM
    Write-Host "WinRM Service Status: $($winrm.Status)" -ForegroundColor Cyan

    if ($winrm.Status -ne 'Running') {
        Write-Host "Starting WinRM service..." -ForegroundColor Yellow
        Start-Service -Name WinRM
        Write-Host "[SUCCESS] WinRM service started" -ForegroundColor Green
    } else {
        Write-Host "[OK] WinRM is running" -ForegroundColor Green
    }

    # Check WinRM configuration
    $winrmConfig = winrm get winrm/config
    Write-Host "`nWinRM Configuration Summary:" -ForegroundColor Cyan
    $winrmConfig | Select-Object -First 10 | ForEach-Object { Write-Host "  $_" -ForegroundColor White }
    Write-Host ""

    # Enable PowerShell Remoting if needed
    Write-Host "[Step 2] Configure PowerShell Remoting" -ForegroundColor Yellow
    $psRemoting = Get-PSSessionConfiguration -Name Microsoft.PowerShell -ErrorAction SilentlyContinue

    if ($psRemoting) {
        Write-Host "[OK] PowerShell Remoting is configured" -ForegroundColor Green
        Write-Host "Session Configuration: $($psRemoting.Name)" -ForegroundColor White
        Write-Host "Permission: $($psRemoting.Permission)" -ForegroundColor White
    } else {
        Write-Host "[INFO] PowerShell Remoting not fully configured" -ForegroundColor Yellow
        Write-Host "Run: Enable-PSRemoting -Force" -ForegroundColor White
    }
    Write-Host ""

    # Collect system information (WAC-style)
    Write-Host "[Step 3] Collect System Overview (WAC-Style)" -ForegroundColor Yellow

    $computerInfo = Get-ComputerInfo
    $overview = [PSCustomObject]@{
        ComputerName = $env:COMPUTERNAME
        OSName = $computerInfo.OsName
        OSVersion = $computerInfo.OsVersion
        OSBuild = $computerInfo.OsBuildNumber
        LastBootTime = $computerInfo.OsLastBootUpTime
        Uptime = (Get-Date) - $computerInfo.OsLastBootUpTime
        Domain = $computerInfo.CsDomain
        TotalPhysicalMemory_GB = [math]::Round($computerInfo.CsTotalPhysicalMemory / 1GB, 2)
        Processors = $computerInfo.CsNumberOfProcessors
        LogicalProcessors = $computerInfo.CsNumberOfLogicalProcessors
    }

    Write-Host "System Overview:" -ForegroundColor Cyan
    $overview | Format-List
    Write-Host ""

    # CPU and Memory metrics (Dashboard view)
    Write-Host "[Step 4] Real-Time Performance Dashboard" -ForegroundColor Yellow

    function Get-PerformanceDashboard {
        # CPU
        $cpu = Get-Counter '\Processor(_Total)\% Processor Time'
        $cpuValue = [math]::Round($cpu.CounterSamples.CookedValue, 2)

        # Memory
        $totalMemory = (Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum).Sum
        $availMemory = (Get-Counter '\Memory\Available MBytes').CounterSamples.CookedValue
        $usedMemory = ($totalMemory / 1MB) - $availMemory
        $memoryPercent = [math]::Round(($usedMemory / ($totalMemory / 1MB)) * 100, 2)

        # Disk
        $disk = Get-Counter '\PhysicalDisk(_Total)\% Disk Time'
        $diskValue = [math]::Round($disk.CounterSamples.CookedValue, 2)

        # Network
        $network = Get-Counter '\Network Interface(*)\Bytes Total/sec'
        $networkValue = ($network.CounterSamples | Measure-Object -Property CookedValue -Sum).Sum
        $networkMbps = [math]::Round(($networkValue * 8) / 1MB, 2)

        return [PSCustomObject]@{
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            CPU_Percent = $cpuValue
            Memory_Percent = $memoryPercent
            Memory_Used_MB = [math]::Round($usedMemory, 2)
            Memory_Available_MB = [math]::Round($availMemory, 2)
            Disk_Percent = $diskValue
            Network_Mbps = $networkMbps
        }
    }

    Write-Host "Collecting real-time metrics (3 samples)..." -ForegroundColor Cyan
    $dashboardData = @()
    for ($i = 1; $i -le 3; $i++) {
        $dashboardData += Get-PerformanceDashboard
        if ($i -lt 3) { Start-Sleep -Seconds 2 }
    }

    $dashboardData | Format-Table -AutoSize
    Write-Host ""

    # Process monitoring (WAC Processes view)
    Write-Host "[Step 5] Top Processes by Resource Usage" -ForegroundColor Yellow

    $processes = Get-Process | Where-Object { $_.CPU -gt 0 } |
        Sort-Object CPU -Descending |
        Select-Object -First 10 Name,
            Id,
            @{Name='CPU';Expression={[math]::Round($_.CPU, 2)}},
            @{Name='Memory_MB';Expression={[math]::Round($_.WorkingSet64 / 1MB, 2)}},
            @{Name='Threads';Expression={$_.Threads.Count}},
            @{Name='Handles';Expression={$_.HandleCount}}

    Write-Host "Top 10 Processes by CPU:" -ForegroundColor Cyan
    $processes | Format-Table -AutoSize
    Write-Host ""

    # Service monitoring
    Write-Host "[Step 6] Critical Services Status" -ForegroundColor Yellow

    $criticalServices = @(
        'WinRM', 'W32Time', 'EventLog', 'Dnscache',
        'LanmanServer', 'LanmanWorkstation', 'RpcSs'
    )

    $serviceStatus = foreach ($svcName in $criticalServices) {
        $service = Get-Service -Name $svcName -ErrorAction SilentlyContinue
        if ($service) {
            [PSCustomObject]@{
                Name = $service.Name
                DisplayName = $service.DisplayName
                Status = $service.Status
                StartType = $service.StartType
            }
        }
    }

    Write-Host "Critical Services:" -ForegroundColor Cyan
    $serviceStatus | Format-Table -AutoSize
    Write-Host ""

    # Storage overview
    Write-Host "[Step 7] Storage Overview (WAC-Style)" -ForegroundColor Yellow

    $volumes = Get-Volume | Where-Object { $_.DriveLetter -ne $null } |
        Select-Object DriveLetter,
            FileSystemLabel,
            FileSystem,
            @{Name='Size_GB';Expression={[math]::Round($_.Size / 1GB, 2)}},
            @{Name='Used_GB';Expression={[math]::Round(($_.Size - $_.SizeRemaining) / 1GB, 2)}},
            @{Name='Free_GB';Expression={[math]::Round($_.SizeRemaining / 1GB, 2)}},
            @{Name='Free_Percent';Expression={[math]::Round(($_.SizeRemaining / $_.Size) * 100, 2)}},
            HealthStatus

    Write-Host "Storage Volumes:" -ForegroundColor Cyan
    $volumes | Format-Table -AutoSize
    Write-Host ""

    # Network adapters
    Write-Host "[Step 8] Network Adapters Status" -ForegroundColor Yellow

    $adapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } |
        Select-Object Name,
            InterfaceDescription,
            Status,
            LinkSpeed,
            MacAddress

    Write-Host "Active Network Adapters:" -ForegroundColor Cyan
    $adapters | Format-Table -AutoSize
    Write-Host ""

    # Event log summary (WAC Events view)
    Write-Host "[Step 9] Recent Critical Events" -ForegroundColor Yellow

    $criticalEvents = Get-WinEvent -FilterHashtable @{
        LogName = 'System', 'Application'
        Level = 1, 2  # Critical and Error
        StartTime = (Get-Date).AddHours(-24)
    } -MaxEvents 10 -ErrorAction SilentlyContinue

    if ($criticalEvents) {
        $eventSummary = $criticalEvents | Select-Object TimeCreated,
            LevelDisplayName,
            LogName,
            Id,
            Message

        Write-Host "Critical/Error Events (Last 24 hours):" -ForegroundColor Cyan
        $eventSummary | Format-Table TimeCreated, LevelDisplayName, LogName, Id -AutoSize
    } else {
        Write-Host "[OK] No critical events in the last 24 hours" -ForegroundColor Green
    }
    Write-Host ""

    # Performance alerts
    Write-Host "[Step 10] Performance Alert Check" -ForegroundColor Yellow

    $currentMetrics = Get-PerformanceDashboard
    $alerts = @()

    if ($currentMetrics.CPU_Percent -gt 80) {
        $alerts += [PSCustomObject]@{
            Severity = 'Warning'
            Category = 'CPU'
            Message = "CPU usage is high: $($currentMetrics.CPU_Percent)%"
        }
    }

    if ($currentMetrics.Memory_Percent -gt 90) {
        $alerts += [PSCustomObject]@{
            Severity = 'Critical'
            Category = 'Memory'
            Message = "Memory usage is critical: $($currentMetrics.Memory_Percent)%"
        }
    }

    $volumes | ForEach-Object {
        if ($_.Free_Percent -lt 10) {
            $alerts += [PSCustomObject]@{
                Severity = 'Critical'
                Category = 'Storage'
                Message = "Drive $($_.DriveLetter): low disk space - $($_.Free_Percent)% free"
            }
        }
    }

    if ($alerts.Count -gt 0) {
        Write-Host "Performance Alerts:" -ForegroundColor Yellow
        $alerts | Format-Table -AutoSize
    } else {
        Write-Host "[OK] No performance alerts" -ForegroundColor Green
    }
    Write-Host ""

    # Remote management capabilities
    Write-Host "[Step 11] Remote Management Capabilities" -ForegroundColor Yellow

    Write-Host "PowerShell Remoting Commands:" -ForegroundColor Cyan
    Write-Host "  # Connect to remote server:" -ForegroundColor White
    Write-Host "  Enter-PSSession -ComputerName SERVER01" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  # Run command on remote server:" -ForegroundColor White
    Write-Host "  Invoke-Command -ComputerName SERVER01 -ScriptBlock { Get-Process }" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  # Create persistent session:" -ForegroundColor White
    Write-Host "  `$session = New-PSSession -ComputerName SERVER01" -ForegroundColor Gray
    Write-Host "  Invoke-Command -Session `$session -ScriptBlock { Get-EventLog -LogName System -Newest 10 }" -ForegroundColor Gray
    Write-Host ""

    # Windows Admin Center information
    Write-Host "[Step 12] Windows Admin Center Information" -ForegroundColor Yellow

    Write-Host "About Windows Admin Center:" -ForegroundColor Cyan
    Write-Host "  - Browser-based management console" -ForegroundColor White
    Write-Host "  - Replaces traditional MMC snap-ins" -ForegroundColor White
    Write-Host "  - Manages servers, clusters, and hyper-converged infrastructure" -ForegroundColor White
    Write-Host "  - Integrates with Azure services" -ForegroundColor White
    Write-Host "  - Default port: 443 (HTTPS)" -ForegroundColor White
    Write-Host ""

    Write-Host "Key WAC Features:" -ForegroundColor Cyan
    Write-Host "  - Overview Dashboard: Real-time performance metrics" -ForegroundColor White
    Write-Host "  - Certificate Management: SSL/TLS certificate deployment" -ForegroundColor White
    Write-Host "  - Devices: Hardware inventory and management" -ForegroundColor White
    Write-Host "  - Events: Centralized event log viewing" -ForegroundColor White
    Write-Host "  - Files & File Sharing: File server management" -ForegroundColor White
    Write-Host "  - Firewall: Windows Firewall management" -ForegroundColor White
    Write-Host "  - Local Users & Groups: Account management" -ForegroundColor White
    Write-Host "  - Networks: Network adapter configuration" -ForegroundColor White
    Write-Host "  - PowerShell: Integrated PowerShell console" -ForegroundColor White
    Write-Host "  - Processes: Process monitoring and management" -ForegroundColor White
    Write-Host "  - Registry: Remote registry editing" -ForegroundColor White
    Write-Host "  - Roles & Features: Server role management" -ForegroundColor White
    Write-Host "  - Scheduled Tasks: Task automation" -ForegroundColor White
    Write-Host "  - Services: Service management" -ForegroundColor White
    Write-Host "  - Storage: Disk and volume management" -ForegroundColor White
    Write-Host "  - Updates: Windows Update management" -ForegroundColor White
    Write-Host "  - Virtual Machines: Hyper-V VM management" -ForegroundColor White
    Write-Host "  - Virtual Switches: Hyper-V networking" -ForegroundColor White
    Write-Host ""

    Write-Host "Installation:" -ForegroundColor Cyan
    Write-Host "  Download from: https://aka.ms/WACDownload" -ForegroundColor White
    Write-Host "  Install on: Windows Server or Windows 10/11 management PC" -ForegroundColor White
    Write-Host ""

    Write-Host "[INFO] WAC Best Practices:" -ForegroundColor Cyan
    Write-Host "  - Install on dedicated management server or PC" -ForegroundColor White
    Write-Host "  - Use HTTPS with valid certificates" -ForegroundColor White
    Write-Host "  - Integrate with Azure for hybrid management" -ForegroundColor White
    Write-Host "  - Keep WAC updated with latest version" -ForegroundColor White
    Write-Host "  - Use role-based access control (RBAC)" -ForegroundColor White
    Write-Host "  - Configure gateway settings for multi-server management" -ForegroundColor White
    Write-Host ""

} catch {
    Write-Host "[ERROR] $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

Write-Host "Demo completed successfully!" -ForegroundColor Green
Write-Host "Next Steps: Install and configure Windows Admin Center for centralized management" -ForegroundColor Yellow
