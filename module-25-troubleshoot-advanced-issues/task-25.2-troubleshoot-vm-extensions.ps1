<#
.SYNOPSIS
    AZ-801 Module 25 Task 2 - Troubleshoot Azure VM Extensions

.DESCRIPTION
    This script demonstrates Azure VM extension troubleshooting techniques.
    It covers Get-AzVMExtension, extension logs, reinstallation procedures,
    common failures, and Azure VM agent troubleshooting.

.NOTES
    Module: 25 - Troubleshoot Advanced Issues
    Task: 25.2 - Troubleshoot Azure VM Extensions
    Exam: AZ-801 - Configuring Windows Server Hybrid Advanced Services
#>

#Requires -RunAsAdministrator
#Requires -Modules Az.Compute

#region Azure Authentication Check

Write-Host "`n=== AZURE VM EXTENSION TROUBLESHOOTING ===" -ForegroundColor Cyan

Write-Host "`nChecking Azure PowerShell Module..." -ForegroundColor Yellow
if (Get-Module -ListAvailable -Name Az.Compute) {
    Write-Host "  Az.Compute module: INSTALLED" -ForegroundColor Green
} else {
    Write-Host "  Az.Compute module: NOT INSTALLED" -ForegroundColor Red
    Write-Host "  Install with: Install-Module -Name Az -AllowClobber -Scope CurrentUser" -ForegroundColor Yellow
}

Write-Host "`nChecking Azure connection..." -ForegroundColor Green
try {
    $context = Get-AzContext -ErrorAction Stop
    if ($context) {
        Write-Host "  Connected to Azure" -ForegroundColor Green
        Write-Host "  Subscription: $($context.Subscription.Name)" -ForegroundColor White
        Write-Host "  Account: $($context.Account.Id)" -ForegroundColor White
    }
} catch {
    Write-Host "  NOT connected to Azure" -ForegroundColor Yellow
    Write-Host "  Connect with: Connect-AzAccount" -ForegroundColor Gray
}

#endregion

#region VM Extension Commands

Write-Host "`n`n=== VM EXTENSION MANAGEMENT COMMANDS ===" -ForegroundColor Cyan

$extensionCommands = @"

Azure VM Extension Commands:

LIST EXTENSIONS ON VM:
Get-AzVMExtension -ResourceGroupName "RG-Name" -VMName "VM-Name"

GET SPECIFIC EXTENSION:
Get-AzVMExtension -ResourceGroupName "RG-Name" -VMName "VM-Name" -Name "ExtensionName"

INSTALL/UPDATE EXTENSION:
Set-AzVMExtension ``
    -ResourceGroupName "RG-Name" ``
    -VMName "VM-Name" ``
    -Name "ExtensionName" ``
    -Publisher "Microsoft.Compute" ``
    -ExtensionType "CustomScriptExtension" ``
    -TypeHandlerVersion "1.10" ``
    -Location "EastUS"

REMOVE EXTENSION:
Remove-AzVMExtension ``
    -ResourceGroupName "RG-Name" ``
    -VMName "VM-Name" ``
    -Name "ExtensionName" ``
    -Force

CHECK EXTENSION STATUS:
`$ext = Get-AzVMExtension -ResourceGroupName "RG" -VMName "VM" -Name "Ext"
`$ext.ProvisioningState
`$ext.Statuses

LIST AVAILABLE EXTENSIONS:
Get-AzVMExtensionImage -Location "EastUS" -PublisherName "Microsoft.Compute"

COMMON EXTENSION PUBLISHERS:
- Microsoft.Compute
- Microsoft.Azure.Diagnostics
- Microsoft.Azure.Security
- Microsoft.EnterpriseCloud.Monitoring
- Microsoft.Azure.Extensions

"@

Write-Host $extensionCommands -ForegroundColor White

#endregion

#region Extension Log Locations

Write-Host "`n=== EXTENSION LOG LOCATIONS ===" -ForegroundColor Cyan

$logLocations = @"

Windows VM Extension Log Locations:

MAIN LOGS DIRECTORY:
C:\WindowsAzure\Logs\Plugins\

EXTENSION-SPECIFIC LOGS:
C:\WindowsAzure\Logs\Plugins\{Publisher}.{ExtensionType}\{Version}\

CUSTOM SCRIPT EXTENSION:
C:\WindowsAzure\Logs\Plugins\Microsoft.Compute.CustomScriptExtension\
- CommandExecution.log
- CustomScriptHandler.log

DSC EXTENSION:
C:\WindowsAzure\Logs\Plugins\Microsoft.Powershell.DSC\
- DscExtensionHandler.log

MONITORING AGENT:
C:\WindowsAzure\Logs\Plugins\Microsoft.EnterpriseCloud.Monitoring.MicrosoftMonitoringAgent\
- MonitoringAgentInstall.log

