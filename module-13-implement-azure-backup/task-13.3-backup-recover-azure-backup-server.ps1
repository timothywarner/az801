<#
.SYNOPSIS
    Task 13.3 - Backup and Recover with Azure Backup Server

.DESCRIPTION
    Demo script for AZ-801 Module 13: Implement Azure Backup
    Demonstrates backup and recovery operations with MABS including protection groups,
    backup jobs, and recovery procedures.

.NOTES
    Module: Module 13 - Implement Azure Backup
    Task: 13.3 - Backup and Recover with Azure Backup Server
    Prerequisites: MABS installed, DPM PowerShell module
    PowerShell Version: 5.1+
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ProtectionGroupName = "PG-FileServers",

    [Parameter(Mandatory = $false)]
    [string]$DataSourcePath = "C:\SharedData",

    [Parameter(Mandatory = $false)]
    [string]$RecoveryPath = "C:\RecoveredData"
)

$ErrorActionPreference = 'Stop'
Write-Host "=== AZ-801 Module 13: Task 13.3 - Backup and Recover with Azure Backup Server ===" -ForegroundColor Cyan
Write-Host ""

try {
    # Step 1: Check MABS Installation
    Write-Host "[Step 1] Verifying MABS Installation" -ForegroundColor Yellow

    $mabsPath = "$env:ProgramFiles\Microsoft Azure Backup Server\DPM\bin"
    $dpmModulePath = Join-Path $mabsPath "DataProtectionManager.psd1"

    if (Test-Path $dpmModulePath) {
        Write-Host "  [OK] MABS installation found" -ForegroundColor Green
        Write-Host "  Path: $mabsPath" -ForegroundColor White

        # Import DPM module
        Import-Module $dpmModulePath -ErrorAction SilentlyContinue
        Write-Host "  DPM PowerShell module imported" -ForegroundColor Green
    } else {
        Write-Host "  [INFO] MABS not installed on this system" -ForegroundColor Yellow
        Write-Host "  Demonstrating MABS cmdlets and workflows..." -ForegroundColor Cyan
    }
    Write-Host ""

    # Step 2: Protection Groups Overview
    Write-Host "[Step 2] Managing Protection Groups" -ForegroundColor Yellow

    Write-Host "Protection Group cmdlets:" -ForegroundColor Cyan
    Write-Host '  Get-DPMProtectionGroup -DPMServerName "MABSServer"' -ForegroundColor Gray
    Write-Host '  New-DPMProtectionGroup -DPMServerName "MABSServer" -Name "PG-SQL"' -ForegroundColor Gray
    Write-Host '  Set-DPMProtectionGroup -ProtectionGroup $pg -Modify' -ForegroundColor Gray
    Write-Host ""

    Write-Host "Example: Creating a File Server Protection Group" -ForegroundColor White
    Write-Host '# Connect to MABS server' -ForegroundColor Gray
    Write-Host '$dpmServer = Connect-DPMServer -DPMServerName "MABS01"' -ForegroundColor Gray
    Write-Host ""
    Write-Host '# Create new protection group' -ForegroundColor Gray
    Write-Host '$pg = New-DPMProtectionGroup -DPMServerName $dpmServer -Name "FileServers"' -ForegroundColor Gray
    Write-Host ""
    Write-Host '# Add datasource (file server)' -ForegroundColor Gray
    Write-Host '$server = Get-DPMProductionServer -DPMServerName $dpmServer | Where-Object {$_.Name -eq "FS01"}' -ForegroundColor Gray
    Write-Host '$ds = Get-DPMDatasource -ProductionServer $server | Where-Object {$_.LogicalPath -eq "C:\SharedData"}' -ForegroundColor Gray
    Write-Host 'Add-DPMChildDatasource -ProtectionGroup $pg -ChildDatasource $ds' -ForegroundColor Gray
    Write-Host ""

    # Step 3: Configure Protection Schedule
    Write-Host "[Step 3] Configuring Protection Schedule" -ForegroundColor Yellow

    Write-Host "Disk-based backup schedule:" -ForegroundColor Cyan
    Write-Host '# Set short-term protection on disk' -ForegroundColor Gray
    Write-Host '$policyDisk = Get-DPMPolicyObjective -ProtectionGroup $pg -ShortTerm Disk' -ForegroundColor Gray
    Write-Host '$policyDisk.SynchronizationFrequencyMinimum = 15  # Sync every 15 minutes' -ForegroundColor Gray
    Write-Host '$policyDisk.RecoveryPointObjective = New-TimeSpan -Days 5' -ForegroundColor Gray
    Write-Host 'Set-DPMPolicyObjective -ProtectionGroup $pg -PolicyObjective $policyDisk' -ForegroundColor Gray
    Write-Host ""

    Write-Host "Online (Azure) backup schedule:" -ForegroundColor Cyan
    Write-Host '# Set long-term protection to Azure' -ForegroundColor Gray
    Write-Host '$policyOnline = Get-DPMPolicyObjective -ProtectionGroup $pg -LongTerm Online' -ForegroundColor Gray
    Write-Host '$schedule = Get-DPMPolicySchedule -ProtectionGroup $pg -LongTerm Online' -ForegroundColor Gray
    Write-Host '$schedule.DaysOfWeek = @("Sunday", "Wednesday")  # Weekly backups' -ForegroundColor Gray
    Write-Host 'Set-DPMPolicySchedule -ProtectionGroup $pg -Schedule $schedule -LongTerm Online' -ForegroundColor Gray
    Write-Host ""

    # Step 4: Start Backup Jobs
    Write-Host "[Step 4] Running Backup Jobs" -ForegroundColor Yellow

    Write-Host "Manual backup operations:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Initial replica creation:" -ForegroundColor White
    Write-Host '  New-DPMReplicaCreationMethod -ProtectionGroup $pg -Now' -ForegroundColor Gray
    Write-Host ""

    Write-Host "Express full backup:" -ForegroundColor White
    Write-Host '  $ds = Get-DPMDatasource -ProtectionGroup $pg' -ForegroundColor Gray
    Write-Host '  New-DPMRecoveryPoint -Datasource $ds[0] -Disk -BackupType ExpressFull' -ForegroundColor Gray
    Write-Host ""

    Write-Host "Online backup to Azure:" -ForegroundColor White
    Write-Host '  New-DPMRecoveryPoint -Datasource $ds[0] -Online -BackupType Full' -ForegroundColor Gray
    Write-Host ""

    # Step 5: Monitor Backup Jobs
    Write-Host "[Step 5] Monitoring Backup Jobs" -ForegroundColor Yellow

    Write-Host "Job monitoring cmdlets:" -ForegroundColor Cyan
    Write-Host '# Get all jobs' -ForegroundColor Gray
    Write-Host '$jobs = Get-DPMJob -DPMServerName $dpmServer -Status InProgress,NotStarted' -ForegroundColor Gray
    Write-Host ""
    Write-Host '# Get jobs for specific datasource' -ForegroundColor Gray
    Write-Host '$jobs = Get-DPMJob -Datasource $ds -Status All' -ForegroundColor Gray
    Write-Host ""
    Write-Host '# Monitor job progress' -ForegroundColor Gray
    Write-Host '$job | Format-Table JobType, Status, StartTime, EndTime, PercentComplete' -ForegroundColor Gray
    Write-Host ""

    # Step 6: Recovery Point Management
    Write-Host "[Step 6] Managing Recovery Points" -ForegroundColor Yellow

    Write-Host "Recovery point operations:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "List available recovery points:" -ForegroundColor White
    Write-Host '  $rps = Get-DPMRecoveryPoint -Datasource $ds' -ForegroundColor Gray
    Write-Host '  $rps | Format-Table DataLocation, RecoveryPointTime, RepresentedPointInTime' -ForegroundColor Gray
    Write-Host ""

    Write-Host "Filter recovery points:" -ForegroundColor White
    Write-Host '  # Disk-based recovery points' -ForegroundColor Gray
    Write-Host '  $diskRP = $rps | Where-Object {$_.DataLocation -eq "Disk"}' -ForegroundColor Gray
    Write-Host '  # Online (Azure) recovery points' -ForegroundColor Gray
    Write-Host '  $cloudRP = $rps | Where-Object {$_.DataLocation -eq "Cloud"}' -ForegroundColor Gray
    Write-Host ""

    # Step 7: Data Recovery
    Write-Host "[Step 7] Performing Data Recovery" -ForegroundColor Yellow

    Write-Host "Recovery scenarios:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. Recover to original location:" -ForegroundColor White
    Write-Host '   $recoverableItem = Get-DPMRecoverableItem -RecoveryPoint $rps[0]' -ForegroundColor Gray
    Write-Host '   $recoveryOption = New-DPMRecoveryOption -DatasourceType FileSystem `' -ForegroundColor Gray
    Write-Host '       -RecoveryLocation OriginalLocation -OverwriteType Overwrite' -ForegroundColor Gray
    Write-Host '   Restore-DPMRecoverableItem -RecoverableItem $recoverableItem `' -ForegroundColor Gray
    Write-Host '       -RecoveryOption $recoveryOption' -ForegroundColor Gray
    Write-Host ""

    Write-Host "2. Recover to alternate location:" -ForegroundColor White
    Write-Host '   $recoveryOption = New-DPMRecoveryOption -DatasourceType FileSystem `' -ForegroundColor Gray
    Write-Host '       -RecoveryLocation AlternateLocation -TargetServer "FS02" `' -ForegroundColor Gray
    Write-Host '       -RecoveryTargetLocation "D:\Recovered"' -ForegroundColor Gray
    Write-Host '   Restore-DPMRecoverableItem -RecoverableItem $recoverableItem `' -ForegroundColor Gray
    Write-Host '       -RecoveryOption $recoveryOption' -ForegroundColor Gray
    Write-Host ""

    Write-Host "3. Recover from Azure (online):" -ForegroundColor White
    Write-Host '   $cloudRP = $rps | Where-Object {$_.DataLocation -eq "Cloud"} | Select-Object -First 1' -ForegroundColor Gray
    Write-Host '   $recoverableItem = Get-DPMRecoverableItem -RecoveryPoint $cloudRP' -ForegroundColor Gray
    Write-Host '   Restore-DPMRecoverableItem -RecoverableItem $recoverableItem `' -ForegroundColor Gray
    Write-Host '       -RecoveryOption $recoveryOption' -ForegroundColor Gray
    Write-Host ""

    # Step 8: Workload-Specific Protection
    Write-Host "[Step 8] Workload-Specific Protection" -ForegroundColor Yellow

    Write-Host "SQL Server protection:" -ForegroundColor Cyan
    Write-Host '  $sqlServer = Get-DPMProductionServer | Where-Object {$_.ServerType -eq "SQL"}' -ForegroundColor Gray
    Write-Host '  $sqlDB = Get-DPMDatasource -ProductionServer $sqlServer | Where-Object {$_.Name -eq "AdventureWorks"}' -ForegroundColor Gray
    Write-Host '  Add-DPMChildDatasource -ProtectionGroup $pg -ChildDatasource $sqlDB' -ForegroundColor Gray
    Write-Host ""

    Write-Host "Hyper-V VM protection:" -ForegroundColor Cyan
    Write-Host '  $hvHost = Get-DPMProductionServer | Where-Object {$_.ServerType -eq "HyperVHost"}' -ForegroundColor Gray
    Write-Host '  $vm = Get-DPMDatasource -ProductionServer $hvHost | Where-Object {$_.Name -eq "WebServer01"}' -ForegroundColor Gray
    Write-Host '  Add-DPMChildDatasource -ProtectionGroup $pg -ChildDatasource $vm' -ForegroundColor Gray
    Write-Host ""

    # Step 9: Reporting and Compliance
    Write-Host "[Step 9] Reporting and Alerts" -ForegroundColor Yellow

    Write-Host "Generate backup reports:" -ForegroundColor Cyan
    Write-Host '  Get-DPMAlert -DPMServerName $dpmServer' -ForegroundColor Gray
    Write-Host '  Get-DPMBackupWindow -ProtectionGroup $pg' -ForegroundColor Gray
    Write-Host '  Get-DPMDatasourceProtectionOption -ProtectionGroup $pg' -ForegroundColor Gray
    Write-Host ""

    Write-Host "Check protection status:" -ForegroundColor Cyan
    Write-Host '  $pg = Get-DPMProtectionGroup -DPMServerName $dpmServer' -ForegroundColor Gray
    Write-Host '  $pg | Select-Object Name, ProtectionStatus, LastSuccessfulBackup' -ForegroundColor Gray
    Write-Host ""

    # Step 10: Best Practices
    Write-Host "[Step 10] MABS Backup Best Practices" -ForegroundColor Yellow

    Write-Host "[INFO] Best Practices:" -ForegroundColor Cyan
    Write-Host "  - Schedule backups during off-peak hours" -ForegroundColor White
    Write-Host "  - Use incremental backups for disk, full for Azure" -ForegroundColor White
    Write-Host "  - Maintain 5-7 days of disk recovery points" -ForegroundColor White
    Write-Host "  - Test recovery procedures monthly" -ForegroundColor White
    Write-Host "  - Monitor job status and resolve failures quickly" -ForegroundColor White
    Write-Host "  - Document protection group configurations" -ForegroundColor White
    Write-Host "  - Implement consistency checks for critical workloads" -ForegroundColor White
    Write-Host "  - Keep MABS agents updated on protected servers" -ForegroundColor White
    Write-Host ""

    Write-Host "[INFO] Recovery Time Considerations:" -ForegroundColor Cyan
    Write-Host "  - Disk recovery: Minutes to hours" -ForegroundColor White
    Write-Host "  - Azure recovery: Hours (depends on data size)" -ForegroundColor White
    Write-Host "  - Use disk for fast recovery, Azure for long-term retention" -ForegroundColor White
    Write-Host ""

} catch {
    Write-Host "[ERROR] An error occurred: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Script completed successfully!" -ForegroundColor Green
Write-Host "MABS backup and recovery procedures documented" -ForegroundColor Yellow
