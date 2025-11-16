<#
.SYNOPSIS
    Task 6.2 - Implement Domain Isolation with IPsec
.DESCRIPTION
    Comprehensive demonstration of domain isolation using IPsec connection security rules.
    Covers IPsec rule creation, authentication methods, and encrypted communications.
.EXAMPLE
    .\task-6.2-domain-isolation.ps1
.NOTES
    Module: Module 6 - Secure Windows Server Networking
    Task: 6.2 - Implement Domain Isolation
    Prerequisites:
    - Windows Server in Active Directory domain
    - Administrative privileges
    - NetSecurity PowerShell module
    PowerShell Version: 5.1+
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

Write-Host "=== AZ-801 Module 6: Task 6.2 - Implement Domain Isolation ===" -ForegroundColor Cyan
Write-Host ""

try {
    # Step 1: Domain Isolation Overview
    Write-Host "[Step 1] Domain Isolation Overview" -ForegroundColor Yellow

    Write-Host "Domain isolation benefits:" -ForegroundColor Cyan
    Write-Host "  - Ensures only domain-joined computers communicate" -ForegroundColor White
    Write-Host "  - Authenticates computer identities using Kerberos" -ForegroundColor White
    Write-Host "  - Encrypts network traffic between domain members" -ForegroundColor White
    Write-Host "  - Protects against rogue devices on network" -ForegroundColor White
    Write-Host "  - Complements network segmentation" -ForegroundColor White
    Write-Host ""

    # Step 2: Check current IPsec rules
    Write-Host "[Step 2] Checking existing IPsec rules" -ForegroundColor Yellow

    $existingRules = Get-NetIPsecRule
    Write-Host "Existing IPsec rules: $($existingRules.Count)" -ForegroundColor White
    if ($existingRules.Count -gt 0) {
        $existingRules | Select-Object -First 5 | Select-Object DisplayName, Enabled, Mode | Format-Table
    }
    Write-Host ""

    # Step 3: Create IPsec authentication sets
    Write-Host "[Step 3] Creating IPsec authentication sets" -ForegroundColor Yellow

    Write-Host "Creating Kerberos authentication set..." -ForegroundColor Cyan
    $kerberosAuth = New-NetIPsecAuthProposal -Machine -Kerberos
    $authSet = New-NetIPsecPhase1AuthSet -DisplayName "Domain Computer Auth" -Proposal $kerberosAuth
    Write-Host "Authentication set created: $($authSet.DisplayName)" -ForegroundColor Green
    Write-Host ""

    # Step 4: Create crypto proposals
    Write-Host "[Step 4] Creating IPsec crypto proposals" -ForegroundColor Yellow

    Write-Host "Creating Phase 1 (Main Mode) crypto set..." -ForegroundColor Cyan
    $mmCryptoProposal = New-NetIPsecMainModeCryptoProposal `
        -Encryption AES256 `
        -Hash SHA256 `
        -KeyExchange DH14

    $mmCryptoSet = New-NetIPsecMainModeCryptoSet `
        -DisplayName "Domain Isolation MM Crypto" `
        -Proposal $mmCryptoProposal
    Write-Host "Main Mode crypto set created" -ForegroundColor Green

    Write-Host ""
    Write-Host "Creating Phase 2 (Quick Mode) crypto set..." -ForegroundColor Cyan
    $qmCryptoProposal = New-NetIPsecQuickModeCryptoProposal `
        -Encapsulation ESP `
        -ESPHash SHA256 `
        -Encryption AES256

    $qmCryptoSet = New-NetIPsecQuickModeCryptoSet `
        -DisplayName "Domain Isolation QM Crypto" `
        -Proposal $qmCryptoProposal
    Write-Host "Quick Mode crypto set created" -ForegroundColor Green
    Write-Host ""

    # Step 5: Create domain isolation rule
    Write-Host "[Step 5] Creating domain isolation IPsec rule" -ForegroundColor Yellow

    Write-Host "Creating IPsec rule for domain isolation..." -ForegroundColor Cyan

    try {
        Remove-NetIPsecRule -DisplayName "Domain Isolation" -ErrorAction SilentlyContinue
    } catch {}

    $ipsecRule = New-NetIPsecRule `
        -DisplayName "Domain Isolation" `
        -Description "Require authentication for all domain computers" `
        -InboundSecurity Require `
        -OutboundSecurity Request `
        -Phase1AuthSet $authSet.Name `
        -QuickModeCryptoSet $qmCryptoSet.Name `
        -Profile Domain `
        -Enabled True

    Write-Host "IPsec rule created successfully" -ForegroundColor Green
    Write-Host "  Display Name: $($ipsecRule.DisplayName)" -ForegroundColor White
    Write-Host "  Inbound Security: Require" -ForegroundColor White
    Write-Host "  Outbound Security: Request" -ForegroundColor White
    Write-Host ""

    # Step 6: View IPsec rules
    Write-Host "[Step 6] Reviewing IPsec configuration" -ForegroundColor Yellow

    $rules = Get-NetIPsecRule | Select-Object DisplayName, Enabled, InboundSecurity, OutboundSecurity
    Write-Host "Current IPsec rules:" -ForegroundColor Cyan
    $rules | Format-Table -AutoSize
    Write-Host ""

    # Step 7: Monitor IPsec SAs
    Write-Host "[Step 7] Monitoring IPsec Security Associations" -ForegroundColor Yellow

    Write-Host "Main Mode SAs:" -ForegroundColor Cyan
    $mmSAs = Get-NetIPsecMainModeSA
    Write-Host "  Active Main Mode SAs: $($mmSAs.Count)" -ForegroundColor White

    Write-Host ""
    Write-Host "Quick Mode SAs:" -ForegroundColor Cyan
    $qmSAs = Get-NetIPsecQuickModeSA
    Write-Host "  Active Quick Mode SAs: $($qmSAs.Count)" -ForegroundColor White
    Write-Host ""

    # Step 8: Test connectivity
    Write-Host "[Step 8] Testing IPsec connectivity" -ForegroundColor Yellow

    Write-Host "Use these commands to test:" -ForegroundColor Cyan
    Write-Host '  Test-NetConnection -ComputerName server01 -InformationLevel Detailed' -ForegroundColor Gray
    Write-Host '  Get-NetIPsecQuickModeSA | Where-Object {$_.LocalEndpoint -eq "IP"}' -ForegroundColor Gray
    Write-Host ""

    # Step 9: Troubleshooting
    Write-Host "[Step 9] Troubleshooting IPsec" -ForegroundColor Yellow

    Write-Host "Common issues and solutions:" -ForegroundColor Cyan
    Write-Host "  Issue: Authentication failures" -ForegroundColor White
    Write-Host "    - Verify computer accounts in AD" -ForegroundColor Gray
    Write-Host "    - Check Kerberos tickets: klist" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Issue: No traffic encrypted" -ForegroundColor White
    Write-Host "    - Verify IPsec rules are enabled" -ForegroundColor Gray
    Write-Host "    - Check Quick Mode SAs" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Issue: Connection failures" -ForegroundColor White
    Write-Host "    - Start with Request/Request mode for testing" -ForegroundColor Gray
    Write-Host "    - Check firewall allows ESP (IP Protocol 50)" -ForegroundColor Gray
    Write-Host ""

    # Step 10: Best practices
    Write-Host "[Step 10] Best practices" -ForegroundColor Yellow

    Write-Host "Best practices:" -ForegroundColor Cyan
    Write-Host "  1. Start with Request/Request mode, then move to Require" -ForegroundColor White
    Write-Host "  2. Use strong encryption (AES256) and hashing (SHA256)" -ForegroundColor White
    Write-Host "  3. Apply rules to Domain profile only initially" -ForegroundColor White
    Write-Host "  4. Create exemption rules for infrastructure servers" -ForegroundColor White
    Write-Host "  5. Monitor IPsec SAs to verify operation" -ForegroundColor White
    Write-Host "  6. Use Group Policy for enterprise-wide deployment" -ForegroundColor White
    Write-Host "  7. Document all IPsec configurations" -ForegroundColor White
    Write-Host "  8. Test thoroughly before production deployment" -ForegroundColor White
    Write-Host "  9. Monitor Windows Firewall logs for connection issues" -ForegroundColor White
    Write-Host "  10. Plan for certificate-based auth for sensitive servers" -ForegroundColor White
    Write-Host ""

    Write-Host "Useful commands:" -ForegroundColor Cyan
    Write-Host '  Get-NetIPsecRule | Format-Table DisplayName, Enabled' -ForegroundColor Gray
    Write-Host '  Get-NetIPsecMainModeSA | Format-Table' -ForegroundColor Gray
    Write-Host '  Get-NetIPsecQuickModeSA | Format-Table' -ForegroundColor Gray
    Write-Host '  Remove-NetIPsecRule -DisplayName "RuleName"' -ForegroundColor Gray
    Write-Host ""

} catch {
    Write-Host "[ERROR] $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

Write-Host "Demo completed successfully!" -ForegroundColor Green
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Test IPsec rules in isolated environment" -ForegroundColor White
Write-Host "  2. Create exemption rules for non-domain devices" -ForegroundColor White
Write-Host "  3. Monitor IPsec Security Associations" -ForegroundColor White
Write-Host "  4. Deploy via Group Policy for production" -ForegroundColor White
Write-Host "  5. Document IPsec infrastructure" -ForegroundColor White
