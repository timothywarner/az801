<#
.SYNOPSIS
    Task 10.3 - Upgrade Cluster Nodes

.DESCRIPTION
    Implements cluster-aware rolling OS upgrades using Cluster OS Rolling Upgrade feature.

.NOTES
    Module: Module 10 - Manage and Maintain Clusters
    Task: 10.3 - Upgrade Cluster Nodes
    Prerequisites: Failover Clustering, Windows Server 2016+
    PowerShell Version: 5.1+
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [string]$ClusterName = (Get-Cluster -ErrorAction SilentlyContinue).Name
)

$ErrorActionPreference = 'Stop'
Write-Host "=== AZ-801 Module 10: Task 10.3 - Upgrade Cluster Nodes ===" -ForegroundColor Cyan

#region Helper Functions
function Write-Step { param([string]$Message); Write-Host "`n[STEP] $Message" -ForegroundColor Yellow }
function Write-Success { param([string]$Message); Write-Host "[SUCCESS] $Message" -ForegroundColor Green }
function Write-Info { param([string]$Message); Write-Host "[INFO] $Message" -ForegroundColor Cyan }
#endregion

try {
    Write-Step "Understanding Cluster OS Rolling Upgrade"
    Write-Info "Allows upgrading cluster nodes without downtime"
    Write-Host "  - Mixed-mode operation during upgrade" -ForegroundColor White
    Write-Host "  - Upgrade nodes one at a time" -ForegroundColor White
    Write-Host "  - Update functional level when complete" -ForegroundColor White

    Write-Step "Pre-Upgrade Steps"
    Write-Host @"
  # 1. Backup cluster configuration
  Get-Cluster | Export-Clixml -Path C:\Backup\ClusterConfig.xml

  # 2. Document current configuration
  Get-ClusterNode | Export-Csv C:\Backup\Nodes.csv
  Get-ClusterGroup | Export-Csv C:\Backup\Groups.csv

  # 3. Check functional level (should be lower version)
  Get-Cluster | Select-Object Name, ClusterFunctionalLevel

  # 4. Ensure cluster is healthy
  Test-Cluster -Include 'System Configuration','Inventory'
"@ -ForegroundColor Gray

    Write-Step "Rolling Upgrade Process"
    Write-Host @"
  # For each node:
  `$node = 'NODE1'
  
  # 1. Drain workloads
  Suspend-ClusterNode -Name `$node -Drain -Wait
  
  # 2. Evict from cluster
  Remove-ClusterNode -Name `$node -Force
  
  # 3. Perform OS upgrade (in-place or rebuild)
  # - Boot from Windows Server 2022 media
  # - Perform in-place upgrade
  # - Or rebuild and restore configuration
  
  # 4. Install Failover Clustering feature
  Install-WindowsFeature -Name Failover-Clustering -IncludeManagementTools -Restart
  
  # 5. Rejoin cluster (from another node)
  Add-ClusterNode -Name `$node -NoStorage
  
  # 6. Verify node
  Get-ClusterNode -Name `$node
  Resume-ClusterNode -Name `$node
  
  # Repeat for each node
"@ -ForegroundColor Gray

    Write-Step "Update Cluster Functional Level"
    Write-Host @"
  # After ALL nodes upgraded:
  
  # 1. Verify all nodes on new OS
  Get-ClusterNode | Select-Object Name, @{N='OS';E={(Get-CimInstance Win32_OperatingSystem -ComputerName `$_.Name).Caption}}
  
  # 2. Check current functional level
  Get-Cluster | Select-Object ClusterFunctionalLevel
  
  # 3. Update functional level (IRREVERSIBLE!)
  Update-ClusterFunctionalLevel -Force
  
  # 4. Verify upgrade
  Get-Cluster | Format-List Name, ClusterFunctionalLevel
"@ -ForegroundColor Gray

    Write-Step "Best Practices"
    Write-Host "  1. Test upgrade process in lab environment" -ForegroundColor White
    Write-Host "  2. Backup all cluster configuration" -ForegroundColor White
    Write-Host "  3. Upgrade one node at a time" -ForegroundColor White
    Write-Host "  4. Validate after each node" -ForegroundColor White
    Write-Host "  5. Don't update functional level until all nodes upgraded" -ForegroundColor White
    Write-Host "  6. Update functional level is irreversible" -ForegroundColor White
    Write-Host "  7. Plan maintenance window (4-8 hours per node)" -ForegroundColor White

    Write-Host "`n" + "="*80 -ForegroundColor Cyan
    Write-Success "Cluster Upgrade Process Overview Completed"
    Write-Host "="*80 -ForegroundColor Cyan

} catch {
    Write-Host "`n[ERROR] $_" -ForegroundColor Red
    exit 1
}
Write-Host "`nScript completed successfully!" -ForegroundColor Green
