<#
.SYNOPSIS
    Task 9.2 - Configure Cluster Workload Options

.DESCRIPTION
    Comprehensive script for configuring cluster resource dependencies, groups,
    failover options, and workload management in Windows Failover Clustering.

.NOTES
    Module: Module 9 - Configure Advanced Cluster Features
    Task: 9.2 - Configure Cluster Workload Options
    Prerequisites:
        - Failover Clustering feature installed
        - Active failover cluster
        - Administrative privileges
    PowerShell Version: 5.1+

.EXAMPLE
    .\task-9.2-cluster-workload-options.ps1
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [string]$ClusterName = (Get-Cluster -ErrorAction SilentlyContinue).Name,
    [string]$ResourceGroupName = "AppGroup",
    [int]$FailoverThreshold = 3
)

$ErrorActionPreference = 'Stop'
Write-Host "=== AZ-801 Module 9: Task 9.2 - Configure Cluster Workload Options ===" -ForegroundColor Cyan
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
    #region Step 1: Cluster Resource Groups Overview
    Write-Step "Understanding Cluster Resource Groups"

    Write-Info "Cluster Resource Groups provide:"
    Write-Host "  - Logical grouping of related resources" -ForegroundColor White
    Write-Host "  - Coordinated failover of dependent resources" -ForegroundColor White
    Write-Host "  - Workload isolation and management" -ForegroundColor White

    # Display existing cluster groups
    if (Get-Command Get-ClusterGroup -ErrorAction SilentlyContinue) {
        Write-Host "`nExisting Cluster Groups:" -ForegroundColor Yellow
        $groups = Get-ClusterGroup
        $groups | Format-Table Name, OwnerNode, State, GroupType -AutoSize
    } else {
        Write-Info "Failover Clustering cmdlets not available - install Failover Clustering feature"
        $groups = @()
    }
    #endregion

    #region Step 2: Resource Dependencies
    Write-Step "Configuring Resource Dependencies"

    Write-Info "Resource dependencies ensure proper startup and shutdown order"

    Write-Host "`nExample: Creating resource dependencies" -ForegroundColor Yellow
    Write-Host @"
  # Simple AND dependency (Resource depends on Provider)
  Add-ClusterResourceDependency -Resource 'WebService' -Provider 'IPAddress'

  # OR dependency (Resource depends on Resource1 OR Resource2)
  Set-ClusterResourceDependency -Resource 'AppService' -Dependency '[IP1] or [IP2]'

  # Complex dependency
  Set-ClusterResourceDependency -Resource 'App' -Dependency '[Storage] and ([Net1] or [Net2])'

  # Remove dependencies
  Remove-ClusterResourceDependency -Resource 'WebService' -Provider 'IPAddress'
"@ -ForegroundColor Gray

    # Display resources and dependencies
    if ($groups.Count -gt 0) {
        Write-Host "`nCluster Resources:" -ForegroundColor Yellow
        $resources = Get-ClusterResource | Select-Object -First 5
        foreach ($resource in $resources) {
            Write-Host "`nResource: $($resource.Name) (Type: $($resource.ResourceType))" -ForegroundColor Cyan
            Write-Host "  State: $($resource.State)" -ForegroundColor White
            Write-Host "  Owner Group: $($resource.OwnerGroup)" -ForegroundColor White
        }
    }
    #endregion

    #region Step 3: Resource Failover Options
    Write-Step "Configuring Resource Failover Options"

    Write-Host "`nFailover Settings Configuration:" -ForegroundColor Yellow
    Write-Host @"
  # Configure restart and failover settings
  Get-ClusterResource -Name 'MyResource' | Set-ClusterParameter -Multiple @{
      RestartAction = 'Restart'
      RestartDelay = 500              # Milliseconds before restart
      RestartPeriod = 900000          # Period in ms (15 minutes)
      RestartThreshold = 3            # Max restarts before failover
      PendingTimeout = 180000         # Timeout for pending state
      LooksAlivePollInterval = 5000   # Health check interval
      IsAlivePollInterval = 60000     # Detailed health check
  }
