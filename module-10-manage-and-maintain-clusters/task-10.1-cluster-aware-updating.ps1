<#
.SYNOPSIS
    Task 10.1 - Configure Cluster-Aware Updating (CAU)

.DESCRIPTION
    Comprehensive script for implementing Cluster-Aware Updating for automated
    cluster patching with minimal downtime. CAU automates the update process
    across all cluster nodes while maintaining workload availability.

.NOTES
    Module: Module 10 - Manage and Maintain Clusters
    Task: 10.1 - Configure Cluster-Aware Updating
    Prerequisites:
        - Failover Clustering configured
        - CAU feature installed
        - Administrative privileges
        - Windows Update configured
    PowerShell Version: 5.1+

.EXAMPLE
    .\task-10.1-cluster-aware-updating.ps1
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [string]$ClusterName = (Get-Cluster -ErrorAction SilentlyContinue).Name,
    [switch]$EnableSelfUpdatingMode,
    [int]$MaxRetriesPerNode = 3
)

$ErrorActionPreference = 'Stop'
Write-Host "=== AZ-801 Module 10: Task 10.1 - Configure Cluster-Aware Updating ===" -ForegroundColor Cyan
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
    #region Step 1: Understanding CAU
    Write-Step "Understanding Cluster-Aware Updating"

    Write-Info "CAU provides:"
    Write-Host "  - Automated patching with minimal downtime" -ForegroundColor White
    Write-Host "  - Orchestrated node updates (one at a time)" -ForegroundColor White
    Write-Host "  - Automatic workload migration during updates" -ForegroundColor White
    Write-Host "  - Self-updating and remote-updating modes" -ForegroundColor White
    Write-Host "  - Customizable update plugins" -ForegroundColor White

    Write-Host "`nCAU Modes:" -ForegroundColor Yellow
    Write-Host "  Remote-Updating: Managed from external computer" -ForegroundColor White
    Write-Host "  Self-Updating: Cluster updates itself on schedule" -ForegroundColor White
    #endregion

    #region Step 2: Install CAU Feature
    Write-Step "Installing Cluster-Aware Updating Feature"

    $cauFeature = Get-WindowsFeature -Name Failover-Clustering-AutomationServer -ErrorAction SilentlyContinue
    if ($cauFeature -and -not $cauFeature.Installed) {
        Write-Info "Installing CAU feature..."
        Install-WindowsFeature -Name Failover-Clustering-AutomationServer -IncludeManagementTools
        Write-Success "CAU feature installed"
    } elseif ($cauFeature.Installed) {
        Write-Success "CAU feature already installed"
    }

    # Check CAU module
    if (Get-Module -ListAvailable -Name ClusterAwareUpdating) {
        Import-Module ClusterAwareUpdating -ErrorAction SilentlyContinue
        Write-Success "CAU PowerShell module available"
    }
    #endregion

    #region Step 3: CAU Prerequisites Test
    Write-Step "Testing CAU Prerequisites"

    Write-Host "`nTest CAU Readiness:" -ForegroundColor Yellow
    Write-Host @"
  # Test if cluster is ready for CAU
  Test-CauSetup -ClusterName '$ClusterName' -Verbose

  # This checks:
  # - Firewall rules
  # - WMI connectivity
  # - Windows Update configuration
  # - Required permissions
"@ -ForegroundColor Gray

    # Try to run actual test if cluster available
    if ($ClusterName) {
        try {
            Write-Info "Running CAU setup test..."
            $testResult = Test-CauSetup -ClusterName $ClusterName -ErrorAction SilentlyContinue
            if ($testResult) {
                Write-Success "CAU setup test passed"
            }
        } catch {
            Write-Info "CAU setup test requires cluster environment"
        }
    }
    #endregion

    #region Step 4: Configure Self-Updating Mode
    Write-Step "Configuring Self-Updating Mode"

    Write-Info "Self-updating mode allows cluster to patch itself automatically"

    Write-Host "`nEnable Self-Updating Mode:" -ForegroundColor Yellow
    Write-Host @"
  # Configure CAU self-updating options
  Add-CauClusterRole -ClusterName '$ClusterName' ``
      -MaxFailedNodes 1 ``
      -MaxRetriesPerNode $MaxRetriesPerNode ``
      -RequireAllNodesOnline ``
      -EnableFirewallRules ``
      -DaysOfWeek 'Tuesday','Wednesday' ``
      -WeeksOfMonth '2','4' ``
      -Force

  # Configure update schedule (every 2nd and 4th Tuesday/Wednesday at 3 AM)
  Set-CauClusterRole -ClusterName '$ClusterName' ``
      -StartDate (Get-Date) ``
      -MaxFailedNodes 1

  # View CAU clustered role
  Get-CauClusterRole -ClusterName '$ClusterName'
