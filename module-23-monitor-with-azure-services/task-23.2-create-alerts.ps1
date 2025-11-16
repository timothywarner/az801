<#
.SYNOPSIS
    Task 23.2 - Create Azure Monitor Alerts

.DESCRIPTION
    Demo script for AZ-801 Module 23: Monitor with Azure Services
    Demonstrates creating Azure Monitor alerts, action groups, and alert rules for
    proactive monitoring of Azure and hybrid resources.

.NOTES
    Module: Module 23 - Monitor with Azure Services
    Task: 23.2 - Create Azure Monitor Alerts
    Prerequisites: Azure subscription, Az PowerShell module
    PowerShell Version: 5.1+
#>

#Requires -RunAsAdministrator
#Requires -Modules Az.Accounts, Az.Monitor, Az.Resources

$ErrorActionPreference = 'Stop'
Write-Host "=== AZ-801 Module 23: Task 23.2 - Create Azure Monitor Alerts ===" -ForegroundColor Cyan
Write-Host ""

try {
    # Check Azure connection
    Write-Host "[Step 1] Verify Azure Connection" -ForegroundColor Yellow
    $context = Get-AzContext -ErrorAction SilentlyContinue
    if (-not $context) {
        Write-Host "Not connected. Use: Connect-AzAccount" -ForegroundColor Yellow
        Write-Host "Demonstrating commands..." -ForegroundColor Cyan
    } else {
        Write-Host "Connected: $($context.Subscription.Name)" -ForegroundColor Green
    }
    Write-Host ""

    # Define variables
    $resourceGroup = "rg-monitoring-prod"
    $location = "eastus"
    $actionGroupName = "ag-critical-alerts"
    $vmName = "vm-webserver-01"

    # Create Action Group
    Write-Host "[Step 2] Create Action Group for Notifications" -ForegroundColor Yellow
    Write-Host "Command:" -ForegroundColor Cyan
    Write-Host @"
  `$emailReceiver = New-AzActionGroupReceiver ``
    -Name 'AdminEmail' ``
    -EmailReceiver ``
    -EmailAddress 'admin@contoso.com'

  `$smsReceiver = New-AzActionGroupReceiver ``
    -Name 'AdminSMS' ``
    -SmsReceiver ``
    -CountryCode '1' ``
    -PhoneNumber '5551234567'

  Set-AzActionGroup ``
    -ResourceGroupName '$resourceGroup' ``
    -Name '$actionGroupName' ``
    -ShortName 'CritAlerts' ``
    -Receiver `$emailReceiver, `$smsReceiver
"@ -ForegroundColor White
    Write-Host ""

    # Create metric alert for CPU
    Write-Host "[Step 3] Create Metric Alert for High CPU Usage" -ForegroundColor Yellow
    Write-Host @"
  `$vmId = (Get-AzVM -ResourceGroupName '$resourceGroup' -Name '$vmName').Id

  `$condition = New-AzMetricAlertRuleV2Criteria ``
    -MetricName 'Percentage CPU' ``
    -TimeAggregation Average ``
    -Operator GreaterThan ``
    -Threshold 80

  Add-AzMetricAlertRuleV2 ``
    -Name 'alert-high-cpu' ``
    -ResourceGroupName '$resourceGroup' ``
    -WindowSize 00:05:00 ``
    -Frequency 00:01:00 ``
    -TargetResourceId `$vmId ``
    -Condition `$condition ``
    -ActionGroupId (Get-AzActionGroup -ResourceGroupName '$resourceGroup' -Name '$actionGroupName').Id ``
    -Severity 2
"@ -ForegroundColor White
    Write-Host ""

    # Create activity log alert
    Write-Host "[Step 4] Create Activity Log Alert for VM Shutdown" -ForegroundColor Yellow
    Write-Host @"
  `$condition = New-AzActivityLogAlertCondition ``
    -Field 'category' ``
    -Equal 'Administrative'

  `$condition2 = New-AzActivityLogAlertCondition ``
    -Field 'operationName' ``
    -Equal 'Microsoft.Compute/virtualMachines/deallocate/action'

  Set-AzActivityLogAlert ``
    -ResourceGroupName '$resourceGroup' ``
    -Name 'alert-vm-shutdown' ``
    -Condition `$condition, `$condition2 ``
    -Scope '/subscriptions/{subscriptionId}' ``
    -ActionGroupId (Get-AzActionGroup -ResourceGroupName '$resourceGroup' -Name '$actionGroupName').Id
"@ -ForegroundColor White
    Write-Host ""

    # Create log search alert
    Write-Host "[Step 5] Create Log Search Alert Query" -ForegroundColor Yellow
    $kqlQuery = @"
Heartbeat
| where TimeGenerated > ago(5m)
| summarize LastHeartbeat = max(TimeGenerated) by Computer
| where LastHeartbeat < ago(5m)
"@
    Write-Host "KQL Query:" -ForegroundColor Cyan
    Write-Host $kqlQuery -ForegroundColor Gray
    Write-Host ""

    Write-Host "Create scheduled query alert:" -ForegroundColor Cyan
    Write-Host @"
  `$source = New-AzScheduledQueryRuleSource ``
    -Query '$($kqlQuery -replace "`n"," ")' ``
    -DataSourceId `$workspaceId ``
    -QueryType 'ResultCount'

  `$schedule = New-AzScheduledQueryRuleSchedule ``
    -FrequencyInMinutes 5 ``
    -TimeWindowInMinutes 5

  `$triggerCondition = New-AzScheduledQueryRuleTriggerCondition ``
    -ThresholdOperator 'GreaterThan' ``
    -Threshold 0

  `$aznsActionGroup = New-AzScheduledQueryRuleAznsActionGroup ``
    -ActionGroup `$actionGroupId ``
    -EmailSubject 'Agent Heartbeat Alert'

  New-AzScheduledQueryRule ``
    -ResourceGroupName '$resourceGroup' ``
    -Location '$location' ``
    -Name 'alert-missing-heartbeat' ``
    -Description 'Alert when agents stop reporting' ``
    -Enabled `$true ``
    -Source `$source ``
    -Schedule `$schedule ``
    -Action `$aznsActionGroup
"@ -ForegroundColor White
    Write-Host ""

    # List all alert rules
    Write-Host "[Step 6] Manage Alert Rules" -ForegroundColor Yellow
    Write-Host "List metric alerts:" -ForegroundColor Cyan
    Write-Host "  Get-AzMetricAlertRuleV2 -ResourceGroupName '$resourceGroup'" -ForegroundColor White
    Write-Host ""

    Write-Host "List activity log alerts:" -ForegroundColor Cyan
    Write-Host "  Get-AzActivityLogAlert -ResourceGroupName '$resourceGroup'" -ForegroundColor White
    Write-Host ""

    Write-Host "List scheduled query rules:" -ForegroundColor Cyan
    Write-Host "  Get-AzScheduledQueryRule -ResourceGroupName '$resourceGroup'" -ForegroundColor White
    Write-Host ""

    # Common alert scenarios
    Write-Host "[Step 7] Common Alert Scenarios" -ForegroundColor Yellow
    $scenarios = @"
1. High Memory Usage:
   - Metric: Available Memory Bytes
   - Threshold: < 500 MB
   - Severity: Warning

2. Disk Space Low:
   - Metric: Disk Free Space %
   - Threshold: < 10%
   - Severity: Critical

3. Service Failure:
   - Log Query: Event | where EventLevelName == "Error" and Source == "Service Control Manager"
   - Threshold: > 0 results
   - Severity: Critical

4. Failed Logins:
   - Log Query: SecurityEvent | where EventID == 4625
   - Threshold: > 5 in 5 minutes
   - Severity: Warning

5. Backup Failure:
   - Activity Log: Microsoft.RecoveryServices/vaults/backupJobs/write
   - Status: Failed
   - Severity: Critical
"@
    Write-Host $scenarios -ForegroundColor White
    Write-Host ""

    Write-Host "[INFO] Alert Best Practices:" -ForegroundColor Cyan
    Write-Host "  - Use action groups for centralized notification management" -ForegroundColor White
    Write-Host "  - Set appropriate severity levels (0=Critical, 4=Informational)" -ForegroundColor White
    Write-Host "  - Configure alert processing rules to reduce noise" -ForegroundColor White
    Write-Host "  - Test alerts before deploying to production" -ForegroundColor White
    Write-Host "  - Use dynamic thresholds for variable workloads" -ForegroundColor White
    Write-Host "  - Document alert runbooks for response procedures" -ForegroundColor White
    Write-Host ""

} catch {
    Write-Host "[ERROR] $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

Write-Host "Demo completed successfully!" -ForegroundColor Green
Write-Host "Next Steps: Configure action groups and create alerts for your environment" -ForegroundColor Yellow
