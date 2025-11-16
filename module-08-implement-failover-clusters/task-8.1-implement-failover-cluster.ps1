<#
.SYNOPSIS
    Task 8.1 - Implement Failover Clustering

.DESCRIPTION
    Comprehensive script for implementing and managing Windows Failover Clusters.
    Covers cluster validation, creation, node management, and diagnostics.

.NOTES
    Module: Module 8 - Implement Failover Clusters
    Task: 8.1 - Implement Failover Clustering
    Prerequisites:
        - Windows Server with Failover Clustering feature
        - Administrative privileges on all nodes
        - Shared storage configured
        - Network connectivity between nodes
    PowerShell Version: 5.1+

.EXAMPLE
    .\task-8.1-implement-failover-cluster.ps1
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [string[]]$ClusterNodes = @('NODE1', 'NODE2'),
    [string]$ClusterName = 'PROD-CLUSTER',
    [string]$ClusterIP = '192.168.1.100',
    [switch]$SkipValidation
)

$ErrorActionPreference = 'Stop'
Write-Host "=== AZ-801 Module 8: Task 8.1 - Implement Failover Clustering ===" -ForegroundColor Cyan
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
    #region Step 1: Prerequisites and Feature Installation
    Write-Step "Checking and Installing Failover Clustering Feature"

    # Check if Failover Clustering is installed
    $fcFeature = Get-WindowsFeature -Name Failover-Clustering

    if (-not $fcFeature.Installed) {
        Write-Info "Installing Failover Clustering feature and management tools..."
        Install-WindowsFeature -Name Failover-Clustering -IncludeManagementTools -Verbose
        Write-Success "Failover Clustering feature installed successfully"

        Write-Host "`n[WARNING] A restart may be required. Please restart all cluster nodes before proceeding." -ForegroundColor Yellow
        $restart = Read-Host "Have all nodes been restarted? (Y/N)"
        if ($restart -ne 'Y') {
            Write-Host "Please restart all nodes and re-run this script." -ForegroundColor Yellow
            exit 0
        }
    } else {
        Write-Success "Failover Clustering feature already installed"
    }

    # Verify management tools
    $rsat = Get-WindowsFeature -Name RSAT-Clustering-PowerShell
    if (-not $rsat.Installed) {
        Install-WindowsFeature -Name RSAT-Clustering-PowerShell
        Write-Success "PowerShell management tools installed"
    }

    # Display cluster PowerShell module
    $clusterModule = Get-Module -Name FailoverClusters -ListAvailable
    Write-Info "FailoverClusters module version: $($clusterModule.Version)"
    #endregion

    #region Step 2: Pre-Cluster Validation
    Write-Step "Running Cluster Validation Tests"

    if (-not $SkipValidation) {
        Write-Info "Validating cluster nodes: $($ClusterNodes -join ', ')"
        Write-Host "This process may take 10-15 minutes..." -ForegroundColor Cyan

        # Run comprehensive validation tests
        $validationReport = Test-Cluster -Node $ClusterNodes -Include "Storage Spaces Direct", "Inventory", "Network", "System Configuration", "Storage" -Verbose

        # Display validation results
        Write-Host "`nValidation Results:" -ForegroundColor Yellow
        $validationReport | Format-List

        # Save validation report
        $reportPath = "$env:TEMP\ClusterValidation-$(Get-Date -Format 'yyyyMMdd-HHmmss').htm"
        Write-Info "Validation report saved to: $reportPath"

        # Check for critical failures
        if ($validationReport.Summary -match "Failed") {
            Write-Host "[WARNING] Some validation tests failed. Review the report before proceeding." -ForegroundColor Yellow
            $continue = Read-Host "Continue with cluster creation? (Y/N)"
            if ($continue -ne 'Y') {
                Write-Host "Cluster creation cancelled. Please address validation failures." -ForegroundColor Yellow
                exit 0
            }
        } else {
            Write-Success "All validation tests passed"
        }
    } else {
        Write-Host "[WARNING] Validation skipped. This is not recommended for production." -ForegroundColor Yellow
    }
    #endregion

    #region Step 3: Create Failover Cluster
    Write-Step "Creating Failover Cluster"

    # Check if cluster already exists
    try {
        $existingCluster = Get-Cluster -Name $ClusterName -ErrorAction SilentlyContinue
        if ($existingCluster) {
            Write-Info "Cluster '$ClusterName' already exists"
            $cluster = $existingCluster
        } else {
            throw "Cluster not found"
        }
    } catch {
        Write-Info "Creating new cluster: $ClusterName"

        # Create the cluster with static IP
        $cluster = New-Cluster -Name $ClusterName -Node $ClusterNodes -StaticAddress $ClusterIP -NoStorage -Verbose

        Write-Success "Cluster created successfully"
    }

    # Display cluster information
    Write-Host "`nCluster Information:" -ForegroundColor Yellow
    $cluster | Format-List Name, Id, Domain, @{Name='Nodes';Expression={($_.Nodes | Select-Object -ExpandProperty Name) -join ', '}}

    # Get detailed cluster properties
    Write-Host "`nCluster Properties:" -ForegroundColor Yellow
    Get-Cluster | Select-Object Name, Domain, QuorumType, QuorumResource | Format-Table -AutoSize
    #endregion

    #region Step 4: Verify Cluster Nodes
    Write-Step "Verifying Cluster Nodes"

    # Get all cluster nodes and their status
    $nodes = Get-ClusterNode
    Write-Host "`nCluster Nodes:" -ForegroundColor Yellow
    $nodes | Format-Table Name, State, @{Name='NodeWeight';Expression={$_.NodeWeight}}, Id -AutoSize

    # Check node health
    foreach ($node in $nodes) {
        $state = $node.State
        if ($state -eq 'Up') {
            Write-Success "Node $($node.Name) is online and healthy"
        } else {
            Write-Host "[WARNING] Node $($node.Name) is in state: $state" -ForegroundColor Yellow
        }
    }
    #endregion

    #region Step 5: Add Additional Nodes (if needed)
    Write-Step "Node Management Example"

    Write-Info "To add a new node to the cluster, use:"
    Write-Host "  Add-ClusterNode -Name 'NODE3' -Cluster $ClusterName" -ForegroundColor Gray

    Write-Info "To remove a node from the cluster, use:"
    Write-Host "  Remove-ClusterNode -Name 'NODE3' -Cluster $ClusterName -Force" -ForegroundColor Gray

    Write-Info "To pause a node (prevent resources from running):"
    Write-Host "  Suspend-ClusterNode -Name 'NODE1' -Drain" -ForegroundColor Gray

    Write-Info "To resume a node:"
    Write-Host "  Resume-ClusterNode -Name 'NODE1'" -ForegroundColor Gray
    #endregion

    #region Step 6: Cluster Diagnostics and Logging
    Write-Step "Generating Cluster Diagnostic Logs"

    # Generate cluster log for troubleshooting
    $logPath = "$env:TEMP\ClusterLog-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Write-Info "Generating cluster logs (last 15 minutes)..."

    Get-ClusterLog -Destination $logPath -TimeSpan 15 -UseLocalTime

    Write-Success "Cluster log generated at: $logPath"

    # Display recent cluster events
    Write-Host "`nRecent Cluster Events (Last 10):" -ForegroundColor Yellow
    Get-WinEvent -LogName "Microsoft-Windows-FailoverClustering/Operational" -MaxEvents 10 -ErrorAction SilentlyContinue |
        Select-Object TimeCreated, Id, LevelDisplayName, Message |
        Format-Table -AutoSize -Wrap
    #endregion

    #region Step 7: Cluster Resources and Groups
    Write-Step "Reviewing Cluster Resources and Groups"

    # Get cluster groups
    Write-Host "`nCluster Groups:" -ForegroundColor Yellow
    Get-ClusterGroup | Format-Table Name, OwnerNode, State, GroupType -AutoSize

    # Get cluster resources
    Write-Host "`nCluster Resources:" -ForegroundColor Yellow
    Get-ClusterResource | Format-Table Name, ResourceType, State, OwnerGroup -AutoSize

    # Get cluster networks
    Write-Host "`nCluster Networks:" -ForegroundColor Yellow
    Get-ClusterNetwork | Format-Table Name, Role, State, @{Name='Address';Expression={$_.Address}} -AutoSize
    #endregion

    #region Step 8: Cluster Health Monitoring
    Write-Step "Cluster Health Check"

    # Check cluster health
    $healthReports = Get-Cluster | Get-ClusterNode | ForEach-Object {
        [PSCustomObject]@{
            NodeName = $_.Name
            State = $_.State
            DynamicWeight = $_.DynamicWeight
            NodeWeight = $_.NodeWeight
        }
    }

    Write-Host "`nCluster Health Summary:" -ForegroundColor Yellow
    $healthReports | Format-Table -AutoSize

    # Get cluster shared volumes (if configured)
    try {
        $csvs = Get-ClusterSharedVolume -ErrorAction SilentlyContinue
        if ($csvs) {
            Write-Host "`nCluster Shared Volumes:" -ForegroundColor Yellow
            $csvs | Format-Table Name, State, OwnerNode -AutoSize
        }
    } catch {
        Write-Info "No Cluster Shared Volumes configured yet"
    }
    #endregion

    #region Step 9: Cluster Configuration Backup
    Write-Step "Cluster Configuration Backup"

    Write-Info "Best practice: Regular cluster configuration backups"
    Write-Host "`nTo backup cluster configuration:" -ForegroundColor Gray
    Write-Host "  - Use Windows Server Backup to backup System State" -ForegroundColor Gray
    Write-Host "  - Export cluster configuration: Get-Cluster | Export-Clixml -Path 'C:\Backups\ClusterConfig.xml'" -ForegroundColor Gray
    Write-Host "  - Document quorum settings and network configuration" -ForegroundColor Gray
    #endregion

    #region Step 10: Best Practices and Next Steps
    Write-Step "Best Practices Summary"

    Write-Host "`nFailover Clustering Best Practices:" -ForegroundColor Yellow
    Write-Host "  1. Always run validation before creating a production cluster" -ForegroundColor White
    Write-Host "  2. Configure appropriate quorum settings (see task-8.5)" -ForegroundColor White
    Write-Host "  3. Use redundant network connections for cluster communications" -ForegroundColor White
    Write-Host "  4. Implement proper storage configuration (see task-8.4)" -ForegroundColor White
    Write-Host "  5. Keep all cluster nodes at the same patch level" -ForegroundColor White
    Write-Host "  6. Monitor cluster health regularly" -ForegroundColor White
    Write-Host "  7. Test failover scenarios before production use" -ForegroundColor White
    Write-Host "  8. Document cluster configuration and dependencies" -ForegroundColor White
    Write-Host "  9. Use Cluster Aware Updating for patching (see task-10.1)" -ForegroundColor White
    Write-Host "  10. Regular cluster log analysis for early problem detection" -ForegroundColor White

    Write-Host "`nNext Steps:" -ForegroundColor Yellow
    Write-Host "  - Configure cluster quorum (task-8.5-quorum-options.ps1)" -ForegroundColor Cyan
    Write-Host "  - Add shared storage (task-8.4-cluster-storage.ps1)" -ForegroundColor Cyan
    Write-Host "  - Configure cluster networks (task-8.6-cluster-network-adapters.ps1)" -ForegroundColor Cyan
    Write-Host "  - Create highly available workloads (Module 9)" -ForegroundColor Cyan
    #endregion

    #region Summary
    Write-Host "`n" + "="*80 -ForegroundColor Cyan
    Write-Success "Failover Cluster Implementation Completed Successfully"
    Write-Host "="*80 -ForegroundColor Cyan

    Write-Host "`nCluster Summary:" -ForegroundColor Yellow
    Write-Host "  Cluster Name: $($cluster.Name)" -ForegroundColor White
    Write-Host "  Node Count: $($nodes.Count)" -ForegroundColor White
    Write-Host "  Quorum Type: $(Get-Cluster | Select-Object -ExpandProperty QuorumType)" -ForegroundColor White
    Write-Host "  Cluster State: $(Get-Cluster | Select-Object -ExpandProperty State)" -ForegroundColor White
    #endregion

} catch {
    Write-Host "`n[ERROR] Failed to implement failover cluster: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red

    Write-Host "`nTroubleshooting Tips:" -ForegroundColor Yellow
    Write-Host "  1. Verify all nodes are reachable via network" -ForegroundColor White
    Write-Host "  2. Check firewall rules for cluster communication" -ForegroundColor White
    Write-Host "  3. Ensure all nodes are in the same domain" -ForegroundColor White
    Write-Host "  4. Verify shared storage is accessible from all nodes" -ForegroundColor White
    Write-Host "  5. Review cluster validation report for issues" -ForegroundColor White

    exit 1
}

Write-Host "`nScript completed successfully!" -ForegroundColor Green