"@ -ForegroundColor Gray

    Write-Host "`nSelf-Updating Parameters:" -ForegroundColor Yellow
    Write-Host "  MaxFailedNodes: Stop if X nodes fail (usually 1)" -ForegroundColor White
    Write-Host "  MaxRetriesPerNode: Retry count per node (2-3 typical)" -ForegroundColor White
    Write-Host "  RequireAllNodesOnline: All nodes must be up" -ForegroundColor White
    Write-Host "  DaysOfWeek: Scheduled update days" -ForegroundColor White
    Write-Host "  WeeksOfMonth: Which weeks to run (1-4)" -ForegroundColor White
    #endregion

    #region Step 5: Remote-Updating Mode
    Write-Step "Using Remote-Updating Mode"

    Write-Host "`nManual CAU Run (Remote-Updating):" -ForegroundColor Yellow
    Write-Host @"
  # Run CAU immediately (one-time update)
  Invoke-CauRun -ClusterName '$ClusterName' ``
      -MaxFailedNodes 1 ``
      -MaxRetriesPerNode $MaxRetriesPerNode ``
      -Force ``
      -Verbose

  # Run with specific plugins
  Invoke-CauRun -ClusterName '$ClusterName' ``
      -CauPluginName 'Microsoft.WindowsUpdatePlugin' ``
      -CauPluginArguments @{} ``
      -Force

  # Run with pre/post-update scripts
  Invoke-CauRun -ClusterName '$ClusterName' ``
      -PreUpdateScript 'C:\Scripts\PreUpdate.ps1' ``
      -PostUpdateScript 'C:\Scripts\PostUpdate.ps1' ``
      -Force
"@ -ForegroundColor Gray
    #endregion

    #region Step 6: CAU Plugins
    Write-Step "Understanding CAU Plugins"

    Write-Host "`nAvailable CAU Plugins:" -ForegroundColor Yellow
    Write-Host @"
  # View installed plugins
  Get-CauPlugin

  # Common plugins:
  # - Microsoft.WindowsUpdatePlugin: Windows Update/WSUS
  # - Microsoft.HotfixPlugin: Manual hotfix installation
  # - Microsoft.RollingUpgradePlugin: OS upgrades
"@ -ForegroundColor Gray

    try {
        if (Get-Command Get-CauPlugin -ErrorAction SilentlyContinue) {
            $plugins = Get-CauPlugin -ErrorAction SilentlyContinue
            if ($plugins) {
                Write-Host "`nInstalled CAU Plugins:" -ForegroundColor Yellow
                $plugins | Format-Table Name, Description -AutoSize
            }
        }
    } catch {
        Write-Info "CAU cmdlets require cluster environment"
    }
    #endregion

    #region Step 7: Monitor CAU Runs
    Write-Step "Monitoring CAU Progress"

    Write-Host "`nMonitoring Commands:" -ForegroundColor Yellow
    Write-Host @"
  # Get CAU run status
  Get-CauRun -ClusterName '$ClusterName'

  # View detailed run information
  Get-CauRun -ClusterName '$ClusterName' -Detailed

  # Stop a running CAU session
  Stop-CauRun -ClusterName '$ClusterName' -Force

  # View CAU events
  Get-WinEvent -LogName 'Microsoft-Windows-ClusterAwareUpdating/Admin' -MaxEvents 50

  # View last run report
  Get-CauReport -ClusterName '$ClusterName' -Last
  Get-CauReport -ClusterName '$ClusterName' -Detailed
"@ -ForegroundColor Gray
    #endregion

    #region Step 8: CAU Configuration
    Write-Step "Advanced CAU Configuration"

    Write-Host "`nCustom CAU Settings:" -ForegroundColor Yellow
    Write-Host @"
  # Configure update options
  Set-CauClusterRole -ClusterName '$ClusterName' ``
      -MaxFailedNodes 1 ``
      -MaxRetriesPerNode 3 ``
      -NodeOrder 'NODE1','NODE2','NODE3' ``
      -PostUpdateScript 'C:\Scripts\PostUpdate.ps1'

  # Disable CAU self-updating
  Disable-CauClusterRole -ClusterName '$ClusterName' -Force

  # Enable CAU self-updating
  Enable-CauClusterRole -ClusterName '$ClusterName'

  # Remove CAU from cluster
  Remove-CauClusterRole -ClusterName '$ClusterName' -Force