"@ -ForegroundColor Gray

    Write-Host "`nRestart Actions:" -ForegroundColor Yellow
    Write-Host "  - Leave: Do nothing (manual intervention required)" -ForegroundColor White
    Write-Host "  - Restart: Restart resource on same node" -ForegroundColor White
    Write-Host "  - Failover: Move resource to another node" -ForegroundColor White
    #endregion

    #region Step 4: Preferred Owners
    Write-Step "Configuring Preferred Owners"

    Write-Host "`nPreferred Owners Configuration:" -ForegroundColor Yellow
    Write-Host @"
  # Set preferred owners for a group (in priority order)
  `$group = Get-ClusterGroup -Name 'AppGroup'
  `$group | Set-ClusterOwnerNode -Owners 'NODE1','NODE2','NODE3'

  # View current preferred owners
  Get-ClusterOwnerNode -Group 'AppGroup'

  # Clear preferred owners (can run on any node)
  Get-ClusterGroup -Name 'AppGroup' | Set-ClusterOwnerNode -Owners @()
"@ -ForegroundColor Gray
    #endregion

    #region Step 5: Anti-Affinity Rules
    Write-Step "Configuring Anti-Affinity Rules"

    Write-Host "`nAnti-Affinity Configuration:" -ForegroundColor Yellow
    Write-Host @"
  # Create anti-affinity class (prevents groups from running on same node)
  (Get-ClusterGroup -Name 'Group1').AntiAffinityClassNames = 'WebServers'
  (Get-ClusterGroup -Name 'Group2').AntiAffinityClassNames = 'WebServers'

  # View anti-affinity configuration
  Get-ClusterGroup | Select-Object Name, AntiAffinityClassNames, OwnerNode

  # Remove anti-affinity
  (Get-ClusterGroup -Name 'Group1').AntiAffinityClassNames = `$null
"@ -ForegroundColor Gray
    #endregion

    #region Step 6: Group Priority
    Write-Step "Managing Group Priorities"

    Write-Host "`nGroup Priority Levels:" -ForegroundColor Yellow
    Write-Host "  - High Priority: 3000 (Critical services)" -ForegroundColor White
    Write-Host "  - Medium-High: 2000 (Important services)" -ForegroundColor White
    Write-Host "  - Medium: 1000 (Default)" -ForegroundColor White
    Write-Host "  - Low: 500 (Non-critical services)" -ForegroundColor White

    Write-Host "`nConfiguring Priority:" -ForegroundColor Yellow
    Write-Host @"
  # Set high priority for critical service
  (Get-ClusterGroup -Name 'SQL-Server').Priority = 3000

  # View priorities
  Get-ClusterGroup | Select-Object Name, Priority | Sort-Object Priority -Descending
"@ -ForegroundColor Gray
    #endregion

    #region Step 7: Failover and Failback
    Write-Step "Configuring Failover and Failback Behavior"

    Write-Host "`nFailover/Failback Configuration:" -ForegroundColor Yellow
    Write-Host @"
  # Configure failover settings for a group
  `$group = Get-ClusterGroup -Name 'AppGroup'
  `$group.FailoverThreshold = 3           # Max failovers in period
  `$group.FailoverPeriod = 6              # Period in hours
  `$group.AutoFailbackType = 'AllowFailback'
  `$group.FailbackWindowStart = 0         # 00:00 (midnight)
  `$group.FailbackWindowEnd = 4           # 04:00 (4 AM)
"@ -ForegroundColor Gray

    Write-Host "`nAuto-Failback Options:" -ForegroundColor Yellow
    Write-Host "  - PreventFailback: Stays on current node" -ForegroundColor White
    Write-Host "  - AllowFailback: Returns to preferred owner" -ForegroundColor White
    #endregion

    #region Step 8: Maintenance Mode
    Write-Step "Node Maintenance Mode and Resource Draining"

    Write-Host "`nMaintenance Commands:" -ForegroundColor Yellow
    Write-Host @"
  # Pause node and drain resources (move to other nodes)
  Suspend-ClusterNode -Name 'NODE1' -Drain -Wait

  # Resume node
  Resume-ClusterNode -Name 'NODE1'

  # Move specific group to another node
  Move-ClusterGroup -Name 'AppGroup' -Node 'NODE2'

  # Move all groups off a node
  Get-ClusterNode -Name 'NODE1' | Get-ClusterGroup | Move-ClusterGroup
