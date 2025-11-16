<#
.SYNOPSIS
    Task 2.3 - Configure Microsoft Entra Password Protection

.DESCRIPTION
    Demo script for AZ-801 Module 2: Secure Local Accounts and Passwords
    This script demonstrates how to deploy and configure Microsoft Entra Password
    Protection (formerly Azure AD Password Protection) for on-premises Active Directory.

.NOTES
    Module: Module 2 - Secure Local Accounts and Passwords
    Task: 2.3 - Configure Microsoft Entra Password Protection

    Prerequisites:
    - Active Directory Domain Services
    - Domain Administrator privileges
    - Azure subscription with Microsoft Entra ID
    - .NET Framework 4.7.2 or later
    - Internet connectivity from domain controllers

    Lab Environment:
    - Domain Controller with Windows Server 2016+
    - Microsoft Entra tenant

    PowerShell Version: 5.1+
#>

#Requires -RunAsAdministrator

# Script configuration
$ErrorActionPreference = 'Stop'

Write-Host "=== AZ-801 Module 2: Task 2.3 - Microsoft Entra Password Protection ===" -ForegroundColor Cyan
Write-Host ""

try {
    # Section 1: Overview of Microsoft Entra Password Protection
    Write-Host "[Step 1] Microsoft Entra Password Protection Overview" -ForegroundColor Yellow

    Write-Host "`nWhat is Microsoft Entra Password Protection?" -ForegroundColor Cyan
    Write-Host "  - Cloud-based service that enhances password policies" -ForegroundColor White
    Write-Host "  - Blocks weak passwords using global and custom banned password lists" -ForegroundColor White
    Write-Host "  - Works for cloud-only and hybrid (on-premises) environments" -ForegroundColor White
    Write-Host "  - Prevents users from setting common weak passwords" -ForegroundColor White
    Write-Host ""
    Write-Host "Components:" -ForegroundColor Cyan
    Write-Host "  1. DC Agent: Installed on domain controllers" -ForegroundColor White
    Write-Host "  2. Proxy Service: Installed on member servers (forwards to Azure)" -ForegroundColor White
    Write-Host "  3. Microsoft Entra ID: Cloud service providing policy" -ForegroundColor White
    Write-Host ""

    Write-Host "[SUCCESS] Overview complete" -ForegroundColor Green
    Write-Host ""

    # Section 2: Check prerequisites
    Write-Host "[Step 2] Checking prerequisites" -ForegroundColor Yellow

    # Check .NET Framework version
    $netVersion = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" -ErrorAction SilentlyContinue).Release

    if ($netVersion -ge 461808) {
        $versionText = if ($netVersion -ge 528040) { "4.8" } elseif ($netVersion -ge 461808) { "4.7.2" } else { "Unknown" }
        Write-Host ".NET Framework Version: $versionText" -ForegroundColor White
        Write-Host "[SUCCESS] .NET Framework 4.7.2+ detected" -ForegroundColor Green
    } else {
        Write-Host "[WARNING] .NET Framework 4.7.2 or later required" -ForegroundColor Yellow
        Write-Host "Download from: https://dotnet.microsoft.com/download/dotnet-framework" -ForegroundColor White
    }

    # Check if DC
    $isDC = (Get-CimInstance -ClassName Win32_ComputerSystem).DomainRole -ge 4
    Write-Host "Is Domain Controller: $isDC" -ForegroundColor White

    # Check OS version
    $osVersion = [System.Environment]::OSVersion.Version
    if ($osVersion.Build -ge 14393) {
        Write-Host "OS Version: Supported" -ForegroundColor White
        Write-Host "[SUCCESS] Windows Server 2016 or later" -ForegroundColor Green
    } else {
        Write-Host "[WARNING] Windows Server 2016 or later required for DC Agent" -ForegroundColor Yellow
    }

    Write-Host ""

    # Section 3: Download and installation guidance
    Write-Host "[Step 3] Download and installation guidance" -ForegroundColor Yellow

    Write-Host "`nDownload Entra Password Protection components:" -ForegroundColor Cyan
    Write-Host "  Microsoft Download Center:" -ForegroundColor White
    Write-Host "  - Search: 'Azure AD Password Protection'" -ForegroundColor White
    Write-Host "  - Download both DC Agent and Proxy Service installers" -ForegroundColor White
    Write-Host ""
    Write-Host "Files to download:" -ForegroundColor Cyan
    Write-Host "  1. AzureADPasswordProtectionDCAgentSetup.msi" -ForegroundColor White
    Write-Host "  2. AzureADPasswordProtectionProxySetup.exe" -ForegroundColor White
    Write-Host ""

    # Check for installed components
    Write-Host "Checking for installed components..." -ForegroundColor White

    $dcAgent = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -like "*Azure AD Password Protection*DC Agent*" }
    $proxyService = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -like "*Azure AD Password Protection*Proxy*" }

    if ($dcAgent) {
        Write-Host "  DC Agent: Installed (Version: $($dcAgent.Version))" -ForegroundColor Green
    } else {
        Write-Host "  DC Agent: Not installed" -ForegroundColor Yellow
    }

    if ($proxyService) {
        Write-Host "  Proxy Service: Installed (Version: $($proxyService.Version))" -ForegroundColor Green
    } else {
        Write-Host "  Proxy Service: Not installed" -ForegroundColor Yellow
    }

    Write-Host ""

    # Section 4: Install DC Agent
    Write-Host "[Step 4] DC Agent installation" -ForegroundColor Yellow

    Write-Host "`nInstall DC Agent on ALL domain controllers:" -ForegroundColor Cyan
    Write-Host "  1. Copy AzureADPasswordProtectionDCAgentSetup.msi to DC" -ForegroundColor White
    Write-Host "  2. Run installer (GUI or silent):" -ForegroundColor White
    Write-Host "     msiexec.exe /i AzureADPasswordProtectionDCAgentSetup.msi /quiet /qn /norestart" -ForegroundColor White
    Write-Host "  3. Reboot the domain controller" -ForegroundColor White
    Write-Host "  4. Repeat for each DC in the domain" -ForegroundColor White
    Write-Host ""
    Write-Host "Verify DC Agent service:" -ForegroundColor Cyan
    Write-Host "  Get-Service AzureADPasswordProtectionDCAgent" -ForegroundColor White
    Write-Host ""

    # Check for DC Agent service
    $dcAgentSvc = Get-Service -Name "AzureADPasswordProtectionDCAgent" -ErrorAction SilentlyContinue

    if ($dcAgentSvc) {
        Write-Host "DC Agent Service Status: $($dcAgentSvc.Status)" -ForegroundColor White
        if ($dcAgentSvc.Status -eq 'Running') {
            Write-Host "[SUCCESS] DC Agent service is running" -ForegroundColor Green
        } else {
            Write-Host "[WARNING] DC Agent service is not running" -ForegroundColor Yellow
        }
    } else {
        Write-Host "[INFO] DC Agent service not found (not installed)" -ForegroundColor Yellow
    }

    Write-Host ""

    # Section 5: Install Proxy Service
    Write-Host "[Step 5] Proxy Service installation" -ForegroundColor Yellow

    Write-Host "`nInstall Proxy Service on member server(s):" -ForegroundColor Cyan
    Write-Host "  Requirements:" -ForegroundColor White
    Write-Host "  - Windows Server 2016 or later" -ForegroundColor White
    Write-Host "  - Member server (not domain controller)" -ForegroundColor White
    Write-Host "  - Internet connectivity" -ForegroundColor White
    Write-Host "  - Port 443 outbound to Azure" -ForegroundColor White
    Write-Host ""
    Write-Host "Installation:" -ForegroundColor Cyan
    Write-Host "  1. Run AzureADPasswordProtectionProxySetup.exe" -ForegroundColor White
    Write-Host "  2. Reboot the server" -ForegroundColor White
    Write-Host "  3. Register the proxy with Azure AD (next step)" -ForegroundColor White
    Write-Host ""
    Write-Host "Best Practices:" -ForegroundColor Cyan
    Write-Host "  - Install on at least 2 servers for redundancy" -ForegroundColor White
    Write-Host "  - Place in different AD sites for availability" -ForegroundColor White
    Write-Host ""

    # Check for Proxy service
    $proxySvc = Get-Service -Name "AzureADPasswordProtectionProxy" -ErrorAction SilentlyContinue

    if ($proxySvc) {
        Write-Host "Proxy Service Status: $($proxySvc.Status)" -ForegroundColor White
        if ($proxySvc.Status -eq 'Running') {
            Write-Host "[SUCCESS] Proxy service is running" -ForegroundColor Green
        }
    } else {
        Write-Host "[INFO] Proxy service not found (install on member server)" -ForegroundColor Yellow
    }

    Write-Host ""

    # Section 6: Register Proxy with Microsoft Entra
    Write-Host "[Step 6] Register Proxy Service with Microsoft Entra" -ForegroundColor Yellow

    Write-Host "`nRegister Proxy (run on Proxy server):" -ForegroundColor Cyan
    Write-Host "  1. Import the module:" -ForegroundColor White
    Write-Host "     Import-Module AzureADPasswordProtection" -ForegroundColor White
    Write-Host ""
    Write-Host "  2. Register the proxy:" -ForegroundColor White
    Write-Host "     Register-AzureADPasswordProtectionProxy ``" -ForegroundColor White
    Write-Host "       -AccountUpn 'admin@contoso.onmicrosoft.com'" -ForegroundColor White
    Write-Host ""
    Write-Host "  3. Verify registration:" -ForegroundColor White
    Write-Host "     Get-AzureADPasswordProtectionProxy" -ForegroundColor White
    Write-Host ""

    Write-Host "Authentication:" -ForegroundColor Cyan
    Write-Host "  - Requires Global Administrator or Security Administrator role" -ForegroundColor White
    Write-Host "  - Interactive authentication to Microsoft Entra ID" -ForegroundColor White
    Write-Host ""

    # Section 7: Register Forest with Microsoft Entra
    Write-Host "[Step 7] Register Active Directory Forest" -ForegroundColor Yellow

    Write-Host "`nRegister AD Forest (run on DC with DC Agent):" -ForegroundColor Cyan
    Write-Host "  1. Import the module:" -ForegroundColor White
    Write-Host "     Import-Module AzureADPasswordProtection" -ForegroundColor White
    Write-Host ""
    Write-Host "  2. Register the forest:" -ForegroundColor White
    Write-Host "     Register-AzureADPasswordProtectionForest ``" -ForegroundColor White
    Write-Host "       -AccountUpn 'admin@contoso.onmicrosoft.com'" -ForegroundColor White
    Write-Host ""
    Write-Host "  3. Verify registration:" -ForegroundColor White
    Write-Host "     Get-AzureADPasswordProtectionForest" -ForegroundColor White
    Write-Host ""

    Write-Host "Notes:" -ForegroundColor Cyan
    Write-Host "  - Only needs to be done once per forest" -ForegroundColor White
    Write-Host "  - Requires Enterprise Administrator privileges" -ForegroundColor White
    Write-Host ""

    # Section 8: Configure password protection in Microsoft Entra
    Write-Host "[Step 8] Configure password protection in Microsoft Entra admin center" -ForegroundColor Yellow

    Write-Host "`nConfigure in Entra admin center:" -ForegroundColor Cyan
    Write-Host "  1. Navigate to: Microsoft Entra admin center > Protection > Authentication methods" -ForegroundColor White
    Write-Host "  2. Select: Password protection" -ForegroundColor White
    Write-Host ""
    Write-Host "Settings to configure:" -ForegroundColor Cyan
    Write-Host "  Custom banned password list:" -ForegroundColor White
    Write-Host "    - Add organization-specific terms (company name, products, etc.)" -ForegroundColor White
    Write-Host "    - Example: CompanyName, ProductNames, Location, etc." -ForegroundColor White
    Write-Host ""
    Write-Host "  Enforce on Windows Server Active Directory:" -ForegroundColor White
    Write-Host "    - Enable: Yes" -ForegroundColor White
    Write-Host "    - Mode: Enforced (or Audit for testing)" -ForegroundColor White
    Write-Host ""
    Write-Host "  Lockout duration:" -ForegroundColor White
    Write-Host "    - Recommended: 60 seconds" -ForegroundColor White
    Write-Host ""

    # Section 9: Testing and monitoring
    Write-Host "[Step 9] Testing and monitoring" -ForegroundColor Yellow

    Write-Host "`nTest Password Protection:" -ForegroundColor Cyan
    Write-Host "  1. Start in Audit mode" -ForegroundColor White
    Write-Host "  2. Attempt to set weak passwords (e.g., 'Password123')" -ForegroundColor White
    Write-Host "  3. Review event logs on DC:" -ForegroundColor White
    Write-Host "     Event Viewer > Applications and Services Logs >" -ForegroundColor White
    Write-Host "     Microsoft > AzureADPasswordProtection > DCAgent > Admin" -ForegroundColor White
    Write-Host ""
    Write-Host "Key Event IDs:" -ForegroundColor Cyan
    Write-Host "  - 10014: Password accepted (Audit mode)" -ForegroundColor White
    Write-Host "  - 10015: Password rejected (Audit mode)" -ForegroundColor White
    Write-Host "  - 10016: Password accepted (Enforced mode)" -ForegroundColor White
    Write-Host "  - 10017: Password rejected (Enforced mode)" -ForegroundColor White
    Write-Host ""
    Write-Host "Monitor with PowerShell:" -ForegroundColor Cyan
    Write-Host "  Get-EventLog -LogName 'Microsoft-AzureADPasswordProtection-DCAgent/Admin' -Newest 50" -ForegroundColor White
    Write-Host ""

    # Section 10: Create deployment guide
    Write-Host "[Step 10] Creating deployment guide" -ForegroundColor Yellow

    $deploymentGuide = @"
