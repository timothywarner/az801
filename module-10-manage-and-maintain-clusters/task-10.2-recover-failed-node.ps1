<#
.SYNOPSIS
    Task 10.2 - Recover Failed Cluster Node

.DESCRIPTION
    Comprehensive procedures for recovering failed cluster nodes, including
    node diagnostics, removal, repair, and re-addition to the cluster.

.NOTES
    Module: Module 10 - Manage and Maintain Clusters
    Task: 10.2 - Recover Failed Cluster Node
    Prerequisites: Failover Clustering, Administrative privileges
    PowerShell Version: 5.1+

.EXAMPLE
    .\task-10.2-recover-failed-node.ps1 -NodeName "NODE2"
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [string]$NodeName = "NODE1",
    [switch]$ForceRemove
)

$ErrorActionPreference = 'Stop'
Write-Host "=== AZ-801 Module 10: Task 10.2 - Recover Failed Cluster Node ===" -ForegroundColor Cyan
Write-Host ""

#region Helper Functions
function Write-Step {
    param([string]$Message)
    Write-Host "`n[STEP] $Message" -ForegroundColor Yellow
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Cyan
}
#endregion

try {
    #region Step 1: Diagnose Node Failure
    Write-Step "Diagnosing Cluster Node Failure"

    Write-Host "`nCheck Node Status:" -ForegroundColor Yellow
    Write-Host @"
  # View all cluster nodes and their states
  Get-ClusterNode | Format-Table Name, State, @{Name='Status';Expression={`$_.StatusInformation}}

  # Check specific node
  Get-ClusterNode -Name '$NodeName' | Format-List *

  # View cluster health
  Get-Cluster | Get-ClusterNode
  Get-ClusterResource | Where-Object State -ne 'Online'
"@ -ForegroundColor Gray

    if (Get-Command Get-ClusterNode -ErrorAction SilentlyContinue) {
        try {
            $nodes = Get-ClusterNode
            Write-Host "`nCluster Nodes:" -ForegroundColor Yellow
            $nodes | Format-Table Name, State, NodeWeight -AutoSize
        } catch {
            Write-Info "Cluster service not available"
        }
    }
    #endregion

    #region Step 2: Suspend and Drain Node
    Write-Step "Suspending and Draining Failed Node"

    Write-Host "`nSuspend Node (if accessible):" -ForegroundColor Yellow
    Write-Host @"
  # Suspend node and drain workloads
  Suspend-ClusterNode -Name '$NodeName' -Drain -Wait

  # Verify workloads moved
  Get-ClusterGroup | Where-Object OwnerNode -eq '$NodeName'

  # If node unresponsive, suspend without drain
  Suspend-ClusterNode -Name '$NodeName' -Force
"@ -ForegroundColor Gray
    #endregion

    #region Step 3: Remove Failed Node
    Write-Step "Removing Failed Node from Cluster"

    Write-Host "`nRemove Node:" -ForegroundColor Yellow
    Write-Host @"
  # Graceful removal (if node accessible)
  Remove-ClusterNode -Name '$NodeName' -Force

  # Force removal (if node offline/unresponsive)
  Remove-ClusterNode -Name '$NodeName' -Force -CleanupDisks

  # Evict node (most forceful)
  (Get-ClusterNode -Name '$NodeName').NodeWeight = 0
  Remove-ClusterNode -Name '$NodeName' -Force
"@ -ForegroundColor Gray

    Write-Host "`nCleanup Steps:" -ForegroundColor Yellow
    Write-Host "  1. Move or remove workloads from failed node" -ForegroundColor White
    Write-Host "  2. Suspend node (if accessible)" -ForegroundColor White
    Write-Host "  3. Remove node from cluster" -ForegroundColor White
    Write-Host "  4. Clean up quorum votes if needed" -ForegroundColor White
    #endregion

    #region Step 4: Node Repair
    Write-Step "Repairing Failed Node"

    Write-Host "`nNode Repair Procedures:" -ForegroundColor Yellow
    Write-Host @"
  # On the failed node (after removal):

  # 1. Check event logs
  Get-WinEvent -LogName System -MaxEvents 100 | Where-Object LevelDisplayName -eq 'Error'
  Get-WinEvent -LogName 'Microsoft-Windows-FailoverClustering/Operational' -MaxEvents 50

  # 2. Verify cluster service
  Get-Service ClusSvc
  Start-Service ClusSvc

  # 3. Clean cluster configuration (if rejoining)
  Clear-ClusterNode -Force

  # 4. Repair networking
  Test-NetConnection -ComputerName <other-node>
  Get-NetAdapter | Where-Object Status -eq 'Up'

  # 5. Repair storage connectivity
  Get-Disk
  Update-HostStorageCache

  # 6. Run SFC and DISM if OS corruption suspected
  sfc /scannow
  DISM /Online /Cleanup-Image /RestoreHealth
"@ -ForegroundColor Gray
    #endregion

    #region Step 5: Re-add Node to Cluster
    Write-Step "Re-adding Node to Cluster"

    Write-Host "`nRe-add Node:" -ForegroundColor Yellow
    Write-Host @"
  # From another cluster node:
  Add-ClusterNode -Name '$NodeName' -NoStorage

  # Verify node added successfully
  Get-ClusterNode -Name '$NodeName'

  # Resume node
  Resume-ClusterNode -Name '$NodeName'

  # Restore preferred owners if needed
  Get-ClusterGroup | Set-ClusterOwnerNode -Owners NODE1,NODE2,$NodeName
"@ -ForegroundColor Gray
    #endregion

    #region Step 6: Validate Cluster
    Write-Step "Validating Cluster After Node Recovery"

    Write-Host "`nValidation Tests:" -ForegroundColor Yellow
    Write-Host @"
  # Run cluster validation
  Test-Cluster -Node (Get-ClusterNode).Name -Include 'Inventory','Network','System Configuration'

  # Check quorum configuration
  Get-ClusterQuorum

  # Verify cluster resources
  Get-ClusterResource | Format-Table Name, State, OwnerNode

  # Test failover
  Move-ClusterGroup -Name 'Test' -Node '$NodeName'
"@ -ForegroundColor Gray
    #endregion

    #region Step 7: Storage Recovery
    Write-Step "Recovering Storage After Node Failure"

    Write-Host "`nStorage Recovery:" -ForegroundColor Yellow
    Write-Host @"
  # Bring disks online
  Get-ClusterResource | Where-Object ResourceType -eq 'Physical Disk' | Start-ClusterResource

  # Repair CSV
  Get-ClusterSharedVolume | Repair-ClusterSharedVolume

  # Update storage cache
  Update-HostStorageCache

  # Verify CSV accessibility
  Get-ClusterSharedVolume | Format-Table Name, State, OwnerNode
"@ -ForegroundColor Gray
    #endregion

    #region Step 8: Common Failure Scenarios
    Write-Step "Common Node Failure Scenarios"

    Write-Host "`n1. Network Failure:" -ForegroundColor Cyan
    Write-Host @"
  # Node isolated due to network issues
  - Check network cables and switches
  - Verify cluster network configuration
  - Test connectivity: Test-NetConnection
  - Review cluster network role settings
"@ -ForegroundColor White

    Write-Host "`n2. Storage Failure:" -ForegroundColor Cyan
    Write-Host @"
  # Node can't access shared storage
  - Verify HBA/iSCSI connectivity
  - Check storage array status
  - Update-HostStorageCache
  - Rescan storage: Update-Disk
"@ -ForegroundColor White

    Write-Host "`n3. Service Failure:" -ForegroundColor Cyan
    Write-Host @"
  # Cluster service won't start
  - Check event logs
  - Verify cluster database integrity
  - Clear-ClusterNode and rejoin
  - Restore from backup if needed
"@ -ForegroundColor White
    #endregion

    #region Step 9: Best Practices
    Write-Step "Node Recovery Best Practices"

    Write-Host "`nBest Practices:" -ForegroundColor Yellow
    Write-Host "  1. Always drain workloads before node maintenance" -ForegroundColor White
    Write-Host "  2. Document node removal/addition procedures" -ForegroundColor White
    Write-Host "  3. Keep cluster validation reports" -ForegroundColor White
    Write-Host "  4. Monitor cluster health regularly" -ForegroundColor White
    Write-Host "  5. Maintain spare hardware for quick replacement" -ForegroundColor White
    Write-Host "  6. Test recovery procedures regularly" -ForegroundColor White
    Write-Host "  7. Keep cluster logs for troubleshooting" -ForegroundColor White
    Write-Host "  8. Verify quorum after node changes" -ForegroundColor White
    Write-Host "  9. Update documentation after recovery" -ForegroundColor White
    Write-Host "  10. Review and address root cause" -ForegroundColor White
    #endregion

    #region Summary
    Write-Host "`n" + "="*80 -ForegroundColor Cyan
    Write-Success "Node Recovery Procedures Completed"
    Write-Host "="*80 -ForegroundColor Cyan

    Write-Host "`nRecovery Steps Summary:" -ForegroundColor Yellow
    Write-Host "  1. Diagnose failure" -ForegroundColor Cyan
    Write-Host "  2. Suspend and drain node" -ForegroundColor Cyan
    Write-Host "  3. Remove node from cluster" -ForegroundColor Cyan
    Write-Host "  4. Repair failed node" -ForegroundColor Cyan
    Write-Host "  5. Re-add node to cluster" -ForegroundColor Cyan
    Write-Host "  6. Validate cluster health" -ForegroundColor Cyan
    #endregion

} catch {
    Write-Host "`n[ERROR] Node recovery failed: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

Write-Host "`nScript completed successfully!" -ForegroundColor Green
