<#
.SYNOPSIS
    Task 3.2 - Configure Read-Only Domain Controller Security

.DESCRIPTION
    Demo script for AZ-801 Module 3: Manage Protected Users and RODCs
    Demonstrates RODC configuration, password replication policies, and security best practices.

.NOTES
    Module: Module 3 - Manage Protected Users and RODCs
    Task: 3.2 - Configure RODC Security

    Prerequisites:
    - Active Directory Domain Services
    - Domain Administrator privileges
    - AD PowerShell module
    - Windows Server 2008 R2 or later

    PowerShell Version: 5.1+
#>

#Requires -RunAsAdministrator

$ErrorActionPreference = 'Stop'

Write-Host "=== AZ-801 Module 3: Task 3.2 - RODC Security ===" -ForegroundColor Cyan
Write-Host ""

try {
    # Section 1: Check AD environment and import module
    Write-Host "[Step 1] Checking Active Directory environment" -ForegroundColor Yellow

    if (Get-Module -ListAvailable -Name ActiveDirectory) {
        Import-Module ActiveDirectory -ErrorAction SilentlyContinue
        Write-Host "[SUCCESS] Active Directory module loaded" -ForegroundColor Green
    } else {
        Write-Host "[WARNING] Active Directory module not available" -ForegroundColor Yellow
        Write-Host "Install with: Install-WindowsFeature RSAT-AD-PowerShell" -ForegroundColor White
    }

    $domain = Get-ADDomain -ErrorAction SilentlyContinue
    if ($domain) {
        Write-Host "Domain: $($domain.DNSRoot)" -ForegroundColor White
        Write-Host "Domain Functional Level: $($domain.DomainMode)" -ForegroundColor White
    }
    Write-Host ""

    # Section 2: Discover RODCs in the domain
    Write-Host "[Step 2] Discovering Read-Only Domain Controllers" -ForegroundColor Yellow

    $rodcs = Get-ADDomainController -Filter {IsReadOnly -eq $true} -ErrorAction SilentlyContinue

    if ($rodcs) {
        Write-Host "`nFound $($rodcs.Count) RODC(s) in domain:" -ForegroundColor Cyan
        foreach ($rodc in $rodcs) {
            Write-Host "  RODC Name: $($rodc.Name)" -ForegroundColor White
            Write-Host "    Hostname: $($rodc.HostName)" -ForegroundColor White
            Write-Host "    Site: $($rodc.Site)" -ForegroundColor White
            Write-Host "    OS Version: $($rodc.OperatingSystem)" -ForegroundColor White
            Write-Host "    IP Address: $($rodc.IPv4Address)" -ForegroundColor White
            Write-Host ""
        }
        Write-Host "[SUCCESS] RODCs discovered" -ForegroundColor Green
    } else {
        Write-Host "[INFO] No RODCs currently deployed in domain" -ForegroundColor Yellow
        Write-Host "RODCs are typically deployed in:" -ForegroundColor White
        Write-Host "  - Branch offices with limited physical security" -ForegroundColor White
        Write-Host "  - DMZ networks" -ForegroundColor White
        Write-Host "  - Locations with unreliable WAN connections" -ForegroundColor White
    }
    Write-Host ""

    # Section 3: Password Replication Policy Groups
    Write-Host "[Step 3] Password Replication Policy (PRP) Groups" -ForegroundColor Yellow

    Write-Host "`nDefault PRP Groups:" -ForegroundColor Cyan

    # Check Allowed RODC Password Replication Group
    $allowedGroup = Get-ADGroup -Identity "Allowed RODC Password Replication Group" -Properties Members -ErrorAction SilentlyContinue
    if ($allowedGroup) {
        Write-Host "Allowed RODC Password Replication Group:" -ForegroundColor White
        Write-Host "  DN: $($allowedGroup.DistinguishedName)" -ForegroundColor White
        Write-Host "  Members: $($allowedGroup.Members.Count)" -ForegroundColor White
        if ($allowedGroup.Members) {
            $allowedGroup.Members | Select-Object -First 5 | ForEach-Object {
                $member = Get-ADObject -Identity $_ -Properties Name
                Write-Host "    - $($member.Name)" -ForegroundColor White
            }
        }
    }
    Write-Host ""

    # Check Denied RODC Password Replication Group
    $deniedGroup = Get-ADGroup -Identity "Denied RODC Password Replication Group" -Properties Members -ErrorAction SilentlyContinue
    if ($deniedGroup) {
        Write-Host "Denied RODC Password Replication Group:" -ForegroundColor White
        Write-Host "  DN: $($deniedGroup.DistinguishedName)" -ForegroundColor White
        Write-Host "  Members: $($deniedGroup.Members.Count)" -ForegroundColor White
        if ($deniedGroup.Members) {
            Write-Host "  Default high-privilege groups (should always be denied):" -ForegroundColor White
            $deniedGroup.Members | Select-Object -First 10 | ForEach-Object {
                $member = Get-ADObject -Identity $_ -Properties Name
                Write-Host "    - $($member.Name)" -ForegroundColor White
            }
        }
    }

    Write-Host "[SUCCESS] PRP groups reviewed" -ForegroundColor Green
    Write-Host ""

    # Section 4: Manage Password Replication Policy
    Write-Host "[Step 4] Managing Password Replication Policy" -ForegroundColor Yellow

    Write-Host "`nAdd users/groups to Allowed PRP:" -ForegroundColor Cyan
    Write-Host "  Add-ADGroupMember -Identity 'Allowed RODC Password Replication Group' ``" -ForegroundColor White
    Write-Host "    -Members 'BranchUsers','BranchComputers'" -ForegroundColor White
    Write-Host ""

    Write-Host "Add sensitive accounts to Denied PRP:" -ForegroundColor Cyan
    Write-Host "  Add-ADGroupMember -Identity 'Denied RODC Password Replication Group' ``" -ForegroundColor White
    Write-Host "    -Members 'ServiceAccounts','VIPUsers'" -ForegroundColor White
    Write-Host ""

    Write-Host "Configure per-RODC Password Replication Policy:" -ForegroundColor Cyan
    Write-Host "  # Set allowed accounts for specific RODC" -ForegroundColor White
    Write-Host "  Set-ADAccountControl -Identity 'CN=RODC01,OU=Domain Controllers,DC=contoso,DC=com' ``" -ForegroundColor White
    Write-Host "    -AllowReversiblePasswordEncryption `$false" -ForegroundColor White
    Write-Host ""

    # Section 5: Check revealed passwords (if RODC exists)
    if ($rodcs) {
        Write-Host "[Step 5] Checking revealed passwords on RODCs" -ForegroundColor Yellow

        foreach ($rodc in $rodcs | Select-Object -First 1) {
            Write-Host "`nChecking RODC: $($rodc.Name)" -ForegroundColor Cyan

            # Get revealed accounts
            $revealedAccounts = Get-ADDomainControllerPasswordReplicationPolicy -Identity $rodc.Name -Revealed -ErrorAction SilentlyContinue

            if ($revealedAccounts) {
                Write-Host "Passwords cached on RODC: $($revealedAccounts.Count)" -ForegroundColor White
                Write-Host "Sample of cached accounts:" -ForegroundColor White
                $revealedAccounts | Select-Object -First 10 | ForEach-Object {
                    Write-Host "  - $($_.Name) ($($_.ObjectClass))" -ForegroundColor White
                }
            } else {
                Write-Host "No passwords currently cached on this RODC" -ForegroundColor Yellow
            }

            # Get accounts denied replication
            $deniedAccounts = Get-ADDomainControllerPasswordReplicationPolicy -Identity $rodc.Name -Denied -ErrorAction SilentlyContinue
            Write-Host "`nAccounts explicitly denied replication: $($deniedAccounts.Count)" -ForegroundColor White
        }

        Write-Host "`nCommands to manage revealed passwords:" -ForegroundColor Cyan
        Write-Host "  # Prepopulate passwords for specific users" -ForegroundColor White
        Write-Host "  Sync-ADObject -Object 'CN=User,DC=contoso,DC=com' ``" -ForegroundColor White
        Write-Host "    -Destination 'RODC01.contoso.com'" -ForegroundColor White
        Write-Host ""
        Write-Host "  # Remove cached credentials" -ForegroundColor White
        Write-Host "  Reset-ADAccountPassword -Identity 'username'" -ForegroundColor White

        Write-Host ""
    }

    # Section 6: RODC Administrator Role Separation
    Write-Host "[Step 6] RODC Administrator Role Separation" -ForegroundColor Yellow

    Write-Host "`nRODC Local Administrator:" -ForegroundColor Cyan
    Write-Host "  Grant local admin rights without domain-wide privileges" -ForegroundColor White
    Write-Host ""
    Write-Host "Command to delegate RODC administration:" -ForegroundColor Cyan
    Write-Host "  Add-ADPrincipalGroupMembership -Identity 'BranchAdmin' ``" -ForegroundColor White
    Write-Host "    -MemberOf 'CN=Managed By,CN=RODC01,OU=Domain Controllers,DC=contoso,DC=com'" -ForegroundColor White
    Write-Host ""
    Write-Host "  Or during RODC installation:" -ForegroundColor White
    Write-Host "  Install-ADDSDomainController -DomainName 'contoso.com' ``" -ForegroundColor White
    Write-Host "    -ReadOnlyReplica ``" -ForegroundColor White
    Write-Host "    -DelegatedAdministratorAccountName 'CONTOSO\BranchAdmin'" -ForegroundColor White
    Write-Host ""

    # Section 7: RODC Filtered Attribute Set
    Write-Host "[Step 7] RODC Filtered Attribute Set (FAS)" -ForegroundColor Yellow

    Write-Host "`nWhat is Filtered Attribute Set?" -ForegroundColor Cyan
    Write-Host "  - Prevents specific AD attributes from replicating to RODCs" -ForegroundColor White
    Write-Host "  - Protects sensitive data in branch offices" -ForegroundColor White
    Write-Host "  - Default: confidential attributes are filtered" -ForegroundColor White
    Write-Host ""

    Write-Host "View FAS attributes:" -ForegroundColor Cyan
    Write-Host "  Get-ADObject -SearchBase (Get-ADRootDSE).SchemaNamingContext ``" -ForegroundColor White
    Write-Host "    -Filter {searchFlags -band 512} ``" -ForegroundColor White
    Write-Host "    -Properties lDAPDisplayName,searchFlags" -ForegroundColor White
    Write-Host ""

    Write-Host "Mark attribute as confidential (filtered):" -ForegroundColor Cyan
    Write-Host "  `$attribute = Get-ADObject -SearchBase (Get-ADRootDSE).SchemaNamingContext ``" -ForegroundColor White
    Write-Host "    -Filter {lDAPDisplayName -eq 'attributeName'}" -ForegroundColor White
    Write-Host "  Set-ADObject `$attribute -Add @{searchFlags=512}" -ForegroundColor White
    Write-Host ""

    # Section 8: Security audit and monitoring
    Write-Host "[Step 8] RODC Security Auditing" -ForegroundColor Yellow

    Write-Host "`nMonitor RODC events:" -ForegroundColor Cyan
    Write-Host "  Event ID 4742: Computer account was changed (RODC)" -ForegroundColor White
    Write-Host "  Event ID 4624: Successful logon to RODC" -ForegroundColor White
    Write-Host "  Event ID 4625: Failed logon attempt" -ForegroundColor White
    Write-Host "  Event ID 4929: Active Directory replica source naming context was removed" -ForegroundColor White
    Write-Host ""

    Write-Host "Regular audit tasks:" -ForegroundColor Cyan
    Write-Host "  - Review revealed password list quarterly" -ForegroundColor White
    Write-Host "  - Verify PRP group membership" -ForegroundColor White
    Write-Host "  - Check for unauthorized RODC installations" -ForegroundColor White
    Write-Host "  - Review RODC administrator delegations" -ForegroundColor White
    Write-Host "  - Monitor replication health" -ForegroundColor White
    Write-Host ""

    # Section 9: RODC deployment guidance
    Write-Host "[Step 9] RODC Deployment Best Practices" -ForegroundColor Yellow

    Write-Host "`nWhen to deploy RODCs:" -ForegroundColor Cyan
    Write-Host "  ✓ Branch offices with limited physical security" -ForegroundColor White
    Write-Host "  ✓ Locations with unreliable WAN connectivity" -ForegroundColor White
    Write-Host "  ✓ DMZ environments" -ForegroundColor White
    Write-Host "  ✓ Locations where local IT expertise is limited" -ForegroundColor White
    Write-Host ""

    Write-Host "RODC Security Best Practices:" -ForegroundColor Cyan
    Write-Host "  - Keep Denied PRP group current (add all privileged accounts)" -ForegroundColor White
    Write-Host "  - Minimize Allowed PRP group (only necessary accounts)" -ForegroundColor White
    Write-Host "  - Use role separation for RODC administration" -ForegroundColor White
    Write-Host "  - Regular review of cached credentials" -ForegroundColor White
    Write-Host "  - Implement physical security measures" -ForegroundColor White
    Write-Host "  - Monitor replication and authentication events" -ForegroundColor White
    Write-Host "  - Consider BitLocker for RODC volumes" -ForegroundColor White
    Write-Host "  - Use Filtered Attribute Set for sensitive data" -ForegroundColor White
    Write-Host ""

    Write-Host "RODC Limitations:" -ForegroundColor Cyan
    Write-Host "  - Cannot perform write operations (read-only)" -ForegroundColor White
    Write-Host "  - Password changes redirected to writable DC" -ForegroundColor White
    Write-Host "  - Cannot be Global Catalog server" -ForegroundColor White
    Write-Host "  - Cannot be FSMO role holder" -ForegroundColor White
    Write-Host "  - Requires Windows Server 2008+ domain functional level" -ForegroundColor White
    Write-Host ""

    # Section 10: RODC disaster recovery
    Write-Host "[Step 10] RODC Disaster Recovery Considerations" -ForegroundColor Yellow

    Write-Host "`nIf RODC is compromised:" -ForegroundColor Cyan
    Write-Host "  1. Isolate the RODC from network" -ForegroundColor White
    Write-Host "  2. Identify cached credentials:" -ForegroundColor White
    Write-Host "     Get-ADDomainControllerPasswordReplicationPolicy -Identity RODC01 -Revealed" -ForegroundColor White
    Write-Host "  3. Reset passwords for all revealed accounts" -ForegroundColor White
    Write-Host "  4. Remove RODC from domain:" -ForegroundColor White
    Write-Host "     Uninstall-ADDSDomainController -ForceRemoval" -ForegroundColor White
    Write-Host "  5. Clean up metadata:" -ForegroundColor White
    Write-Host "     Remove-ADDomainController -Identity RODC01" -ForegroundColor White
    Write-Host "  6. Investigate security breach" -ForegroundColor White
    Write-Host "  7. Rebuild RODC with hardened configuration" -ForegroundColor White
    Write-Host ""

    Write-Host "[SUCCESS] RODC security configuration review complete" -ForegroundColor Green
    Write-Host ""

} catch {
    Write-Host "[ERROR] $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

Write-Host "Demo completed successfully!" -ForegroundColor Green
Write-Host "Next Steps: Deploy RODC in branch locations and configure PRP appropriately" -ForegroundColor Yellow
