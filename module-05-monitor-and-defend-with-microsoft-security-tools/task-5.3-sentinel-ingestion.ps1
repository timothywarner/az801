<#
.SYNOPSIS
    Task 5.3 - Configure Microsoft Sentinel Data Ingestion
.DESCRIPTION
    Comprehensive demonstration of configuring Microsoft Sentinel for Windows Server monitoring.
    Covers workspace creation, data collection rules, agent installation, and event ingestion.
.EXAMPLE
    .\task-5.3-sentinel-ingestion.ps1
.NOTES
    Module: Module 5 - Monitor and Defend with Microsoft Security Tools
    Task: 5.3 - Configure Microsoft Sentinel Data Ingestion
    Prerequisites:
    - Azure subscription with appropriate permissions
    - Az PowerShell modules (Az.Accounts, Az.OperationalInsights, Az.Monitor)
    - Windows Server with administrative privileges
    PowerShell Version: 5.1+
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

Write-Host "=== AZ-801 Module 5: Task 5.3 - Configure Microsoft Sentinel Data Ingestion ===" -ForegroundColor Cyan
Write-Host ""

try {
    # Step 1: Microsoft Sentinel Overview
    Write-Host "[Step 1] Microsoft Sentinel Overview" -ForegroundColor Yellow

    Write-Host "Microsoft Sentinel capabilities:" -ForegroundColor Cyan
    Write-Host "  - Cloud-native SIEM and SOAR solution" -ForegroundColor White
    Write-Host "  - Collect data across enterprise, users, apps, servers, and IoT" -ForegroundColor White
    Write-Host "  - Detect threats using Microsoft's analytics and threat intelligence" -ForegroundColor White
    Write-Host "  - Investigate threats with AI and hunt for suspicious activities" -ForegroundColor White
    Write-Host "  - Respond to incidents rapidly with built-in orchestration" -ForegroundColor White
    Write-Host ""

    Write-Host "Key components for Windows Server:" -ForegroundColor Cyan
    Write-Host "  - Log Analytics workspace (data repository)" -ForegroundColor White
    Write-Host "  - Azure Monitor Agent (data collector)" -ForegroundColor White
    Write-Host "  - Data Collection Rules (what to collect)" -ForegroundColor White
    Write-Host "  - Data connectors (integrate sources)" -ForegroundColor White
    Write-Host ""

    # Step 2: Check Azure PowerShell modules
    Write-Host "[Step 2] Checking Azure PowerShell modules" -ForegroundColor Yellow

    $requiredModules = @('Az.Accounts', 'Az.OperationalInsights', 'Az.Monitor', 'Az.SecurityInsights')

    foreach ($module in $requiredModules) {
        $installedModule = Get-Module -ListAvailable -Name $module | Select-Object -First 1
        if ($installedModule) {
            Write-Host "  $module : Version $($installedModule.Version) [OK]" -ForegroundColor Green
        } else {
            Write-Host "  $module : Not installed [MISSING]" -ForegroundColor Yellow
            Write-Host "    Install with: Install-Module -Name $module -Force -AllowClobber" -ForegroundColor Gray
        }
    }
    Write-Host ""

    # Step 3: Connect to Azure
    Write-Host "[Step 3] Connecting to Azure" -ForegroundColor Yellow

    Write-Host "Checking Azure connection..." -ForegroundColor Cyan
    try {
        $context = Get-AzContext
        if ($context) {
            Write-Host "Already connected to Azure" -ForegroundColor Green
            Write-Host "  Subscription: $($context.Subscription.Name)" -ForegroundColor White
            Write-Host "  Account: $($context.Account.Id)" -ForegroundColor White
            Write-Host "  Tenant: $($context.Tenant.Id)" -ForegroundColor White
        } else {
            Write-Host "Not connected to Azure" -ForegroundColor Yellow
            Write-Host "Run: Connect-AzAccount" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "Example:" -ForegroundColor Cyan
            Write-Host '  Connect-AzAccount' -ForegroundColor Gray
            Write-Host '  Set-AzContext -Subscription "Your Subscription Name"' -ForegroundColor Gray
        }
    } catch {
        Write-Host "Azure PowerShell not authenticated" -ForegroundColor Yellow
        Write-Host "Run: Connect-AzAccount" -ForegroundColor Cyan
    }
    Write-Host ""

    # Step 4: Create or configure Log Analytics Workspace
    Write-Host "[Step 4] Log Analytics Workspace configuration" -ForegroundColor Yellow

    Write-Host "Creating/configuring Log Analytics workspace for Sentinel..." -ForegroundColor Cyan
    Write-Host ""

    Write-Host "Example: Create new Log Analytics workspace" -ForegroundColor Cyan
    Write-Host @'
  # Define parameters
  $resourceGroupName = "rg-sentinel-prod"
  $workspaceName = "law-sentinel-prod"
  $location = "East US"

  # Create resource group if needed
  New-AzResourceGroup -Name $resourceGroupName -Location $location -ErrorAction SilentlyContinue

  # Create Log Analytics workspace
  $workspace = New-AzOperationalInsightsWorkspace `
      -ResourceGroupName $resourceGroupName `
      -Name $workspaceName `
      -Location $location `
      -Sku "PerGB2018" `
      -RetentionInDays 90

  # Get workspace ID and key
  $workspaceId = $workspace.CustomerId
  $workspaceKey = (Get-AzOperationalInsightsWorkspaceSharedKey `
      -ResourceGroupName $resourceGroupName `
      -Name $workspaceName).PrimarySharedKey
'@ -ForegroundColor Gray
    Write-Host ""

    Write-Host "Workspace SKU options:" -ForegroundColor Cyan
    Write-Host "  - PerGB2018: Pay per GB ingested (recommended)" -ForegroundColor White
    Write-Host "  - CapacityReservation: Commitment tiers (100+ GB/day)" -ForegroundColor White
    Write-Host ""

    # Step 5: Configure Windows Event data sources
    Write-Host "[Step 5] Configuring Windows Event data sources" -ForegroundColor Yellow

    Write-Host "Windows Event logs to collect for security monitoring:" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "Example: Configure Windows Event data sources" -ForegroundColor Cyan
    Write-Host @'
  # Configure Windows Security events
  $securityEvents = New-AzOperationalInsightsWindowsEventDataSource `
      -ResourceGroupName $resourceGroupName `
      -WorkspaceName $workspaceName `
      -Name "WindowsSecurityEvents" `
      -EventLogName "Security" `
      -CollectErrors `
      -CollectWarnings `
      -CollectInformation

  # Configure Windows System events
  $systemEvents = New-AzOperationalInsightsWindowsEventDataSource `
      -ResourceGroupName $resourceGroupName `
      -WorkspaceName $workspaceName `
      -Name "WindowsSystemEvents" `
      -EventLogName "System" `
      -CollectErrors `
      -CollectWarnings

  # Configure Windows Application events
  $appEvents = New-AzOperationalInsightsWindowsEventDataSource `
      -ResourceGroupName $resourceGroupName `
      -WorkspaceName $workspaceName `
      -Name "WindowsApplicationEvents" `
      -EventLogName "Application" `
      -CollectErrors `
      -CollectWarnings
'@ -ForegroundColor Gray
    Write-Host ""

    Write-Host "Key event logs for security:" -ForegroundColor Cyan
    Write-Host "  - Security: Logon events, privilege use, policy changes" -ForegroundColor White
    Write-Host "  - System: Service events, system changes" -ForegroundColor White
    Write-Host "  - Application: Application-specific events" -ForegroundColor White
    Write-Host "  - Windows PowerShell: Script execution and commands" -ForegroundColor White
    Write-Host "  - Sysmon: Advanced system monitoring (if installed)" -ForegroundColor White
    Write-Host ""

    # Step 6: Install Azure Monitor Agent
    Write-Host "[Step 6] Installing Azure Monitor Agent" -ForegroundColor Yellow

    Write-Host "Azure Monitor Agent (AMA) replaces legacy agents:" -ForegroundColor Cyan
    Write-Host "  - Log Analytics Agent (MMA) - deprecated" -ForegroundColor Gray
    Write-Host "  - Azure Diagnostics extension - legacy" -ForegroundColor Gray
    Write-Host ""

    Write-Host "Install AMA on Windows Server:" -ForegroundColor Cyan
    Write-Host @'
  # For Azure VMs
  Set-AzVMExtension `
      -Publisher "Microsoft.Azure.Monitor" `
      -ExtensionType "AzureMonitorWindowsAgent" `
      -Name "AzureMonitorWindowsAgent" `
      -ResourceGroupName "rg-servers" `
      -VMName "server01" `
      -Location "East US" `
      -TypeHandlerVersion "1.0" `
      -EnableAutomaticUpgrade $true

  # For Azure Arc-enabled servers (on-premises)
  New-AzConnectedMachineExtension `
      -Name "AzureMonitorWindowsAgent" `
      -ResourceGroupName "rg-servers" `
      -MachineName "server01" `
      -Location "East US" `
      -Publisher "Microsoft.Azure.Monitor" `
      -ExtensionType "AzureMonitorWindowsAgent" `
      -Settings @{"workspaceId"=$workspaceId} `
      -ProtectedSettings @{"workspaceKey"=$workspaceKey}
'@ -ForegroundColor Gray
    Write-Host ""

    # Check if AMA is installed locally
    Write-Host "Checking for Azure Monitor Agent on local system..." -ForegroundColor Cyan
    $amaService = Get-Service -Name "AzureMonitorAgent" -ErrorAction SilentlyContinue
    if ($amaService) {
        Write-Host "Azure Monitor Agent Status: $($amaService.Status)" -ForegroundColor Green
    } else {
        Write-Host "Azure Monitor Agent not installed on this system" -ForegroundColor Yellow
    }
    Write-Host ""

    # Step 7: Create Data Collection Rules
    Write-Host "[Step 7] Creating Data Collection Rules (DCR)" -ForegroundColor Yellow

    Write-Host "Data Collection Rules define what to collect and where to send it" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "Example: Create DCR for Windows Security Events" -ForegroundColor Cyan
    Write-Host @'
  # Define DCR for Windows Security events
  $dcrName = "dcr-windows-security-events"

  # Create data collection endpoint (required for DCR)
  $dce = New-AzDataCollectionEndpoint `
      -Name "dce-sentinel" `
      -ResourceGroupName $resourceGroupName `
      -Location $location `
      -NetworkAclsPublicNetworkAccess "Enabled"

  # Create data collection rule
  $dcr = New-AzDataCollectionRule `
      -Name $dcrName `
      -ResourceGroupName $resourceGroupName `
      -Location $location `
      -DataCollectionEndpointId $dce.Id `
      -DataFlow @(
          @{
              Streams = @("Microsoft-SecurityEvent")
              Destinations = @($workspaceName)
          }
      ) `
      -DataSource @{
          WindowsEventLogs = @(
              @{
                  Name = "SecurityEvents"
                  Streams = @("Microsoft-SecurityEvent")
                  XPathQueries = @(
                      "Security!*[System[(EventID=4624 or EventID=4625 or EventID=4648)]]",
                      "Security!*[System[(EventID=4672 or EventID=4673)]]",
                      "Security!*[System[(EventID=4688)]]",
                      "Security!*[System[(EventID=4740 or EventID=4767)]]"
                  )
              }
          )
      } `
      -Destination @{
          LogAnalytics = @(
              @{
                  WorkspaceResourceId = $workspace.ResourceId
                  Name = $workspaceName
              }
          )
      }

  # Associate DCR with VMs
  New-AzDataCollectionRuleAssociation `
      -AssociationName "dcra-server01" `
      -ResourceUri "/subscriptions/<sub-id>/resourceGroups/rg-servers/providers/Microsoft.Compute/virtualMachines/server01" `
      -DataCollectionRuleId $dcr.Id
'@ -ForegroundColor Gray
    Write-Host ""

    Write-Host "Important Security Event IDs:" -ForegroundColor Cyan
    Write-Host "  4624 - Successful logon" -ForegroundColor White
    Write-Host "  4625 - Failed logon" -ForegroundColor White
    Write-Host "  4648 - Logon using explicit credentials" -ForegroundColor White
    Write-Host "  4672 - Special privileges assigned to new logon" -ForegroundColor White
    Write-Host "  4688 - Process creation" -ForegroundColor White
    Write-Host "  4740 - User account locked out" -ForegroundColor White
    Write-Host "  4767 - User account unlocked" -ForegroundColor White
    Write-Host ""

    # Step 8: Enable Microsoft Sentinel
    Write-Host "[Step 8] Enabling Microsoft Sentinel on workspace" -ForegroundColor Yellow

    Write-Host "Enable Sentinel on Log Analytics workspace:" -ForegroundColor Cyan
    Write-Host @'
  # Enable Sentinel (via Azure Portal or ARM template)
  # Note: Az.SecurityInsights module provides Sentinel cmdlets

  # Get workspace for Sentinel
  $workspace = Get-AzOperationalInsightsWorkspace `
      -ResourceGroupName $resourceGroupName `
      -Name $workspaceName

  # Sentinel is enabled through Azure portal or ARM deployment
  # Once enabled, configure data connectors
'@ -ForegroundColor Gray
    Write-Host ""

    Write-Host "Sentinel can also be enabled via Azure Portal:" -ForegroundColor Cyan
    Write-Host "  1. Navigate to Microsoft Sentinel in Azure Portal" -ForegroundColor White
    Write-Host "  2. Click 'Add' and select your Log Analytics workspace" -ForegroundColor White
    Write-Host "  3. Click 'Add Microsoft Sentinel'" -ForegroundColor White
    Write-Host ""

    # Step 9: Configure Sentinel data connectors
    Write-Host "[Step 9] Configuring Sentinel data connectors" -ForegroundColor Yellow

    Write-Host "Key data connectors for Windows Server:" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "Security Events connector (Windows Security logs):" -ForegroundColor White
    Write-Host "  - Common Events: Selected important events" -ForegroundColor Gray
    Write-Host "  - Minimal: Minimum required for Sentinel" -ForegroundColor Gray
    Write-Host "  - All Events: Complete security log (large volume)" -ForegroundColor Gray
    Write-Host ""

    Write-Host "Other recommended connectors:" -ForegroundColor White
    Write-Host "  - Azure Active Directory" -ForegroundColor Gray
    Write-Host "  - Azure Activity" -ForegroundColor Gray
    Write-Host "  - Microsoft Defender for Cloud" -ForegroundColor Gray
    Write-Host "  - Microsoft Defender for Endpoint" -ForegroundColor Gray
    Write-Host "  - Microsoft Defender for Identity" -ForegroundColor Gray
    Write-Host "  - DNS (via AMA)" -ForegroundColor Gray
    Write-Host "  - Windows Firewall" -ForegroundColor Gray
    Write-Host ""

    # Step 10: Verify data ingestion
    Write-Host "[Step 10] Verifying data ingestion" -ForegroundColor Yellow

    Write-Host "Query Log Analytics to verify data collection:" -ForegroundColor Cyan
    Write-Host @'
  # Get recent workspace data
  $query = @"
  SecurityEvent
  | where TimeGenerated > ago(1h)
  | summarize Count = count() by EventID, Computer
  | order by Count desc
  | take 10
"@

  # Execute query
  $results = Invoke-AzOperationalInsightsQuery `
      -WorkspaceId $workspaceId `
      -Query $query

  # Display results
  $results.Results | Format-Table

  # Check ingestion status
  Get-AzOperationalInsightsWorkspace `
      -ResourceGroupName $resourceGroupName `
      -Name $workspaceName |
      Select-Object Name, ProvisioningState, RetentionInDays, Sku
'@ -ForegroundColor Gray
    Write-Host ""

    Write-Host "Common KQL queries for monitoring:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Failed logons in last 24 hours:" -ForegroundColor White
    Write-Host '  SecurityEvent | where EventID == 4625 and TimeGenerated > ago(24h)' -ForegroundColor Gray
    Write-Host ""
    Write-Host "Successful privileged logons:" -ForegroundColor White
    Write-Host '  SecurityEvent | where EventID == 4672 and TimeGenerated > ago(24h)' -ForegroundColor Gray
    Write-Host ""
    Write-Host "Process creation events:" -ForegroundColor White
    Write-Host '  SecurityEvent | where EventID == 4688 and TimeGenerated > ago(1h)' -ForegroundColor Gray
    Write-Host ""

    # Best Practices
    Write-Host "Best Practices:" -ForegroundColor Cyan
    Write-Host "  1. Start with 'Common Events' to control costs" -ForegroundColor White
    Write-Host "  2. Use Data Collection Rules for fine-grained control" -ForegroundColor White
    Write-Host "  3. Set appropriate retention periods (90+ days for security)" -ForegroundColor White
    Write-Host "  4. Enable diagnostic settings on all Azure resources" -ForegroundColor White
    Write-Host "  5. Configure alert rules for critical events" -ForegroundColor White
    Write-Host "  6. Use workbooks for visualization" -ForegroundColor White
    Write-Host "  7. Implement playbooks for automated response" -ForegroundColor White
    Write-Host "  8. Monitor ingestion costs and optimize queries" -ForegroundColor White
    Write-Host "  9. Use Azure Arc for hybrid server monitoring" -ForegroundColor White
    Write-Host "  10. Regular review of analytics rules and incidents" -ForegroundColor White
    Write-Host ""

    Write-Host "[INFO] Additional Resources:" -ForegroundColor Cyan
    Write-Host "  Portal: https://portal.azure.com/#view/Microsoft_Azure_Security/SentinelMenuBlade" -ForegroundColor White
    Write-Host "  Docs: https://docs.microsoft.com/azure/sentinel/" -ForegroundColor White
    Write-Host "  KQL: https://docs.microsoft.com/azure/data-explorer/kusto/query/" -ForegroundColor White
    Write-Host ""

} catch {
    Write-Host "[ERROR] $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

Write-Host "Demo completed successfully!" -ForegroundColor Green
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Create Log Analytics workspace in Azure" -ForegroundColor White
Write-Host "  2. Enable Microsoft Sentinel on the workspace" -ForegroundColor White
Write-Host "  3. Install Azure Monitor Agent on Windows Servers" -ForegroundColor White
Write-Host "  4. Create Data Collection Rules for security events" -ForegroundColor White
Write-Host "  5. Configure data connectors in Sentinel" -ForegroundColor White
Write-Host "  6. Verify data ingestion with KQL queries" -ForegroundColor White
Write-Host "  7. Create analytics rules for threat detection" -ForegroundColor White
Write-Host "  8. Set up automated response with playbooks" -ForegroundColor White
