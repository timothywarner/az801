<#
.SYNOPSIS
    Task 4.2 - Restrict Domain Controller Access
.DESCRIPTION
    Comprehensive demonstration of restricting and securing domain controller access.
    Implements best practices for DC security including GPO restrictions, logon rights,
    and network access controls.
.EXAMPLE
    .\task-4.2-restrict-dc-access.ps1
.NOTES
    Module: Module 4 - Configure Advanced Domain Security
    Task: 4.2 - Restrict Domain Controller Access
    Prerequisites:
    - Windows Server Domain Controller
    - ActiveDirectory PowerShell module
    - GroupPolicy PowerShell module
    - Domain Admin or equivalent permissions
    PowerShell Version: 5.1+
#>

#Requires -RunAsAdministrator
#Requires -Modules ActiveDirectory

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

Write-Host "=== AZ-801 Module 4: Task 4.2 - Restrict Domain Controller Access ===" -ForegroundColor Cyan
Write-Host ""

try {
    # Step 1: Identify domain controllers
    Write-Host "[Step 1] Identifying domain controllers" -ForegroundColor Yellow

    $domainControllers = Get-ADDomainController -Filter *
    Write-Host "Found $($domainControllers.Count) domain controller(s):" -ForegroundColor White
    foreach ($dc in $domainControllers) {
        Write-Host "  - $($dc.Name) ($($dc.IPv4Address))" -ForegroundColor Cyan
        Write-Host "    Site: $($dc.Site) | OS: $($dc.OperatingSystem)" -ForegroundColor Gray
    }
    Write-Host ""

    # Step 2: Check current DC security settings
    Write-Host "[Step 2] Checking current domain controller security settings" -ForegroundColor Yellow

    # Check if running on a DC
    $isDC = (Get-WmiObject -Class Win32_ComputerSystem).DomainRole -ge 4
    if ($isDC) {
        Write-Host "This server is a Domain Controller" -ForegroundColor Green

        # Check local security policy settings
        Write-Host ""
        Write-Host "Checking local security policy settings..." -ForegroundColor Cyan

        # Export current security policy to temp file
        $tempFile = [System.IO.Path]::GetTempFileName()
        $null = secedit /export /cfg $tempFile /quiet

        if (Test-Path $tempFile) {
            $secPolicy = Get-Content $tempFile
            Write-Host "Current security policy exported for review" -ForegroundColor White

            # Check for interactive logon restrictions
            $interactiveLogon = $secPolicy | Select-String "SeInteractiveLogonRight"
            if ($interactiveLogon) {
                Write-Host "Interactive logon rights: $($interactiveLogon -replace '.*= ','')" -ForegroundColor Gray
            }

            Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
        }
    } else {
        Write-Host "This server is NOT a Domain Controller" -ForegroundColor Yellow
        Write-Host "Demo will show DC security configuration commands" -ForegroundColor Cyan
    }
    Write-Host ""

    # Step 3: Create or configure DC security GPO
    Write-Host "[Step 3] Configuring Domain Controller security GPO" -ForegroundColor Yellow

    # Import GroupPolicy module if available
    if (Get-Module -ListAvailable -Name GroupPolicy) {
        Import-Module GroupPolicy -ErrorAction SilentlyContinue

        $gpoName = "DC-Security-Restrictions"
        Write-Host "Checking for GPO: $gpoName" -ForegroundColor Cyan

        try {
            $gpo = Get-GPO -Name $gpoName -ErrorAction SilentlyContinue
            if ($gpo) {
                Write-Host "  GPO already exists: $($gpo.DisplayName)" -ForegroundColor Yellow
                Write-Host "  GUID: $($gpo.Id)" -ForegroundColor Gray
                Write-Host "  Created: $($gpo.CreationTime)" -ForegroundColor Gray
            } else {
                Write-Host "  Creating new GPO: $gpoName" -ForegroundColor Cyan
                # New-GPO -Name $gpoName -Comment "Restricts access to Domain Controllers"
                Write-Host "  [DEMO] Would create: New-GPO -Name '$gpoName'" -ForegroundColor White
            }
        } catch {
            Write-Host "  [INFO] Could not manage GPO: $($_.Exception.Message)" -ForegroundColor Yellow
        }

        # Link GPO to Domain Controllers OU
        $dcOU = (Get-ADDomain).DomainControllersContainer
        Write-Host ""
        Write-Host "Domain Controllers OU: $dcOU" -ForegroundColor White
        Write-Host "  [DEMO] Would link GPO: New-GPLink -Name '$gpoName' -Target '$dcOU'" -ForegroundColor Cyan
    } else {
        Write-Host "[INFO] GroupPolicy module not available" -ForegroundColor Yellow
        Write-Host "Install with: Install-WindowsFeature -Name GPMC" -ForegroundColor Cyan
    }
    Write-Host ""

    # Step 4: Configure user rights assignments
    Write-Host "[Step 4] Recommended user rights assignments for DCs" -ForegroundColor Yellow

    $userRights = @{
        "Allow log on locally" = "Administrators, Backup Operators"
        "Allow log on through Remote Desktop Services" = "Administrators"
        "Deny log on locally" = "Guests"
        "Deny access to this computer from the network" = "Guests, Local account"
        "Deny log on through Remote Desktop Services" = "Guests, Local account"
    }

    Write-Host "Recommended DC logon rights configuration:" -ForegroundColor Cyan
    foreach ($right in $userRights.GetEnumerator()) {
        Write-Host "  $($right.Key):" -ForegroundColor White
        Write-Host "    $($right.Value)" -ForegroundColor Gray
    }
    Write-Host ""

    Write-Host "Configure via GPO or use secedit for local policy:" -ForegroundColor Cyan
    Write-Host '  SeInteractiveLogonRight = *S-1-5-32-544 (Administrators)' -ForegroundColor White
    Write-Host '  SeRemoteInteractiveLogonRight = *S-1-5-32-544 (Administrators)' -ForegroundColor White
    Write-Host ""

    # Step 5: Restrict RDP access
    Write-Host "[Step 5] Configuring Remote Desktop access restrictions" -ForegroundColor Yellow

    # Check current RDP status
    $rdpEnabled = (Get-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name fDenyTSConnections).fDenyTSConnections
    if ($rdpEnabled -eq 0) {
        Write-Host "Remote Desktop is ENABLED" -ForegroundColor Yellow

        # Get RDP allowed users
        try {
            $rdpUsers = Get-LocalGroupMember -Group "Remote Desktop Users" -ErrorAction SilentlyContinue
            if ($rdpUsers) {
                Write-Host "Users with RDP access:" -ForegroundColor Cyan
                foreach ($user in $rdpUsers) {
                    Write-Host "  - $($user.Name)" -ForegroundColor White
                }
            } else {
                Write-Host "No additional users in Remote Desktop Users group" -ForegroundColor White
            }
        } catch {
            Write-Host "Could not enumerate RDP users: $($_.Exception.Message)" -ForegroundColor Gray
        }

        Write-Host ""
        Write-Host "Best Practice: Limit RDP access to only authorized administrators" -ForegroundColor Cyan
        Write-Host "  Remove unnecessary users from Remote Desktop Users group" -ForegroundColor White
    } else {
        Write-Host "Remote Desktop is DISABLED" -ForegroundColor Green
    }
    Write-Host ""

    # Step 6: Firewall rules for DC protection
    Write-Host "[Step 6] Domain Controller firewall configuration" -ForegroundColor Yellow

    Write-Host "Checking Windows Defender Firewall status..." -ForegroundColor Cyan
    $firewallProfiles = Get-NetFirewallProfile

    foreach ($profile in $firewallProfiles) {
        $status = if ($profile.Enabled) { "ENABLED" } else { "DISABLED" }
        $color = if ($profile.Enabled) { "Green" } else { "Red" }
        Write-Host "  $($profile.Name) Profile: $status" -ForegroundColor $color
    }
    Write-Host ""

    Write-Host "Critical DC firewall rules to verify:" -ForegroundColor Cyan
    $criticalPorts = @(
        @{Port=53; Protocol="TCP/UDP"; Service="DNS"},
        @{Port=88; Protocol="TCP/UDP"; Service="Kerberos"},
        @{Port=389; Protocol="TCP/UDP"; Service="LDAP"},
        @{Port=636; Protocol="TCP"; Service="LDAPS"},
        @{Port=3268; Protocol="TCP"; Service="Global Catalog"},
        @{Port=3269; Protocol="TCP"; Service="Global Catalog SSL"}
    )

    foreach ($port in $criticalPorts) {
        Write-Host "  Port $($port.Port) - $($port.Service) ($($port.Protocol))" -ForegroundColor White
    }
    Write-Host ""

    # Step 7: Audit and logging configuration
    Write-Host "[Step 7] Configuring audit policy for DC access" -ForegroundColor Yellow

    Write-Host "Recommended audit policies for Domain Controllers:" -ForegroundColor Cyan
    $auditCategories = @(
        "Account Logon",
        "Account Management",
        "Logon/Logoff",
        "Policy Change",
        "Privilege Use",
        "System"
    )

    foreach ($category in $auditCategories) {
        Write-Host "  Enable Success and Failure auditing for: $category" -ForegroundColor White
    }
    Write-Host ""

    Write-Host "Configure via command:" -ForegroundColor Cyan
    Write-Host '  auditpol /set /category:"Account Logon" /success:enable /failure:enable' -ForegroundColor White
    Write-Host '  auditpol /set /category:"Logon/Logoff" /success:enable /failure:enable' -ForegroundColor White
    Write-Host ""

    # Check current audit settings
    Write-Host "Checking current audit policy..." -ForegroundColor Cyan
    try {
        $auditOutput = auditpol /get /category:* 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Current audit policy retrieved (use 'auditpol /get /category:*' to view)" -ForegroundColor White
        }
    } catch {
        Write-Host "Could not retrieve audit policy" -ForegroundColor Yellow
    }
    Write-Host ""

    # Step 8: Implement network segmentation recommendations
    Write-Host "[Step 8] Network segmentation recommendations" -ForegroundColor Yellow

    Write-Host "Best practices for DC network security:" -ForegroundColor Cyan
    Write-Host "  1. Place DCs in dedicated VLAN/subnet" -ForegroundColor White
    Write-Host "  2. Use firewall rules to restrict management access" -ForegroundColor White
    Write-Host "  3. Implement jump servers/PAWs for DC administration" -ForegroundColor White
    Write-Host "  4. Block internet access from DCs" -ForegroundColor White
    Write-Host "  5. Monitor DC network traffic for anomalies" -ForegroundColor White
    Write-Host ""

    # Step 9: Restrict DC services
    Write-Host "[Step 9] Domain Controller service hardening" -ForegroundColor Yellow

    Write-Host "Services to disable/restrict on DCs:" -ForegroundColor Cyan
    $unnecessaryServices = @(
        "Print Spooler",
        "Server (SMB) - if not needed for SYSVOL",
        "Windows Update - use manual updates",
        "Remote Registry - unless required"
    )

    foreach ($svc in $unnecessaryServices) {
        Write-Host "  - $svc" -ForegroundColor White
    }
    Write-Host ""

    Write-Host "Example - Disable Print Spooler (common attack vector):" -ForegroundColor Cyan
    Write-Host '  Stop-Service -Name Spooler -Force' -ForegroundColor White
    Write-Host '  Set-Service -Name Spooler -StartupType Disabled' -ForegroundColor White
    Write-Host ""

    # Step 10: Review and verification
    Write-Host "[Step 10] Security verification checklist" -ForegroundColor Yellow

    $checklist = @(
        "Verify GPO is linked to Domain Controllers OU",
        "Confirm only authorized users can log on to DCs",
        "Review Remote Desktop Users group membership",
        "Enable audit logging for all critical categories",
        "Disable unnecessary services (e.g., Print Spooler)",
        "Implement firewall rules for DC protection",
        "Use Privileged Access Workstations (PAWs) for DC admin",
        "Regular review of DC security logs",
        "Implement least privilege for DC administration",
        "Enable Windows Defender on DCs"
    )

    Write-Host "Domain Controller Security Checklist:" -ForegroundColor Cyan
    for ($i = 0; $i -lt $checklist.Count; $i++) {
        Write-Host "  [$($i + 1)] $($checklist[$i])" -ForegroundColor White
    }
    Write-Host ""

    # Step 11: Best practices summary
    Write-Host "[Step 11] Best Practices for DC Access Control" -ForegroundColor Yellow
    Write-Host "  1. Minimize Interactive Logons: Only authorized admins should log on locally" -ForegroundColor White
    Write-Host "  2. Use Tiered Administration: Implement Tier 0 controls for DCs" -ForegroundColor White
    Write-Host "  3. Enable Advanced Auditing: Monitor all DC access and changes" -ForegroundColor White
    Write-Host "  4. Implement MFA: Require multi-factor authentication for DC admin" -ForegroundColor White
    Write-Host "  5. Use PAWs: Dedicated workstations for DC administration" -ForegroundColor White
    Write-Host "  6. Regular Reviews: Audit who has DC access quarterly" -ForegroundColor White
    Write-Host "  7. Network Isolation: Separate DCs from general network" -ForegroundColor White
    Write-Host "  8. Patch Management: Keep DCs updated with security patches" -ForegroundColor White
    Write-Host ""

    Write-Host "[INFO] Additional Resources:" -ForegroundColor Cyan
    Write-Host "  - Microsoft Security Baselines for Domain Controllers" -ForegroundColor White
    Write-Host "  - CIS Benchmarks for Windows Server" -ForegroundColor White
    Write-Host "  - NIST 800-53 Controls for Domain Controllers" -ForegroundColor White
    Write-Host "  - Securing Privileged Access documentation" -ForegroundColor White
    Write-Host ""

} catch {
    Write-Host "[ERROR] $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

Write-Host "Demo completed successfully!" -ForegroundColor Green
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Review and apply GPO settings to Domain Controllers OU" -ForegroundColor White
Write-Host "  2. Audit current user rights assignments on DCs" -ForegroundColor White
Write-Host "  3. Implement PAW/jump server for DC administration" -ForegroundColor White
Write-Host "  4. Enable comprehensive audit logging" -ForegroundColor White
Write-Host "  5. Document all DC access permissions and review quarterly" -ForegroundColor White
