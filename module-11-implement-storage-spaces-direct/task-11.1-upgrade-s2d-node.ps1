<#
.SYNOPSIS
    Task 11.1 - Upgrade Storage Spaces Direct Node

.DESCRIPTION
    Procedures for upgrading S2D cluster nodes with storage maintenance mode.

.NOTES
    Module: Module 11 - Implement Storage Spaces Direct
    Task: 11.1 - Upgrade S2D Node
    Prerequisites: Storage Spaces Direct cluster
    PowerShell Version: 5.1+
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param([string]$NodeName = "S2D-NODE1")

$ErrorActionPreference = 'Stop'
Write-Host "=== AZ-801 Module 11: Task 11.1 - Upgrade S2D Node ===" -ForegroundColor Cyan

function Write-Step { param([string]$Message); Write-Host "`n[STEP] $Message" -ForegroundColor Yellow }

try {
    Write-Step "Enable Storage Maintenance Mode"
    Write-Host @"
  # Put node in storage maintenance mode
  Suspend-ClusterNode -Name '$NodeName' -Drain -ForceDrain -Wait
  
  # Enable storage maintenance mode (stops storage repair jobs)
  Get-StorageFaultDomain -Type StorageScaleUnit |
      Where-Object FriendlyName -eq '$NodeName' |
      Enable-StorageMaintenanceMode
  
  # Verify maintenance mode
  Get-StorageFaultDomain -Type StorageScaleUnit |
      Where-Object FriendlyName -eq '$NodeName' |
      Format-Table FriendlyName, OperationalStatus, HealthStatus
"@ -ForegroundColor Gray

    Write-Step "Perform Node Maintenance/Upgrade"
    Write-Host @"
  # Now safe to:
  # - Install Windows Updates
  # - Replace hardware
  # - Perform firmware updates
  # - In-place OS upgrade
  
  # Example: Install updates with CAU
  Invoke-CauRun -ClusterName CLUSTER1 -NodeNames '$NodeName' -Force
  
  # Or manual updates
  Install-WindowsUpdate -ComputerName '$NodeName' -AcceptAll -AutoReboot
"@ -ForegroundColor Gray

    Write-Step "Disable Storage Maintenance Mode"
    Write-Host @"
  # After maintenance complete:
  
  # Disable storage maintenance mode
  Get-StorageFaultDomain -Type StorageScaleUnit |
      Where-Object FriendlyName -eq '$NodeName' |
      Disable-StorageMaintenanceMode
  
  # Resume cluster node
  Resume-ClusterNode -Name '$NodeName'
  
  # Verify storage health
  Get-StorageSubSystem Cluster* | Get-StorageHealth
  Get-VirtualDisk | Format-Table FriendlyName, HealthStatus, OperationalStatus
  
  # Monitor storage repair jobs
  Get-StorageJob
"@ -ForegroundColor Gray

    Write-Step "Best Practices for S2D Node Maintenance"
    Write-Host "  1. Always use storage maintenance mode" -ForegroundColor White
    Write-Host "  2. Drain node before maintenance" -ForegroundColor White
    Write-Host "  3. One node at a time" -ForegroundColor White
    Write-Host "  4. Wait for storage repair before next node" -ForegroundColor White
    Write-Host "  5. Monitor storage health throughout" -ForegroundColor White
    Write-Host "  6. Keep minimum 3 nodes in S2D cluster" -ForegroundColor White
    Write-Host "  7. Test in non-production first" -ForegroundColor White

    Write-Host "`n" + "="*80 -ForegroundColor Cyan
    Write-Host "[SUCCESS] S2D Node Upgrade Procedures Complete" -ForegroundColor Green

} catch {
    Write-Host "`n[ERROR] $_" -ForegroundColor Red
    exit 1
}