AZURE DIAGNOSTICS:
C:\WindowsAzure\Logs\Plugins\Microsoft.Azure.Diagnostics.IaaSDiagnostics\
- DiagnosticsPlugin.log

VM AGENT LOGS:
C:\WindowsAzure\Logs\
- WaAppAgent.log (main agent log)
- TransparentInstaller.log
- Telemetry.log

CONFIG FILES:
C:\Packages\Plugins\{Publisher}.{ExtensionType}\{Version}\
- HandlerEnvironment.json
- HandlerManifest.json
- RuntimeSettings\{seq}.settings

STATUS FILES:
C:\Packages\Plugins\{Publisher}.{ExtensionType}\{Version}\Status\
- {seq}.status

VIEWING LOGS:
# List all extension directories
Get-ChildItem "C:\WindowsAzure\Logs\Plugins\" -Directory

# View CustomScript logs
Get-Content "C:\WindowsAzure\Logs\Plugins\Microsoft.Compute.CustomScriptExtension\*\CommandExecution.log" -Tail 50

# Search for errors
Get-ChildItem "C:\WindowsAzure\Logs\Plugins\" -Recurse -Filter "*.log" | 
    Select-String -Pattern "error|fail|exception" -Context 2

"@

Write-Host $logLocations -ForegroundColor White

# Check if logs exist
if (Test-Path "C:\WindowsAzure\Logs\Plugins\") {
    Write-Host "`nExtension Logs Found:" -ForegroundColor Green
    Get-ChildItem "C:\WindowsAzure\Logs\Plugins\" -Directory | ForEach-Object {
        Write-Host "  - $($_.Name)" -ForegroundColor White
    }
} else {
    Write-Host "`nExtension logs directory not found (not an Azure VM)" -ForegroundColor Yellow
}

#endregion

#region Common Extension Failures

Write-Host "`n`n=== COMMON EXTENSION FAILURES ===" -ForegroundColor Cyan

$commonFailures = @"

Common Extension Failures and Solutions:

1. EXTENSION PROVISIONING FAILED
   Error: Extension provisioning failed with terminal state
   
   Causes:
   - Network connectivity issues
   - Extension version not available
   - Extension prerequisites not met
   
   Solutions:
   - Check VM internet connectivity
   - Verify extension version: Get-AzVMExtensionImage
   - Review extension logs in C:\WindowsAzure\Logs\Plugins\
   - Remove and reinstall extension

2. CUSTOM SCRIPT EXTENSION TIMEOUT
   Error: Operation timed out or failed
   
   Causes:
   - Script execution takes >90 minutes (default timeout)
   - Script has errors
   - Script waiting for user input
   
   Solutions:
   - Reduce script execution time
   - Test script locally first
   - Check CommandExecution.log for errors
   - Increase timeout in extension settings
   - Use Run Command for quick tests

3. CONFLICTING EXTENSIONS
   Error: Cannot install extension - conflict detected
   
   Causes:
   - Multiple extensions managing same resource
   - DSC and Custom Script Extension conflict
   
   Solutions:
   - Review installed extensions: Get-AzVMExtension
   - Remove conflicting extension
   - Use single configuration management solution

4. VM AGENT NOT READY
   Error: VM Agent is not ready
   
   Causes:
   - VM Agent not installed
   - VM Agent service stopped
   - VM Agent out of date
   
   Solutions:
   - Check service: Get-Service RdAgent, WindowsAzureGuestAgent
   - Restart services
   - Reinstall VM Agent from Azure portal
   - Update VM Agent

5. EXTENSION STUCK IN TRANSITIONING
   Error: Extension in transitioning state
   
   Causes:
   - Previous operation didn't complete
   - Extension process hung
   
   Solutions:
   - Wait 15-30 minutes
   - Remove extension: Remove-AzVMExtension -Force
   - Restart VM
   - Reinstall extension

6. ACCESS DENIED / PERMISSION ISSUES
   Error: Access denied or insufficient permissions
   
   Causes:
   - Script accessing protected resources
   - Running as wrong user context
   - File/folder permissions
   
   Solutions:
   - Check script user context
   - Verify file permissions
   - Review security logs
   - Run script with appropriate privileges

TROUBLESHOOTING WORKFLOW:
1. Check extension status in Azure Portal
2. Review extension logs on VM
3. Verify VM Agent running
4. Test network connectivity
5. Remove and reinstall if needed
6. Check Azure Activity Log for deployment errors

"@

Write-Host $commonFailures -ForegroundColor White

#endregion

#region Azure VM Agent

Write-Host "`n=== AZURE VM AGENT TROUBLESHOOTING ===" -ForegroundColor Cyan