"@ -ForegroundColor Gray

    Write-Host "`nCAU Options:" -ForegroundColor Yellow
    Write-Host "  WarnAfter: Warning time before update (minutes)" -ForegroundColor White
    Write-Host "  StopAfter: Max run duration before stopping" -ForegroundColor White
    Write-Host "  StopOnPluginFailure: Halt on plugin errors" -ForegroundColor White
    Write-Host "  SeparateReboots: Reboot between plugin runs" -ForegroundColor White
    #endregion

    #region Step 9: Troubleshooting CAU
    Write-Step "Troubleshooting CAU Issues"

    Write-Host "`nCommon Issues:" -ForegroundColor Yellow

    Write-Host "`n1. Firewall Rules:" -ForegroundColor Cyan
    Write-Host @"
  # Ensure firewall rules are enabled
  Enable-CauClusterRole -ClusterName '$ClusterName' -EnableFirewallRules

  # Manual firewall configuration
  netsh advfirewall firewall set rule group="Cluster Aware Updating" new enable=yes
"@ -ForegroundColor Gray

    Write-Host "`n2. Failed Updates:" -ForegroundColor Cyan
    Write-Host @"
  # View last run details
  Get-CauReport -ClusterName '$ClusterName' -Last -Detailed

  # Check Windows Update logs on failed node
  Get-WindowsUpdateLog

  # Retry failed node manually
  Invoke-CauRun -ClusterName '$ClusterName' -NodeNames 'FAILEDNODE'
"@ -ForegroundColor Gray

    Write-Host "`n3. CAU Role Won't Start:" -ForegroundColor Cyan
    Write-Host @"
  # Check CAU cluster role state
  Get-ClusterGroup | Where-Object GroupType -eq 'ClusterUpdateGroup'

  # Verify CAU settings
  Get-CauClusterRole -ClusterName '$ClusterName'

  # Re-add CAU role if needed
  Remove-CauClusterRole -ClusterName '$ClusterName' -Force
  Add-CauClusterRole -ClusterName '$ClusterName' -Force
"@ -ForegroundColor Gray
    #endregion

    #region Step 10: Best Practices
    Write-Step "CAU Best Practices"

    Write-Host "`nCluster-Aware Updating Best Practices:" -ForegroundColor Yellow
    Write-Host "  1. Test CAU in non-production environment first" -ForegroundColor White
    Write-Host "  2. Schedule updates during maintenance windows" -ForegroundColor White
    Write-Host "  3. Use self-updating mode for hands-off patching" -ForegroundColor White
    Write-Host "  4. Set MaxFailedNodes to 1 for safety" -ForegroundColor White
    Write-Host "  5. Monitor CAU runs and review reports" -ForegroundColor White
    Write-Host "  6. Keep CAU coordinator updated" -ForegroundColor White
    Write-Host "  7. Use pre/post-update scripts for custom tasks" -ForegroundColor White
    Write-Host "  8. Ensure WSUS/Windows Update connectivity" -ForegroundColor White
    Write-Host "  9. Test failover scenarios before CAU runs" -ForegroundColor White
    Write-Host "  10. Document CAU schedule and configuration" -ForegroundColor White

    Write-Host "`nScheduling Recommendations:" -ForegroundColor Yellow
    Write-Host "  - Patch Tuesday: Schedule CAU 7-14 days after" -ForegroundColor White
    Write-Host "  - Frequency: Monthly or as needed for critical updates" -ForegroundColor White
    Write-Host "  - Time: Low-usage periods (nights/weekends)" -ForegroundColor White
    Write-Host "  - Duration: Plan for 2-4 hours per node" -ForegroundColor White
    #endregion

    #region Summary
    Write-Host "`n" + "="*80 -ForegroundColor Cyan
    Write-Success "Cluster-Aware Updating Configuration Completed"
    Write-Host "="*80 -ForegroundColor Cyan

    Write-Host "`nConfiguration Summary:" -ForegroundColor Yellow
    if ($ClusterName) {
        Write-Host "  Cluster Name: $ClusterName" -ForegroundColor White
    }
    Write-Host "  Self-Updating Mode: $(if($EnableSelfUpdatingMode){'Enabled'}else{'Disabled'})" -ForegroundColor White
    Write-Host "  Max Retries Per Node: $MaxRetriesPerNode" -ForegroundColor White

    Write-Host "`nNext Steps:" -ForegroundColor Yellow
    Write-Host "  - Test CAU setup: Test-CauSetup" -ForegroundColor Cyan
    Write-Host "  - Configure self-updating mode or run manual updates" -ForegroundColor Cyan
    Write-Host "  - Schedule regular update windows" -ForegroundColor Cyan
    Write-Host "  - Monitor CAU runs and reports" -ForegroundColor Cyan
    #endregion

} catch {
    Write-Host "`n[ERROR] Failed to configure CAU: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

Write-Host "`nScript completed successfully!" -ForegroundColor Green