"@ -ForegroundColor Gray
    #endregion

    #region Step 9: Generic Application Resources
    Write-Step "Creating Generic Application Resources"

    Write-Host "`nCreating Generic Service Resource:" -ForegroundColor Yellow
    Write-Host @"
  # Create resource group
  Add-ClusterGroup -Name 'CustomApp' -GroupType GenericService

  # Add IP address resource
  Add-ClusterResource -Name 'AppIP' -ResourceType 'IP Address' -Group 'CustomApp'
  Get-ClusterResource -Name 'AppIP' | Set-ClusterParameter -Multiple @{
      Address = '192.168.1.50'
      SubnetMask = '255.255.255.0'
  }

  # Add Network Name resource
  Add-ClusterResource -Name 'AppName' -ResourceType 'Network Name' -Group 'CustomApp'
  Get-ClusterResource -Name 'AppName' | Set-ClusterParameter -Name Name -Value 'APPSERVER'
  Add-ClusterResourceDependency -Resource 'AppName' -Provider 'AppIP'

  # Add Generic Service
  Add-ClusterResource -Name 'AppSvc' -ResourceType 'Generic Service' -Group 'CustomApp'
  Get-ClusterResource -Name 'AppSvc' | Set-ClusterParameter -Name ServiceName -Value 'MyService'
  Add-ClusterResourceDependency -Resource 'AppSvc' -Provider 'AppName'

  # Start resources
  Start-ClusterGroup -Name 'CustomApp'
"@ -ForegroundColor Gray
    #endregion

    #region Step 10: Best Practices
    Write-Step "Cluster Workload Best Practices"

    Write-Host "`nBest Practices:" -ForegroundColor Yellow
    Write-Host "  1. Use resource groups to logically organize dependent resources" -ForegroundColor White
    Write-Host "  2. Configure appropriate failover thresholds (typically 2-3)" -ForegroundColor White
    Write-Host "  3. Set failover periods to prevent resource thrashing" -ForegroundColor White
    Write-Host "  4. Use preferred owners for workload distribution" -ForegroundColor White
    Write-Host "  5. Configure auto-failback during maintenance windows" -ForegroundColor White
    Write-Host "  6. Implement anti-affinity for workload separation" -ForegroundColor White
    Write-Host "  7. Set appropriate resource priorities" -ForegroundColor White
    Write-Host "  8. Test failover scenarios regularly" -ForegroundColor White
    Write-Host "  9. Monitor cluster events and resource health" -ForegroundColor White
    Write-Host "  10. Keep dependency chains simple and logical" -ForegroundColor White
    #endregion

    #region Summary
    Write-Host "`n" + "="*80 -ForegroundColor Cyan
    Write-Success "Cluster Workload Options Configuration Completed"
    Write-Host "="*80 -ForegroundColor Cyan

    if ($groups.Count -gt 0) {
        Write-Host "`nConfiguration Summary:" -ForegroundColor Yellow
        Write-Host "  Total Cluster Groups: $(($groups | Measure-Object).Count)" -ForegroundColor White
        Write-Host "  Online Groups: $(($groups | Where-Object State -eq 'Online' | Measure-Object).Count)" -ForegroundColor White
    }

    Write-Host "`nNext Steps:" -ForegroundColor Yellow
    Write-Host "  - Configure Scale-Out File Server (task-9.3)" -ForegroundColor Cyan
    Write-Host "  - Test failover scenarios for critical workloads" -ForegroundColor Cyan
    #endregion

} catch {
    Write-Host "`n[ERROR] Failed to configure cluster workload options: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

Write-Host "`nScript completed successfully!" -ForegroundColor Green