Write-Host "`nChecking Azure VM Agent Services:" -ForegroundColor Green
$vmAgentServices = @("RdAgent", "WindowsAzureGuestAgent", "WindowsAzureTelemetryService")

foreach ($serviceName in $vmAgentServices) {
    $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
    if ($service) {
        Write-Host "  $serviceName : $($service.Status)" -ForegroundColor $(
            if ($service.Status -eq 'Running') {'Green'} else {'Red'}
        )
    } else {
        Write-Host "  $serviceName : NOT FOUND" -ForegroundColor Yellow
    }
}

$vmAgentGuide = @"

Azure VM Agent Troubleshooting:

CHECK VM AGENT STATUS:
# Check services
Get-Service RdAgent, WindowsAzureGuestAgent

# Check process
Get-Process -Name "WindowsAzureGuestAgent", "WaAppAgent"

# Check version
Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows Azure\HandlerState" -Name Version

VM AGENT INSTALLATION:
# Download from:
https://go.microsoft.com/fwlink/?LinkID=394789

# Install manually:
msiexec /i WindowsAzureVmAgent.msi /qn /l*v %temp%\WaAgent_Install.log

# Verify installation:
Get-Service WindowsAzureGuestAgent

VM AGENT LOGS:
C:\WindowsAzure\Logs\WaAppAgent.log
C:\WindowsAzure\Logs\TransparentInstaller.log

RESTART VM AGENT:
Restart-Service RdAgent, WindowsAzureGuestAgent

VM AGENT REGISTRY:
HKLM:\SOFTWARE\Microsoft\Windows Azure\
- HandlerState (extension handler info)
- OSImageVersion
- GuestAgent

TROUBLESHOOTING STEPS:
1. Verify VM Agent services running
2. Check WaAppAgent.log for errors
3. Ensure VM has internet connectivity
4. Test: Test-NetConnection <extension-endpoint> -Port 443
5. Verify time sync (critical for Azure communication)
6. Check firewall not blocking Azure endpoints
7. Reinstall VM Agent if necessary

REQUIRED OUTBOUND CONNECTIVITY:
- *.blob.core.windows.net:443
- *.queue.core.windows.net:443
- *.table.core.windows.net:443
- *.servicebus.windows.net:443
- login.microsoftonline.com:443

CHECK CONNECTIVITY:
Test-NetConnection *.blob.core.windows.net -Port 443

"@

Write-Host $vmAgentGuide -ForegroundColor White

#endregion

#region Extension Reinstallation

Write-Host "`n=== EXTENSION REINSTALLATION PROCEDURE ===" -ForegroundColor Cyan

$reinstallGuide = @"

Extension Reinstallation Procedure:

POWERSHELL METHOD:
# Step 1: Get extension details
`$ext = Get-AzVMExtension -ResourceGroupName "RG" -VMName "VM" -Name "ExtName"
`$ext | Format-List *

# Step 2: Note configuration
`$publisher = `$ext.Publisher
`$type = `$ext.ExtensionType
`$version = `$ext.TypeHandlerVersion
`$settings = `$ext.Settings

# Step 3: Remove extension
Remove-AzVMExtension ``
    -ResourceGroupName "RG" ``
    -VMName "VM" ``
    -Name "ExtName" ``
    -Force

# Step 4: Verify removal
Get-AzVMExtension -ResourceGroupName "RG" -VMName "VM"

# Step 5: Reinstall extension
Set-AzVMExtension ``
    -ResourceGroupName "RG" ``
    -VMName "VM" ``
    -Name "ExtName" ``
    -Publisher `$publisher ``
    -ExtensionType `$type ``
    -TypeHandlerVersion `$version ``
    -Settings `$settings ``
    -Location "EastUS"

# Step 6: Verify installation
Get-AzVMExtension -ResourceGroupName "RG" -VMName "VM" -Name "ExtName"

AZURE PORTAL METHOD:
1. Navigate to VM in Azure Portal
2. Select "Extensions + applications"
3. Select extension
4. Click "Uninstall"
5. Wait for completion
6. Click "Add"
7. Select extension type
8. Configure settings
9. Click "Review + create"

TROUBLESHOOTING REINSTALL ISSUES:
- Wait 5-10 minutes between remove and reinstall
- Restart VM if extension won't uninstall
- Check VM Agent is running
- Verify internet connectivity
- Review Activity Log for detailed errors

"@

Write-Host $reinstallGuide -ForegroundColor White

#endregion

Write-Host "`n=== VM EXTENSION TROUBLESHOOTING COMPLETE ===" -ForegroundColor Green
Write-Host "Review extension logs in C:\WindowsAzure\Logs\Plugins\ for detailed diagnostics`n" -ForegroundColor Yellow
