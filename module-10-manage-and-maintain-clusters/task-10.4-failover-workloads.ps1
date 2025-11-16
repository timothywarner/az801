<#
.SYNOPSIS
    Task 10.4 - Failover Cluster Workloads

.DESCRIPTION
    Demonstrates manual and automatic failover of cluster workloads.

.NOTES
    Module: Module 10 - Manage and Maintain Clusters
    Task: 10.4 - Failover Cluster Workloads
    Prerequisites: Failover Clustering
    PowerShell Version: 5.1+
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param([string]$GroupName = "TestGroup", [string]$TargetNode = "NODE2")

$ErrorActionPreference = 'Stop'
Write-Host "=== AZ-801 Module 10: Task 10.4 - Failover Cluster Workloads ===" -ForegroundColor Cyan

function Write-Step { param([string]$Message); Write-Host "`n[STEP] $Message" -ForegroundColor Yellow }
function Write-Info { param([string]$Message); Write-Host "[INFO] $Message" -ForegroundColor Cyan }

try {
    Write-Step "Manual Failover Operations"
    Write-Host @"
  # Move group to specific node
  Move-ClusterGroup -Name '$GroupName' -Node '$TargetNode'
  
  # Move all groups off a node
  Get-ClusterNode -Name NODE1 | Get-ClusterGroup | Move-ClusterGroup
  
  # Move group to best available node
  Move-ClusterGroup -Name '$GroupName'
  
  # Quick migration (brief interruption)
  Move-ClusterVirtualMachineRole -Name VM1 -Node '$TargetNode'
  
  # Live migration (no interruption - VMs only)
  Move-ClusterVirtualMachineRole -Name VM1 -Node '$TargetNode' -MigrationType Live
"@ -ForegroundColor Gray

    Write-Step "Preferred Owners Configuration"
    Write-Host @"
  # Set preferred owners (priority order)
  Get-ClusterGroup -Name '$GroupName' | Set-ClusterOwnerNode -Owners 'NODE1','NODE2','NODE3'
  
  # View preferred owners
  Get-ClusterOwnerNode -Group '$GroupName'
  
  # Failback to preferred owner
  Start-ClusterGroup -Name '$GroupName' -IgnorePersistentState
  
  # Configure auto-failback
  `$group = Get-ClusterGroup -Name '$GroupName'
  `$group.AutoFailbackType = 'AllowFailback'
  `$group.FailbackWindowStart = 2  # 2 AM
  `$group.FailbackWindowEnd = 6    # 6 AM
"@ -ForegroundColor Gray

    Write-Step "Testing Failover Scenarios"
    Write-Host @"
  # Test planned failover
  Move-ClusterGroup -Name '$GroupName' -Node '$TargetNode'
  Get-ClusterGroup -Name '$GroupName' | Format-Table Name, OwnerNode, State
  
  # Test unplanned failover (simulate node failure)
  Stop-ClusterNode -Name NODE1 -Force
  Get-ClusterGroup | Where-Object OwnerNode -eq 'NODE1'  # Should have moved
  
  # Bring node back
  Start-ClusterNode -Name NODE1
  
  # Monitor failover events
  Get-WinEvent -LogName 'Microsoft-Windows-FailoverClustering/Operational' ``
      -MaxEvents 50 | Where-Object Message -like '*failover*'
"@ -ForegroundColor Gray

    Write-Step "Failover Priority and Anti-Affinity"
    Write-Host @"
  # Set group priority (higher = starts first)
  (Get-ClusterGroup -Name 'CriticalApp').Priority = 3000
  (Get-ClusterGroup -Name 'LowPriority').Priority = 500
  
  # Anti-affinity (keep groups on different nodes)
  (Get-ClusterGroup -Name 'WebFE1').AntiAffinityClassNames = 'WebServers'
  (Get-ClusterGroup -Name 'WebFE2').AntiAffinityClassNames = 'WebServers'
  
  # View priorities
  Get-ClusterGroup | Select-Object Name, Priority, OwnerNode | Sort Priority -Desc
"@ -ForegroundColor Gray

    Write-Host "`n" + "="*80 -ForegroundColor Cyan
    Write-Host "[SUCCESS] Failover Operations Completed" -ForegroundColor Green
    Write-Host "="*80 -ForegroundColor Cyan

} catch {
    Write-Host "`n[ERROR] $_" -ForegroundColor Red
    exit 1
}
Write-Host "`nScript completed!" -ForegroundColor Green
