<#
.SYNOPSIS
    Task 6.1 - Configure Windows Defender Firewall
.DESCRIPTION
    Comprehensive demonstration of Windows Defender Firewall with Advanced Security configuration.
    Covers profile management, firewall rules, logging, and monitoring.
.EXAMPLE
    .\task-6.1-defender-firewall.ps1
.NOTES
    Module: Module 6 - Secure Windows Server Networking
    Task: 6.1 - Configure Windows Defender Firewall
    Prerequisites:
    - Windows Server with administrative privileges
    - NetSecurity PowerShell module
    PowerShell Version: 5.1+
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

Write-Host "=== AZ-801 Module 6: Task 6.1 - Configure Windows Defender Firewall ===" -ForegroundColor Cyan
Write-Host ""

try {
    # Step 1: Windows Defender Firewall Overview
    Write-Host "[Step 1] Windows Defender Firewall Overview" -ForegroundColor Yellow

    Write-Host "Firewall profiles:" -ForegroundColor Cyan
    Write-Host "  - Domain: Applied when connected to domain network" -ForegroundColor White
    Write-Host "  - Private: Applied to private/home networks" -ForegroundColor White
    Write-Host "  - Public: Applied to public networks (most restrictive)" -ForegroundColor White
    Write-Host ""

    # Step 2: Get current firewall profiles status
    Write-Host "[Step 2] Checking firewall profile status" -ForegroundColor Yellow

    Write-Host "Querying firewall profile configuration..." -ForegroundColor Cyan
    $profiles = Get-NetFirewallProfile

    foreach ($profile in $profiles) {
        Write-Host ""
        Write-Host "$($profile.Name) Profile:" -ForegroundColor White
        Write-Host "  Enabled: $($profile.Enabled)" -ForegroundColor $(if ($profile.Enabled) {"Green"} else {"Red"})
        Write-Host "  Default Inbound Action: $($profile.DefaultInboundAction)" -ForegroundColor White
        Write-Host "  Default Outbound Action: $($profile.DefaultOutboundAction)" -ForegroundColor White
        Write-Host "  Allow Inbound Rules: $($profile.AllowInboundRules)" -ForegroundColor White
        Write-Host "  Log File Path: $($profile.LogFileName)" -ForegroundColor Gray
    }
    Write-Host ""

    # Step 3: Configure firewall profiles
    Write-Host "[Step 3] Configuring firewall profiles" -ForegroundColor Yellow

    Write-Host "Enabling and configuring all firewall profiles..." -ForegroundColor Cyan

    # Enable all profiles
    Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True
    Write-Host "All firewall profiles enabled" -ForegroundColor Green

    # Set default actions
    Set-NetFirewallProfile -Profile Domain,Private -DefaultInboundAction Block -DefaultOutboundAction Allow
    Write-Host "Domain/Private: Inbound=Block, Outbound=Allow" -ForegroundColor Green

    Set-NetFirewallProfile -Profile Public -DefaultInboundAction Block -DefaultOutboundAction Allow
    Write-Host "Public: Inbound=Block, Outbound=Allow (most restrictive)" -ForegroundColor Green
    Write-Host ""

    # Step 4: View existing firewall rules
    Write-Host "[Step 4] Reviewing existing firewall rules" -ForegroundColor Yellow

    Write-Host "Getting enabled inbound rules..." -ForegroundColor Cyan
    $inboundRules = Get-NetFirewallRule -Direction Inbound -Enabled True | Select-Object -First 10
    Write-Host "Sample of enabled inbound rules (first 10):" -ForegroundColor White
    $inboundRules | Select-Object DisplayName, Direction, Action, Profile | Format-Table -AutoSize

    Write-Host "Total firewall rules:" -ForegroundColor Cyan
    $totalRules = (Get-NetFirewallRule).Count
    $enabledRules = (Get-NetFirewallRule -Enabled True).Count
    Write-Host "  Total: $totalRules rules" -ForegroundColor White
    Write-Host "  Enabled: $enabledRules rules" -ForegroundColor White
    Write-Host ""

    # Step 5: Create custom firewall rules
    Write-Host "[Step 5] Creating custom firewall rules" -ForegroundColor Yellow

    Write-Host "Example 1: Allow HTTP inbound traffic" -ForegroundColor Cyan
    try {
        Remove-NetFirewallRule -DisplayName "Allow HTTP Inbound" -ErrorAction SilentlyContinue
        New-NetFirewallRule `
            -DisplayName "Allow HTTP Inbound" `
            -Direction Inbound `
            -Protocol TCP `
            -LocalPort 80 `
            -Action Allow `
            -Profile Domain,Private `
            -Description "Allow HTTP traffic for web server"
        Write-Host "  Created: Allow HTTP Inbound (Port 80)" -ForegroundColor Green
    } catch {
        Write-Host "  Rule may already exist" -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host "Example 2: Allow HTTPS inbound traffic" -ForegroundColor Cyan
    try {
        Remove-NetFirewallRule -DisplayName "Allow HTTPS Inbound" -ErrorAction SilentlyContinue
        New-NetFirewallRule `
            -DisplayName "Allow HTTPS Inbound" `
            -Direction Inbound `
            -Protocol TCP `
            -LocalPort 443 `
            -Action Allow `
            -Profile Domain,Private `
            -Description "Allow HTTPS traffic for web server"
        Write-Host "  Created: Allow HTTPS Inbound (Port 443)" -ForegroundColor Green
    } catch {
        Write-Host "  Rule may already exist" -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host "Example 3: Allow specific IP range" -ForegroundColor Cyan
    try {
        Remove-NetFirewallRule -DisplayName "Allow Management Subnet" -ErrorAction SilentlyContinue
        New-NetFirewallRule `
            -DisplayName "Allow Management Subnet" `
            -Direction Inbound `
            -Protocol TCP `
            -LocalPort 3389 `
            -RemoteAddress "192.168.1.0/24" `
            -Action Allow `
            -Profile Domain `
            -Description "Allow RDP from management subnet only"
        Write-Host "  Created: Allow Management Subnet (RDP from 192.168.1.0/24)" -ForegroundColor Green
    } catch {
        Write-Host "  Rule may already exist" -ForegroundColor Yellow
    }
    Write-Host ""

    # Step 6: Manage firewall rules
    Write-Host "[Step 6] Managing firewall rules" -ForegroundColor Yellow

    Write-Host "Disable a firewall rule:" -ForegroundColor Cyan
    Write-Host '  Disable-NetFirewallRule -DisplayName "Allow HTTP Inbound"' -ForegroundColor Gray

    Write-Host ""
    Write-Host "Enable a firewall rule:" -ForegroundColor Cyan
    Write-Host '  Enable-NetFirewallRule -DisplayName "Allow HTTP Inbound"' -ForegroundColor Gray

    Write-Host ""
    Write-Host "Remove a firewall rule:" -ForegroundColor Cyan
    Write-Host '  Remove-NetFirewallRule -DisplayName "Allow HTTP Inbound"' -ForegroundColor Gray

    Write-Host ""
    Write-Host "Modify existing rule:" -ForegroundColor Cyan
    Write-Host @'
  Set-NetFirewallRule `
      -DisplayName "Allow HTTP Inbound" `
      -RemoteAddress "10.0.0.0/8" `
      -Description "Updated: Allow HTTP from internal network only"
'@ -ForegroundColor Gray
    Write-Host ""

    # Step 7: Configure firewall logging
    Write-Host "[Step 7] Configuring firewall logging" -ForegroundColor Yellow

    Write-Host "Enable firewall logging..." -ForegroundColor Cyan

    # Configure logging for all profiles
    Set-NetFirewallProfile -All `
        -LogFileName "%SystemRoot%\System32\LogFiles\Firewall\pfirewall.log" `
        -LogMaxSizeKilobytes 16384 `
        -LogBlocked True `
        -LogAllowed False

    Write-Host "Logging configured:" -ForegroundColor Green
    Write-Host "  Log File: %SystemRoot%\System32\LogFiles\Firewall\pfirewall.log" -ForegroundColor White
    Write-Host "  Max Size: 16 MB" -ForegroundColor White
    Write-Host "  Log Blocked: Yes" -ForegroundColor White
    Write-Host "  Log Allowed: No" -ForegroundColor White
    Write-Host ""

    # Step 8: View firewall rules by criteria
    Write-Host "[Step 8] Querying firewall rules" -ForegroundColor Yellow

    Write-Host "Find rules by port:" -ForegroundColor Cyan
    $rdpRules = Get-NetFirewallRule | Where-Object {
        $_ | Get-NetFirewallPortFilter | Where-Object { $_.LocalPort -eq 3389 }
    } | Select-Object -First 3

    Write-Host "RDP rules (port 3389):" -ForegroundColor White
    $rdpRules | Select-Object DisplayName, Direction, Action, Enabled | Format-Table -AutoSize

    Write-Host "Find rules by display name pattern:" -ForegroundColor Cyan
    Write-Host '  Get-NetFirewallRule -DisplayName "*Remote Desktop*"' -ForegroundColor Gray
    Write-Host ""

    # Step 9: Export and import firewall rules
    Write-Host "[Step 9] Export and import firewall rules" -ForegroundColor Yellow

    Write-Host "Export firewall configuration:" -ForegroundColor Cyan
    $exportPath = "$env:TEMP\firewall-export.wfw"
    try {
        netsh advfirewall export $exportPath | Out-Null
        if (Test-Path $exportPath) {
            Write-Host "  Exported to: $exportPath" -ForegroundColor Green
        }
    } catch {
        Write-Host "  Export failed: $_" -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host "Import firewall configuration:" -ForegroundColor Cyan
    Write-Host "  netsh advfirewall import `"C:\path\to\firewall-export.wfw`"" -ForegroundColor Gray
    Write-Host ""

    # Step 10: Best practices
    Write-Host "[Step 10] Firewall best practices" -ForegroundColor Yellow

    Write-Host "Best practices:" -ForegroundColor Cyan
    Write-Host "  1. Keep firewall enabled on all profiles" -ForegroundColor White
    Write-Host "  2. Use deny-by-default approach (block inbound, allow outbound)" -ForegroundColor White
    Write-Host "  3. Create specific rules instead of opening all ports" -ForegroundColor White
    Write-Host "  4. Use IP address restrictions when possible" -ForegroundColor White
    Write-Host "  5. Enable logging for blocked connections" -ForegroundColor White
    Write-Host "  6. Regularly review and remove unused rules" -ForegroundColor White
    Write-Host "  7. Use Group Policy for centralized firewall management" -ForegroundColor White
    Write-Host "  8. Document all custom firewall rules" -ForegroundColor White
    Write-Host "  9. Test firewall changes in non-production first" -ForegroundColor White
    Write-Host "  10. Monitor firewall logs for security incidents" -ForegroundColor White
    Write-Host ""

    Write-Host "Useful commands:" -ForegroundColor Cyan
    Write-Host '  Get-NetFirewallProfile | Format-Table Name, Enabled, DefaultInboundAction' -ForegroundColor Gray
    Write-Host '  Get-NetFirewallRule -Enabled True -Direction Inbound | Format-Table DisplayName, Action' -ForegroundColor Gray
    Write-Host '  Show-NetFirewallRule -DisplayName "Rule Name"' -ForegroundColor Gray
    Write-Host '  Test-NetConnection -ComputerName server01 -Port 80' -ForegroundColor Gray
    Write-Host ""

} catch {
    Write-Host "[ERROR] $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

Write-Host "Demo completed successfully!" -ForegroundColor Green
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Review and document all enabled firewall rules" -ForegroundColor White
Write-Host "  2. Ensure all profiles are enabled" -ForegroundColor White
Write-Host "  3. Enable firewall logging for security monitoring" -ForegroundColor White
Write-Host "  4. Remove unnecessary or overly permissive rules" -ForegroundColor White
Write-Host "  5. Use Group Policy for enterprise-wide firewall management" -ForegroundColor White
Write-Host "  6. Regularly review firewall logs for anomalies" -ForegroundColor White
Write-Host "  7. Test application connectivity after rule changes" -ForegroundColor White
