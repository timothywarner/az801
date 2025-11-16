<#
.SYNOPSIS
    Task 4.1 - Configure Authentication Policy Silos
.DESCRIPTION
    Comprehensive demonstration of Active Directory Authentication Policy Silos.
    Authentication Policy Silos provide a way to protect high-value accounts by restricting
    where and how they can authenticate, preventing credential theft attacks.
.EXAMPLE
    .\task-4.1-authentication-policy-silos.ps1
.NOTES
    Module: Module 4 - Configure Advanced Domain Security
    Task: 4.1 - Configure Authentication Policy Silos
    Prerequisites:
    - Windows Server 2012 R2+ Domain Controller
    - Domain Functional Level 2012 R2 or higher
    - ActiveDirectory PowerShell module
    - Domain Admin or equivalent permissions
    PowerShell Version: 5.1+
#>

#Requires -RunAsAdministrator
#Requires -Modules ActiveDirectory

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

Write-Host "=== AZ-801 Module 4: Task 4.1 - Configure Authentication Policy Silos ===" -ForegroundColor Cyan
Write-Host ""

try {
    # Step 1: Verify domain functional level
    Write-Host "[Step 1] Verifying domain functional level and prerequisites" -ForegroundColor Yellow

    $domain = Get-ADDomain
    $domainLevel = $domain.DomainMode

    Write-Host "Domain Name: $($domain.DNSRoot)" -ForegroundColor White
    Write-Host "Domain Functional Level: $domainLevel" -ForegroundColor White

    if ($domainLevel -notmatch '2012R2|2016|Windows2016') {
        Write-Warning "Authentication Policy Silos require Domain Functional Level 2012 R2 or higher"
        Write-Host "Current level: $domainLevel - This demo will show the commands but may not execute" -ForegroundColor Yellow
    } else {
        Write-Host "[SUCCESS] Domain meets requirements for Authentication Policy Silos" -ForegroundColor Green
    }
    Write-Host ""

    # Step 2: Check existing authentication policies
    Write-Host "[Step 2] Checking existing authentication policies" -ForegroundColor Yellow

    $existingPolicies = Get-ADAuthenticationPolicy -Filter *
    if ($existingPolicies) {
        Write-Host "Found $($existingPolicies.Count) existing authentication policies:" -ForegroundColor White
        foreach ($policy in $existingPolicies) {
            Write-Host "  - $($policy.Name)" -ForegroundColor Cyan
        }
    } else {
        Write-Host "No existing authentication policies found" -ForegroundColor White
    }

    $existingSilos = Get-ADAuthenticationPolicySilo -Filter *
    if ($existingSilos) {
        Write-Host "Found $($existingSilos.Count) existing authentication policy silos:" -ForegroundColor White
        foreach ($silo in $existingSilos) {
            Write-Host "  - $($silo.Name)" -ForegroundColor Cyan
        }
    } else {
        Write-Host "No existing authentication policy silos found" -ForegroundColor White
    }
    Write-Host ""

    # Step 3: Create authentication policies for different account types
    Write-Host "[Step 3] Creating authentication policies" -ForegroundColor Yellow

    # Policy for domain administrators - very restrictive
    $adminPolicyParams = @{
        Name = "AdminUserPolicy"
        Enforce = $false  # Start in audit mode
        UserAllowedToAuthenticateFrom = 'O:SYG:SYD:(XA;OICI;CR;;;WD;(@USER.ad://ext/AuthenticationSilo == "AdminSilo"))'
        UserTGTLifetimeMins = 240  # 4 hours
    }

    Write-Host "Creating authentication policy for admin users..." -ForegroundColor Cyan
    Write-Host "  Policy Name: AdminUserPolicy" -ForegroundColor White
    Write-Host "  TGT Lifetime: 240 minutes (4 hours)" -ForegroundColor White
    Write-Host "  Enforce Mode: Audit (not enforced initially)" -ForegroundColor White

    try {
        $adminPolicy = Get-ADAuthenticationPolicy -Identity "AdminUserPolicy" -ErrorAction SilentlyContinue
        if ($adminPolicy) {
            Write-Host "  Policy already exists - updating..." -ForegroundColor Yellow
            Set-ADAuthenticationPolicy -Identity "AdminUserPolicy" -UserTGTLifetimeMins 240 -Enforce $false
        } else {
            New-ADAuthenticationPolicy @adminPolicyParams
            Write-Host "[SUCCESS] Admin authentication policy created" -ForegroundColor Green
        }
    } catch {
        Write-Host "[INFO] Could not create policy (may require 2012 R2+ domain): $($_.Exception.Message)" -ForegroundColor Yellow
    }

    # Policy for servers - restrict which accounts can authenticate
    $serverPolicyParams = @{
        Name = "ServerPolicy"
        Enforce = $false
        ComputerAllowedToAuthenticateTo = 'O:SYG:SYD:(XA;OICI;CR;;;WD;(@USER.ad://ext/AuthenticationSilo == "AdminSilo"))'
        ComputerTGTLifetimeMins = 480  # 8 hours
    }

    Write-Host ""
    Write-Host "Creating authentication policy for servers..." -ForegroundColor Cyan
    Write-Host "  Policy Name: ServerPolicy" -ForegroundColor White
    Write-Host "  TGT Lifetime: 480 minutes (8 hours)" -ForegroundColor White

    try {
        $serverPolicy = Get-ADAuthenticationPolicy -Identity "ServerPolicy" -ErrorAction SilentlyContinue
        if ($serverPolicy) {
            Write-Host "  Policy already exists - updating..." -ForegroundColor Yellow
            Set-ADAuthenticationPolicy -Identity "ServerPolicy" -ComputerTGTLifetimeMins 480 -Enforce $false
        } else {
            New-ADAuthenticationPolicy @serverPolicyParams
            Write-Host "[SUCCESS] Server authentication policy created" -ForegroundColor Green
        }
    } catch {
        Write-Host "[INFO] Could not create policy: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    Write-Host ""

    # Step 4: Create authentication policy silo
    Write-Host "[Step 4] Creating authentication policy silo" -ForegroundColor Yellow

    $siloParams = @{
        Name = "AdminSilo"
        UserAuthenticationPolicy = "AdminUserPolicy"
        ComputerAuthenticationPolicy = "ServerPolicy"
        Enforce = $false  # Start in audit mode
        Description = "Silo for protecting administrative accounts and their workstations"
    }

    Write-Host "Creating authentication policy silo..." -ForegroundColor Cyan
    Write-Host "  Silo Name: AdminSilo" -ForegroundColor White
    Write-Host "  User Policy: AdminUserPolicy" -ForegroundColor White
    Write-Host "  Computer Policy: ServerPolicy" -ForegroundColor White
    Write-Host "  Description: Silo for protecting administrative accounts" -ForegroundColor White

    try {
        $silo = Get-ADAuthenticationPolicySilo -Identity "AdminSilo" -ErrorAction SilentlyContinue
        if ($silo) {
            Write-Host "  Silo already exists - configuration preserved" -ForegroundColor Yellow
        } else {
            New-ADAuthenticationPolicySilo @siloParams
            Write-Host "[SUCCESS] Authentication policy silo created" -ForegroundColor Green
        }
    } catch {
        Write-Host "[INFO] Could not create silo: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    Write-Host ""

    # Step 5: Add members to the silo (example)
    Write-Host "[Step 5] Managing silo membership" -ForegroundColor Yellow

    Write-Host "To add users or computers to the silo, use:" -ForegroundColor Cyan
    Write-Host '  Grant-ADAuthenticationPolicySiloAccess -Identity "AdminSilo" -Account "DOMAIN\AdminUser"' -ForegroundColor White
    Write-Host ""
    Write-Host "Example: Adding sample members (demo only)..." -ForegroundColor Cyan

    # Check if example admin user exists
    $demoUser = "Administrator"
    try {
        $user = Get-ADUser -Identity $demoUser -ErrorAction SilentlyContinue
        if ($user) {
            Write-Host "  Would add $demoUser to AdminSilo (audit mode)" -ForegroundColor White
            # Grant-ADAuthenticationPolicySiloAccess -Identity "AdminSilo" -Account $user
            Write-Host "  Use: Grant-ADAuthenticationPolicySiloAccess -Identity 'AdminSilo' -Account '$demoUser'" -ForegroundColor Cyan
        }
    } catch {
        Write-Host "  Demo user not found - skip membership example" -ForegroundColor Gray
    }
    Write-Host ""

    # Step 6: Monitoring and auditing
    Write-Host "[Step 6] Monitoring authentication policy events" -ForegroundColor Yellow

    Write-Host "Checking for recent authentication policy events..." -ForegroundColor Cyan

    # Check event logs for authentication policy events
    $eventParams = @{
        LogName = 'Security'
        FilterHashtable = @{
            LogName = 'Security'
            ID = @(4768, 4769, 4771)  # Kerberos authentication events
        }
        MaxEvents = 5
        ErrorAction = 'SilentlyContinue'
    }

    $authEvents = Get-WinEvent -FilterHashtable $eventParams -ErrorAction SilentlyContinue
    if ($authEvents) {
        Write-Host "Recent Kerberos authentication events (sample):" -ForegroundColor White
        $authEvents | Select-Object -First 3 | ForEach-Object {
            Write-Host "  [$($_.TimeCreated)] Event $($_.Id) - $($_.Message.Split("`n")[0])" -ForegroundColor Gray
        }
    } else {
        Write-Host "No recent authentication events found in Security log" -ForegroundColor White
    }
    Write-Host ""

    # Step 7: Verification and reporting
    Write-Host "[Step 7] Verifying configuration" -ForegroundColor Yellow

    $policies = Get-ADAuthenticationPolicy -Filter * | Select-Object Name, Enforce, UserTGTLifetimeMins, ComputerTGTLifetimeMins
    if ($policies) {
        Write-Host "Configured Authentication Policies:" -ForegroundColor Cyan
        $policies | Format-Table -AutoSize | Out-String | ForEach-Object { Write-Host $_ -ForegroundColor White }
    }

    $silos = Get-ADAuthenticationPolicySilo -Filter * | Select-Object Name, Enforce, UserAuthenticationPolicy, ComputerAuthenticationPolicy
    if ($silos) {
        Write-Host "Configured Authentication Policy Silos:" -ForegroundColor Cyan
        $silos | Format-Table -AutoSize | Out-String | ForEach-Object { Write-Host $_ -ForegroundColor White }
    }
    Write-Host ""

    # Step 8: Best practices and guidance
    Write-Host "[Step 8] Best Practices for Authentication Policy Silos" -ForegroundColor Yellow
    Write-Host "  1. Always start in audit mode (Enforce = `$false) to test impact" -ForegroundColor White
    Write-Host "  2. Monitor Event IDs 4768, 4769, 4771 in Security log for authentication failures" -ForegroundColor White
    Write-Host "  3. Use shorter TGT lifetimes for privileged accounts (4-8 hours)" -ForegroundColor White
    Write-Host "  4. Create separate silos for different admin tiers (Tier 0, Tier 1, Tier 2)" -ForegroundColor White
    Write-Host "  5. Document all silo memberships and policy assignments" -ForegroundColor White
    Write-Host "  6. Test thoroughly before enabling enforcement mode" -ForegroundColor White
    Write-Host "  7. Use claims-based access control for fine-grained restrictions" -ForegroundColor White
    Write-Host "  8. Regularly review silo membership and remove stale accounts" -ForegroundColor White
    Write-Host ""

    Write-Host "[INFO] Additional Commands:" -ForegroundColor Cyan
    Write-Host "  View silo members: Get-ADAuthenticationPolicySilo -Identity 'AdminSilo' -ShowMemberOf" -ForegroundColor White
    Write-Host "  Enable enforcement: Set-ADAuthenticationPolicySilo -Identity 'AdminSilo' -Enforce `$true" -ForegroundColor White
    Write-Host "  Remove member: Revoke-ADAuthenticationPolicySiloAccess -Identity 'AdminSilo' -Account 'User'" -ForegroundColor White
    Write-Host ""

} catch {
    Write-Host "[ERROR] $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

Write-Host "Demo completed successfully!" -ForegroundColor Green
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Review audit logs for 30 days before enabling enforcement" -ForegroundColor White
Write-Host "  2. Add administrative users and their workstations to the silo" -ForegroundColor White
Write-Host "  3. Test authentication patterns in audit mode" -ForegroundColor White
Write-Host "  4. Enable enforcement when confident no legitimate access is blocked" -ForegroundColor White
