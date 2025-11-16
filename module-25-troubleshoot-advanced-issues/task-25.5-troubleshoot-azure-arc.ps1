<#
.SYNOPSIS
    Task 25.5 - Troubleshoot Azure Arc

.DESCRIPTION
    Demo script for AZ-801 Module 25: Troubleshoot Advanced Issues
    Demonstrates Azure Arc connectivity and agent troubleshooting.

    Covers:
    - Azure Arc agent status and health checks
    - Connectivity testing and validation
    - Extension troubleshooting
    - Log collection and analysis
    - Agent reinstallation procedures
    - Network requirements validation

.NOTES
    Module: Module 25 - Troubleshoot Advanced Issues
    Task: 25.5 - Troubleshoot Azure Arc
    Prerequisites: Windows Server, Azure Arc agent installed
    PowerShell Version: 5.1+
#>

#Requires -RunAsAdministrator

$ErrorActionPreference = 'Stop'
Write-Host "=== AZ-801 Module 25: Task 25.5 - Troubleshoot Azure Arc ===" -ForegroundColor Cyan
Write-Host ""

try {
    Write-Host "[Step 1] Azure Arc Troubleshooting - Overview" -ForegroundColor Yellow
    Write-Host "Comprehensive Azure Arc agent troubleshooting procedures" -ForegroundColor White
    Write-Host ""

    # ============================================
    # STEP 2: Check Arc Agent Installation
    # ============================================
    Write-Host "[Step 2] Azure Arc Agent Status" -ForegroundColor Yellow

    Write-Host "`n[2.1] Checking if Arc Agent is Installed..." -ForegroundColor Cyan

    # Check for azcmagent executable
    $azcmagentPath = "C:\Program Files\AzureConnectedMachineAgent\azcmagent.exe"
    $agentInstalled = Test-Path $azcmagentPath

    if ($agentInstalled) {
        Write-Host "  [SUCCESS] Azure Arc agent is installed" -ForegroundColor Green
        Write-Host "  Agent Location: $azcmagentPath" -ForegroundColor Gray

        # Get agent version
        Write-Host "`n[2.2] Getting Agent Version..." -ForegroundColor Cyan
        Write-Host "  Command: azcmagent version" -ForegroundColor Gray
        Write-Host "  [INFO] Run this command to see agent version details" -ForegroundColor White
        Write-Host ""

        # Show agent status
        Write-Host "[2.3] Checking Agent Status..." -ForegroundColor Cyan
        Write-Host "  Command: azcmagent show" -ForegroundColor Gray
        Write-Host "  [INFO] This command displays:" -ForegroundColor White
        Write-Host "    - Resource Name" -ForegroundColor Gray
        Write-Host "    - Resource Group" -ForegroundColor Gray
        Write-Host "    - Subscription ID" -ForegroundColor Gray
        Write-Host "    - Azure Resource ID" -ForegroundColor Gray
        Write-Host "    - Agent Status" -ForegroundColor Gray
        Write-Host "    - Last Heartbeat" -ForegroundColor Gray
        Write-Host ""

    } else {
        Write-Host "  [WARNING] Azure Arc agent is NOT installed" -ForegroundColor Yellow
        Write-Host "  Expected location: $azcmagentPath" -ForegroundColor Gray
        Write-Host "  [INFO] Install instructions shown in Step 8" -ForegroundColor Cyan
    }

    # Check Arc agent service
    Write-Host "[2.4] Checking Arc Agent Services..." -ForegroundColor Cyan
    $arcServices = @(
        'himds',           # Hybrid Instance Metadata Service
        'GCArcService'     # Guest Configuration Arc Service
    )

    foreach ($serviceName in $arcServices) {
        $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
        if ($service) {
            $statusColor = if ($service.Status -eq 'Running') { 'Green' } else { 'Red' }
            Write-Host "  Service: $serviceName" -ForegroundColor White
            Write-Host "    Status: $($service.Status)" -ForegroundColor $statusColor
            Write-Host "    Startup Type: $($service.StartType)" -ForegroundColor Gray

            if ($service.Status -ne 'Running') {
                Write-Host "    [WARNING] Service is not running!" -ForegroundColor Red
                Write-Host "    [FIX] Start-Service -Name $serviceName" -ForegroundColor Yellow
            }
        } else {
            Write-Host "  [WARNING] Service '$serviceName' not found" -ForegroundColor Yellow
        }
    }

    Write-Host "[SUCCESS] Agent status check completed" -ForegroundColor Green
    Write-Host ""

    # ============================================
    # STEP 3: Connectivity Tests
    # ============================================
    Write-Host "[Step 3] Azure Arc Connectivity Testing" -ForegroundColor Yellow

    Write-Host "`n[3.1] Network Requirements..." -ForegroundColor Cyan
    Write-Host "  Azure Arc requires connectivity to these endpoints:" -ForegroundColor White
    Write-Host ""

    # Define required endpoints
    $requiredEndpoints = @(
        @{Name="Azure Resource Manager"; URL="management.azure.com"; Port=443}
        @{Name="Azure AD"; URL="login.microsoftonline.com"; Port=443}
        @{Name="Azure Arc"; URL="*.guestconfiguration.azure.com"; Port=443}
        @{Name="Hybrid Metadata Service"; URL="*.his.arc.azure.com"; Port=443}
        @{Name="Guest Configuration"; URL="*.guestconfiguration.azure.com"; Port=443}
        @{Name="Download Service"; URL="download.microsoft.com"; Port=443}
    )

    foreach ($endpoint in $requiredEndpoints) {
        Write-Host "  $($endpoint.Name):" -ForegroundColor Cyan
        Write-Host "    Endpoint: $($endpoint.URL):$($endpoint.Port)" -ForegroundColor Gray
    }

    Write-Host "`n[3.2] Testing Connectivity..." -ForegroundColor Cyan
    Write-Host "  Command: azcmagent check" -ForegroundColor Gray
    Write-Host "  [INFO] This command validates:" -ForegroundColor White
    Write-Host "    - Network connectivity to required endpoints" -ForegroundColor Gray
    Write-Host "    - Proxy configuration (if applicable)" -ForegroundColor Gray
    Write-Host "    - DNS resolution" -ForegroundColor Gray
    Write-Host "    - TLS/SSL connectivity" -ForegroundColor Gray
    Write-Host ""

    # Test basic connectivity to key endpoints
    Write-Host "[3.3] Testing Key Azure Endpoints..." -ForegroundColor Cyan
    $testEndpoints = @(
        "management.azure.com",
        "login.microsoftonline.com",
        "download.microsoft.com"
    )

    foreach ($endpoint in $testEndpoints) {
        Write-Host "  Testing $endpoint..." -ForegroundColor White
        try {
            $result = Test-NetConnection -ComputerName $endpoint -Port 443 -InformationLevel Quiet -WarningAction SilentlyContinue
            if ($result) {
                Write-Host "    [SUCCESS] Connected to $endpoint" -ForegroundColor Green
            } else {
                Write-Host "    [ERROR] Cannot connect to $endpoint" -ForegroundColor Red
            }
        } catch {
            Write-Host "    [ERROR] Connection test failed: $_" -ForegroundColor Red
        }
    }

    Write-Host "`n[3.4] Proxy Configuration Check..." -ForegroundColor Cyan
    Write-Host "  If using a proxy, configure with:" -ForegroundColor White
    Write-Host "    azcmagent config set proxy.url 'http://proxy.contoso.com:8080'" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Check current proxy setting:" -ForegroundColor White
    Write-Host "    azcmagent config get proxy.url" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[SUCCESS] Connectivity testing completed" -ForegroundColor Green
    Write-Host ""

    # ============================================
    # STEP 4: Extension Troubleshooting
    # ============================================
    Write-Host "[Step 4] Azure Arc Extension Troubleshooting" -ForegroundColor Yellow

    Write-Host "`n[4.1] Listing Installed Extensions..." -ForegroundColor Cyan
    Write-Host "  PowerShell Command:" -ForegroundColor White
    Write-Host "    Get-AzConnectedMachineExtension -ResourceGroupName '<RG>' -MachineName '<Machine>'" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  [INFO] Extensions add functionality to Arc-enabled servers:" -ForegroundColor Gray
    Write-Host "    - Azure Monitor Agent" -ForegroundColor Gray
    Write-Host "    - Log Analytics Agent" -ForegroundColor Gray
    Write-Host "    - Dependency Agent" -ForegroundColor Gray
    Write-Host "    - Custom Script Extension" -ForegroundColor Gray
    Write-Host "    - Azure Policy Guest Configuration" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[4.2] Extension Status Check..." -ForegroundColor Cyan
    Write-Host "  Extension properties to check:" -ForegroundColor White
    Write-Host "    - ProvisioningState: Should be 'Succeeded'" -ForegroundColor Gray
    Write-Host "    - ExtensionType: Identifies the extension" -ForegroundColor Gray
    Write-Host "    - TypeHandlerVersion: Extension version" -ForegroundColor Gray
    Write-Host "    - Settings: Extension configuration" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[4.3] Extension Troubleshooting Commands..." -ForegroundColor Cyan
    Write-Host "  View extension details:" -ForegroundColor White
    Write-Host "    Get-AzConnectedMachineExtension -Name '<ExtName>' -ResourceGroupName '<RG>' -MachineName '<Machine>'" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Remove problematic extension:" -ForegroundColor White
    Write-Host "    Remove-AzConnectedMachineExtension -Name '<ExtName>' -ResourceGroupName '<RG>' -MachineName '<Machine>'" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Reinstall extension:" -ForegroundColor White
    Write-Host "    New-AzConnectedMachineExtension -Name '<ExtName>' -ResourceGroupName '<RG>' -MachineName '<Machine>' -Location '<Location>' -Publisher '<Publisher>' -ExtensionType '<Type>'" -ForegroundColor Yellow
    Write-Host ""

    # Check extension logs location
    Write-Host "[4.4] Extension Log Locations..." -ForegroundColor Cyan
    $extensionLogPath = "C:\ProgramData\GuestConfig\extension_logs"
    Write-Host "  Extension logs directory: $extensionLogPath" -ForegroundColor White
    if (Test-Path $extensionLogPath) {
        Write-Host "  [SUCCESS] Extension log directory exists" -ForegroundColor Green
        $logFiles = Get-ChildItem -Path $extensionLogPath -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 5
        if ($logFiles) {
            Write-Host "  Recent log files:" -ForegroundColor Gray
            foreach ($log in $logFiles) {
                Write-Host "    - $($log.FullName)" -ForegroundColor DarkGray
            }
        }
    } else {
        Write-Host "  [INFO] Extension log directory not found" -ForegroundColor Gray
    }

    Write-Host "[SUCCESS] Extension troubleshooting information provided" -ForegroundColor Green
    Write-Host ""

    # ============================================
    # STEP 5: Log Collection and Analysis
    # ============================================
    Write-Host "[Step 5] Azure Arc Log Collection" -ForegroundColor Yellow

    Write-Host "`n[5.1] Arc Agent Log Locations..." -ForegroundColor Cyan
    $logLocations = @{
        "Agent Logs" = "C:\ProgramData\AzureConnectedMachineAgent\Log"
        "Guest Config Logs" = "C:\ProgramData\GuestConfig"
        "Extension Logs" = "C:\ProgramData\GuestConfig\extension_logs"
        "Windows Event Logs" = "Application and System logs"
    }

    foreach ($location in $logLocations.GetEnumerator()) {
        Write-Host "  $($location.Key):" -ForegroundColor White
        Write-Host "    Location: $($location.Value)" -ForegroundColor Gray

        if ($location.Value -notmatch "Application|System") {
            if (Test-Path $location.Value) {
                Write-Host "    [SUCCESS] Directory exists" -ForegroundColor Green
            } else {
                Write-Host "    [WARNING] Directory not found" -ForegroundColor Yellow
            }
        }
    }

    Write-Host "`n[5.2] Collecting Arc Agent Logs..." -ForegroundColor Cyan
    Write-Host "  Command to collect logs:" -ForegroundColor White
    Write-Host "    azcmagent logs" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  This creates a ZIP file with:" -ForegroundColor Gray
    Write-Host "    - Agent logs" -ForegroundColor Gray
    Write-Host "    - Service logs" -ForegroundColor Gray
    Write-Host "    - Extension logs" -ForegroundColor Gray
    Write-Host "    - System information" -ForegroundColor Gray
    Write-Host ""

    # Check recent agent logs
    Write-Host "[5.3] Recent Agent Log Files..." -ForegroundColor Cyan
    $agentLogPath = "C:\ProgramData\AzureConnectedMachineAgent\Log"
    if (Test-Path $agentLogPath) {
        $recentLogs = Get-ChildItem -Path $agentLogPath -Filter "*.log" -File -ErrorAction SilentlyContinue |
                      Sort-Object LastWriteTime -Descending |
                      Select-Object -First 5

        if ($recentLogs) {
            Write-Host "  Recent log files:" -ForegroundColor White
            foreach ($log in $recentLogs) {
                Write-Host "    - $($log.Name) (Modified: $($log.LastWriteTime))" -ForegroundColor Gray
            }
        }
    }

    Write-Host "`n[5.4] Event Log Analysis..." -ForegroundColor Cyan
    Write-Host "  Checking for Arc-related events..." -ForegroundColor White

    # Check for Hybrid Instance Metadata Service events
    $himdEvents = Get-WinEvent -FilterHashtable @{
        LogName = 'Application'
        ProviderName = 'himds'
    } -MaxEvents 10 -ErrorAction SilentlyContinue

    if ($himdEvents) {
        Write-Host "  [INFO] Found $($himdEvents.Count) recent HIMDS events:" -ForegroundColor Cyan
        $himdEvents | Select-Object -First 5 | ForEach-Object {
            $levelColor = switch ($_.Level) {
                2 { 'Red' }      # Error
                3 { 'Yellow' }   # Warning
                default { 'Gray' }
            }
            Write-Host "    [$($_.TimeCreated)] Level $($_.Level): $($_.Message.Substring(0, [Math]::Min(80, $_.Message.Length)))..." -ForegroundColor $levelColor
        }
    } else {
        Write-Host "  [INFO] No recent HIMDS events found" -ForegroundColor Gray
    }

    # Check for Guest Configuration events
    $gcEvents = Get-WinEvent -FilterHashtable @{
        LogName = 'Application'
        ProviderName = 'GCArcService'
    } -MaxEvents 10 -ErrorAction SilentlyContinue

    if ($gcEvents) {
        Write-Host "`n  [INFO] Found $($gcEvents.Count) recent Guest Config events:" -ForegroundColor Cyan
        $gcEvents | Select-Object -First 5 | ForEach-Object {
            Write-Host "    [$($_.TimeCreated)] Event $($_.Id): $($_.Message.Substring(0, [Math]::Min(80, $_.Message.Length)))..." -ForegroundColor Gray
        }
    }

    Write-Host "[SUCCESS] Log collection analysis completed" -ForegroundColor Green
    Write-Host ""

    # ============================================
    # STEP 6: Agent Reconnection
    # ============================================
    Write-Host "[Step 6] Agent Reconnection Procedures" -ForegroundColor Yellow

    Write-Host "`n[6.1] When Agent Connection is Lost..." -ForegroundColor Cyan
    Write-Host "  Symptoms:" -ForegroundColor White
    Write-Host "    - 'Disconnected' status in Azure Portal" -ForegroundColor Gray
    Write-Host "    - No recent heartbeat" -ForegroundColor Gray
    Write-Host "    - Extensions failing to install/update" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[6.2] Reconnection Steps..." -ForegroundColor Cyan
    Write-Host "  Step 1: Check service status" -ForegroundColor White
    Write-Host "    Get-Service -Name himds, GCArcService" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Step 2: Restart services if needed" -ForegroundColor White
    Write-Host "    Restart-Service -Name himds" -ForegroundColor Yellow
    Write-Host "    Restart-Service -Name GCArcService" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Step 3: Test connectivity" -ForegroundColor White
    Write-Host "    azcmagent check" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Step 4: Force reconnection (if needed)" -ForegroundColor White
    Write-Host "    azcmagent connect --resource-group '<RG>' --location '<Location>'" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[6.3] Network Troubleshooting..." -ForegroundColor Cyan
    Write-Host "  Check firewall rules:" -ForegroundColor White
    Write-Host "    - Allow outbound HTTPS (443) to Azure endpoints" -ForegroundColor Gray
    Write-Host "    - Check proxy configuration if applicable" -ForegroundColor Gray
    Write-Host "    - Verify DNS resolution for Azure endpoints" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[SUCCESS] Reconnection procedures documented" -ForegroundColor Green
    Write-Host ""

    # ============================================
    # STEP 7: Agent Reinstallation
    # ============================================
    Write-Host "[Step 7] Agent Reinstallation Procedures" -ForegroundColor Yellow

    Write-Host "`n[7.1] When to Reinstall..." -ForegroundColor Cyan
    Write-Host "  Consider reinstalling if:" -ForegroundColor White
    Write-Host "    - Agent is corrupted" -ForegroundColor Gray
    Write-Host "    - Persistent connection issues after troubleshooting" -ForegroundColor Gray
    Write-Host "    - After major OS changes" -ForegroundColor Gray
    Write-Host "    - Upgrade to new agent version" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[7.2] Disconnection Process..." -ForegroundColor Cyan
    Write-Host "  Step 1: Disconnect agent from Azure" -ForegroundColor White
    Write-Host "    azcmagent disconnect --force-local-only" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Note: Use --force-local-only if you can't reach Azure" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[7.3] Uninstallation Process..." -ForegroundColor Cyan
    Write-Host "  Step 2: Uninstall the agent" -ForegroundColor White
    Write-Host "    # Via Programs and Features, or:" -ForegroundColor Gray
    Write-Host "    Get-Package -Name 'Azure Connected Machine Agent' | Uninstall-Package" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[7.4] Installation Process..." -ForegroundColor Cyan
    Write-Host "  Step 3: Download and install latest agent" -ForegroundColor White
    Write-Host "    # Download from: https://aka.ms/AzureConnectedMachineAgent" -ForegroundColor Gray
    Write-Host "    msiexec /i AzureConnectedMachineAgent.msi /qn" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Step 4: Connect to Azure" -ForegroundColor White
    Write-Host "    azcmagent connect --resource-group '<RG>' --tenant-id '<TenantID>' --location '<Location>' --subscription-id '<SubID>'" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Step 5: Verify connection" -ForegroundColor White
    Write-Host "    azcmagent show" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[SUCCESS] Reinstallation procedures documented" -ForegroundColor Green
    Write-Host ""

    # ============================================
    # STEP 8: Common Issues and Solutions
    # ============================================
    Write-Host "[Step 8] Common Azure Arc Issues and Solutions" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[Issue 1] Agent Shows 'Disconnected' in Portal" -ForegroundColor Cyan
    Write-Host "  Cause: No heartbeat received from agent" -ForegroundColor White
    Write-Host "  Diagnosis:" -ForegroundColor White
    Write-Host "    - Check if himds service is running" -ForegroundColor Gray
    Write-Host "    - Review agent logs for errors" -ForegroundColor Gray
    Write-Host "    - Test network connectivity" -ForegroundColor Gray
    Write-Host "  Resolution:" -ForegroundColor White
    Write-Host "    1. Restart-Service -Name himds" -ForegroundColor Yellow
    Write-Host "    2. azcmagent check" -ForegroundColor Yellow
    Write-Host "    3. azcmagent show" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[Issue 2] Extension Installation Fails" -ForegroundColor Cyan
    Write-Host "  Cause: Extension service issues or network problems" -ForegroundColor White
    Write-Host "  Diagnosis:" -ForegroundColor White
    Write-Host "    - Check GCArcService status" -ForegroundColor Gray
    Write-Host "    - Review extension logs" -ForegroundColor Gray
    Write-Host "    - Verify connectivity to download endpoints" -ForegroundColor Gray
    Write-Host "  Resolution:" -ForegroundColor White
    Write-Host "    1. Restart-Service -Name GCArcService" -ForegroundColor Yellow
    Write-Host "    2. Remove-AzConnectedMachineExtension (then reinstall)" -ForegroundColor Yellow
    Write-Host "    3. Check C:\ProgramData\GuestConfig\extension_logs for errors" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[Issue 3] Cannot Connect to Azure" -ForegroundColor Cyan
    Write-Host "  Cause: Network or authentication issues" -ForegroundColor White
    Write-Host "  Diagnosis:" -ForegroundColor White
    Write-Host "    - Test connectivity to management.azure.com" -ForegroundColor Gray
    Write-Host "    - Verify DNS resolution" -ForegroundColor Gray
    Write-Host "    - Check proxy configuration" -ForegroundColor Gray
    Write-Host "  Resolution:" -ForegroundColor White
    Write-Host "    1. Test-NetConnection -ComputerName management.azure.com -Port 443" -ForegroundColor Yellow
    Write-Host "    2. Configure proxy: azcmagent config set proxy.url '<ProxyURL>'" -ForegroundColor Yellow
    Write-Host "    3. azcmagent check" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[Issue 4] High CPU Usage by Agent" -ForegroundColor Cyan
    Write-Host "  Cause: Extension activity or policy evaluation" -ForegroundColor White
    Write-Host "  Diagnosis:" -ForegroundColor White
    Write-Host "    - Check which extensions are installed" -ForegroundColor Gray
    Write-Host "    - Review extension logs" -ForegroundColor Gray
    Write-Host "    - Check for policy assignments" -ForegroundColor Gray
    Write-Host "  Resolution:" -ForegroundColor White
    Write-Host "    1. Get-Process | Where-Object {`$_.ProcessName -match 'gc_|himds'}" -ForegroundColor Yellow
    Write-Host "    2. Review and remove unnecessary extensions" -ForegroundColor Yellow
    Write-Host "    3. Check Azure Policy assignments" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[Issue 5] Agent Version is Outdated" -ForegroundColor Cyan
    Write-Host "  Cause: No automatic update configured" -ForegroundColor White
    Write-Host "  Diagnosis:" -ForegroundColor White
    Write-Host "    - Check current version: azcmagent version" -ForegroundColor Gray
    Write-Host "    - Compare with latest version in docs" -ForegroundColor Gray
    Write-Host "  Resolution:" -ForegroundColor White
    Write-Host "    1. Download latest agent from https://aka.ms/AzureConnectedMachineAgent" -ForegroundColor Yellow
    Write-Host "    2. Run installer to upgrade in-place" -ForegroundColor Yellow
    Write-Host "    3. Verify: azcmagent version" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[SUCCESS] Common issues and solutions documented" -ForegroundColor Green
    Write-Host ""

    # ============================================
    # STEP 9: Monitoring and Best Practices
    # ============================================
    Write-Host "[Step 9] Monitoring and Best Practices" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[Best Practice 1] Regular Health Checks" -ForegroundColor Cyan
    Write-Host "  - Monitor connection status in Azure Portal" -ForegroundColor White
    Write-Host "  - Set up alerts for disconnected agents" -ForegroundColor White
    Write-Host "  - Review agent logs weekly" -ForegroundColor White
    Write-Host "  - Keep agent version current" -ForegroundColor White
    Write-Host ""

    Write-Host "[Best Practice 2] Network Configuration" -ForegroundColor Cyan
    Write-Host "  - Document all required endpoints" -ForegroundColor White
    Write-Host "  - Configure firewall rules properly" -ForegroundColor White
    Write-Host "  - Test connectivity after network changes" -ForegroundColor White
    Write-Host "  - Use private endpoints where possible" -ForegroundColor White
    Write-Host ""

    Write-Host "[Best Practice 3] Extension Management" -ForegroundColor Cyan
    Write-Host "  - Only install required extensions" -ForegroundColor White
    Write-Host "  - Monitor extension status" -ForegroundColor White
    Write-Host "  - Review extension logs for errors" -ForegroundColor White
    Write-Host "  - Test extensions in dev before production" -ForegroundColor White
    Write-Host ""

    Write-Host "[Best Practice 4] Security" -ForegroundColor Cyan
    Write-Host "  - Use managed identities for authentication" -ForegroundColor White
    Write-Host "  - Apply least privilege RBAC roles" -ForegroundColor White
    Write-Host "  - Keep agent and extensions updated" -ForegroundColor White
    Write-Host "  - Monitor for security events in logs" -ForegroundColor White
    Write-Host ""

    Write-Host "[Monitoring Commands]" -ForegroundColor Cyan
    Write-Host "  Check all Arc machines in subscription:" -ForegroundColor White
    Write-Host "    Get-AzConnectedMachine | Select-Object Name, Status, LastStatusChange" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Find disconnected machines:" -ForegroundColor White
    Write-Host "    Get-AzConnectedMachine | Where-Object {`$_.Status -eq 'Disconnected'}" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Check extension status for all machines:" -ForegroundColor White
    Write-Host "    Get-AzConnectedMachine | ForEach-Object { Get-AzConnectedMachineExtension -MachineName `$_.Name -ResourceGroupName `$_.ResourceGroupName }" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[INFO] Additional Resources:" -ForegroundColor Cyan
    Write-Host "  - Azure Arc documentation: https://docs.microsoft.com/azure/azure-arc/" -ForegroundColor White
    Write-Host "  - Troubleshooting guide: https://docs.microsoft.com/azure/azure-arc/servers/troubleshoot-agent-onboard" -ForegroundColor White
    Write-Host "  - Network requirements: https://docs.microsoft.com/azure/azure-arc/servers/network-requirements" -ForegroundColor White
    Write-Host ""

} catch {
    Write-Host "[ERROR] $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

Write-Host "Azure Arc troubleshooting demonstration completed successfully!" -ForegroundColor Green
Write-Host "Next Steps: Implement monitoring and maintain agent health" -ForegroundColor Yellow
