<#
.SYNOPSIS
    Task 4.4 - Secure Administrative Groups
.DESCRIPTION
    Comprehensive demonstration of securing administrative groups in Active Directory.
    Implements admin tier model, group protection, and least privilege access.
.EXAMPLE
    .\task-4.4-admin-group-security.ps1
.NOTES
    Module: Module 4 - Configure Advanced Domain Security
    Task: 4.4 - Secure Administrative Groups
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

Write-Host "=== AZ-801 Module 4: Task 4.4 - Secure Administrative Groups ===" -ForegroundColor Cyan
Write-Host ""

try {
    # Step 1: Identify privileged groups
    Write-Host "[Step 1] Identifying privileged administrative groups" -ForegroundColor Yellow

    $privilegedGroups = @(
        "Domain Admins",
        "Enterprise Admins",
        "Schema Admins",
        "Administrators",
        "Account Operators",
        "Server Operators",
        "Backup Operators",
        "Print Operators",
        "DnsAdmins"
    )

    Write-Host "Auditing privileged groups:" -ForegroundColor Cyan
    foreach ($groupName in $privilegedGroups) {
        try {
            $group = Get-ADGroup -Identity $groupName -Properties Members, Description -ErrorAction SilentlyContinue
            if ($group) {
                $memberCount = @($group.Members).Count
                Write-Host "  $groupName`: $memberCount member(s)" -ForegroundColor White

                # Get actual member objects
                $members = Get-ADGroupMember -Identity $groupName -ErrorAction SilentlyContinue
                if ($members) {
                    foreach ($member in $members | Select-Object -First 3) {
                        Write-Host "    - $($member.Name) ($($member.objectClass))" -ForegroundColor Gray
                    }
                    if ($memberCount -gt 3) {
                        Write-Host "    ... and $($memberCount - 3) more" -ForegroundColor Gray
                    }
                }
            }
        } catch {
            Write-Host "  $groupName`: Not found or inaccessible" -ForegroundColor Gray
        }
    }
    Write-Host ""

    # Step 2: Implement AdminSDHolder protection
    Write-Host "[Step 2] AdminSDHolder and protected groups" -ForegroundColor Yellow

    Write-Host "AdminSDHolder protects privileged groups from unauthorized permission changes" -ForegroundColor Cyan
    Write-Host ""

    # Get AdminSDHolder object
    $domain = Get-ADDomain
    $adminSDHolderDN = "CN=AdminSDHolder,CN=System,$($domain.DistinguishedName)"

    Write-Host "AdminSDHolder DN: $adminSDHolderDN" -ForegroundColor White
    try {
        $adminSDHolder = Get-ADObject -Identity $adminSDHolderDN -Properties *
        Write-Host "AdminSDHolder exists and is protecting privileged groups" -ForegroundColor Green
        Write-Host ""
        Write-Host "Protected groups (automatically by default):" -ForegroundColor Cyan
        $protectedGroups = @(
            "Account Operators", "Administrators", "Backup Operators",
            "Domain Admins", "Domain Controllers", "Enterprise Admins",
            "Print Operators", "Read-only Domain Controllers",
            "Replicator", "Schema Admins", "Server Operators"
        )
        foreach ($pg in $protectedGroups) {
            Write-Host "  - $pg" -ForegroundColor White
        }
    } catch {
        Write-Host "AdminSDHolder not accessible: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    Write-Host ""

    # Step 3: Audit group memberships
    Write-Host "[Step 3] Auditing Domain Admins group membership" -ForegroundColor Yellow

    try {
        $domainAdmins = Get-ADGroupMember -Identity "Domain Admins" -Recursive
        $domainAdminUsers = $domainAdmins | Where-Object { $_.objectClass -eq 'user' }
        $domainAdminGroups = $domainAdmins | Where-Object { $_.objectClass -eq 'group' }

        Write-Host "Domain Admins Analysis:" -ForegroundColor Cyan
        Write-Host "  Total members: $($domainAdmins.Count)" -ForegroundColor White
        Write-Host "  User accounts: $($domainAdminUsers.Count)" -ForegroundColor White
        Write-Host "  Nested groups: $($domainAdminGroups.Count)" -ForegroundColor White
        Write-Host ""

        if ($domainAdminUsers.Count -gt 5) {
            Write-Host "  [WARNING] Consider reducing Domain Admins membership" -ForegroundColor Yellow
            Write-Host "  Recommended: 2-3 emergency access accounts only" -ForegroundColor Cyan
        } else {
            Write-Host "  [GOOD] Domain Admins group has minimal membership" -ForegroundColor Green
        }

        Write-Host ""
        Write-Host "Domain Admin members:" -ForegroundColor Cyan
        foreach ($user in $domainAdminUsers | Select-Object -First 10) {
            Write-Host "  - $($user.Name) [$($user.SamAccountName)]" -ForegroundColor White
        }
    } catch {
        Write-Host "Could not enumerate Domain Admins: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    Write-Host ""

    # Step 4: Create administrative tier structure
    Write-Host "[Step 4] Administrative tier model" -ForegroundColor Yellow

    Write-Host "Microsoft Tiered Administration Model:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Tier 0 - Enterprise Admins (Domain Controllers, AD, Critical Systems)" -ForegroundColor White
    Write-Host "    Groups: Enterprise Admins, Schema Admins, Domain Admins" -ForegroundColor Gray
    Write-Host "    Scope: Forest-wide administrative rights" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Tier 1 - Server Admins (Application & Infrastructure Servers)" -ForegroundColor White
    Write-Host "    Groups: Server Admins (custom group)" -ForegroundColor Gray
    Write-Host "    Scope: Server management, application administration" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Tier 2 - Workstation Admins (User workstations, help desk)" -ForegroundColor White
    Write-Host "    Groups: Workstation Admins, Help Desk (custom groups)" -ForegroundColor Gray
    Write-Host "    Scope: User support, workstation management" -ForegroundColor Gray
    Write-Host ""

    # Create sample tier groups
    $tierGroups = @(
        @{Name="Tier0-Admins"; Description="Tier 0 - Domain and Infrastructure Administrators"; Scope="Global"},
        @{Name="Tier1-Admins"; Description="Tier 1 - Server Administrators"; Scope="Global"},
        @{Name="Tier2-Admins"; Description="Tier 2 - Workstation Administrators"; Scope="Global"}
    )

    Write-Host "Example tier group structure:" -ForegroundColor Cyan
    foreach ($tg in $tierGroups) {
        Write-Host "  Create: $($tg.Name)" -ForegroundColor White
        Write-Host "    Description: $($tg.Description)" -ForegroundColor Gray
        # Check if group exists
        $existingGroup = Get-ADGroup -Filter "Name -eq '$($tg.Name)'" -ErrorAction SilentlyContinue
        if ($existingGroup) {
            Write-Host "    Status: Already exists" -ForegroundColor Yellow
        } else {
            Write-Host "    Status: Would create with:" -ForegroundColor Cyan
            Write-Host "      New-ADGroup -Name '$($tg.Name)' -GroupScope $($tg.Scope) -Description '$($tg.Description)'" -ForegroundColor Gray
        }
    }
    Write-Host ""

    # Step 5: Implement group access reviews
    Write-Host "[Step 5] Privileged group access review" -ForegroundColor Yellow

    Write-Host "Generating access review report for privileged groups..." -ForegroundColor Cyan
    Write-Host ""

    $reviewGroups = @("Domain Admins", "Enterprise Admins", "Schema Admins")
    foreach ($reviewGroup in $reviewGroups) {
        try {
            $members = Get-ADGroupMember -Identity $reviewGroup -ErrorAction SilentlyContinue
            if ($members) {
                Write-Host "$reviewGroup Review:" -ForegroundColor Yellow
                foreach ($member in $members) {
                    if ($member.objectClass -eq 'user') {
                        $user = Get-ADUser -Identity $member.SamAccountName -Properties LastLogonDate, PasswordLastSet, Enabled
                        $lastLogon = if ($user.LastLogonDate) { $user.LastLogonDate.ToString("yyyy-MM-dd") } else { "Never" }
                        $pwdAge = if ($user.PasswordLastSet) { ((Get-Date) - $user.PasswordLastSet).Days } else { "N/A" }

                        Write-Host "  User: $($user.Name)" -ForegroundColor White
                        Write-Host "    Last Logon: $lastLogon | Password Age: $pwdAge days | Enabled: $($user.Enabled)" -ForegroundColor Gray
                    }
                }
                Write-Host ""
            }
        } catch {
            Write-Host "$reviewGroup`: Unable to review - $($_.Exception.Message)" -ForegroundColor Gray
        }
    }

    # Step 6: Configure group policy security
    Write-Host "[Step 6] Group security settings" -ForegroundColor Yellow

    Write-Host "Recommended security settings for administrative groups:" -ForegroundColor Cyan
    Write-Host "  1. Enable 'Deny log on locally' for service accounts" -ForegroundColor White
    Write-Host "  2. Enable 'Deny log on through Remote Desktop Services' for service accounts" -ForegroundColor White
    Write-Host "  3. Restrict 'Allow log on locally' to specific admin groups per tier" -ForegroundColor White
    Write-Host "  4. Use separate admin accounts (not elevating standard user accounts)" -ForegroundColor White
    Write-Host "  5. Implement time-based group membership with JIT access" -ForegroundColor White
    Write-Host ""

    # Step 7: Monitor group changes
    Write-Host "[Step 7] Monitoring administrative group changes" -ForegroundColor Yellow

    Write-Host "Checking recent group membership changes in Security log..." -ForegroundColor Cyan

    # Event IDs for group changes:
    # 4728 - Member added to security-enabled global group
    # 4729 - Member removed from security-enabled global group
    # 4732 - Member added to security-enabled local group
    # 4733 - Member removed from security-enabled local group
    # 4756 - Member added to security-enabled universal group
    # 4757 - Member removed from security-enabled universal group

    $groupChangeEvents = @(4728, 4729, 4732, 4733, 4756, 4757)

    try {
        $recentChanges = Get-WinEvent -FilterHashtable @{
            LogName = 'Security'
            ID = $groupChangeEvents
            StartTime = (Get-Date).AddDays(-7)
        } -MaxEvents 10 -ErrorAction SilentlyContinue

        if ($recentChanges) {
            Write-Host "Recent group membership changes (last 7 days):" -ForegroundColor White
            foreach ($event in $recentChanges | Select-Object -First 5) {
                Write-Host "  [$($event.TimeCreated)] Event $($event.Id)" -ForegroundColor Gray
                Write-Host "    $($event.Message.Split("`n")[0])" -ForegroundColor Gray
            }
        } else {
            Write-Host "No recent group membership changes found" -ForegroundColor White
        }
    } catch {
        Write-Host "Could not retrieve group change events: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    Write-Host ""

    Write-Host "To monitor group changes, enable auditing:" -ForegroundColor Cyan
    Write-Host '  auditpol /set /subcategory:"Security Group Management" /success:enable /failure:enable' -ForegroundColor White
    Write-Host ""

    # Step 8: Delegated administration
    Write-Host "[Step 8] Delegated administration best practices" -ForegroundColor Yellow

    Write-Host "Least privilege delegation recommendations:" -ForegroundColor Cyan
    Write-Host "  1. Create role-specific groups (e.g., Help Desk, Password Reset Admins)" -ForegroundColor White
    Write-Host "  2. Delegate only required permissions to specific OUs" -ForegroundColor White
    Write-Host "  3. Never add service accounts to admin groups" -ForegroundColor White
    Write-Host "  4. Regular quarterly review of all group memberships" -ForegroundColor White
    Write-Host "  5. Remove unnecessary nested groups" -ForegroundColor White
    Write-Host "  6. Document all delegated permissions" -ForegroundColor White
    Write-Host ""

    Write-Host "Example delegation groups:" -ForegroundColor Cyan
    $delegationGroups = @(
        @{Name="HelpDesk-PasswordReset"; Permissions="Reset passwords, unlock accounts"},
        @{Name="HelpDesk-GroupManagement"; Permissions="Add/remove users from non-privileged groups"},
        @{Name="Server-Operators"; Permissions="Manage specific server OUs"},
        @{Name="Workstation-Operators"; Permissions="Join computers to domain, manage workstation OUs"}
    )

    foreach ($dg in $delegationGroups) {
        Write-Host "  $($dg.Name)" -ForegroundColor White
        Write-Host "    Permissions: $($dg.Permissions)" -ForegroundColor Gray
    }
    Write-Host ""

    # Step 9: Administrative account naming
    Write-Host "[Step 9] Administrative account naming conventions" -ForegroundColor Yellow

    Write-Host "Recommended naming conventions:" -ForegroundColor Cyan
    Write-Host "  Regular User: john.doe" -ForegroundColor White
    Write-Host "  Admin Account (Tier 2): john.doe-wa (workstation admin)" -ForegroundColor White
    Write-Host "  Admin Account (Tier 1): john.doe-sa (server admin)" -ForegroundColor White
    Write-Host "  Admin Account (Tier 0): john.doe-da (domain admin)" -ForegroundColor White
    Write-Host ""
    Write-Host "Benefits:" -ForegroundColor Cyan
    Write-Host "  - Clear identification of privilege level" -ForegroundColor White
    Write-Host "  - Easier auditing and tracking" -ForegroundColor White
    Write-Host "  - Separation of duties enforcement" -ForegroundColor White
    Write-Host "  - Reduced credential theft impact" -ForegroundColor White
    Write-Host ""

    # Step 10: Best practices summary
    Write-Host "[Step 10] Administrative Group Security Best Practices" -ForegroundColor Yellow
    Write-Host "  1. Minimize Domain Admins membership (2-3 emergency accounts only)" -ForegroundColor White
    Write-Host "  2. Implement tiered administration model (Tier 0/1/2)" -ForegroundColor White
    Write-Host "  3. Use separate admin accounts per tier (never elevate regular user accounts)" -ForegroundColor White
    Write-Host "  4. Enable comprehensive auditing of group membership changes" -ForegroundColor White
    Write-Host "  5. Conduct quarterly access reviews of all privileged groups" -ForegroundColor White
    Write-Host "  6. Never nest groups unnecessarily" -ForegroundColor White
    Write-Host "  7. Use delegation groups instead of adding users to built-in admin groups" -ForegroundColor White
    Write-Host "  8. Protect admin accounts with MFA, smart cards, or Windows Hello" -ForegroundColor White
    Write-Host "  9. Use Privileged Access Workstations (PAWs) for Tier 0 administration" -ForegroundColor White
    Write-Host "  10. Implement Just-In-Time (JIT) access for temporary admin permissions" -ForegroundColor White
    Write-Host ""

    Write-Host "[INFO] Monitoring Commands:" -ForegroundColor Cyan
    Write-Host '  List all privileged group members: Get-ADGroupMember -Identity "Domain Admins"' -ForegroundColor White
    Write-Host '  Find all groups a user belongs to: Get-ADPrincipalGroupMembership -Identity "username"' -ForegroundColor White
    Write-Host '  Export group membership: Get-ADGroupMember -Identity "Group" | Export-Csv report.csv' -ForegroundColor White
    Write-Host ""

} catch {
    Write-Host "[ERROR] $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

Write-Host "Demo completed successfully!" -ForegroundColor Green
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Review all privileged group memberships" -ForegroundColor White
Write-Host "  2. Implement tiered administration model" -ForegroundColor White
Write-Host "  3. Create delegation groups for specific administrative tasks" -ForegroundColor White
Write-Host "  4. Enable auditing for group membership changes" -ForegroundColor White
Write-Host "  5. Establish quarterly access review process" -ForegroundColor White
