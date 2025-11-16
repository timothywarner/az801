<#
.SYNOPSIS
    Task 23.1 - Configure Data Collection Rules

.DESCRIPTION
    Demo script for AZ-801 Module 23: Monitor with Azure Services
    Demonstrates Azure Monitor Data Collection Rules (DCRs) and Azure Monitor Agent
    for collecting telemetry from on-premises and Azure VMs.

.NOTES
    Module: Module 23 - Monitor with Azure Services
    Task: 23.1 - Configure Data Collection Rules
    Prerequisites: Azure subscription, Az PowerShell module
    PowerShell Version: 5.1+
#>

#Requires -RunAsAdministrator
#Requires -Modules Az.Accounts, Az.Monitor, Az.OperationalInsights

$ErrorActionPreference = 'Stop'
Write-Host "=== AZ-801 Module 23: Task 23.1 - Configure Data Collection Rules ===" -ForegroundColor Cyan
Write-Host ""

try {
    # Check Azure connection
    Write-Host "[Step 1] Verify Azure Connection" -ForegroundColor Yellow

    $context = Get-AzContext -ErrorAction SilentlyContinue
    if (-not $context) {
        Write-Host "Not connected to Azure. Use: Connect-AzAccount" -ForegroundColor Yellow
        Write-Host "This demo will show commands and concepts..." -ForegroundColor Cyan
    } else {
        Write-Host "Connected to Azure:" -ForegroundColor Green
        Write-Host "  Subscription: $($context.Subscription.Name)" -ForegroundColor White
        Write-Host "  Tenant: $($context.Tenant.Id)" -ForegroundColor White
    }
    Write-Host ""

    # Define variables
    $resourceGroup = "rg-monitoring-prod"
    $location = "eastus"
    $dcrName = "dcr-windows-server-monitoring"
    $workspaceName = "law-monitoring-prod"
    $vmName = "vm-webserver-01"

    # Create resource group
    Write-Host "[Step 2] Create Resource Group for Monitoring Resources" -ForegroundColor Yellow
    Write-Host "Command:" -ForegroundColor Cyan
    Write-Host "  New-AzResourceGroup -Name '$resourceGroup' -Location '$location'" -ForegroundColor White
    Write-Host ""

    # Create Log Analytics workspace
    Write-Host "[Step 3] Create Log Analytics Workspace" -ForegroundColor Yellow
    Write-Host "Command:" -ForegroundColor Cyan
    Write-Host @"
  New-AzOperationalInsightsWorkspace ``
    -ResourceGroupName '$resourceGroup' ``
    -Name '$workspaceName' ``
    -Location '$location' ``
    -Sku 'PerGB2018' ``
    -RetentionInDays 30
"@ -ForegroundColor White
    Write-Host ""

    # Get workspace ID
    Write-Host "[Step 4] Get Log Analytics Workspace Details" -ForegroundColor Yellow
    Write-Host "Command:" -ForegroundColor Cyan
    Write-Host @"
  `$workspace = Get-AzOperationalInsightsWorkspace ``
    -ResourceGroupName '$resourceGroup' ``
    -Name '$workspaceName'

  `$workspaceId = `$workspace.ResourceId
  `$workspaceKey = (Get-AzOperationalInsightsWorkspaceSharedKey ``
    -ResourceGroupName '$resourceGroup' ``
    -Name '$workspaceName').PrimarySharedKey
"@ -ForegroundColor White
    Write-Host ""

    # Create Data Collection Endpoint
    Write-Host "[Step 5] Create Data Collection Endpoint (DCE)" -ForegroundColor Yellow
    Write-Host "Command:" -ForegroundColor Cyan
    Write-Host @"
  `$dceParams = @{
    ResourceGroupName = '$resourceGroup'
    Name = 'dce-$location'
    Location = '$location'
    NetworkAclsPublicNetworkAccess = 'Enabled'
  }

  New-AzDataCollectionEndpoint @dceParams
"@ -ForegroundColor White
    Write-Host ""

    # Define performance counters
    Write-Host "[Step 6] Define Performance Counter Collection" -ForegroundColor Yellow

    $perfCounters = @(
        @{
            Name = "Processor"
            Counters = @(
                @{Counter = "\\Processor(_Total)\\% Processor Time"; SampleInterval = 60}
                @{Counter = "\\Processor(_Total)\\% Privileged Time"; SampleInterval = 60}
            )
        }
        @{
            Name = "Memory"
            Counters = @(
                @{Counter = "\\Memory\\Available MBytes"; SampleInterval = 60}
                @{Counter = "\\Memory\\% Committed Bytes In Use"; SampleInterval = 60}
            )
        }
        @{
            Name = "Disk"
            Counters = @(
                @{Counter = "\\PhysicalDisk(_Total)\\% Disk Time"; SampleInterval = 60}
                @{Counter = "\\PhysicalDisk(_Total)\\Avg. Disk Queue Length"; SampleInterval = 60}
            )
        }
    )

    Write-Host "Performance Counters Configuration:" -ForegroundColor Cyan
    foreach ($category in $perfCounters) {
        Write-Host "  Category: $($category.Name)" -ForegroundColor White
        foreach ($counter in $category.Counters) {
            Write-Host "    - $($counter.Counter) (every $($counter.SampleInterval)s)" -ForegroundColor Gray
        }
    }
    Write-Host ""

    # Define Windows event logs
    Write-Host "[Step 7] Define Windows Event Log Collection" -ForegroundColor Yellow

    $eventLogs = @(
        @{LogName = "System"; Levels = @("Critical", "Error", "Warning")}
        @{LogName = "Application"; Levels = @("Critical", "Error", "Warning")}
        @{LogName = "Microsoft-Windows-WindowsUpdateClient/Operational"; Levels = @("Critical", "Error")}
    )

    Write-Host "Event Log Configuration:" -ForegroundColor Cyan
    foreach ($log in $eventLogs) {
        Write-Host "  $($log.LogName): $($log.Levels -join ', ')" -ForegroundColor White
    }
    Write-Host ""

    # Create Data Collection Rule
    Write-Host "[Step 8] Create Data Collection Rule (DCR)" -ForegroundColor Yellow

    $dcrConfig = @"
{
  "location": "$location",
  "properties": {
    "dataSources": {
      "performanceCounters": [
        {
          "name": "perfCounterDataSource",
          "streams": ["Microsoft-Perf"],
          "scheduledTransferPeriod": "PT1M",
          "samplingFrequencyInSeconds": 60,
          "counterSpecifiers": [
            "\\Processor(_Total)\\% Processor Time",
            "\\Memory\\Available MBytes",
            "\\PhysicalDisk(_Total)\\% Disk Time",
            "\\Network Interface(*)\\Bytes Total/sec"
          ]
        }
      ],
      "windowsEventLogs": [
        {
          "name": "eventLogsDataSource",
          "streams": ["Microsoft-Event"],
          "xPathQueries": [
            "System!*[System[(Level=1 or Level=2 or Level=3)]]",
            "Application!*[System[(Level=1 or Level=2 or Level=3)]]"
          ]
        }
      ]
    },
    "destinations": {
      "logAnalytics": [
        {
          "workspaceResourceId": "/subscriptions/{subscriptionId}/resourceGroups/$resourceGroup/providers/Microsoft.OperationalInsights/workspaces/$workspaceName",
          "name": "lawDestination"
        }
      ]
    },
    "dataFlows": [
      {
        "streams": ["Microsoft-Perf"],
        "destinations": ["lawDestination"]
      },
      {
        "streams": ["Microsoft-Event"],
        "destinations": ["lawDestination"]
      }
    ]
  }
}
"@

    Write-Host "DCR Configuration (JSON):" -ForegroundColor Cyan
    Write-Host $dcrConfig -ForegroundColor Gray
    Write-Host ""

    Write-Host "Create DCR using Azure CLI or ARM template:" -ForegroundColor Cyan
    Write-Host "  az monitor data-collection rule create --name '$dcrName' --resource-group '$resourceGroup' --rule-file dcr.json" -ForegroundColor White
    Write-Host ""

    # Install Azure Monitor Agent
    Write-Host "[Step 9] Install Azure Monitor Agent on VM" -ForegroundColor Yellow

    Write-Host "Using Azure CLI:" -ForegroundColor Cyan
    Write-Host @"
  az vm extension set ``
    --name AzureMonitorWindowsAgent ``
    --publisher Microsoft.Azure.Monitor ``
    --resource-group '$resourceGroup' ``
    --vm-name '$vmName' ``
    --enable-auto-upgrade true
"@ -ForegroundColor White
    Write-Host ""

    Write-Host "Using PowerShell:" -ForegroundColor Cyan
    Write-Host @"
  Set-AzVMExtension ``
    -Name AzureMonitorWindowsAgent ``
    -ExtensionType AzureMonitorWindowsAgent ``
    -Publisher Microsoft.Azure.Monitor ``
    -ResourceGroupName '$resourceGroup' ``
    -VMName '$vmName' ``
    -Location '$location' ``
    -TypeHandlerVersion '1.0' ``
    -EnableAutomaticUpgrade `$true
"@ -ForegroundColor White
    Write-Host ""

    # Associate DCR with VM
    Write-Host "[Step 10] Associate DCR with Virtual Machine" -ForegroundColor Yellow

    Write-Host "Create association:" -ForegroundColor Cyan
    Write-Host @"
  `$vmResourceId = (Get-AzVM -ResourceGroupName '$resourceGroup' -Name '$vmName').Id
  `$dcrResourceId = (Get-AzDataCollectionRule -ResourceGroupName '$resourceGroup' -Name '$dcrName').Id

  New-AzDataCollectionRuleAssociation ``
    -AssociationName "dcr-association-$vmName" ``
    -ResourceUri `$vmResourceId ``
    -DataCollectionRuleId `$dcrResourceId
"@ -ForegroundColor White
    Write-Host ""

    # Verify agent installation
    Write-Host "[Step 11] Verify Azure Monitor Agent Installation" -ForegroundColor Yellow

    Write-Host "Check agent status on VM:" -ForegroundColor Cyan
    Write-Host @"
  # On the VM:
  Get-Service -Name AzureMonitorAgent

  # Check agent configuration:
  Get-Content 'C:\WindowsAzure\Logs\AzureMonitorAgent\Configuration\*.json'

  # View agent logs:
  Get-Content 'C:\WindowsAzure\Logs\AzureMonitorAgent\*.log' -Tail 50
"@ -ForegroundColor White
    Write-Host ""

    # Query collected data
    Write-Host "[Step 12] Query Collected Data in Log Analytics" -ForegroundColor Yellow

    $kqlQueries = @"
-- Performance counters
Perf
| where TimeGenerated > ago(1h)
| where ObjectName == "Processor" and CounterName == "% Processor Time"
| summarize avg(CounterValue) by bin(TimeGenerated, 5m), Computer
| render timechart

-- Event logs
Event
| where TimeGenerated > ago(24h)
| where EventLevelName in ("Error", "Warning")
| summarize count() by Computer, Source, EventLevelName
| order by count_ desc

-- Heartbeat (agent connectivity)
Heartbeat
| where TimeGenerated > ago(1h)
| summarize max(TimeGenerated) by Computer
| where max_TimeGenerated < ago(5m)
| project Computer, LastHeartbeat = max_TimeGenerated
"@

    Write-Host "KQL Queries for monitoring:" -ForegroundColor Cyan
    Write-Host $kqlQueries -ForegroundColor Gray
    Write-Host ""

    # DCR management
    Write-Host "[Step 13] Manage Data Collection Rules" -ForegroundColor Yellow

    Write-Host "List all DCRs:" -ForegroundColor Cyan
    Write-Host "  Get-AzDataCollectionRule -ResourceGroupName '$resourceGroup'" -ForegroundColor White
    Write-Host ""

    Write-Host "Get DCR details:" -ForegroundColor Cyan
    Write-Host "  Get-AzDataCollectionRule -ResourceGroupName '$resourceGroup' -Name '$dcrName'" -ForegroundColor White
    Write-Host ""

    Write-Host "List DCR associations:" -ForegroundColor Cyan
    Write-Host "  Get-AzDataCollectionRuleAssociation -TargetResourceId `$vmResourceId" -ForegroundColor White
    Write-Host ""

    Write-Host "Remove DCR association:" -ForegroundColor Cyan
    Write-Host "  Remove-AzDataCollectionRuleAssociation -AssociationName 'dcr-association-$vmName' -TargetResourceId `$vmResourceId" -ForegroundColor White
    Write-Host ""

    # Cost optimization
    Write-Host "[Step 14] Cost Optimization for Data Collection" -ForegroundColor Yellow

    Write-Host "Best practices for cost control:" -ForegroundColor Cyan
    Write-Host "  1. Collect only necessary performance counters" -ForegroundColor White
    Write-Host "  2. Use appropriate sampling intervals (60s minimum recommended)" -ForegroundColor White
    Write-Host "  3. Filter event logs to critical/error levels" -ForegroundColor White
    Write-Host "  4. Set appropriate Log Analytics workspace retention" -ForegroundColor White
    Write-Host "  5. Use data transformation to reduce data volume" -ForegroundColor White
    Write-Host ""

    Write-Host "Estimate data ingestion:" -ForegroundColor Cyan
    Write-Host @"
  # Query to estimate daily ingestion
  union *
  | where TimeGenerated > ago(24h)
  | summarize DataSizeMB = sum(_BilledSize) / 1024 / 1024 by _ResourceId
  | extend EstimatedMonthlyGB = DataSizeMB * 30 / 1024
"@ -ForegroundColor Gray
    Write-Host ""

    # Hybrid monitoring
    Write-Host "[Step 15] Monitor On-Premises Servers with Azure Arc" -ForegroundColor Yellow

    Write-Host "Install Azure Arc agent on on-premises server:" -ForegroundColor Cyan
    Write-Host @"
  # Download and run Arc installation script
  Invoke-WebRequest -Uri https://aka.ms/AzureConnectedMachineAgent -OutFile AzureConnectedMachineAgent.msi

  msiexec /i AzureConnectedMachineAgent.msi /l*v install.log /qn

  # Connect to Azure
  azcmagent connect ``
    --resource-group '$resourceGroup' ``
    --tenant-id '{tenantId}' ``
    --location '$location' ``
    --subscription-id '{subscriptionId}' ``
    --cloud 'AzureCloud'
"@ -ForegroundColor White
    Write-Host ""

    Write-Host "Install Azure Monitor Agent on Arc-enabled server:" -ForegroundColor Cyan
    Write-Host @"
  New-AzConnectedMachineExtension ``
    -Name AzureMonitorWindowsAgent ``
    -ResourceGroupName '$resourceGroup' ``
    -MachineName 'onprem-server-01' ``
    -Location '$location' ``
    -Publisher 'Microsoft.Azure.Monitor' ``
    -ExtensionType 'AzureMonitorWindowsAgent' ``
    -EnableAutomaticUpgrade
"@ -ForegroundColor White
    Write-Host ""

    Write-Host "[INFO] Data Collection Rules Best Practices:" -ForegroundColor Cyan
    Write-Host "  - Use DCRs for centralized configuration management" -ForegroundColor White
    Write-Host "  - Create separate DCRs for different server roles" -ForegroundColor White
    Write-Host "  - Test DCRs in dev/test before production deployment" -ForegroundColor White
    Write-Host "  - Use Azure Policy to enforce DCR associations" -ForegroundColor White
    Write-Host "  - Monitor agent health using Heartbeat table" -ForegroundColor White
    Write-Host "  - Leverage data transformation to optimize costs" -ForegroundColor White
    Write-Host "  - Document DCR configurations in source control" -ForegroundColor White
    Write-Host ""

    Write-Host "[INFO] Migration from Legacy Agents:" -ForegroundColor Cyan
    Write-Host "  - Azure Monitor Agent (AMA) replaces Log Analytics Agent (MMA)" -ForegroundColor White
    Write-Host "  - DCRs replace workspace-based collection rules" -ForegroundColor White
    Write-Host "  - MMA retirement planned for August 2024" -ForegroundColor White
    Write-Host "  - Use DCR Config Generator for migration assistance" -ForegroundColor White
    Write-Host "  - Test AMA alongside MMA before full migration" -ForegroundColor White
    Write-Host ""

} catch {
    Write-Host "[ERROR] $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

Write-Host "Demo completed successfully!" -ForegroundColor Green
Write-Host "Next Steps: Create and deploy Data Collection Rules for your environment" -ForegroundColor Yellow