Microsoft Entra Password Protection Deployment Guide
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

=== Overview ===
Microsoft Entra Password Protection extends password policies to include:
- Global banned password list (Microsoft-maintained)
- Custom banned password list (organization-specific)
- Smart lockout features
- Hybrid integration with on-premises AD

=== Deployment Phases ===

PHASE 1: Planning
[ ] Verify prerequisites (.NET 4.7.2+, Windows Server 2016+)
[ ] Identify domain controllers for agent installation
[ ] Identify member servers for proxy installation
[ ] Verify internet connectivity requirements
[ ] Create custom banned password list
[ ] Plan pilot group for testing

PHASE 2: Proxy Installation
[ ] Install Proxy service on 2+ member servers
[ ] Reboot proxy servers
[ ] Register proxy with Microsoft Entra
      Register-AzureADPasswordProtectionProxy -AccountUpn 'admin@tenant.onmicrosoft.com'
[ ] Verify proxy registration
      Get-AzureADPasswordProtectionProxy

PHASE 3: DC Agent Installation
[ ] Install DC Agent on first domain controller
[ ] Reboot domain controller
[ ] Verify DC Agent service is running
[ ] Register AD forest with Microsoft Entra (once per forest)
      Register-AzureADPasswordProtectionForest -AccountUpn 'admin@tenant.onmicrosoft.com'
