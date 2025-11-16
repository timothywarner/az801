<#
.SYNOPSIS
    Task 4.5 - Configure Active Directory Delegation
.DESCRIPTION
    Comprehensive demonstration of Active Directory permission delegation.
    Implements least-privilege delegation for common administrative tasks.
.EXAMPLE
    .\task-4.5-ad-delegation.ps1
.NOTES
    Module: Module 4 - Configure Advanced Domain Security
    Task: 4.5 - Configure Active Directory Delegation
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

Write-Host "=== AZ-801 Module 4: Task 4.5 - Configure Active Directory Delegation ===" -ForegroundColor Cyan
Write-Host ""

try {
    # Step 1: Review current OU structure
    Write-Host "[Step 1] Reviewing OU structure" -ForegroundColor Yellow

    $domain = Get-ADDomain
    $domainDN = $domain.DistinguishedName

    Write-Host "Domain: $($domain.DNSRoot)" -ForegroundColor White
    Write-Host "Domain DN: $domainDN" -ForegroundColor White
    Write-Host ""

    # Get all OUs
    $ous = Get-ADOrganizationalUnit -Filter * | Select-Object -First 10 Name, DistinguishedName
    if ($ous) {
        Write-Host "Sample OUs in domain (first 10):" -ForegroundColor Cyan
        foreach ($ou in $ous) {
            Write-Host "  - $($ou.Name)" -ForegroundColor White
            Write-Host "    $($ou.DistinguishedName)" -ForegroundColor Gray
        }
    }
    Write-Host ""

    # Step 2: Common delegation scenarios
    Write-Host "[Step 2] Common delegation scenarios" -ForegroundColor Yellow

    $delegationScenarios = @(
        @{
            Task = "Password Reset"
            Permissions = "Reset Password, Change Password"
            Group = "HelpDesk-PasswordReset"
            Risk = "Low"
        },
        @{
            Task = "Account Unlock"
            Permissions = "Write lockoutTime"
            Group = "HelpDesk-AccountUnlock"
            Risk = "Low"
        },
        @{
            Task = "Group Management"
            Permissions = "Create/Delete groups, Modify group membership"
            Group = "IT-GroupAdmins"
            Risk = "Medium"
        },
        @{
            Task = "User Account Creation"
            Permissions = "Create/Delete user objects"
            Group = "IT-UserAdmins"
            Risk = "Medium"
        },
        @{
            Task = "Computer Join Domain"
            Permissions = "Create/Delete computer objects"
            Group = "IT-ComputerAdmins"
            Risk = "Medium"
        }
    )

    Write-Host "Common delegation scenarios:" -ForegroundColor Cyan
    foreach ($scenario in $delegationScenarios) {
        Write-Host ""
        Write-Host "  Task: $($scenario.Task)" -ForegroundColor Yellow
        Write-Host "    Permissions Needed: $($scenario.Permissions)" -ForegroundColor White
        Write-Host "    Delegation Group: $($scenario.Group)" -ForegroundColor White
        Write-Host "    Risk Level: $($scenario.Risk)" -ForegroundColor White
    }
    Write-Host ""

    # Step 3: View current permissions on an OU
    Write-Host "[Step 3] Reviewing current OU permissions" -ForegroundColor Yellow

    # Get first OU for demonstration
    $sampleOU = Get-ADOrganizationalUnit -Filter * | Select-Object -First 1

    if ($sampleOU) {
        Write-Host "Sample OU: $($sampleOU.Name)" -ForegroundColor Cyan
        Write-Host "Distinguished Name: $($sampleOU.DistinguishedName)" -ForegroundColor White
        Write-Host ""

        try {
            $acl = Get-Acl -Path "AD:$($sampleOU.DistinguishedName)"
            $accessRules = $acl.Access | Where-Object { $_.IsInherited -eq $false } | Select-Object -First 5

            if ($accessRules) {
                Write-Host "Sample non-inherited permissions (first 5):" -ForegroundColor Cyan
                foreach ($rule in $accessRules) {
                    Write-Host "  $($rule.IdentityReference)" -ForegroundColor White
                    Write-Host "    Rights: $($rule.ActiveDirectoryRights)" -ForegroundColor Gray
                    Write-Host "    Type: $($rule.AccessControlType)" -ForegroundColor Gray
                }
            } else {
                Write-Host "No explicit (non-inherited) permissions set" -ForegroundColor White
            }
        } catch {
            Write-Host "Could not retrieve ACL: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
    Write-Host ""

    # Step 4: Delegate password reset permissions
    Write-Host "[Step 4] Delegating password reset permissions" -ForegroundColor Yellow

    Write-Host "Example: Delegate password reset to Help Desk group" -ForegroundColor Cyan
    Write-Host ""

    $delegationExample = @'
# Create delegation group if it doesn't exist
$groupName = "HelpDesk-PasswordReset"
$targetOU = "OU=Users,DC=contoso,DC=com"

# Check if group exists
if (-not (Get-ADGroup -Filter "Name -eq '$groupName'" -ErrorAction SilentlyContinue)) {
    New-ADGroup -Name $groupName -GroupScope Global -Description "Help Desk - Password Reset Delegation"
}

# Get the group SID
$group = Get-ADGroup -Identity $groupName
$groupSID = New-Object System.Security.Principal.SecurityIdentifier $group.SID

# Get the OU ACL
$acl = Get-Acl -Path "AD:$targetOU"

# Create ACE for Reset Password permission
$identity = [System.Security.Principal.IdentityReference] $groupSID
$adRights = [System.DirectoryServices.ActiveDirectoryRights]::ExtendedRight
$type = [System.Security.AccessControl.AccessControlType]::Allow
$guidResetPwd = New-Object Guid 00299570-246d-11d0-a768-00aa006e0529  # Reset Password
$inheritanceType = [System.DirectoryServices.ActiveDirectorySecurityInheritance]::Descendents
$inheritedObjectType = New-Object Guid bf967aba-0de6-11d0-a285-00aa003049e2  # User class

$ace = New-Object System.DirectoryServices.ActiveDirectoryAccessRule($identity, $adRights, $type, $guidResetPwd, $inheritanceType, $inheritedObjectType)

# Add the ACE and apply
$acl.AddAccessRule($ace)
Set-Acl -Path "AD:$targetOU" -AclObject $acl
'@

    Write-Host $delegationExample -ForegroundColor White
    Write-Host ""

    # Step 5: Delegate group management
    Write-Host "[Step 5] Delegating group management permissions" -ForegroundColor Yellow

    Write-Host "Example GUIDs for common delegation tasks:" -ForegroundColor Cyan
    $commonGUIDs = @(
        @{Task="Reset Password"; GUID="00299570-246d-11d0-a768-00aa006e0529"},
        @{Task="Change Password"; GUID="ab721a53-1e2f-11d0-9819-00aa0040529b"},
        @{Task="Read All Properties"; GUID="00000000-0000-0000-0000-000000000000"},
        @{Task="Write All Properties"; GUID="00000000-0000-0000-0000-000000000000"},
        @{Task="Create User Objects"; GUID="bf967aba-0de6-11d0-a285-00aa003049e2"},
        @{Task="Create Group Objects"; GUID="bf967a9c-0de6-11d0-a285-00aa003049e2"},
        @{Task="Create Computer Objects"; GUID="bf967a86-0de6-11d0-a285-00aa003049e2"}
    )

    Write-Host ""
    foreach ($guid in $commonGUIDs) {
        Write-Host "  $($guid.Task):" -ForegroundColor White
        Write-Host "    $($guid.GUID)" -ForegroundColor Gray
    }
    Write-Host ""

    # Step 6: Using Active Directory Users and Computers delegation wizard
    Write-Host "[Step 6] GUI-based delegation (Active Directory Users and Computers)" -ForegroundColor Yellow

    Write-Host "Using the Delegation of Control Wizard:" -ForegroundColor Cyan
    Write-Host "  1. Open Active Directory Users and Computers" -ForegroundColor White
    Write-Host "  2. Right-click the OU > Delegate Control" -ForegroundColor White
    Write-Host "  3. Add users or groups to delegate to" -ForegroundColor White
    Write-Host "  4. Select tasks to delegate:" -ForegroundColor White
    Write-Host "     - Create, delete, and manage user accounts" -ForegroundColor Gray
    Write-Host "     - Reset user passwords and force password change at next logon" -ForegroundColor Gray
    Write-Host "     - Read all user information" -ForegroundColor Gray
    Write-Host "     - Create, delete, and manage groups" -ForegroundColor Gray
    Write-Host "     - Modify the membership of a group" -ForegroundColor Gray
    Write-Host "     - Join a computer to a domain" -ForegroundColor Gray
    Write-Host "  5. Complete the wizard" -ForegroundColor White
    Write-Host ""

    # Step 7: Verify delegated permissions
    Write-Host "[Step 7] Verifying delegated permissions" -ForegroundColor Yellow

    Write-Host "To verify delegation, check the OU's ACL:" -ForegroundColor Cyan
    Write-Host '  Get-Acl -Path "AD:OU=Users,DC=contoso,DC=com" | Select-Object -ExpandProperty Access' -ForegroundColor White
    Write-Host ""
    Write-Host "Filter for specific group:" -ForegroundColor Cyan
    Write-Host '  $acl = Get-Acl -Path "AD:OU=Users,DC=contoso,DC=com"' -ForegroundColor White
    Write-Host '  $acl.Access | Where-Object {$_.IdentityReference -like "*HelpDesk*"}' -ForegroundColor White
    Write-Host ""

    # Step 8: Remove delegated permissions
    Write-Host "[Step 8] Removing delegated permissions" -ForegroundColor Yellow

    $removalExample = @'
# Example: Remove specific delegation
$targetOU = "OU=Users,DC=contoso,DC=com"
$groupName = "HelpDesk-PasswordReset"

# Get the ACL
$acl = Get-Acl -Path "AD:$targetOU"

# Get the group
$group = Get-ADGroup -Identity $groupName
$groupSID = New-Object System.Security.Principal.SecurityIdentifier $group.SID

# Find and remove matching ACEs
$acl.Access | Where-Object {$_.IdentityReference -eq $groupSID} | ForEach-Object {
    $acl.RemoveAccessRule($_)
}

# Apply the changes
Set-Acl -Path "AD:$targetOU" -AclObject $acl
'@

    Write-Host $removalExample -ForegroundColor White
    Write-Host ""

    # Step 9: Best practices for delegation
    Write-Host "[Step 9] Delegation Best Practices" -ForegroundColor Yellow

    Write-Host "  1. Principle of Least Privilege: Only grant minimum required permissions" -ForegroundColor White
    Write-Host "  2. Use Groups: Always delegate to groups, never individual users" -ForegroundColor White
    Write-Host "  3. Document Everything: Maintain a delegation matrix" -ForegroundColor White
    Write-Host "  4. Regular Audits: Review delegations quarterly" -ForegroundColor White
    Write-Host "  5. OU Structure: Organize OUs to support delegation requirements" -ForegroundColor White
    Write-Host "  6. Test First: Test delegations in non-production OU" -ForegroundColor White
    Write-Host "  7. Avoid Over-Delegation: Don't delegate full control unless absolutely necessary" -ForegroundColor White
    Write-Host "  8. Use Specific Permissions: Delegate specific tasks, not broad permissions" -ForegroundColor White
    Write-Host "  9. Monitor Usage: Track who uses delegated permissions" -ForegroundColor White
    Write-Host "  10. Remove When Done: Remove delegations that are no longer needed" -ForegroundColor White
    Write-Host ""

    # Step 10: Delegation monitoring
    Write-Host "[Step 10] Monitoring delegated permissions" -ForegroundColor Yellow

    Write-Host "Commands to audit delegation:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "List all non-inherited permissions on an OU:" -ForegroundColor White
    Write-Host '  $acl = Get-Acl "AD:OU=Users,DC=contoso,DC=com"' -ForegroundColor Gray
    Write-Host '  $acl.Access | Where-Object {-not $_.IsInherited} | Format-Table IdentityReference, ActiveDirectoryRights' -ForegroundColor Gray
    Write-Host ""
    Write-Host "Export delegation report:" -ForegroundColor White
    Write-Host '  Get-ADOrganizationalUnit -Filter * | ForEach-Object {' -ForegroundColor Gray
    Write-Host '      $ou = $_' -ForegroundColor Gray
    Write-Host '      $acl = Get-Acl "AD:$($ou.DistinguishedName)"' -ForegroundColor Gray
    Write-Host '      $acl.Access | Where-Object {-not $_.IsInherited} | Select-Object @{N="OU";E={$ou.Name}}, IdentityReference, ActiveDirectoryRights' -ForegroundColor Gray
    Write-Host '  } | Export-Csv delegation-report.csv' -ForegroundColor Gray
    Write-Host ""

    Write-Host "[INFO] PowerShell Module for Advanced Delegation:" -ForegroundColor Cyan
    Write-Host "  Consider using: DsAcls.exe command-line tool" -ForegroundColor White
    Write-Host "  Or: PowerShell AD module with System.DirectoryServices namespace" -ForegroundColor White
    Write-Host ""

} catch {
    Write-Host "[ERROR] $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

Write-Host "Demo completed successfully!" -ForegroundColor Green
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Plan delegation structure based on OU design" -ForegroundColor White
Write-Host "  2. Create delegation groups for specific tasks" -ForegroundColor White
Write-Host "  3. Implement least-privilege delegations" -ForegroundColor White
Write-Host "  4. Document all delegations in a matrix" -ForegroundColor White
Write-Host "  5. Schedule quarterly audits of all delegated permissions" -ForegroundColor White
