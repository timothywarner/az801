<#
.SYNOPSIS
    Task 23.4 - Deploy Azure Arc Extensions

.DESCRIPTION
    Demo script for AZ-801 Module 23: Monitor with Azure Services
    Demonstrates deploying and managing Azure Arc extensions for hybrid server
    monitoring, security, and management.

.NOTES
    Module: Module 23 - Monitor with Azure Services
    Task: 23.4 - Deploy Azure Arc Extensions
    Prerequisites: Azure Arc-enabled servers, Az PowerShell module
    PowerShell Version: 5.1+
#>

#Requires -RunAsAdministrator
#Requires -Modules Az.Accounts, Az.ConnectedMachine

$ErrorActionPreference = 'Stop'
Write-Host "=== AZ-801 Module 23: Task 23.4 - Deploy Azure Arc Extensions ===" -ForegroundColor Cyan
Write-Host ""

try {
    # Check Azure connection
    Write-Host "[Step 1] Verify Azure Arc Agent Status" -ForegroundColor Yellow

    # Check if azcmagent is installed
    $azcmagentPath = "C:\Program Files\AzureConnectedMachineAgent\azcmagent.exe"
    if (Test-Path $azcmagentPath) {
        Write-Host "Azure Arc agent is installed" -ForegroundColor Green

        # Get agent status
        Write-Host "`nAgent status:" -ForegroundColor Cyan
        & $azcmagentPath show
    } else {
        Write-Host "Azure Arc agent not installed. Commands will be demonstrated..." -ForegroundColor Yellow
    }
    Write-Host ""

    # Variables
    $resourceGroup = "rg-arc-servers"
    $location = "eastus"
    $machineName = "onprem-server-01"

    # List available extensions
    Write-Host "[Step 2] List Available Arc Extensions" -ForegroundColor Yellow
    Write-Host @"
  Get-AzConnectedMachineExtension ``
    -ResourceGroupName '$resourceGroup' ``
    -MachineName '$machineName'
"@ -ForegroundColor White
    Write-Host ""

    # Install Azure Monitor Agent
    Write-Host "[Step 3] Install Azure Monitor Agent Extension" -ForegroundColor Yellow
    Write-Host @"
  New-AzConnectedMachineExtension ``
    -ResourceGroupName '$resourceGroup' ``
    -MachineName '$machineName' ``
    -Name 'AzureMonitorWindowsAgent' ``
    -Location '$location' ``
    -Publisher 'Microsoft.Azure.Monitor' ``
    -ExtensionType 'AzureMonitorWindowsAgent' ``
    -EnableAutomaticUpgrade `$true
"@ -ForegroundColor White
    Write-Host ""

    # Install Dependency Agent
    Write-Host "[Step 4] Install Dependency Agent for VM Insights" -ForegroundColor Yellow
    Write-Host @"
  New-AzConnectedMachineExtension ``
    -ResourceGroupName '$resourceGroup' ``
    -MachineName '$machineName' ``
    -Name 'DependencyAgentWindows' ``
    -Location '$location' ``
    -Publisher 'Microsoft.Azure.Monitoring.DependencyAgent' ``
    -ExtensionType 'DependencyAgentWindows'
"@ -ForegroundColor White
    Write-Host ""

    # Install Microsoft Defender for Cloud
    Write-Host "[Step 5] Install Microsoft Defender for Cloud Extension" -ForegroundColor Yellow
    Write-Host @"
  New-AzConnectedMachineExtension ``
    -ResourceGroupName '$resourceGroup' ``
    -MachineName '$machineName' ``
    -Name 'MDE.Windows' ``
    -Location '$location' ``
    -Publisher 'Microsoft.Azure.AzureDefenderForServers' ``
    -ExtensionType 'MDE.Windows'
"@ -ForegroundColor White
    Write-Host ""

    # Install Custom Script Extension
    Write-Host "[Step 6] Deploy Custom Script Extension" -ForegroundColor Yellow
    Write-Host @"
  `$settings = @{
    fileUris = @('https://mystorageaccount.blob.core.windows.net/scripts/configure-server.ps1')
    commandToExecute = 'powershell.exe -ExecutionPolicy Unrestricted -File configure-server.ps1'
  }

  New-AzConnectedMachineExtension ``
    -ResourceGroupName '$resourceGroup' ``
    -MachineName '$machineName' ``
    -Name 'CustomScriptExtension' ``
    -Location '$location' ``
    -Publisher 'Microsoft.Compute' ``
    -ExtensionType 'CustomScriptExtension' ``
    -Settings `$settings
"@ -ForegroundColor White
    Write-Host ""

    # Install Azure Policy Guest Configuration
    Write-Host "[Step 7] Install Azure Policy Guest Configuration Extension" -ForegroundColor Yellow
    Write-Host @"
  New-AzConnectedMachineExtension ``
    -ResourceGroupName '$resourceGroup' ``
    -MachineName '$machineName' ``
    -Name 'AzurePolicyforWindows' ``
    -Location '$location' ``
    -Publisher 'Microsoft.GuestConfiguration' ``
    -ExtensionType 'ConfigurationforWindows'
"@ -ForegroundColor White
    Write-Host ""

    # Manage extensions
    Write-Host "[Step 8] Manage Extension Status" -ForegroundColor Yellow
    Write-Host "Get extension details:" -ForegroundColor Cyan
    Write-Host @"
  Get-AzConnectedMachineExtension ``
    -ResourceGroupName '$resourceGroup' ``
    -MachineName '$machineName' ``
    -Name 'AzureMonitorWindowsAgent'
"@ -ForegroundColor White
    Write-Host ""

    Write-Host "Update extension:" -ForegroundColor Cyan
    Write-Host @"
  Update-AzConnectedMachineExtension ``
    -ResourceGroupName '$resourceGroup' ``
    -MachineName '$machineName' ``
    -Name 'AzureMonitorWindowsAgent' ``
    -EnableAutomaticUpgrade `$true
"@ -ForegroundColor White
    Write-Host ""

    Write-Host "Remove extension:" -ForegroundColor Cyan
    Write-Host @"
  Remove-AzConnectedMachineExtension ``
    -ResourceGroupName '$resourceGroup' ``
    -MachineName '$machineName' ``
    -Name 'CustomScriptExtension'
"@ -ForegroundColor White
    Write-Host ""

    # Bulk deployment
    Write-Host "[Step 9] Bulk Deploy Extensions to Multiple Arc Servers" -ForegroundColor Yellow
    Write-Host @"
  # Get all Arc-enabled machines
  `$arcMachines = Get-AzConnectedMachine -ResourceGroupName '$resourceGroup'

  foreach (`$machine in `$arcMachines) {
    Write-Host "Deploying extensions to `$(`$machine.Name)..."

    # Deploy Azure Monitor Agent
    New-AzConnectedMachineExtension ``
      -ResourceGroupName '$resourceGroup' ``
      -MachineName `$machine.Name ``
      -Name 'AzureMonitorWindowsAgent' ``
      -Location `$machine.Location ``
      -Publisher 'Microsoft.Azure.Monitor' ``
      -ExtensionType 'AzureMonitorWindowsAgent' ``
      -EnableAutomaticUpgrade `$true
  }
"@ -ForegroundColor White
    Write-Host ""

    # Verify extension logs
    Write-Host "[Step 10] Check Extension Logs on Arc Server" -ForegroundColor Yellow
    Write-Host "Extension log locations:" -ForegroundColor Cyan
    Write-Host "  Azure Monitor Agent: C:\ProgramData\GuestConfig\extension_logs\Microsoft.Azure.Monitor.AzureMonitorWindowsAgent\" -ForegroundColor White
    Write-Host "  Dependency Agent: C:\ProgramData\GuestConfig\extension_logs\Microsoft.Azure.Monitoring.DependencyAgent\" -ForegroundColor White
    Write-Host "  Custom Script: C:\Packages\Plugins\Microsoft.Compute.CustomScriptExtension\" -ForegroundColor White
    Write-Host ""

    Write-Host "View extension status:" -ForegroundColor Cyan
    Write-Host @"
  Get-ChildItem 'C:\ProgramData\GuestConfig\extension_logs' -Recurse |
    Where-Object {`$_.Name -like '*.log'} |
    Get-Content -Tail 50
"@ -ForegroundColor White
    Write-Host ""

    # Extension use cases
    Write-Host "[Step 11] Common Extension Use Cases" -ForegroundColor Yellow
    $useCases = @"
1. Monitoring & Observability:
   - Azure Monitor Agent: Collect logs and metrics
   - Dependency Agent: Application dependency mapping
   - Log Analytics Agent (legacy): Log collection

2. Security & Compliance:
   - Microsoft Defender for Endpoint: Threat protection
   - Azure Policy Guest Configuration: Compliance auditing
   - Qualys: Vulnerability scanning

3. Management & Automation:
   - Custom Script Extension: Run configuration scripts
   - Desired State Configuration: Configuration management
   - Azure Automation Hybrid Worker: Run automation runbooks

4. Backup & Disaster Recovery:
   - Azure Backup Extension: Server backup
   - Azure Site Recovery: Disaster recovery

5. Application Services:
   - SQL Server IaaS Agent: SQL Server management
   - Key Vault Extension: Certificate management
"@
    Write-Host $useCases -ForegroundColor White
    Write-Host ""

    Write-Host "[INFO] Arc Extension Best Practices:" -ForegroundColor Cyan
    Write-Host "  - Enable automatic upgrades for extensions when available" -ForegroundColor White
    Write-Host "  - Monitor extension status regularly" -ForegroundColor White
    Write-Host "  - Use Azure Policy to enforce extension deployment" -ForegroundColor White
    Write-Host "  - Test extensions in non-production first" -ForegroundColor White
    Write-Host "  - Review extension logs for troubleshooting" -ForegroundColor White
    Write-Host "  - Remove unused extensions to reduce overhead" -ForegroundColor White
    Write-Host ""

} catch {
    Write-Host "[ERROR] $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

Write-Host "Demo completed successfully!" -ForegroundColor Green
Write-Host "Next Steps: Deploy required extensions to your Arc-enabled servers" -ForegroundColor Yellow
