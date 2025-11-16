<#
.SYNOPSIS
    Task 12.4 - Perform Hyper-V Failover

.DESCRIPTION
    Execute test, planned, and unplanned failover operations for Hyper-V replicated VMs.

.NOTES
    Module: Module 12 - Protect VMs with Hyper-V Replication
    Task: 12.4 - Perform Failover
    Prerequisites: Hyper-V Replica configured and replicating
    PowerShell Version: 5.1+
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param([string]$VMName = "TestVM")

$ErrorActionPreference = 'Stop'
Write-Host "=== AZ-801 Module 12: Task 12.4 - Perform Hyper-V Failover ===" -ForegroundColor Cyan

function Write-Step { param([string]$Message); Write-Host "`n[STEP] $Message" -ForegroundColor Yellow }

try {
    Write-Step "Test Failover (No Impact to Production)"
    Write-Host @"
  # Start test failover
  Start-VMFailover -VMName '$VMName' -Prepare -AsTest
  
  # On replica server, start test VM
  Start-VMFailover -VMName '$VMName' -AsTest
  Start-VM -Name '$VMName'
  
  # Verify test VM works correctly
  # Perform application testing
  
  # Stop test failover (cleanup)
  Stop-VMFailover -VMName '$VMName'
  
  # Resume replication
  Resume-VMReplication -VMName '$VMName'
"@ -ForegroundColor Gray

    Write-Step "Planned Failover (Controlled Migration)"
    Write-Host @"
  # Use for planned maintenance, zero data loss
  # On PRIMARY server:
  
  # 1. Prepare for failover (final sync)
  Start-VMFailover -VMName '$VMName' -Prepare
  # This does final replication sync
  
  # 2. Shut down primary VM
  Stop-VM -Name '$VMName'
  
  # 3. On REPLICA server, complete failover
  Start-VMFailover -VMName '$VMName'
  Start-VM -Name '$VMName'
  
  # 4. Verify VM is running on replica
  Get-VM -Name '$VMName'
"@ -ForegroundColor Gray

    Write-Step "Unplanned Failover (Disaster Recovery)"
    Write-Host @"
  # Use when primary site fails, potential data loss
  # On REPLICA server only:
  
  # 1. Choose recovery point
  Get-VMSnapshot -VMName '$VMName' -SnapshotType Replica
  
  # 2. Start unplanned failover (latest recovery point)
  Start-VMFailover -VMName '$VMName'
  
  # 3. Or use specific recovery point
  Start-VMFailover -VMName '$VMName' -VMRecoverySnapshot (Get-VMSnapshot -VMName '$VMName')[0]
  
  # 4. Start the VM
  Start-VM -Name '$VMName'
  
  # 5. Commit failover (makes it permanent)
  Set-VMReplication -VMName '$VMName' -Reverse
  Complete-VMFailover -VMName '$VMName'
"@ -ForegroundColor Gray

    Write-Step "Reverse Replication (Failback)"
    Write-Host @"
  # After failover, reverse replication direction
  # On current active server (former replica):
  
  # 1. Set reverse replication
  Set-VMReplication -VMName '$VMName' -Reverse
  
  # 2. Start initial replication back to original primary
  Start-VMInitialReplication -VMName '$VMName'
  
  # 3. When ready to failback, repeat planned failover process
  
  # 4. On new replica (original primary), prepare
  Start-VMFailover -VMName '$VMName' -Prepare
  
  # 5. Shut down VM on current active
  Stop-VM -Name '$VMName'
  
  # 6. On original primary, complete failover
  Start-VMFailover -VMName '$VMName'
  Start-VM -Name '$VMName'
"@ -ForegroundColor Gray

    Write-Step "Cancel Failover"
    Write-Host @"
  # Cancel test failover
  Stop-VMFailover -VMName '$VMName'
  Resume-VMReplication -VMName '$VMName'
  
  # Cancel planned failover (before completion)
  Resume-VMReplication -VMName '$VMName' -Resynchronize
"@ -ForegroundColor Gray

    Write-Step "Failover Best Practices"
    Write-Host "  1. Test failover monthly in non-production" -ForegroundColor White
    Write-Host "  2. Document failover procedures" -ForegroundColor White
    Write-Host "  3. Use planned failover for maintenance" -ForegroundColor White
    Write-Host "  4. Verify application functionality after failover" -ForegroundColor White
    Write-Host "  5. Monitor replication health before failover" -ForegroundColor White
    Write-Host "  6. Have rollback plan ready" -ForegroundColor White
    Write-Host "  7. Update DNS after failover if needed" -ForegroundColor White
    Write-Host "  8. Coordinate with application teams" -ForegroundColor White

    Write-Host "`n" + "="*80 -ForegroundColor Cyan
    Write-Host "[SUCCESS] Hyper-V Failover Procedures Complete" -ForegroundColor Green
    Write-Host "="*80 -ForegroundColor Cyan

    Write-Host "`nFailover Type Summary:" -ForegroundColor Yellow
    Write-Host "  Test Failover: Testing only, no impact" -ForegroundColor Cyan
    Write-Host "  Planned Failover: Controlled migration, no data loss" -ForegroundColor Cyan
    Write-Host "  Unplanned Failover: Emergency DR, potential data loss" -ForegroundColor Cyan

} catch {
    Write-Host "`n[ERROR] $_" -ForegroundColor Red
    exit 1
}
Write-Host "`nScript completed successfully!" -ForegroundColor Green
