<#
.SYNOPSIS
    Task 10.5 - Manage Cluster Windows Updates

.DESCRIPTION
    Windows Update management for failover clusters using CAU and manual methods.

.NOTES
    Module: Module 10 - Manage and Maintain Clusters
    Task: 10.5 - Manage Cluster Windows Updates
    Prerequisites: Failover Clustering, CAU
    PowerShell Version: 5.1+
#>

#Requires -RunAsAdministrator

$ErrorActionPreference = 'Stop'
Write-Host "=== AZ-801 Module 10: Task 10.5 - Manage Cluster Windows Updates ===" -ForegroundColor Cyan

function Write-Step { param([string]$Message); Write-Host "`n[STEP] $Message" -ForegroundColor Yellow }

try {
    Write-Step "Update Methods for Clusters"
    Write-Host "  1. Cluster-Aware Updating (CAU) - Automated" -ForegroundColor White
    Write-Host "  2. Manual rolling updates" -ForegroundColor White
    Write-Host "  3. Maintenance mode updates" -ForegroundColor White

    Write-Step "Using CAU for Updates (Recommended)"
    Write-Host @"
  # One-time update run
  Invoke-CauRun -ClusterName CLUSTER1 -MaxFailedNodes 1 -Force
  
  # Schedule monthly updates
  Add-CauClusterRole -ClusterName CLUSTER1 ``
      -DaysOfWeek Tuesday ``
      -WeeksOfMonth 2 ``
      -MaxFailedNodes 1 ``
      -EnableFirewallRules
  
  # Monitor update progress
  Get-CauRun -ClusterName CLUSTER1
  
  # View update report
  Get-CauReport -ClusterName CLUSTER1 -Last -Detailed
"@ -ForegroundColor Gray

    Write-Step "Manual Rolling Updates"
    Write-Host @"
  # For each node:
  foreach (`$node in Get-ClusterNode) {
      # 1. Drain workloads
      Suspend-ClusterNode -Name `$node.Name -Drain -Wait
      
      # 2. Install updates
      Install-WindowsUpdate -ComputerName `$node.Name -AcceptAll -AutoReboot
      
      # 3. Wait for reboot and updates
      Wait-Computer -ComputerName `$node.Name
      
      # 4. Resume node
      Resume-ClusterNode -Name `$node.Name
      
      # 5. Verify node health
      Get-ClusterNode -Name `$node.Name
  }
"@ -ForegroundColor Gray

    Write-Step "WSUS Integration"
    Write-Host @"
  # Configure Windows Update to use WSUS
  Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' ``
      -Name 'WUServer' -Value 'http://wsus.contoso.com:8530'
  
  # Configure CAU to use WSUS
  Invoke-CauRun -ClusterName CLUSTER1 ``
      -CauPluginName 'Microsoft.WindowsUpdatePlugin' ``
      -CauPluginArguments @{'IncludeRecommendedUpdates' = 'True'}
"@ -ForegroundColor Gray

    Write-Step "Best Practices"
    Write-Host "  1. Use CAU for automated patching" -ForegroundColor White
    Write-Host "  2. Schedule during maintenance windows" -ForegroundColor White
    Write-Host "  3. Test updates in lab first" -ForegroundColor White
    Write-Host "  4. Set MaxFailedNodes to 1" -ForegroundColor White
    Write-Host "  5. Monitor update progress" -ForegroundColor White
    Write-Host "  6. Keep update documentation" -ForegroundColor White

    Write-Host "`n" + "="*80 -ForegroundColor Cyan
    Write-Host "[SUCCESS] Update Management Overview Completed" -ForegroundColor Green

} catch {
    Write-Host "`n[ERROR] $_" -ForegroundColor Red
    exit 1
}