[ ] Install DC Agent on remaining domain controllers
[ ] Reboot all DCs

PHASE 4: Configuration
[ ] Configure in Entra admin center:
    - Navigate to Protection > Authentication methods > Password protection
[ ] Add custom banned passwords
    - Company name, product names, locations
    - Common variations and misspellings
[ ] Enable for Windows Server Active Directory
[ ] Set mode to "Audit" for initial testing
[ ] Configure lockout settings

PHASE 5: Testing (Audit Mode)
[ ] Test password changes with weak passwords
[ ] Review DC Agent event logs
[ ] Verify banned passwords are detected
[ ] Monitor for false positives
[ ] Adjust custom banned list as needed
[ ] Test for 2-4 weeks in audit mode

PHASE 6: Enforcement
[ ] Review audit logs and adjust policies
[ ] Change mode from "Audit" to "Enforced"
[ ] Communicate change to users
[ ] Monitor event logs for issues
[ ] Provide help desk with guidance

=== Configuration Commands ===

# Check service status
Get-Service AzureADPasswordProtectionDCAgent
Get-Service AzureADPasswordProtectionProxy

# Verify registration
Get-AzureADPasswordProtectionProxy
Get-AzureADPasswordProtectionForest

# View recent password events
Get-EventLog -LogName 'Microsoft-AzureADPasswordProtection-DCAgent/Admin' -Newest 100

