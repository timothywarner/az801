<#
.SYNOPSIS
    Task 25.4 - Troubleshoot Storage Issues

.DESCRIPTION
    Demo script for AZ-801 Module 25: Troubleshoot Advanced Issues
    Shows storage troubleshooting for local and cluster storage.

    Covers:
    - Disk and volume analysis
    - Storage Spaces troubleshooting
    - Volume repair and integrity checks
    - Performance monitoring
    - Event log analysis

.NOTES
    Module: Module 25 - Troubleshoot Advanced Issues
    Task: 25.4 - Troubleshoot Storage Issues
    Prerequisites: Windows Server, Administrative privileges
    PowerShell Version: 5.1+
#>

#Requires -RunAsAdministrator

$ErrorActionPreference = 'Stop'
Write-Host "=== AZ-801 Module 25: Task 25.4 - Troubleshoot Storage Issues ===" -ForegroundColor Cyan
Write-Host ""

try {
    Write-Host "[Step 1] Storage Troubleshooting - Overview" -ForegroundColor Yellow
    Write-Host "Comprehensive storage analysis and troubleshooting procedures" -ForegroundColor White
    Write-Host ""

    # ============================================
    # STEP 2: Basic Disk Analysis
    # ============================================
    Write-Host "[Step 2] Basic Disk and Volume Analysis" -ForegroundColor Yellow

    # Get all physical disks
    Write-Host "`n[2.1] Analyzing Physical Disks..." -ForegroundColor Cyan
    $physicalDisks = Get-PhysicalDisk

    foreach ($disk in $physicalDisks) {
        Write-Host "  Physical Disk $($disk.DeviceId):" -ForegroundColor White
        Write-Host "    Friendly Name: $($disk.FriendlyName)" -ForegroundColor Gray
        Write-Host "    Size: $([math]::Round($disk.Size / 1GB, 2)) GB" -ForegroundColor Gray
        Write-Host "    Media Type: $($disk.MediaType)" -ForegroundColor Gray
        Write-Host "    Health Status: $($disk.HealthStatus)" -ForegroundColor $(if($disk.HealthStatus -eq 'Healthy'){'Green'}else{'Red'})
        Write-Host "    Operational Status: $($disk.OperationalStatus)" -ForegroundColor Gray
        Write-Host "    Bus Type: $($disk.BusType)" -ForegroundColor Gray

        # Check for warnings
        if ($disk.HealthStatus -ne 'Healthy') {
            Write-Host "    [WARNING] Disk health issue detected!" -ForegroundColor Red
        }
    }

    # Get all disks (logical)
    Write-Host "`n[2.2] Analyzing Logical Disks..." -ForegroundColor Cyan
    $disks = Get-Disk

    foreach ($disk in $disks) {
        Write-Host "  Disk $($disk.Number):" -ForegroundColor White
        Write-Host "    Friendly Name: $($disk.FriendlyName)" -ForegroundColor Gray
        Write-Host "    Partition Style: $($disk.PartitionStyle)" -ForegroundColor Gray
        Write-Host "    Operational Status: $($disk.OperationalStatus)" -ForegroundColor Gray
        Write-Host "    Is Boot: $($disk.IsBoot)" -ForegroundColor Gray
        Write-Host "    Is System: $($disk.IsSystem)" -ForegroundColor Gray

        # Get partitions for this disk
        $partitions = Get-Partition -DiskNumber $disk.Number -ErrorAction SilentlyContinue
        if ($partitions) {
            Write-Host "    Partitions:" -ForegroundColor Gray
            foreach ($partition in $partitions) {
                $volume = Get-Volume -Partition $partition -ErrorAction SilentlyContinue
                if ($volume) {
                    Write-Host "      - Drive $($volume.DriveLetter): $([math]::Round($partition.Size / 1GB, 2)) GB, FS: $($volume.FileSystem), Health: $($volume.HealthStatus)" -ForegroundColor DarkGray
                }
            }
        }
    }

    # Get all volumes
    Write-Host "`n[2.3] Analyzing Volumes..." -ForegroundColor Cyan
    $volumes = Get-Volume | Where-Object {$_.DriveLetter}

    foreach ($volume in $volumes) {
        $freePercent = [math]::Round(($volume.SizeRemaining / $volume.Size) * 100, 2)
        Write-Host "  Volume $($volume.DriveLetter):\" -ForegroundColor White
        Write-Host "    File System: $($volume.FileSystem)" -ForegroundColor Gray
        Write-Host "    Size: $([math]::Round($volume.Size / 1GB, 2)) GB" -ForegroundColor Gray
        Write-Host "    Free Space: $([math]::Round($volume.SizeRemaining / 1GB, 2)) GB ($freePercent%)" -ForegroundColor Gray
        Write-Host "    Health Status: $($volume.HealthStatus)" -ForegroundColor $(if($volume.HealthStatus -eq 'Healthy'){'Green'}else{'Red'})

        # Check for low disk space
        if ($freePercent -lt 10) {
            Write-Host "    [WARNING] Low disk space (<10%)!" -ForegroundColor Red
        } elseif ($freePercent -lt 20) {
            Write-Host "    [CAUTION] Disk space getting low (<20%)" -ForegroundColor Yellow
        }
    }

    Write-Host "[SUCCESS] Basic disk analysis completed" -ForegroundColor Green
    Write-Host ""

    # ============================================
    # STEP 3: Storage Spaces Analysis
    # ============================================
    Write-Host "[Step 3] Storage Spaces Analysis" -ForegroundColor Yellow

    # Check if Storage Spaces is in use
    Write-Host "`n[3.1] Checking Storage Pools..." -ForegroundColor Cyan
    $storagePools = Get-StoragePool -ErrorAction SilentlyContinue | Where-Object {$_.IsPrimordial -eq $false}

    if ($storagePools) {
        foreach ($pool in $storagePools) {
            Write-Host "  Storage Pool: $($pool.FriendlyName)" -ForegroundColor White
            Write-Host "    Health Status: $($pool.HealthStatus)" -ForegroundColor $(if($pool.HealthStatus -eq 'Healthy'){'Green'}else{'Red'})
            Write-Host "    Operational Status: $($pool.OperationalStatus)" -ForegroundColor Gray
            Write-Host "    Total Size: $([math]::Round($pool.Size / 1GB, 2)) GB" -ForegroundColor Gray
            Write-Host "    Allocated: $([math]::Round($pool.AllocatedSize / 1GB, 2)) GB" -ForegroundColor Gray

            # Get virtual disks in this pool
            Write-Host "`n[3.2] Virtual Disks in Pool..." -ForegroundColor Cyan
            $virtualDisks = Get-VirtualDisk -StoragePool $pool -ErrorAction SilentlyContinue

            if ($virtualDisks) {
                foreach ($vDisk in $virtualDisks) {
                    Write-Host "    Virtual Disk: $($vDisk.FriendlyName)" -ForegroundColor White
                    Write-Host "      Health Status: $($vDisk.HealthStatus)" -ForegroundColor $(if($vDisk.HealthStatus -eq 'Healthy'){'Green'}else{'Red'})
                    Write-Host "      Operational Status: $($vDisk.OperationalStatus)" -ForegroundColor Gray
                    Write-Host "      Resiliency Type: $($vDisk.ResiliencySettingName)" -ForegroundColor Gray
                    Write-Host "      Size: $([math]::Round($vDisk.Size / 1GB, 2)) GB" -ForegroundColor Gray
                }
            }

            # Get physical disks in pool
            Write-Host "`n[3.3] Physical Disks in Pool..." -ForegroundColor Cyan
            $poolPhysicalDisks = Get-PhysicalDisk -StoragePool $pool -ErrorAction SilentlyContinue

            if ($poolPhysicalDisks) {
                foreach ($pDisk in $poolPhysicalDisks) {
                    Write-Host "    Physical Disk: $($pDisk.FriendlyName)" -ForegroundColor White
                    Write-Host "      Health: $($pDisk.HealthStatus)" -ForegroundColor $(if($pDisk.HealthStatus -eq 'Healthy'){'Green'}else{'Red'})
                    Write-Host "      Usage: $($pDisk.Usage)" -ForegroundColor Gray
                }
            }
        }
    } else {
        Write-Host "  No Storage Spaces pools configured (only primordial pool exists)" -ForegroundColor Gray
    }

    Write-Host "[SUCCESS] Storage Spaces analysis completed" -ForegroundColor Green
    Write-Host ""

    # ============================================
    # STEP 4: Volume Repair and Integrity
    # ============================================
    Write-Host "[Step 4] Volume Integrity Checks" -ForegroundColor Yellow
    Write-Host "Note: Actual repair operations commented out for safety" -ForegroundColor Gray
    Write-Host ""

    # Show how to check volume integrity
    Write-Host "[4.1] Volume Scan Commands (Educational):" -ForegroundColor Cyan
    Write-Host "  To scan volume C: for errors (read-only):" -ForegroundColor White
    Write-Host "    chkdsk C: /scan" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  To scan and repair volume C: (requires offline/reboot):" -ForegroundColor White
    Write-Host "    chkdsk C: /f /r" -ForegroundColor Yellow
    Write-Host "    Where /f = fix errors, /r = locate bad sectors" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  To repair volume using PowerShell:" -ForegroundColor White
    Write-Host "    Repair-Volume -DriveLetter C -Scan           # Scan only" -ForegroundColor Yellow
    Write-Host "    Repair-Volume -DriveLetter C -OfflineScanAndFix  # Full repair" -ForegroundColor Yellow
    Write-Host ""

    # Example: Scan volumes (non-destructive)
    Write-Host "[4.2] Performing Online Volume Scans..." -ForegroundColor Cyan
    foreach ($volume in $volumes) {
        if ($volume.DriveLetter) {
            Write-Host "  Scanning volume $($volume.DriveLetter):..." -ForegroundColor White
            Write-Host "    [INFO] In production, run: Repair-Volume -DriveLetter $($volume.DriveLetter) -Scan" -ForegroundColor Gray
            # Repair-Volume -DriveLetter $volume.DriveLetter -Scan -ErrorAction SilentlyContinue
        }
    }

    Write-Host "[SUCCESS] Volume integrity check information provided" -ForegroundColor Green
    Write-Host ""

    # ============================================
    # STEP 5: Storage Diagnostics
    # ============================================
    Write-Host "[Step 5] Storage Diagnostic Information" -ForegroundColor Yellow

    Write-Host "`n[5.1] Collecting Storage Diagnostics..." -ForegroundColor Cyan
    Write-Host "  [INFO] Storage diagnostic info helps identify performance issues" -ForegroundColor Gray
    Write-Host "  Command: Get-StorageDiagnosticInfo -StorageSubSystemFriendlyName '*'" -ForegroundColor Yellow
    Write-Host ""

    # Get storage subsystems
    $storageSubSystems = Get-StorageSubSystem -ErrorAction SilentlyContinue
    foreach ($subsystem in $storageSubSystems) {
        Write-Host "  Storage Subsystem: $($subsystem.FriendlyName)" -ForegroundColor White
        Write-Host "    Health Status: $($subsystem.HealthStatus)" -ForegroundColor $(if($subsystem.HealthStatus -eq 'Healthy'){'Green'}else{'Red'})
        Write-Host "    Operational Status: $($subsystem.OperationalStatus)" -ForegroundColor Gray
    }

    Write-Host "[SUCCESS] Storage diagnostics reviewed" -ForegroundColor Green
    Write-Host ""

    # ============================================
    # STEP 6: Event Log Analysis
    # ============================================
    Write-Host "[Step 6] Storage Event Log Analysis" -ForegroundColor Yellow

    Write-Host "`n[6.1] Checking Disk Event Logs..." -ForegroundColor Cyan
    # Check System log for disk errors
    $diskErrors = Get-WinEvent -FilterHashtable @{
        LogName = 'System'
        ProviderName = 'disk', 'Ntfs', 'Volmgr'
        Level = 2,3  # Error and Warning
    } -MaxEvents 50 -ErrorAction SilentlyContinue

    if ($diskErrors) {
        Write-Host "  Found $($diskErrors.Count) recent disk-related errors/warnings:" -ForegroundColor Yellow
        $diskErrors | Select-Object -First 10 | ForEach-Object {
            Write-Host "    [$($_.TimeCreated)] $($_.ProviderName) - Event $($_.Id): $($_.Message.Substring(0, [Math]::Min(100, $_.Message.Length)))..." -ForegroundColor Gray
        }
    } else {
        Write-Host "  No recent disk errors found" -ForegroundColor Green
    }

    Write-Host "`n[6.2] Checking Storage Spaces Event Logs..." -ForegroundColor Cyan
    $storageSpacesErrors = Get-WinEvent -FilterHashtable @{
        LogName = 'Microsoft-Windows-Storage-Spaces-Driver/Operational'
        Level = 2,3
    } -MaxEvents 50 -ErrorAction SilentlyContinue

    if ($storageSpacesErrors) {
        Write-Host "  Found $($storageSpacesErrors.Count) recent Storage Spaces errors/warnings:" -ForegroundColor Yellow
        $storageSpacesErrors | Select-Object -First 10 | ForEach-Object {
            Write-Host "    [$($_.TimeCreated)] Event $($_.Id): $($_.Message.Substring(0, [Math]::Min(100, $_.Message.Length)))..." -ForegroundColor Gray
        }
    } else {
        Write-Host "  No recent Storage Spaces errors found" -ForegroundColor Green
    }

    Write-Host "[SUCCESS] Event log analysis completed" -ForegroundColor Green
    Write-Host ""

    # ============================================
    # STEP 7: Performance Monitoring
    # ============================================
    Write-Host "[Step 7] Storage Performance Monitoring" -ForegroundColor Yellow

    Write-Host "`n[7.1] Disk Performance Counters..." -ForegroundColor Cyan
    Write-Host "  Collecting disk performance metrics..." -ForegroundColor White

    # Get disk performance counters
    $physicalDiskCounters = Get-Counter -Counter "\PhysicalDisk(*)\Avg. Disk Queue Length",
                                                  "\PhysicalDisk(*)\Avg. Disk sec/Read",
                                                  "\PhysicalDisk(*)\Avg. Disk sec/Write",
                                                  "\PhysicalDisk(*)\% Disk Time" -ErrorAction SilentlyContinue

    if ($physicalDiskCounters) {
        foreach ($sample in $physicalDiskCounters.CounterSamples) {
            if ($sample.InstanceName -ne '_total') {
                $value = [math]::Round($sample.CookedValue, 3)
                $counterName = $sample.Path.Split('\')[-1]
                Write-Host "    $($sample.InstanceName) - $counterName : $value" -ForegroundColor Gray
            }
        }
    }

    Write-Host "`n[7.2] Performance Monitoring Tips:" -ForegroundColor Cyan
    Write-Host "  High Queue Length (>2): Indicates disk bottleneck" -ForegroundColor White
    Write-Host "  High Disk Time (>80%): Disk is saturated" -ForegroundColor White
    Write-Host "  High Latency (>20ms): Slow disk response" -ForegroundColor White
    Write-Host ""
    Write-Host "  Monitor continuously with:" -ForegroundColor Cyan
    Write-Host "    Get-Counter -Counter '\PhysicalDisk(*)\*' -Continuous" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[SUCCESS] Performance monitoring completed" -ForegroundColor Green
    Write-Host ""

    # ============================================
    # STEP 8: Common Troubleshooting Scenarios
    # ============================================
    Write-Host "[Step 8] Common Storage Troubleshooting Scenarios" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[Scenario 1] Disk Shows as 'Offline'" -ForegroundColor Cyan
    Write-Host "  Diagnosis:" -ForegroundColor White
    Write-Host "    Get-Disk | Where-Object {`$_.OperationalStatus -eq 'Offline'}" -ForegroundColor Yellow
    Write-Host "  Resolution:" -ForegroundColor White
    Write-Host "    Set-Disk -Number <DiskNumber> -IsOffline `$false" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[Scenario 2] Volume Shows as 'Unhealthy'" -ForegroundColor Cyan
    Write-Host "  Diagnosis:" -ForegroundColor White
    Write-Host "    Get-Volume | Where-Object {`$_.HealthStatus -ne 'Healthy'}" -ForegroundColor Yellow
    Write-Host "  Resolution:" -ForegroundColor White
    Write-Host "    Repair-Volume -DriveLetter <Letter> -OfflineScanAndFix" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[Scenario 3] Storage Pool Degraded" -ForegroundColor Cyan
    Write-Host "  Diagnosis:" -ForegroundColor White
    Write-Host "    Get-StoragePool | Where-Object {`$_.HealthStatus -ne 'Healthy'}" -ForegroundColor Yellow
    Write-Host "    Get-PhysicalDisk | Where-Object {`$_.HealthStatus -ne 'Healthy'}" -ForegroundColor Yellow
    Write-Host "  Resolution:" -ForegroundColor White
    Write-Host "    1. Identify failed disk: Get-PhysicalDisk | Where-Object {`$_.OperationalStatus -ne 'OK'}" -ForegroundColor Yellow
    Write-Host "    2. Remove failed disk: Remove-PhysicalDisk -PhysicalDisks <Disk> -StoragePoolFriendlyName '<Pool>'" -ForegroundColor Yellow
    Write-Host "    3. Add replacement: Add-PhysicalDisk -PhysicalDisks <NewDisk> -StoragePoolFriendlyName '<Pool>'" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[Scenario 4] Cannot Access Drive Letter" -ForegroundColor Cyan
    Write-Host "  Diagnosis:" -ForegroundColor White
    Write-Host "    Get-Volume | Where-Object {-not `$_.DriveLetter -and `$_.FileSystem}" -ForegroundColor Yellow
    Write-Host "  Resolution:" -ForegroundColor White
    Write-Host "    Get-Partition | Set-Partition -NewDriveLetter <Letter>" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[Scenario 5] Disk Performance Issues" -ForegroundColor Cyan
    Write-Host "  Diagnosis Commands:" -ForegroundColor White
    Write-Host "    # Check for high queue length" -ForegroundColor Gray
    Write-Host "    Get-Counter '\PhysicalDisk(*)\Avg. Disk Queue Length'" -ForegroundColor Yellow
    Write-Host "    # Check for high latency" -ForegroundColor Gray
    Write-Host "    Get-Counter '\PhysicalDisk(*)\Avg. Disk sec/Read'" -ForegroundColor Yellow
    Write-Host "    # Check disk utilization" -ForegroundColor Gray
    Write-Host "    Get-Counter '\PhysicalDisk(*)\% Disk Time'" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[SUCCESS] Troubleshooting scenarios documented" -ForegroundColor Green
    Write-Host ""

    # ============================================
    # STEP 9: Additional Troubleshooting Tools
    # ============================================
    Write-Host "[Step 9] Additional Storage Troubleshooting Tools" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[Tool 1] CHKDSK Parameters:" -ForegroundColor Cyan
    Write-Host "  chkdsk C: /scan           - Quick online scan" -ForegroundColor White
    Write-Host "  chkdsk C: /f              - Fix file system errors (offline)" -ForegroundColor White
    Write-Host "  chkdsk C: /r              - Locate bad sectors and recover data (offline)" -ForegroundColor White
    Write-Host "  chkdsk C: /x              - Force dismount first" -ForegroundColor White
    Write-Host ""

    Write-Host "[Tool 2] DISKPART Commands:" -ForegroundColor Cyan
    Write-Host "  diskpart -> list disk     - Show all disks" -ForegroundColor White
    Write-Host "  diskpart -> list volume   - Show all volumes" -ForegroundColor White
    Write-Host "  diskpart -> select disk N - Select disk for operations" -ForegroundColor White
    Write-Host ""

    Write-Host "[Tool 3] Storage Reports:" -ForegroundColor Cyan
    Write-Host "  Get-StorageReliabilityCounter -PhysicalDisk (Get-PhysicalDisk)" -ForegroundColor Yellow
    Write-Host "  Get-StorageHealthReport" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[SUCCESS] Additional tools documented" -ForegroundColor Green
    Write-Host ""

    # ============================================
    # Summary and Best Practices
    # ============================================
    Write-Host "[Summary] Storage Troubleshooting Best Practices" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Regular Monitoring:" -ForegroundColor Cyan
    Write-Host "  - Check disk health weekly: Get-PhysicalDisk | Select FriendlyName, HealthStatus" -ForegroundColor White
    Write-Host "  - Monitor free space: Get-Volume | Select DriveLetter, SizeRemaining" -ForegroundColor White
    Write-Host "  - Review storage events: Get-WinEvent for disk errors" -ForegroundColor White
    Write-Host ""

    Write-Host "Proactive Maintenance:" -ForegroundColor Cyan
    Write-Host "  - Schedule regular disk scans during maintenance windows" -ForegroundColor White
    Write-Host "  - Keep 20% free space on volumes for optimal performance" -ForegroundColor White
    Write-Host "  - Implement alerts for disk health status changes" -ForegroundColor White
    Write-Host "  - Regular backup verification and testing" -ForegroundColor White
    Write-Host ""

    Write-Host "Emergency Response:" -ForegroundColor Cyan
    Write-Host "  - Document DSRM password and recovery procedures" -ForegroundColor White
    Write-Host "  - Have replacement hardware available for critical systems" -ForegroundColor White
    Write-Host "  - Test disaster recovery procedures regularly" -ForegroundColor White
    Write-Host "  - Maintain offline copies of critical recovery tools" -ForegroundColor White
    Write-Host ""

    Write-Host "[INFO] Key Event IDs to Monitor:" -ForegroundColor Cyan
    Write-Host "  Event 7    - Disk has bad blocks" -ForegroundColor White
    Write-Host "  Event 11   - Disk controller error" -ForegroundColor White
    Write-Host "  Event 15   - Disk not ready for access" -ForegroundColor White
    Write-Host "  Event 51   - Disk warning/error during paging operation" -ForegroundColor White
    Write-Host "  Event 55   - File system structure corruption" -ForegroundColor White
    Write-Host ""

} catch {
    Write-Host "[ERROR] $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

Write-Host "Storage troubleshooting demonstration completed successfully!" -ForegroundColor Green
Write-Host "Next Steps: Implement monitoring and establish maintenance schedules" -ForegroundColor Yellow
