<#
.SYNOPSIS
    Task 2.2 - Configure Password Policies and Fine-Grained Password Policies

.DESCRIPTION
    Demo script for AZ-801 Module 2: Secure Local Accounts and Passwords
    This script demonstrates how to configure domain password policies and
    implement Fine-Grained Password Policies (FGPP) for different user groups.

.NOTES
    Module: Module 2 - Secure Local Accounts and Passwords
    Task: 2.2 - Configure Password Policies

    Prerequisites:
    - Active Directory Domain Services
    - Domain Administrator privileges
    - AD PowerShell module
    - Domain functional level 2008 or higher for FGPP

    Lab Environment:
    - Domain Controller with Windows Server 2022
    - Multiple user groups for testing FGPP

    PowerShell Version: 5.1+
#>

#Requires -RunAsAdministrator

# Script configuration
$ErrorActionPreference = 'Stop'

Write-Host "=== AZ-801 Module 2: Task 2.2 - Password Policies ===" -ForegroundColor Cyan
Write-Host ""

try {
    # Section 1: Check domain environment
    Write-Host "[Step 1] Checking Active Directory environment" -ForegroundColor Yellow

    $computerSystem = Get-CimInstance -ClassName Win32_ComputerSystem
    $domain = $computerSystem.Domain
    $isDC = $computerSystem.DomainRole -ge 4

    Write-Host "Domain: $domain" -ForegroundColor White
    Write-Host "Is Domain Controller: $isDC" -ForegroundColor White

    # Import AD module
    if (Get-Module -ListAvailable -Name ActiveDirectory) {
        Import-Module ActiveDirectory -ErrorAction SilentlyContinue
        Write-Host "[SUCCESS] Active Directory module loaded" -ForegroundColor Green
    } else {
        Write-Host "[WARNING] Active Directory module not available" -ForegroundColor Yellow
        Write-Host "Install with: Install-WindowsFeature RSAT-AD-PowerShell" -ForegroundColor White
        Write-Host ""
    }

    # Get domain info
    try {
        $domainInfo = Get-ADDomain
        Write-Host "Domain Functional Level: $($domainInfo.DomainMode)" -ForegroundColor White

        if ($domainInfo.DomainMode -ge "Windows2008Domain") {
            Write-Host "[SUCCESS] Domain supports Fine-Grained Password Policies" -ForegroundColor Green
        } else {
            Write-Host "[WARNING] Raise domain functional level to Windows Server 2008 for FGPP" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "[WARNING] Could not query domain information" -ForegroundColor Yellow
    }
    Write-Host ""

    # Section 2: Display current default domain password policy
    Write-Host "[Step 2] Reviewing current default domain password policy" -ForegroundColor Yellow

    try {
        $defaultPolicy = Get-ADDefaultDomainPasswordPolicy

        Write-Host "`nDefault Domain Password Policy:" -ForegroundColor Cyan
        Write-Host "  Minimum Password Length: $($defaultPolicy.MinPasswordLength) characters" -ForegroundColor White
        Write-Host "  Password Complexity: $($defaultPolicy.ComplexityEnabled)" -ForegroundColor White
        Write-Host "  Maximum Password Age: $($defaultPolicy.MaxPasswordAge.Days) days" -ForegroundColor White
        Write-Host "  Minimum Password Age: $($defaultPolicy.MinPasswordAge.Days) days" -ForegroundColor White
        Write-Host "  Password History Count: $($defaultPolicy.PasswordHistoryCount) passwords" -ForegroundColor White
        Write-Host "  Lockout Threshold: $($defaultPolicy.LockoutThreshold) attempts" -ForegroundColor White
        Write-Host "  Lockout Duration: $($defaultPolicy.LockoutDuration.Minutes) minutes" -ForegroundColor White
        Write-Host "  Lockout Observation Window: $($defaultPolicy.LockoutObservationWindow.Minutes) minutes" -ForegroundColor White
        Write-Host "  Reversible Encryption: $($defaultPolicy.ReversibleEncryptionEnabled)" -ForegroundColor White

        Write-Host "[SUCCESS] Default policy retrieved" -ForegroundColor Green
    } catch {
        Write-Host "[WARNING] Could not retrieve default password policy" -ForegroundColor Yellow
    }
    Write-Host ""

    # Section 3: Configure recommended default password policy
    Write-Host "[Step 3] Recommended default domain password policy settings" -ForegroundColor Yellow

    Write-Host "`nRecommended Settings:" -ForegroundColor Cyan
    Write-Host "  Minimum Password Length: 14 characters" -ForegroundColor White
    Write-Host "  Password Complexity: Enabled" -ForegroundColor White
    Write-Host "  Maximum Password Age: 90 days" -ForegroundColor White
    Write-Host "  Minimum Password Age: 1 day" -ForegroundColor White
    Write-Host "  Password History: 24 passwords" -ForegroundColor White
    Write-Host "  Account Lockout Threshold: 5 attempts" -ForegroundColor White
    Write-Host "  Account Lockout Duration: 30 minutes" -ForegroundColor White
    Write-Host "  Reset Account Lockout Counter: 30 minutes" -ForegroundColor White
    Write-Host ""

    Write-Host "To configure default policy:" -ForegroundColor Cyan
    Write-Host "  Set-ADDefaultDomainPasswordPolicy ``" -ForegroundColor White
    Write-Host "    -Identity $domain ``" -ForegroundColor White
    Write-Host "    -MinPasswordLength 14 ``" -ForegroundColor White
    Write-Host "    -ComplexityEnabled `$true ``" -ForegroundColor White
    Write-Host "    -MaxPasswordAge '90.00:00:00' ``" -ForegroundColor White
    Write-Host "    -MinPasswordAge '1.00:00:00' ``" -ForegroundColor White
    Write-Host "    -PasswordHistoryCount 24 ``" -ForegroundColor White
    Write-Host "    -LockoutThreshold 5 ``" -ForegroundColor White
    Write-Host "    -LockoutDuration '00:30:00' ``" -ForegroundColor White
    Write-Host "    -LockoutObservationWindow '00:30:00'" -ForegroundColor White
    Write-Host ""

    # Section 4: List existing Fine-Grained Password Policies
    Write-Host "[Step 4] Checking existing Fine-Grained Password Policies" -ForegroundColor Yellow

    try {
        $fgpps = Get-ADFineGrainedPasswordPolicy -Filter * -ErrorAction SilentlyContinue

        if ($fgpps) {
            Write-Host "`nExisting Fine-Grained Password Policies:" -ForegroundColor Cyan
            foreach ($fgpp in $fgpps) {
                Write-Host "  Policy Name: $($fgpp.Name)" -ForegroundColor White
                Write-Host "    Precedence: $($fgpp.Precedence)" -ForegroundColor White
                Write-Host "    Min Password Length: $($fgpp.MinPasswordLength)" -ForegroundColor White
                Write-Host "    Max Password Age: $($fgpp.MaxPasswordAge.Days) days" -ForegroundColor White
                Write-Host "    Lockout Threshold: $($fgpp.LockoutThreshold)" -ForegroundColor White
                Write-Host ""
            }
            Write-Host "[SUCCESS] Found $($fgpps.Count) Fine-Grained Password Policy(ies)" -ForegroundColor Green
        } else {
            Write-Host "No Fine-Grained Password Policies found" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "[WARNING] Could not query Fine-Grained Password Policies" -ForegroundColor Yellow
    }
    Write-Host ""

    # Section 5: Create Fine-Grained Password Policy for Administrators
    Write-Host "[Step 5] Creating Fine-Grained Password Policy for Administrators" -ForegroundColor Yellow

    $adminPolicyName = "AdminPasswordPolicy"

    Write-Host "`nExample: Administrator Password Policy" -ForegroundColor Cyan
    Write-Host "Policy Configuration:" -ForegroundColor White
    Write-Host "  Name: $adminPolicyName" -ForegroundColor White
    Write-Host "  Precedence: 10 (lower number = higher priority)" -ForegroundColor White
    Write-Host "  Minimum Password Length: 16 characters" -ForegroundColor White
    Write-Host "  Password Complexity: Enabled" -ForegroundColor White
    Write-Host "  Maximum Password Age: 60 days" -ForegroundColor White
    Write-Host "  Minimum Password Age: 1 day" -ForegroundColor White
    Write-Host "  Password History: 24 passwords" -ForegroundColor White
    Write-Host "  Lockout Threshold: 3 attempts" -ForegroundColor White
    Write-Host "  Lockout Duration: 60 minutes" -ForegroundColor White
    Write-Host ""

    Write-Host "Command to create:" -ForegroundColor Cyan
    Write-Host "  New-ADFineGrainedPasswordPolicy ``" -ForegroundColor White
    Write-Host "    -Name '$adminPolicyName' ``" -ForegroundColor White
    Write-Host "    -Precedence 10 ``" -ForegroundColor White
    Write-Host "    -MinPasswordLength 16 ``" -ForegroundColor White
    Write-Host "    -ComplexityEnabled `$true ``" -ForegroundColor White
    Write-Host "    -MaxPasswordAge '60.00:00:00' ``" -ForegroundColor White
    Write-Host "    -MinPasswordAge '1.00:00:00' ``" -ForegroundColor White
    Write-Host "    -PasswordHistoryCount 24 ``" -ForegroundColor White
    Write-Host "    -LockoutThreshold 3 ``" -ForegroundColor White
    Write-Host "    -LockoutDuration '01:00:00' ``" -ForegroundColor White
    Write-Host "    -LockoutObservationWindow '01:00:00' ``" -ForegroundColor White
    Write-Host "    -Description 'Strict password policy for administrative accounts'" -ForegroundColor White
    Write-Host ""

    # Section 6: Create FGPP for Service Accounts
    Write-Host "[Step 6] Creating Fine-Grained Password Policy for Service Accounts" -ForegroundColor Yellow

    $servicePolicyName = "ServiceAccountPasswordPolicy"

    Write-Host "`nExample: Service Account Password Policy" -ForegroundColor Cyan
    Write-Host "Policy Configuration:" -ForegroundColor White
    Write-Host "  Name: $servicePolicyName" -ForegroundColor White
    Write-Host "  Precedence: 20" -ForegroundColor White
    Write-Host "  Minimum Password Length: 20 characters" -ForegroundColor White
    Write-Host "  Password Complexity: Enabled" -ForegroundColor White
    Write-Host "  Maximum Password Age: 365 days (rarely change to avoid service disruption)" -ForegroundColor White
    Write-Host "  No account lockout (service accounts)" -ForegroundColor White
    Write-Host ""

    Write-Host "Command to create:" -ForegroundColor Cyan
    Write-Host "  New-ADFineGrainedPasswordPolicy ``" -ForegroundColor White
    Write-Host "    -Name '$servicePolicyName' ``" -ForegroundColor White
    Write-Host "    -Precedence 20 ``" -ForegroundColor White
    Write-Host "    -MinPasswordLength 20 ``" -ForegroundColor White
    Write-Host "    -ComplexityEnabled `$true ``" -ForegroundColor White
    Write-Host "    -MaxPasswordAge '365.00:00:00' ``" -ForegroundColor White
    Write-Host "    -MinPasswordAge '1.00:00:00' ``" -ForegroundColor White
    Write-Host "    -PasswordHistoryCount 24 ``" -ForegroundColor White
    Write-Host "    -LockoutThreshold 0 ``" -ForegroundColor White
    Write-Host "    -Description 'Password policy for service accounts'" -ForegroundColor White
    Write-Host ""

    # Section 7: Apply FGPP to groups
    Write-Host "[Step 7] Applying Fine-Grained Password Policies to groups" -ForegroundColor Yellow

    Write-Host "`nApply FGPP to Active Directory groups or users:" -ForegroundColor Cyan
    Write-Host "  # Apply to a group:" -ForegroundColor White
    Write-Host "  Add-ADFineGrainedPasswordPolicySubject ``" -ForegroundColor White
    Write-Host "    -Identity '$adminPolicyName' ``" -ForegroundColor White
    Write-Host "    -Subjects 'Domain Admins','Enterprise Admins'" -ForegroundColor White
    Write-Host ""
    Write-Host "  # Apply to specific users:" -ForegroundColor White
    Write-Host "  Add-ADFineGrainedPasswordPolicySubject ``" -ForegroundColor White
    Write-Host "    -Identity '$servicePolicyName' ``" -ForegroundColor White
    Write-Host "    -Subjects 'SQL_Service','IIS_AppPool'" -ForegroundColor White
    Write-Host ""

    Write-Host "View applied policies:" -ForegroundColor Cyan
    Write-Host "  # See which policy applies to a user:" -ForegroundColor White
    Write-Host "  Get-ADUserResultantPasswordPolicy -Identity 'username'" -ForegroundColor White
    Write-Host ""
    Write-Host "  # See who has a policy applied:" -ForegroundColor White
    Write-Host "  Get-ADFineGrainedPasswordPolicySubject -Identity '$adminPolicyName'" -ForegroundColor White
    Write-Host ""

    # Section 8: Password policy precedence
    Write-Host "[Step 8] Understanding Password Policy Precedence" -ForegroundColor Yellow

    Write-Host "`nPassword Policy Precedence Rules:" -ForegroundColor Cyan
    Write-Host "  1. If user has multiple FGPPs directly applied:" -ForegroundColor White
    Write-Host "     - FGPP with LOWEST precedence number wins" -ForegroundColor White
    Write-Host "  2. If user is member of multiple groups with FGPPs:" -ForegroundColor White
    Write-Host "     - FGPP with LOWEST precedence number wins" -ForegroundColor White
    Write-Host "  3. If no FGPP applies:" -ForegroundColor White
    Write-Host "     - Default domain password policy applies" -ForegroundColor White
    Write-Host ""
    Write-Host "Best Practices:" -ForegroundColor Cyan
    Write-Host "  - Use precedence 1-10 for critical accounts (admins)" -ForegroundColor White
    Write-Host "  - Use precedence 11-50 for standard policies" -ForegroundColor White
    Write-Host "  - Use precedence 51-100 for service accounts" -ForegroundColor White
    Write-Host "  - Document precedence numbers in policy descriptions" -ForegroundColor White
    Write-Host ""

    # Section 9: Create password policy implementation guide
    Write-Host "[Step 9] Creating password policy implementation guide" -ForegroundColor Yellow

    $guide = @"
Password Policy Implementation Guide
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

=== Password Policy Strategy ===

1. DEFAULT DOMAIN POLICY (applies to all users unless overridden)
   - Minimum Length: 14 characters
   - Complexity: Enabled
   - Max Age: 90 days
   - History: 24 passwords
   - Lockout: 5 attempts / 30 minutes

2. ADMINISTRATOR POLICY (Precedence: 10)
   Target: Domain Admins, Enterprise Admins, Schema Admins
   - Minimum Length: 16 characters
   - Max Age: 60 days
   - Lockout: 3 attempts / 60 minutes
   - Higher security for privileged accounts

3. SERVICE ACCOUNT POLICY (Precedence: 20)
   Target: Service account OUs
   - Minimum Length: 20 characters
   - Max Age: 365 days (long-lived to prevent service disruption)
   - No lockout (prevents service interruption)
   - Use Managed Service Accounts when possible

4. VIP USER POLICY (Precedence: 15)
   Target: Executives, high-value targets
   - Minimum Length: 16 characters
   - Max Age: 60 days
   - Lockout: 3 attempts / 60 minutes

=== Implementation Steps ===

1. Create Fine-Grained Password Policies
   New-ADFineGrainedPasswordPolicy -Name "PolicyName" [parameters]

2. Create or identify target security groups
   New-ADGroup -Name "FGPP-Admins" -GroupScope Global

3. Apply policies to groups
   Add-ADFineGrainedPasswordPolicySubject -Identity "PolicyName" -Subjects "GroupName"

4. Add users to appropriate groups
   Add-ADGroupMember -Identity "FGPP-Admins" -Members "username"

5. Verify policy application
   Get-ADUserResultantPasswordPolicy -Identity "username"

=== Monitoring and Compliance ===

1. Regular audits
   - Review password policy compliance quarterly
   - Check for accounts with weak passwords
   - Verify FGPP assignments

2. Event log monitoring
   - Event ID 4740: Account lockout
   - Event ID 4723: Password change attempt
   - Event ID 4724: Password reset

3. Reporting
   - Users with expiring passwords
   - Locked out accounts
   - Password policy violations

=== PowerShell Commands Reference ===

# List all FGPPs
Get-ADFineGrainedPasswordPolicy -Filter *

# Get user's effective password policy
Get-ADUserResultantPasswordPolicy -Identity username

# Modify existing FGPP
Set-ADFineGrainedPasswordPolicy -Identity "PolicyName" -MinPasswordLength 16

# Remove FGPP from user/group
Remove-ADFineGrainedPasswordPolicySubject -Identity "PolicyName" -Subjects "GroupName"

# Delete FGPP
Remove-ADFineGrainedPasswordPolicy -Identity "PolicyName"
"@

    $guidePath = "$env:TEMP\PasswordPolicy-Implementation-Guide.txt"
    $guide | Out-File -FilePath $guidePath -Encoding UTF8

    Write-Host "Implementation guide saved to: $guidePath" -ForegroundColor White
    Write-Host "[SUCCESS] Guide created" -ForegroundColor Green
    Write-Host ""

    # Section 10: Educational notes
    Write-Host "[INFO] Password Policy Best Practices:" -ForegroundColor Cyan
    Write-Host "  - Implement Fine-Grained Password Policies for role-based security" -ForegroundColor White
    Write-Host "  - Administrators should have stricter policies than regular users" -ForegroundColor White
    Write-Host "  - Service accounts need long password ages to prevent disruption" -ForegroundColor White
    Write-Host "  - Use precedence numbers strategically (lower = higher priority)" -ForegroundColor White
    Write-Host "  - Apply FGPPs to groups, not individual users (easier management)" -ForegroundColor White
    Write-Host "  - Regular audit of password policy compliance" -ForegroundColor White
    Write-Host "  - Consider password complexity vs. length (longer is often better)" -ForegroundColor White
    Write-Host "  - Document all password policies and their purposes" -ForegroundColor White
    Write-Host ""

} catch {
    Write-Host "[ERROR] $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

Write-Host "Demo completed successfully!" -ForegroundColor Green
Write-Host "Next Steps: Implement FGPPs for different user roles and monitor compliance" -ForegroundColor Yellow
