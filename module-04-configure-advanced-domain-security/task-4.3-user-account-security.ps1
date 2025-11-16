<#
.SYNOPSIS
    Task 4.3 - Secure User Accounts
.DESCRIPTION
    Comprehensive demonstration of user account security configurations in Active Directory.
    Covers password policies, account lockout, account protections, and monitoring.
.EXAMPLE
    .\task-4.3-user-account-security.ps1
.NOTES
    Module: Module 4 - Configure Advanced Domain Security
    Task: 4.3 - Secure User Accounts
    Prerequisites:
    - Windows Server with Active Directory
    - ActiveDirectory PowerShell module
    - Domain Admin or equivalent permissions
    PowerShell Version: 5.1+
#>

#Requires -RunAsAdministrator
#Requires -Modules ActiveDirectory

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

Write-Host "=== AZ-801 Module 4: Task 4.3 - Secure User Accounts ===" -ForegroundColor Cyan
Write-Host ""

try {
    # Step 1: Review current domain password policy
    Write-Host "[Step 1] Reviewing domain password policy" -ForegroundColor Yellow

    $defaultPolicy = Get-ADDefaultDomainPasswordPolicy
    Write-Host "Current Default Domain Password Policy:" -ForegroundColor Cyan
    Write-Host "  Complexity Enabled: $($defaultPolicy.ComplexityEnabled)" -ForegroundColor White
    Write-Host "  Min Password Length: $($defaultPolicy.MinPasswordLength) characters" -ForegroundColor White
    Write-Host "  Min Password Age: $($defaultPolicy.MinPasswordAge.Days) days" -ForegroundColor White
    Write-Host "  Max Password Age: $($defaultPolicy.MaxPasswordAge.Days) days" -ForegroundColor White
    Write-Host "  Password History: $($defaultPolicy.PasswordHistoryCount) passwords remembered" -ForegroundColor White
    Write-Host "  Lockout Duration: $($defaultPolicy.LockoutDuration.TotalMinutes) minutes" -ForegroundColor White
    Write-Host "  Lockout Threshold: $($defaultPolicy.LockoutThreshold) attempts" -ForegroundColor White
    Write-Host "  Lockout Window: $($defaultPolicy.LockoutObservationWindow.TotalMinutes) minutes" -ForegroundColor White
    Write-Host ""

    # Step 2: Check for fine-grained password policies (PSOs)
    Write-Host "[Step 2] Checking fine-grained password policies" -ForegroundColor Yellow

    $psos = Get-ADFineGrainedPasswordPolicy -Filter *
    if ($psos) {
        Write-Host "Found $($psos.Count) fine-grained password policy(ies):" -ForegroundColor Cyan
        foreach ($pso in $psos) {
            Write-Host "  - $($pso.Name) (Precedence: $($pso.Precedence))" -ForegroundColor White
            Write-Host "    Min Length: $($pso.MinPasswordLength), Complexity: $($pso.ComplexityEnabled)" -ForegroundColor Gray
        }
    } else {
        Write-Host "No fine-grained password policies configured" -ForegroundColor White
        Write-Host ""
        Write-Host "Creating example fine-grained password policy for administrators..." -ForegroundColor Cyan

        $psoParams = @{
            Name = "AdminPasswordPolicy"
            Precedence = 10
            ComplexityEnabled = $true
            Description = "Strict password policy for administrative accounts"
            DisplayName = "Administrator Password Policy"
            LockoutDuration = "00:30:00"
            LockoutObservationWindow = "00:30:00"
            LockoutThreshold = 3
            MaxPasswordAge = "60.00:00:00"
            MinPasswordAge = "1.00:00:00"
            MinPasswordLength = 15
            PasswordHistoryCount = 24
            ReversibleEncryptionEnabled = $false
        }

        Write-Host "  [DEMO] Would create PSO with:" -ForegroundColor Yellow
        Write-Host "    Min Length: 15 characters" -ForegroundColor White
        Write-Host "    Max Age: 60 days" -ForegroundColor White
        Write-Host "    History: 24 passwords" -ForegroundColor White
        Write-Host "    Lockout: 3 attempts" -ForegroundColor White
        Write-Host ""
        Write-Host "  Command: New-ADFineGrainedPasswordPolicy @psoParams" -ForegroundColor Cyan
    }
    Write-Host ""

    # Step 3: Identify privileged accounts
    Write-Host "[Step 3] Identifying privileged accounts" -ForegroundColor Yellow

    $adminGroups = @(
        "Domain Admins",
        "Enterprise Admins",
        "Schema Admins",
        "Administrators"
    )

    $privilegedUsers = @()
    foreach ($group in $adminGroups) {
        try {
            $members = Get-ADGroupMember -Identity $group -Recursive -ErrorAction SilentlyContinue |
                       Where-Object { $_.objectClass -eq 'user' }
            if ($members) {
                $privilegedUsers += $members
                Write-Host "$group`: $($members.Count) member(s)" -ForegroundColor Cyan
            }
        } catch {
            Write-Host "$group`: Not found or inaccessible" -ForegroundColor Gray
        }
    }

    $uniquePrivilegedUsers = $privilegedUsers | Select-Object -Unique -ExpandProperty SamAccountName
    Write-Host ""
    Write-Host "Total unique privileged users: $($uniquePrivilegedUsers.Count)" -ForegroundColor White
    Write-Host ""

    # Step 4: Configure account protections
    Write-Host "[Step 4] Configuring account security attributes" -ForegroundColor Yellow

    Write-Host "Recommended user account security settings:" -ForegroundColor Cyan
    Write-Host "  1. Account is sensitive and cannot be delegated (for admin accounts)" -ForegroundColor White
    Write-Host "  2. Smart card required for interactive logon (for high-privilege accounts)" -ForegroundColor White
    Write-Host "  3. This account supports Kerberos AES 128/256 encryption" -ForegroundColor White
    Write-Host "  4. Do not require Kerberos preauthentication (disabled for security)" -ForegroundColor White
    Write-Host ""

    Write-Host "Example: Securing a test admin account..." -ForegroundColor Cyan
    Write-Host '  Set-ADUser -Identity "testadmin" -AccountNotDelegated $true' -ForegroundColor White
    Write-Host '  Set-ADUser -Identity "testadmin" -SmartcardLogonRequired $true' -ForegroundColor White
    Write-Host '  Set-ADAccountControl -Identity "testadmin" -DoesNotRequirePreAuth $false' -ForegroundColor White
    Write-Host ""

    # Step 5: Scan for account security issues
    Write-Host "[Step 5] Scanning for account security issues" -ForegroundColor Yellow

    # Check for users with passwords that never expire
    Write-Host "Checking for users with non-expiring passwords..." -ForegroundColor Cyan
    $nonExpiringUsers = Get-ADUser -Filter {PasswordNeverExpires -eq $true -and Enabled -eq $true} -Properties PasswordNeverExpires, PasswordLastSet
    if ($nonExpiringUsers) {
        Write-Host "  Found $($nonExpiringUsers.Count) user(s) with passwords that never expire:" -ForegroundColor Yellow
        $nonExpiringUsers | Select-Object -First 5 | ForEach-Object {
            Write-Host "    - $($_.SamAccountName) (Last set: $($_.PasswordLastSet))" -ForegroundColor White
        }
        if ($nonExpiringUsers.Count -gt 5) {
            Write-Host "    ... and $($nonExpiringUsers.Count - 5) more" -ForegroundColor Gray
        }
    } else {
        Write-Host "  [GOOD] No enabled users found with non-expiring passwords" -ForegroundColor Green
    }
    Write-Host ""

    # Check for users with old passwords
    Write-Host "Checking for users with passwords older than 90 days..." -ForegroundColor Cyan
    $oldPasswordDate = (Get-Date).AddDays(-90)
    $oldPasswords = Get-ADUser -Filter {Enabled -eq $true} -Properties PasswordLastSet |
                    Where-Object { $_.PasswordLastSet -lt $oldPasswordDate -and $_.PasswordLastSet -ne $null }

    if ($oldPasswords) {
        Write-Host "  Found $($oldPasswords.Count) user(s) with passwords older than 90 days:" -ForegroundColor Yellow
        $oldPasswords | Select-Object -First 5 | ForEach-Object {
            $age = ((Get-Date) - $_.PasswordLastSet).Days
            Write-Host "    - $($_.SamAccountName) ($age days old)" -ForegroundColor White
        }
    } else {
        Write-Host "  [GOOD] No users with passwords older than 90 days" -ForegroundColor Green
    }
    Write-Host ""

    # Check for accounts with reversible encryption
    Write-Host "Checking for accounts with reversible encryption..." -ForegroundColor Cyan
    $reversibleUsers = Get-ADUser -Filter {AllowReversiblePasswordEncryption -eq $true} -Properties AllowReversiblePasswordEncryption
    if ($reversibleUsers) {
        Write-Host "  [WARNING] Found $($reversibleUsers.Count) user(s) with reversible encryption:" -ForegroundColor Red
        $reversibleUsers | ForEach-Object {
            Write-Host "    - $($_.SamAccountName)" -ForegroundColor White
        }
    } else {
        Write-Host "  [GOOD] No accounts with reversible encryption enabled" -ForegroundColor Green
    }
    Write-Host ""

    # Step 6: Check for inactive accounts
    Write-Host "[Step 6] Identifying inactive user accounts" -ForegroundColor Yellow

    $inactiveDays = 90
    $inactiveDate = (Get-Date).AddDays(-$inactiveDays)

    Write-Host "Searching for accounts inactive for more than $inactiveDays days..." -ForegroundColor Cyan
    $inactiveUsers = Get-ADUser -Filter {Enabled -eq $true} -Properties LastLogonDate |
                     Where-Object { $_.LastLogonDate -lt $inactiveDate -and $_.LastLogonDate -ne $null }

    if ($inactiveUsers) {
        Write-Host "  Found $($inactiveUsers.Count) inactive enabled account(s):" -ForegroundColor Yellow
        $inactiveUsers | Select-Object -First 5 | ForEach-Object {
            $daysSinceLogon = if ($_.LastLogonDate) { ((Get-Date) - $_.LastLogonDate).Days } else { "Never" }
            Write-Host "    - $($_.SamAccountName) (Last logon: $daysSinceLogon days ago)" -ForegroundColor White
        }
        Write-Host ""
        Write-Host "  Recommendation: Disable or remove inactive accounts" -ForegroundColor Cyan
        Write-Host '    Disable-ADAccount -Identity "username"' -ForegroundColor White
    } else {
        Write-Host "  [GOOD] No long-term inactive accounts found" -ForegroundColor Green
    }
    Write-Host ""

    # Step 7: Implement account lockout monitoring
    Write-Host "[Step 7] Account lockout monitoring" -ForegroundColor Yellow

    Write-Host "Checking for recently locked out accounts..." -ForegroundColor Cyan
    $lockedAccounts = Search-ADAccount -LockedOut -UsersOnly

    if ($lockedAccounts) {
        Write-Host "  Found $($lockedAccounts.Count) locked account(s):" -ForegroundColor Yellow
        $lockedAccounts | Select-Object -First 5 | ForEach-Object {
            Write-Host "    - $($_.SamAccountName)" -ForegroundColor White
        }
        Write-Host ""
        Write-Host "  To unlock an account:" -ForegroundColor Cyan
        Write-Host '    Unlock-ADAccount -Identity "username"' -ForegroundColor White
    } else {
        Write-Host "  No currently locked accounts" -ForegroundColor Green
    }
    Write-Host ""

    # Step 8: Protected Users group
    Write-Host "[Step 8] Protected Users security group" -ForegroundColor Yellow

    Write-Host "The Protected Users group provides additional protections:" -ForegroundColor Cyan
    Write-Host "  - Cannot use NTLM, Digest, or CredSSP authentication" -ForegroundColor White
    Write-Host "  - Cannot use DES or RC4 in Kerberos pre-authentication" -ForegroundColor White
    Write-Host "  - TGTs limited to 4-hour lifetime (non-renewable)" -ForegroundColor White
    Write-Host "  - Cannot be delegated with Kerberos" -ForegroundColor White
    Write-Host ""

    try {
        $protectedGroup = Get-ADGroup -Identity "Protected Users" -ErrorAction SilentlyContinue
        if ($protectedGroup) {
            $protectedMembers = Get-ADGroupMember -Identity "Protected Users" -ErrorAction SilentlyContinue
            Write-Host "Protected Users group members: $($protectedMembers.Count)" -ForegroundColor White
            if ($protectedMembers) {
                $protectedMembers | Select-Object -First 5 | ForEach-Object {
                    Write-Host "  - $($_.Name)" -ForegroundColor Cyan
                }
            }
            Write-Host ""
            Write-Host "To add a user to Protected Users:" -ForegroundColor Cyan
            Write-Host '  Add-ADGroupMember -Identity "Protected Users" -Members "username"' -ForegroundColor White
        }
    } catch {
        Write-Host "Protected Users group not available (requires 2012 R2+ domain)" -ForegroundColor Yellow
    }
    Write-Host ""

    # Step 9: Service account security
    Write-Host "[Step 9] Service account security best practices" -ForegroundColor Yellow

    Write-Host "Recommendations for service accounts:" -ForegroundColor Cyan
    Write-Host "  1. Use Group Managed Service Accounts (gMSA) when possible" -ForegroundColor White
    Write-Host "  2. Use Managed Service Accounts (MSA) for single-server services" -ForegroundColor White
    Write-Host "  3. For traditional service accounts:" -ForegroundColor White
    Write-Host "     - Use strong, unique passwords (30+ characters)" -ForegroundColor White
    Write-Host "     - Set 'This account is sensitive and cannot be delegated'" -ForegroundColor White
    Write-Host "     - Limit logon permissions to specific computers" -ForegroundColor White
    Write-Host "     - Regular password rotation" -ForegroundColor White
    Write-Host ""

    Write-Host "Creating a Group Managed Service Account (example):" -ForegroundColor Cyan
    Write-Host '  New-ADServiceAccount -Name "svc-webapp-gmsa" -DNSHostName "svc-webapp.domain.com" `' -ForegroundColor White
    Write-Host '    -PrincipalsAllowedToRetrieveManagedPassword "WebServers" -ManagedPasswordIntervalInDays 30' -ForegroundColor White
    Write-Host ""

    # Step 10: Best practices summary
    Write-Host "[Step 10] User Account Security Best Practices" -ForegroundColor Yellow
    Write-Host "  1. Enforce strong password policies (15+ chars for admins, 12+ for users)" -ForegroundColor White
    Write-Host "  2. Enable account lockout policies (3-5 failed attempts)" -ForegroundColor White
    Write-Host "  3. Use fine-grained password policies for different account types" -ForegroundColor White
    Write-Host "  4. Add privileged accounts to Protected Users group" -ForegroundColor White
    Write-Host "  5. Enable 'Account is sensitive and cannot be delegated' for admins" -ForegroundColor White
    Write-Host "  6. Regularly audit for inactive accounts and disable/remove them" -ForegroundColor White
    Write-Host "  7. Never allow reversible password encryption" -ForegroundColor White
    Write-Host "  8. Use separate accounts for administration (user + admin accounts)" -ForegroundColor White
    Write-Host "  9. Implement MFA for all administrative accounts" -ForegroundColor White
    Write-Host "  10. Use gMSA or MSA for service accounts" -ForegroundColor White
    Write-Host ""

    Write-Host "[INFO] Monitoring Commands:" -ForegroundColor Cyan
    Write-Host '  Search for locked accounts: Search-ADAccount -LockedOut' -ForegroundColor White
    Write-Host '  Search for expired accounts: Search-ADAccount -AccountExpired' -ForegroundColor White
    Write-Host '  Search for inactive accounts: Search-ADAccount -AccountInactive -TimeSpan 90' -ForegroundColor White
    Write-Host '  Search for disabled accounts: Search-ADAccount -AccountDisabled' -ForegroundColor White
    Write-Host ""

} catch {
    Write-Host "[ERROR] $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

Write-Host "Demo completed successfully!" -ForegroundColor Green
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Review and update domain password policy" -ForegroundColor White
Write-Host "  2. Create fine-grained password policies for admin accounts" -ForegroundColor White
Write-Host "  3. Add privileged accounts to Protected Users group" -ForegroundColor White
Write-Host "  4. Audit and disable/remove inactive accounts" -ForegroundColor White
Write-Host "  5. Migrate service accounts to gMSA where possible" -ForegroundColor White
