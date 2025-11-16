<#
.SYNOPSIS
    Task 6.3 - Configure Connection Security Rules
.DESCRIPTION
    Comprehensive demonstration of IPsec connection security rules configuration.
    Covers server-to-server isolation, authenticated bypass, and encryption requirements.
.EXAMPLE
    .\task-6.3-connection-security-rules.ps1
.NOTES
    Module: Module 6 - Secure Windows Server Networking
    Task: 6.3 - Configure Connection Security Rules
    Prerequisites:
    - Windows Server with administrative privileges
    - NetSecurity PowerShell module
    PowerShell Version: 5.1+
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

Write-Host "=== AZ-801 Module 6: Task 6.3 - Configure Connection Security Rules ===" -ForegroundColor Cyan
Write-Host ""

try {
    # Step 1: Connection Security Rules Overview
    Write-Host "[Step 1] Connection Security Rules Overview" -ForegroundColor Yellow

    Write-Host "Connection security rule types:" -ForegroundColor Cyan
    Write-Host "  - Isolation: Restrict connections based on authentication" -ForegroundColor White
    Write-Host "  - Authentication Exemption: Allow specific computers without auth" -ForegroundColor White
    Write-Host "  - Server-to-Server: Protect traffic between specific servers" -ForegroundColor White
    Write-Host "  - Tunnel: Create IPsec tunnel between gateways" -ForegroundColor White
    Write-Host "  - Custom: Flexible rules for specific scenarios" -ForegroundColor White
    Write-Host ""

    # Step 2: Create authentication methods
    Write-Host "[Step 2] Creating authentication methods" -ForegroundColor Yellow

    Write-Host "Setting up Kerberos authentication..." -ForegroundColor Cyan
    $kerberosAuth = New-NetIPsecAuthProposal -Machine -Kerberos
    $authSet1 = New-NetIPsecPhase1AuthSet -DisplayName "Kerberos Auth" -Proposal $kerberosAuth
    Write-Host "Created: Kerberos authentication set" -ForegroundColor Green

    Write-Host ""
    Write-Host "Setting up Certificate authentication..." -ForegroundColor Cyan
    $certAuth = New-NetIPsecAuthProposal -Machine -Cert -Authority "DC=contoso,DC=com" -AuthorityType Root
    $authSet2 = New-NetIPsecPhase1AuthSet -DisplayName "Certificate Auth" -Proposal $certAuth
    Write-Host "Created: Certificate authentication set" -ForegroundColor Green
    Write-Host ""

    # Step 3: Create crypto proposals
    Write-Host "[Step 3] Creating IPsec crypto proposals" -ForegroundColor Yellow

    $qmProposal = New-NetIPsecQuickModeCryptoProposal -Encapsulation ESP -ESPHash SHA256 -Encryption AES256
    $qmCrypto = New-NetIPsecQuickModeCryptoSet -DisplayName "AES256-SHA256" -Proposal $qmProposal
    Write-Host "Created QuickMode crypto set: AES256-SHA256" -ForegroundColor Green
    Write-Host ""

    # Step 4: Server-to-Server rule
    Write-Host "[Step 4] Creating server-to-server connection security rule" -ForegroundColor Yellow

    Write-Host "Creating rule for database server protection..." -ForegroundColor Cyan
    try {
        Remove-NetIPsecRule -DisplayName "Protect Database Server" -ErrorAction SilentlyContinue
    } catch {}

    New-NetIPsecRule `
        -DisplayName "Protect Database Server" `
        -Description "Require encryption for database traffic" `
        -InboundSecurity Require `
        -OutboundSecurity Require `
        -Protocol TCP `
        -LocalPort 1433 `
        -Phase1AuthSet $authSet1.Name `
        -QuickModeCryptoSet $qmCrypto.Name `
        -Profile Domain

    Write-Host "Created server-to-server rule for SQL Server (port 1433)" -ForegroundColor Green
    Write-Host ""

    # Step 5: Authentication exemption rule
    Write-Host "[Step 5] Creating authentication exemption rule" -ForegroundColor Yellow

    Write-Host "Creating exemption for infrastructure servers..." -ForegroundColor Cyan
    try {
        Remove-NetIPsecRule -DisplayName "Exempt DHCP Server" -ErrorAction SilentlyContinue
    } catch {}

    New-NetIPsecRule `
        -DisplayName "Exempt DHCP Server" `
        -Description "Allow DHCP without IPsec" `
        -InboundSecurity None `
        -OutboundSecurity None `
        -Protocol UDP `
        -LocalPort 67,68 `
        -Profile Domain

    Write-Host "Created exemption rule for DHCP traffic" -ForegroundColor Green
    Write-Host ""

    # Step 6: Custom rule for specific IPs
    Write-Host "[Step 6] Creating custom IP-specific rule" -ForegroundColor Yellow

    Write-Host "Creating rule for management subnet..." -ForegroundColor Cyan
    try {
        Remove-NetIPsecRule -DisplayName "Secure Management Traffic" -ErrorAction SilentlyContinue
    } catch {}

    New-NetIPsecRule `
        -DisplayName "Secure Management Traffic" `
        -Description "Require auth for management subnet" `
        -InboundSecurity Require `
        -OutboundSecurity Request `
        -RemoteAddress "10.0.1.0/24" `
        -Phase1AuthSet $authSet1.Name `
        -QuickModeCryptoSet $qmCrypto.Name `
        -Profile Domain

    Write-Host "Created rule for management subnet (10.0.1.0/24)" -ForegroundColor Green
    Write-Host ""

    # Step 7: View and manage rules
    Write-Host "[Step 7] Viewing connection security rules" -ForegroundColor Yellow

    $rules = Get-NetIPsecRule | Select-Object DisplayName, Enabled, InboundSecurity, OutboundSecurity, Profile
    Write-Host "Current IPsec rules:" -ForegroundColor Cyan
    $rules | Format-Table -AutoSize
    Write-Host ""

    # Step 8: Test IPsec connections
    Write-Host "[Step 8] Testing IPsec connections" -ForegroundColor Yellow

    Write-Host "Verification commands:" -ForegroundColor Cyan
    Write-Host '  Test-NetConnection -ComputerName dbserver -Port 1433 -InformationLevel Detailed' -ForegroundColor Gray
    Write-Host '  Get-NetIPsecQuickModeSA | Where-Object {$_.RemotePort -eq 1433}' -ForegroundColor Gray
    Write-Host '  netsh advfirewall monitor show mmsa' -ForegroundColor Gray
    Write-Host ""

    # Step 9: Monitor IPsec performance
    Write-Host "[Step 9] Monitoring IPsec performance" -ForegroundColor Yellow

    Write-Host "Performance counters to monitor:" -ForegroundColor Cyan
    Write-Host "  IPsec Driver: Active Security Associations" -ForegroundColor White
    Write-Host "  IPsec Driver: Packets Not Authenticated" -ForegroundColor White
    Write-Host "  IPsec Driver: Packets Not Decrypted" -ForegroundColor White
    Write-Host ""

    Write-Host "Get performance data:" -ForegroundColor Cyan
    Write-Host '  Get-Counter "\IPsec Driver\Active Security Associations"' -ForegroundColor Gray
    Write-Host ""

    # Step 10: Best practices
    Write-Host "[Step 10] Best practices" -ForegroundColor Yellow

    Write-Host "Best practices:" -ForegroundColor Cyan
    Write-Host "  1. Start with Request mode for testing, then Require for production" -ForegroundColor White
    Write-Host "  2. Create exemptions for infrastructure services (DHCP, DNS)" -ForegroundColor White
    Write-Host "  3. Use server-to-server rules for sensitive applications" -ForegroundColor White
    Write-Host "  4. Document all connection security rules" -ForegroundColor White
    Write-Host "  5. Test rules thoroughly before production deployment" -ForegroundColor White
    Write-Host "  6. Monitor IPsec SAs to verify connectivity" -ForegroundColor White
    Write-Host "  7. Use certificates for high-security scenarios" -ForegroundColor White
    Write-Host "  8. Deploy via Group Policy for consistency" -ForegroundColor White
    Write-Host "  9. Review and update rules regularly" -ForegroundColor White
    Write-Host "  10. Enable logging for troubleshooting" -ForegroundColor White
    Write-Host ""

    Write-Host "Useful commands:" -ForegroundColor Cyan
    Write-Host '  Get-NetIPsecRule | Format-List *' -ForegroundColor Gray
    Write-Host '  Set-NetIPsecRule -DisplayName "RuleName" -Enabled $false' -ForegroundColor Gray
    Write-Host '  Get-NetIPsecQuickModeSA | Format-Table' -ForegroundColor Gray
    Write-Host ""

} catch {
    Write-Host "[ERROR] $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

Write-Host "Demo completed successfully!" -ForegroundColor Green
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Define security requirements for each application" -ForegroundColor White
Write-Host "  2. Create specific rules for sensitive servers" -ForegroundColor White
Write-Host "  3. Test connection security rules in isolated environment" -ForegroundColor White
Write-Host "  4. Monitor IPsec Security Associations" -ForegroundColor White
Write-Host "  5. Deploy to production via Group Policy" -ForegroundColor White
