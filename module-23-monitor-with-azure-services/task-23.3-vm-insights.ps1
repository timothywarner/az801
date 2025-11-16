<#
.SYNOPSIS
    Task 23.3 - Configure VM Insights

.DESCRIPTION
    Demo script for AZ-801 Module 23: Monitor with Azure Services
    Demonstrates VM Insights deployment for performance and dependency monitoring
    on Azure VMs and Arc-enabled servers.

.NOTES
    Module: Module 23 - Monitor with Azure Services
    Task: 23.3 - Configure VM Insights
    Prerequisites: Azure subscription, Az PowerShell module
    PowerShell Version: 5.1+
#>

#Requires -RunAsAdministrator
#Requires -Modules Az.Accounts, Az.Compute, Az.OperationalInsights

$ErrorActionPreference = 'Stop'
Write-Host "=== AZ-801 Module 23: Task 23.3 - Configure VM Insights ===" -ForegroundColor Cyan
Write-Host ""

try {
    # Check Azure connection
    Write-Host "[Step 1] Verify Azure Connection" -ForegroundColor Yellow
    $context = Get-AzContext -ErrorAction SilentlyContinue
    if (-not $context) {
        Write-Host "Not connected. Use: Connect-AzAccount" -ForegroundColor Yellow
    } else {
        Write-Host "Connected: $($context.Subscription.Name)" -ForegroundColor Green
    }
    Write-Host ""

    # Variables
    $resourceGroup = "rg-monitoring-prod"
    $workspaceName = "law-monitoring-prod"
    $vmName = "vm-webserver-01"
    $location = "eastus"

    # Enable VM Insights
    Write-Host "[Step 2] Enable VM Insights on Azure VM" -ForegroundColor Yellow
    Write-Host @"
  # Install Dependency Agent extension
  Set-AzVMExtension ``
    -ResourceGroupName '$resourceGroup' ``
    -VMName '$vmName' ``
    -Name 'DAExtension' ``
    -Publisher 'Microsoft.Azure.Monitoring.DependencyAgent' ``
    -Type 'DependencyAgentWindows' ``
    -TypeHandlerVersion '9.10' ``
    -Location '$location'

  # Install Azure Monitor Agent
  Set-AzVMExtension ``
    -ResourceGroupName '$resourceGroup' ``
    -VMName '$vmName' ``
    -Name 'AzureMonitorWindowsAgent' ``
    -Publisher 'Microsoft.Azure.Monitor' ``
    -Type 'AzureMonitorWindowsAgent' ``
    -TypeHandlerVersion '1.0' ``
    -Location '$location' ``
    -EnableAutomaticUpgrade `$true
"@ -ForegroundColor White
    Write-Host ""

    # Configure workspace
    Write-Host "[Step 3] Configure Log Analytics Workspace for VM Insights" -ForegroundColor Yellow
    Write-Host @"
  # Enable VMInsights solution
  Set-AzOperationalInsightsIntelligencePack ``
    -ResourceGroupName '$resourceGroup' ``
    -WorkspaceName '$workspaceName' ``
    -IntelligencePackName 'VMInsights' ``
    -Enabled `$true

  # Enable ServiceMap solution
  Set-AzOperationalInsightsIntelligencePack ``
    -ResourceGroupName '$resourceGroup' ``
    -WorkspaceName '$workspaceName' ``
    -IntelligencePackName 'ServiceMap' ``
    -Enabled `$true
"@ -ForegroundColor White
    Write-Host ""

    # Query performance data
    Write-Host "[Step 4] Query VM Insights Performance Data" -ForegroundColor Yellow
    $perfQueries = @"
// Average CPU by computer
InsightsMetrics
| where Namespace == "Processor" and Name == "UtilizationPercentage"
| summarize AvgCPU = avg(Val) by bin(TimeGenerated, 5m), Computer
| render timechart

// Memory usage
InsightsMetrics
| where Namespace == "Memory" and Name == "AvailableMB"
| summarize AvgMemory = avg(Val) by bin(TimeGenerated, 5m), Computer
| render timechart

// Disk performance
InsightsMetrics
| where Namespace == "LogicalDisk" and Name == "FreeSpacePercentage"
| summarize AvgFreeSpace = avg(Val) by bin(TimeGenerated, 1h), Computer, Tags
| render timechart

// Network performance
InsightsMetrics
| where Namespace == "Network" and Name == "WriteBytesPerSecond"
| summarize NetworkSent = sum(Val) by bin(TimeGenerated, 5m), Computer
| render timechart
"@
    Write-Host "KQL Queries:" -ForegroundColor Cyan
    Write-Host $perfQueries -ForegroundColor Gray
    Write-Host ""

    # Service Map dependencies
    Write-Host "[Step 5] Query Service Map Dependencies" -ForegroundColor Yellow
    $mapQueries = @"
// Find all connections from a machine
VMConnection
| where Computer == "vm-webserver-01"
| summarize by DestinationIp, DestinationPort, ProcessName

// Find machines with most connections
VMConnection
| summarize ConnectionCount = count() by Computer
| order by ConnectionCount desc
| take 10

// Find failed connections
VMConnection
| where LinksFailed > 0
| project TimeGenerated, Computer, RemoteIp, ProcessName, LinksFailed

// Process dependencies
VMProcess
| where Computer == "vm-webserver-01"
| project TimeGenerated, ProcessName, CommandLine, Company
"@
    Write-Host "Service Map Queries:" -ForegroundColor Cyan
    Write-Host $mapQueries -ForegroundColor Gray
    Write-Host ""

    # Enable for Arc-enabled servers
    Write-Host "[Step 6] Enable VM Insights on Arc-Enabled Server" -ForegroundColor Yellow
    Write-Host @"
  # Install Dependency Agent
  New-AzConnectedMachineExtension ``
    -ResourceGroupName '$resourceGroup' ``
    -MachineName 'onprem-server-01' ``
    -Name 'DependencyAgentWindows' ``
    -Publisher 'Microsoft.Azure.Monitoring.DependencyAgent' ``
    -ExtensionType 'DependencyAgentWindows' ``
    -Location '$location'

  # Install Azure Monitor Agent
  New-AzConnectedMachineExtension ``
    -ResourceGroupName '$resourceGroup' ``
    -MachineName 'onprem-server-01' ``
    -Name 'AzureMonitorWindowsAgent' ``
    -Publisher 'Microsoft.Azure.Monitor' ``
    -ExtensionType 'AzureMonitorWindowsAgent' ``
    -Location '$location'
"@ -ForegroundColor White
    Write-Host ""

    # Bulk deployment
    Write-Host "[Step 7] Bulk Enable VM Insights" -ForegroundColor Yellow
    Write-Host @"
  # Get all VMs in resource group
  `$vms = Get-AzVM -ResourceGroupName '$resourceGroup'

  foreach (`$vm in `$vms) {
    Write-Host "Enabling VM Insights on `$(`$vm.Name)..."

    # Install agents
    Set-AzVMExtension ``
      -ResourceGroupName '$resourceGroup' ``
      -VMName `$vm.Name ``
      -Name 'AzureMonitorWindowsAgent' ``
      -Publisher 'Microsoft.Azure.Monitor' ``
      -Type 'AzureMonitorWindowsAgent' ``
      -TypeHandlerVersion '1.0' ``
      -Location `$vm.Location

    Set-AzVMExtension ``
      -ResourceGroupName '$resourceGroup' ``
      -VMName `$vm.Name ``
      -Name 'DAExtension' ``
      -Publisher 'Microsoft.Azure.Monitoring.DependencyAgent' ``
      -Type 'DependencyAgentWindows' ``
      -TypeHandlerVersion '9.10' ``
      -Location `$vm.Location
  }
"@ -ForegroundColor White
    Write-Host ""

    # Performance views
    Write-Host "[Step 8] Access VM Insights Views in Azure Portal" -ForegroundColor Yellow
    Write-Host "Navigate to:" -ForegroundColor Cyan
    Write-Host "  Azure Monitor > Virtual Machines > Performance" -ForegroundColor White
    Write-Host "  - CPU Utilization" -ForegroundColor Gray
    Write-Host "  - Available Memory" -ForegroundColor Gray
    Write-Host "  - Logical Disk Space" -ForegroundColor Gray
    Write-Host "  - Disk IOPS" -ForegroundColor Gray
    Write-Host "  - Network Send/Receive" -ForegroundColor Gray
    Write-Host ""

    Write-Host "  Azure Monitor > Virtual Machines > Map" -ForegroundColor White
    Write-Host "  - Process dependencies" -ForegroundColor Gray
    Write-Host "  - Network connections" -ForegroundColor Gray
    Write-Host "  - Port information" -ForegroundColor Gray
    Write-Host "  - Machine groups" -ForegroundColor Gray
    Write-Host ""

    # Workbooks
    Write-Host "[Step 9] Use VM Insights Workbooks" -ForegroundColor Yellow
    Write-Host "Available workbooks:" -ForegroundColor Cyan
    Write-Host "  - Performance by VM" -ForegroundColor White
    Write-Host "  - Connections Overview" -ForegroundColor White
    Write-Host "  - Active Ports" -ForegroundColor White
    Write-Host "  - Top Processes" -ForegroundColor White
    Write-Host "  - Capacity Planning" -ForegroundColor White
    Write-Host ""

    Write-Host "[INFO] VM Insights Best Practices:" -ForegroundColor Cyan
    Write-Host "  - Enable on all production VMs for complete visibility" -ForegroundColor White
    Write-Host "  - Use performance charts to identify resource constraints" -ForegroundColor White
    Write-Host "  - Leverage dependency maps for troubleshooting" -ForegroundColor White
    Write-Host "  - Create alerts based on performance metrics" -ForegroundColor White
    Write-Host "  - Regular review workbooks for capacity planning" -ForegroundColor White
    Write-Host "  - Combine with Application Insights for full-stack monitoring" -ForegroundColor White
    Write-Host ""

} catch {
    Write-Host "[ERROR] $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

Write-Host "Demo completed successfully!" -ForegroundColor Green
Write-Host "Next Steps: Enable VM Insights and explore performance and dependency data" -ForegroundColor Yellow
