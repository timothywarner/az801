<#
.SYNOPSIS
    Task 3.1 - Configure Protected Users Security Group

.DESCRIPTION
    Demo script for AZ-801 Module 3: Manage Protected Users and RODCs
    This script demonstrates how to configure and use the Protected Users security
    group to enhance security for high-privilege accounts.

.NOTES
    Module: Module 3 - Manage Protected Users and RODCs
    Task: 3.1 - Configure Protected Users

    Prerequisites:
    - Windows Server 2012 R2 domain functional level or higher
    - Domain Administrator privileges
    - Active Directory PowerShell module

    Lab Environment:
    - Domain Controller with Windows Server 2022
    - Test user accounts

    PowerShell Version: 5.1+
#>

#Requires -RunAsAdministrator

$ErrorActionPreference = 'Stop'

Write-Host "=== AZ-801 Module 3: Task 3.1 - Protected Users Security Group ===" -ForegroundColor Cyan
Write-Host ""

try {
    # Section 1: Check domain functional level
    Write-Host "[Step 1] Checking domain functional level" -ForegroundColor Yellow

    if (Get-Module -ListAvailable -Name ActiveDirectory) {
        Import-Module ActiveDirectory -ErrorAction SilentlyContinue

        $domain = Get-ADDomain
        Write-Host "Domain: $($domain.DNSRoot)" -ForegroundColor White
        Write-Host "Domain Functional Level: $($domain.DomainMode)" -ForegroundColor White

        if ($domain.DomainMode -ge "Windows2012R2Domain") {
            Write-Host "[SUCCESS] Domain supports Protected Users group" -ForegroundColor Green
        } else {
            Write-Host "[WARNING] Raise domain functional level to Windows Server 2012 R2 or higher" -ForegroundColor Yellow
        }
    }
    Write-Host ""

    # Section 2: Locate Protected Users group
    Write-Host "[Step 2] Locating Protected Users security group" -ForegroundColor Yellow

    $protectedUsers = Get-ADGroup -Identity "Protected Users" -ErrorAction SilentlyContinue

    if ($protectedUsers) {
        Write-Host "Protected Users Group:" -ForegroundColor Cyan
        Write-Host "  Name: $($protectedUsers.Name)" -ForegroundColor White
        Write-Host "  Distinguished Name: $($protectedUsers.DistinguishedName)" -ForegroundColor White
        Write-Host "  SID: $($protectedUsers.SID)" -ForegroundColor White

        # Get members
        $members = Get-ADGroupMember -Identity "Protected Users" -ErrorAction SilentlyContinue

        Write-Host "  Current Members: $($members.Count)" -ForegroundColor White
        if ($members) {
            $members | Select-Object -First 5 | ForEach-Object {
                Write-Host "    - $($_.Name)" -ForegroundColor White
            }
        }

        Write-Host "[SUCCESS] Protected Users group found" -ForegroundColor Green
    }
    Write-Host ""

    # Section 3: Protected Users protections
    Write-Host "[Step 3] Protected Users security protections" -ForegroundColor Yellow

    Write-Host "`nProtections applied to members:" -ForegroundColor Cyan
    Write-Host "  Authentication:" -ForegroundColor White
    Write-Host "    - Cannot use NTLM authentication" -ForegroundColor White
    Write-Host "    - Cannot use DES or RC4 encryption in Kerberos" -ForegroundColor White
    Write-Host "    - Cannot use Kerberos delegation (constrained/unconstrained)" -ForegroundColor White
    Write-Host "    - Kerberos TGTs limited to 4-hour lifetime (not renewable beyond)" -ForegroundColor White
    Write-Host ""
    Write-Host "  Credential Caching:" -ForegroundColor White
    Write-Host "    - Credentials not cached locally" -ForegroundColor White
    Write-Host "    - Cannot sign in if DC not available" -ForegroundColor White
    Write-Host "    - CredSSP and WDigest disabled" -ForegroundColor White
    Write-Host ""

    # Section 4: Add users to Protected Users
    Write-Host "[Step 4] Adding users to Protected Users group" -ForegroundColor Yellow

    Write-Host "`nTo add a user to Protected Users:" -ForegroundColor Cyan
    Write-Host "  Add-ADGroupMember -Identity 'Protected Users' -Members 'username'" -ForegroundColor White
    Write-Host ""
    Write-Host "Example - Add administrator accounts:" -ForegroundColor Cyan
    Write-Host "  Add-ADGroupMember -Identity 'Protected Users' -Members 'DomainAdmin1','DomainAdmin2'" -ForegroundColor White
    Write-Host ""

    Write-Host "Best practices for membership:" -ForegroundColor Cyan
    Write-Host "  - Add privileged administrator accounts" -ForegroundColor White
    Write-Host "  - Add service accounts with elevated privileges" -ForegroundColor White
    Write-Host "  - Test compatibility before adding production accounts" -ForegroundColor White
    Write-Host "  - Do NOT add: Built-in Administrator, KRBTGT" -ForegroundColor White
    Write-Host ""

    # Section 5: Monitoring and troubleshooting
    Write-Host "[Step 5] Monitoring Protected Users" -ForegroundColor Yellow

    Write-Host "`nMonitoring event logs:" -ForegroundColor Cyan
    Write-Host "  Security Event Log:" -ForegroundColor White
    Write-Host "    - Event ID 4728: Member added to security-enabled global group" -ForegroundColor White
    Write-Host "    - Event ID 4729: Member removed from security-enabled global group" -ForegroundColor White
    Write-Host ""
    Write-Host "  Authentication failures:" -ForegroundColor White
    Write-Host "    - Event ID 4625: Logon failure" -ForegroundColor White
    Write-Host "    - Check for NTLM or weak encryption attempts" -ForegroundColor White
    Write-Host ""

    # Educational notes
    Write-Host "[INFO] Protected Users Best Practices:" -ForegroundColor Cyan
    Write-Host "  - Test accounts in pilot before production deployment" -ForegroundColor White
    Write-Host "  - Ensure applications don't require NTLM or delegation" -ForegroundColor White
    Write-Host "  - Monitor for authentication failures after adding members" -ForegroundColor White
    Write-Host "  - Document all accounts added to the group" -ForegroundColor White
    Write-Host "  - Regular review of group membership" -ForegroundColor White
    Write-Host ""

} catch {
    Write-Host "[ERROR] $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

Write-Host "Demo completed successfully!" -ForegroundColor Green
Write-Host "Next Steps: Test accounts in Protected Users and monitor authentication" -ForegroundColor Yellow