=== Custom Banned Password List Examples ===
- Company name and variations
- Product names
- Office locations (cities, building names)
- Seasonal terms (Summer2024, Winter2024)
- Common substitutions (P@ssw0rd, Passw0rd)
- Industry-specific terms

=== Troubleshooting ===

Proxy not communicating:
- Verify internet connectivity
- Check firewall rules (port 443 outbound)
- Verify proxy service is running
- Check event logs on proxy server

DC Agent not working:
- Verify DC Agent service is running
- Check connectivity to proxy servers
- Review DC Agent event logs
- Ensure forest is registered

Passwords not being validated:
- Verify mode is set to "Enforced" (not "Audit")
- Check replication of password policies
- Confirm DC Agent is running on all DCs
- Review event logs for errors

=== Monitoring and Maintenance ===

Daily:
- Monitor event logs for errors
- Check service status on all servers

Weekly:
- Review rejected password attempts
- Identify patterns or trends

Monthly:
- Update custom banned password list
- Review and adjust lockout settings
- Audit proxy and DC agent versions
- Plan updates if new versions available

Quarterly:
- Full compliance review
- User awareness training
- Documentation updates

=== Best Practices ===
- Install proxy on at least 2 servers for redundancy
- Install DC Agent on ALL domain controllers
- Start in Audit mode before enforcing
- Keep custom banned list up to date
- Monitor event logs regularly
- Keep agents and proxies updated
- Document custom banned passwords
- User education on password requirements
"@

    $guidePath = "$env:TEMP\EntraPasswordProtection-Deployment-Guide.txt"
    $deploymentGuide | Out-File -FilePath $guidePath -Encoding UTF8

    Write-Host "Deployment guide saved to: $guidePath" -ForegroundColor White
    Write-Host "[SUCCESS] Guide created" -ForegroundColor Green
    Write-Host ""

    # Section 11: Educational notes
    Write-Host "[INFO] Microsoft Entra Password Protection Best Practices:" -ForegroundColor Cyan
    Write-Host "  - Always start in Audit mode to monitor impact" -ForegroundColor White
    Write-Host "  - Install proxy on multiple servers for redundancy" -ForegroundColor White
    Write-Host "  - Install DC Agent on ALL domain controllers" -ForegroundColor White
    Write-Host "  - Keep custom banned list relevant to your organization" -ForegroundColor White
    Write-Host "  - Monitor event logs for password rejection patterns" -ForegroundColor White
    Write-Host "  - Educate users about new password requirements" -ForegroundColor White
    Write-Host "  - Regular updates of agents and proxy services" -ForegroundColor White
    Write-Host "  - Integrate with password self-service reset" -ForegroundColor White
    Write-Host ""

} catch {
    Write-Host "[ERROR] $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

Write-Host "Demo completed successfully!" -ForegroundColor Green
Write-Host "Next Steps: Download components, install in audit mode, and monitor" -ForegroundColor Yellow
