<#
.SYNOPSIS
    Task 1.5 - Configure Security Settings via Group Policy

.DESCRIPTION
    Demo script for AZ-801 Module 1: Implement Core OS Security
    This script demonstrates how to configure and audit security settings using
    Group Policy, including password policies, audit policies, and user rights.

.NOTES
    Module: Module 1 - Implement Core OS Security
    Task: 1.5 - Configure Security Settings via Group Policy

    Prerequisites:
    - Active Directory Domain Services
    - Domain Administrator privileges
    - Group Policy Management Console

    Lab Environment:
    - Domain Controller with Windows Server 2022
    - Active Directory domain

    PowerShell Version: 5.1+
#>

#Requires -RunAsAdministrator

# Script configuration
$ErrorActionPreference = 'Stop'

Write-Host "=== AZ-801 Module 1: Task 1.5 - GPO Security Settings ===" -ForegroundColor Cyan
Write-Host ""

try {
    # Section 1: Check if running on domain controller
    Write-Host "[Step 1] Checking domain environment" -ForegroundColor Yellow

    $isDomainController = (Get-CimInstance -ClassName Win32_ComputerSystem).DomainRole -ge 4
    $domain = (Get-CimInstance -ClassName Win32_ComputerSystem).Domain

    Write-Host "Computer Domain: $domain" -ForegroundColor White
    Write-Host "Is Domain Controller: $isDomainController" -ForegroundColor White

    if ($isDomainController) {
        Write-Host "[SUCCESS] Running on domain controller" -ForegroundColor Green
    } else {
        Write-Host "[INFO] Running on domain member (GPO import/export available)" -ForegroundColor Yellow
    }
    Write-Host ""

    # Section 2: Import Group Policy module
    Write-Host "[Step 2] Loading Group Policy module" -ForegroundColor Yellow

    if (Get-Module -ListAvailable -Name GroupPolicy) {
        Import-Module GroupPolicy -ErrorAction SilentlyContinue
        Write-Host "[SUCCESS] Group Policy module loaded" -ForegroundColor Green
    } else {
        Write-Host "[WARNING] Group Policy module not available" -ForegroundColor Yellow
        Write-Host "Install with: Install-WindowsFeature GPMC" -ForegroundColor White
    }
    Write-Host ""

    # Section 3: Display current local security policy
    Write-Host "[Step 3] Reviewing current local security policy" -ForegroundColor Yellow

    # Export current security policy
    $tempSecPol = "$env:TEMP\secpol.cfg"
    secedit /export /cfg $tempSecPol /quiet

    if (Test-Path $tempSecPol) {
        Write-Host "Security policy exported to: $tempSecPol" -ForegroundColor White

        # Read and display some key settings
        $secContent = Get-Content $tempSecPol

        Write-Host "`nPassword Policy Settings:" -ForegroundColor Cyan
        $secContent | Select-String "PasswordComplexity|MinimumPasswordLength|MaximumPasswordAge" | ForEach-Object {
            Write-Host "  $_" -ForegroundColor White
        }

        Write-Host "`nAccount Lockout Settings:" -ForegroundColor Cyan
        $secContent | Select-String "LockoutBadCount|ResetLockoutCount|LockoutDuration" | ForEach-Object {
            Write-Host "  $_" -ForegroundColor White
        }

        Write-Host "[SUCCESS] Local policy reviewed" -ForegroundColor Green
    }
    Write-Host ""

    # Section 4: Configure password policy settings
    Write-Host "[Step 4] Demonstrating password policy configuration" -ForegroundColor Yellow

    Write-Host "`nRecommended Password Policy:" -ForegroundColor Cyan
    Write-Host "  - Minimum Password Length: 14 characters" -ForegroundColor White
    Write-Host "  - Password Complexity: Enabled" -ForegroundColor White
    Write-Host "  - Maximum Password Age: 90 days" -ForegroundColor White
    Write-Host "  - Minimum Password Age: 1 day" -ForegroundColor White
    Write-Host "  - Password History: 24 passwords remembered" -ForegroundColor White

    # Create a sample security template
    $secTemplate = @"
[Unicode]
Unicode=yes
[Version]
signature="`$CHICAGO`$"
Revision=1
[System Access]
MinimumPasswordAge = 1
MaximumPasswordAge = 90
MinimumPasswordLength = 14
PasswordComplexity = 1
PasswordHistorySize = 24
LockoutBadCount = 5
ResetLockoutCount = 30
LockoutDuration = 30
[Event Audit]
AuditSystemEvents = 3
AuditLogonEvents = 3
AuditObjectAccess = 3
AuditPrivilegeUse = 3
AuditPolicyChange = 3
AuditAccountManage = 3
AuditProcessTracking = 0
AuditDSAccess = 3
AuditAccountLogon = 3
"@

    $templatePath = "$env:TEMP\SecurityTemplate.inf"
    $secTemplate | Out-File -FilePath $templatePath -Encoding unicode

    Write-Host "`nSecurity template created: $templatePath" -ForegroundColor White
    Write-Host "[SUCCESS] Password policy configuration ready" -ForegroundColor Green
    Write-Host ""

    # Section 5: Configure audit policy
    Write-Host "[Step 5] Configuring advanced audit policy" -ForegroundColor Yellow

    Write-Host "`nEnabling advanced audit policies..." -ForegroundColor White

    # Configure advanced audit policies
    $auditPolicies = @{
        "Logon/Logoff:Logon" = "Success and Failure"
        "Logon/Logoff:Logoff" = "Success"
        "Account Logon:Credential Validation" = "Success and Failure"
        "Account Management:User Account Management" = "Success and Failure"
        "Policy Change:Audit Policy Change" = "Success and Failure"
        "Privilege Use:Sensitive Privilege Use" = "Success and Failure"
    }

    Write-Host "Recommended Audit Policies:" -ForegroundColor Cyan
    foreach ($policy in $auditPolicies.GetEnumerator()) {
        Write-Host "  $($policy.Key): $($policy.Value)" -ForegroundColor White
    }

    # Enable advanced audit policy
    auditpol /set /category:"Logon/Logoff" /success:enable /failure:enable
    auditpol /set /category:"Account Logon" /success:enable /failure:enable
    auditpol /set /category:"Account Management" /success:enable /failure:enable

    Write-Host "[SUCCESS] Audit policies configured" -ForegroundColor Green
    Write-Host ""

    # Section 6: Display current audit policy
    Write-Host "[Step 6] Verifying audit policy configuration" -ForegroundColor Yellow

    Write-Host "`nCurrent Audit Policy Settings:" -ForegroundColor Cyan
    auditpol /get /category:*

    Write-Host ""

    # Section 7: User Rights Assignment
    Write-Host "[Step 7] Reviewing user rights assignment" -ForegroundColor Yellow

    Write-Host "`nCritical User Rights to Configure:" -ForegroundColor Cyan
    Write-Host "  - Access this computer from the network" -ForegroundColor White
    Write-Host "  - Allow log on locally" -ForegroundColor White
    Write-Host "  - Allow log on through Remote Desktop Services" -ForegroundColor White
    Write-Host "  - Deny log on as a batch job" -ForegroundColor White
    Write-Host "  - Deny log on through Remote Desktop Services" -ForegroundColor White

    Write-Host "`nThese are configured in:" -ForegroundColor White
    Write-Host "GPO > Computer Configuration > Policies > Windows Settings >" -ForegroundColor White
    Write-Host "Security Settings > Local Policies > User Rights Assignment" -ForegroundColor White

    Write-Host "[SUCCESS] User rights reviewed" -ForegroundColor Green
    Write-Host ""

    # Section 8: Security Options
    Write-Host "[Step 8] Key security options configuration" -ForegroundColor Yellow

    Write-Host "`nRecommended Security Options:" -ForegroundColor Cyan
    Write-Host "  - Interactive logon: Do not display last user name - Enabled" -ForegroundColor White
    Write-Host "  - Interactive logon: Machine inactivity limit - 900 seconds (15 min)" -ForegroundColor White
    Write-Host "  - Network security: LAN Manager authentication level - NTLMv2 only" -ForegroundColor White
    Write-Host "  - Network security: Minimum session security for NTLM - Require NTLMv2 and 128-bit" -ForegroundColor White
    Write-Host "  - User Account Control: Admin Approval Mode - Enabled" -ForegroundColor White

    Write-Host "[SUCCESS] Security options documented" -ForegroundColor Green
    Write-Host ""

    # Section 9: GPO creation example (if on DC)
    Write-Host "[Step 9] Group Policy Object management" -ForegroundColor Yellow

    if (Get-Command Get-GPO -ErrorAction SilentlyContinue) {
        try {
            # List existing GPOs
            $gpos = Get-GPO -All | Select-Object -First 5 DisplayName, CreationTime

            Write-Host "`nExisting Group Policy Objects (first 5):" -ForegroundColor Cyan
            $gpos | ForEach-Object {
                Write-Host "  - $($_.DisplayName) (Created: $($_.CreationTime))" -ForegroundColor White
            }

            Write-Host "`nTo create a new security GPO:" -ForegroundColor Cyan
            Write-Host "  New-GPO -Name 'Corporate Security Policy' -Comment 'AZ-801 Security Settings'" -ForegroundColor White

        } catch {
            Write-Host "[INFO] GPO cmdlets require domain environment" -ForegroundColor Yellow
        }
    } else {
        Write-Host "[INFO] Group Policy cmdlets not available" -ForegroundColor Yellow
        Write-Host "To manage GPOs, use Group Policy Management Console (GPMC)" -ForegroundColor White
    }

    Write-Host ""

    # Section 10: Educational notes
    Write-Host "[INFO] GPO Security Best Practices:" -ForegroundColor Cyan
    Write-Host "  - Use separate GPOs for different security areas" -ForegroundColor White
    Write-Host "  - Link GPOs at appropriate OU levels" -ForegroundColor White
    Write-Host "  - Use security filtering for targeted deployment" -ForegroundColor White
    Write-Host "  - Enable detailed audit logging for compliance" -ForegroundColor White
    Write-Host "  - Regular review GPO settings with Get-GPOReport" -ForegroundColor White
    Write-Host "  - Back up GPOs before making changes" -ForegroundColor White
    Write-Host "  - Use AGPM (Advanced Group Policy Management) for change control" -ForegroundColor White
    Write-Host ""
    Write-Host "Key GPO Locations:" -ForegroundColor Cyan
    Write-Host "  - Password Policy: Default Domain Policy" -ForegroundColor White
    Write-Host "  - Audit Policy: Computer Configuration > Security Settings" -ForegroundColor White
    Write-Host "  - User Rights: Local Policies > User Rights Assignment" -ForegroundColor White
    Write-Host ""

    # Cleanup
    if (Test-Path $tempSecPol) {
        Remove-Item $tempSecPol -Force
    }

} catch {
    Write-Host "[ERROR] $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

Write-Host "Demo completed successfully!" -ForegroundColor Green
Write-Host "Next Steps: Create security baseline GPO and link to appropriate OUs" -ForegroundColor Yellow
