<#
.SYNOPSIS
    Task 11.3 - Configure Storage Spaces Direct

.DESCRIPTION
    Complete S2D deployment including enablement, pool, tier, and volume creation.

.NOTES
    Module: Module 11 - Implement Storage Spaces Direct
    Task: 11.3 - Configure Storage Spaces Direct
    Prerequisites: Failover Cluster with identical storage on all nodes
    PowerShell Version: 5.1+
#>

#Requires -RunAsAdministrator

$ErrorActionPreference = 'Stop'
Write-Host "=== AZ-801 Module 11: Task 11.3 - Configure Storage Spaces Direct ===" -ForegroundColor Cyan

function Write-Step { param([string]$Message); Write-Host "`n[STEP] $Message" -ForegroundColor Yellow }

try {
    Write-Step "Prerequisites for S2D"
    Write-Host "  - 2-16 nodes (4+ recommended for production)" -ForegroundColor White
    Write-Host "  - Identical servers (CPU, RAM, storage)" -ForegroundColor White
    Write-Host "  - Minimum 4 drives per node" -ForegroundColor White
    Write-Host "  - 10+ GbE networking with RDMA" -ForegroundColor White
    Write-Host "  - Windows Server 2016+ Datacenter Edition" -ForegroundColor White

    Write-Step "Enable Storage Spaces Direct"
    Write-Host @"
  # Test S2D readiness
  Test-Cluster -Include 'Storage Spaces Direct','Inventory','Network','System Configuration'
  
  # Enable S2D
  Enable-ClusterStorageSpacesDirect -Verbose
  # This will:
  # - Create storage pool from all available drives
  # - Create cache tier (if NVMe/SSD + HDD present)
  # - Configure fault domains
  # - Create default tiers
  
  # Verify S2D enabled
  Get-ClusterStorageSpacesDirect
  Get-StorageSubSystem Cluster* | Format-Table FriendlyName, HealthStatus
"@ -ForegroundColor Gray

    Write-Step "Create Storage Tiers"
    Write-Host @"
  # View available media types
  Get-StorageTier
  
  # Create custom performance tier
  New-StorageTier -StoragePoolFriendlyName 'S2D on *' ``
      -FriendlyName 'Performance' ``
      -MediaType SSD ``
      -ResiliencySettingName 'Mirror'
  
  # Create capacity tier
  New-StorageTier -StoragePoolFriendlyName 'S2D on *' ``
      -FriendlyName 'Capacity' ``
      -MediaType HDD ``
      -ResiliencySettingName 'Parity'
"@ -ForegroundColor Gray

    Write-Step "Create Virtual Disks"
    Write-Host @"
  # Create 3-way mirror volume (fastest, lowest capacity)
  New-Volume -FriendlyName 'VM-Storage' ``
      -FileSystem CSVFS_ReFS ``
      -StoragePoolFriendlyName 'S2D on *' ``
      -Size 1TB ``
      -ResiliencySettingName 'Mirror' ``
      -PhysicalDiskRedundancy 2  # 3-way mirror
  
  # Create 2-way mirror volume
  New-Volume -FriendlyName 'Data' ``
      -FileSystem CSVFS_ReFS ``
      -Size 2TB ``
      -ResiliencySettingName 'Mirror'
  
  # Create parity volume (highest capacity, slower)
  New-Volume -FriendlyName 'Archive' ``
      -FileSystem CSVFS_ReFS ``
      -Size 10TB ``
      -ResiliencySettingName 'Parity'
  
  # Create tiered volume (performance + capacity)
  New-Volume -FriendlyName 'Hybrid' ``
      -FileSystem CSVFS_ReFS ``
      -StorageTiers (Get-StorageTier Performance), (Get-StorageTier Capacity) ``
      -StorageTierSizes 200GB, 1800GB
"@ -ForegroundColor Gray

    Write-Step "Monitor S2D Health"
    Write-Host @"
  # Check storage health
  Get-StorageSubSystem Cluster* | Get-StorageHealth
  Get-StoragePool S2D* | Get-StorageHealthReport
  
  # View virtual disks
  Get-VirtualDisk | Format-Table FriendlyName, HealthStatus, OperationalStatus, Size
  
  # View physical disks
  Get-PhysicalDisk | Format-Table FriendlyName, MediaType, HealthStatus, Size
  
  # Monitor storage jobs
  Get-StorageJob
  
  # View CSV volumes
  Get-ClusterSharedVolume | Select-Object Name, State, OwnerNode
"@ -ForegroundColor Gray

    Write-Step "S2D Maintenance"
    Write-Host @"
  # Add capacity (add drives to all nodes, then):
  Get-StoragePool S2D* | Set-StoragePool -IsAutoPoolingEnabled `$true
  Get-StoragePool S2D* | Add-PhysicalDisk -PhysicalDisks (Get-PhysicalDisk -CanPool `$true)
  
  # Expand volume
  Get-VirtualDisk 'VM-Storage' | Resize-VirtualDisk -Size 2TB
  
  # Repair volume (if degraded)
  Get-VirtualDisk 'VM-Storage' | Repair-VirtualDisk
  
  # Optimize storage (defrag/trim)
  Get-StoragePool S2D* | Optimize-StoragePool
"@ -ForegroundColor Gray

    Write-Host "`n" + "="*80 -ForegroundColor Cyan
    Write-Host "[SUCCESS] Storage Spaces Direct Configuration Complete" -ForegroundColor Green

} catch {
    Write-Host "`n[ERROR] $_" -ForegroundColor Red
    exit 1
}
