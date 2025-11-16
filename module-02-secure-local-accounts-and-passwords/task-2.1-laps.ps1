<#
.SYNOPSIS
    Task 2.1 - Configure Local Administrator Password Solution (LAPS)

.DESCRIPTION
    Demo script for AZ-801 Module 2: Secure Local Accounts and Passwords
    This script demonstrates how to deploy and configure Microsoft LAPS (Local
    Administrator Password Solution) to manage local administrator passwords.

.NOTES
    Module: Module 2 - Secure Local Accounts and Passwords
    Task: 2.1 - Configure LAPS

    Prerequisites:
    - Active Directory Domain
    - Domain Administrator privileges
    - Windows LAPS (included in Windows Server 2022+)
    - RSAT-AD-PowerShell module

    Lab Environment:
    - Domain Controller with Windows Server 2022
    - Client computers joined to domain

    PowerShell Version: 5.1+
#>

#Requires -RunAsAdministrator

# Script configuration
$ErrorActionPreference = 'Stop'

Write-Host "=== AZ-801 Module 2: Task 2.1 - Local Administrator Password Solution (LAPS) ===" -ForegroundColor Cyan
Write-Host ""

try {
    # Section 1: Check LAPS availability
    Write-Host "[Step 1] Checking Windows LAPS availability" -ForegroundColor Yellow

    # Check OS version (Windows LAPS is built into Windows Server 2022 and Windows 11)
    $osVersion = [System.Environment]::OSVersion.Version
    Write-Host "OS Version: $($osVersion.Major).$($osVersion.Minor).$($osVersion.Build)" -ForegroundColor White

    # Check for LAPS cmdlets
    $lapsCommands = Get-Command -Module LAPS -ErrorAction SilentlyContinue

    if ($lapsCommands) {
        Write-Host "[SUCCESS] Windows LAPS module found" -ForegroundColor Green
        Write-Host "Available LAPS cmdlets:" -ForegroundColor White
        $lapsCommands | Select-Object -First 5 Name | ForEach-Object {
            Write-Host "  - $($_.Name)" -ForegroundColor White
        }
    } else {
        Write-Host "[INFO] Windows LAPS module not found" -ForegroundColor Yellow
        Write-Host "For legacy LAPS, download from Microsoft Download Center" -ForegroundColor White
        Write-Host "For Windows LAPS, included in Windows Server 2022+" -ForegroundColor White
    }
    Write-Host ""

    # Section 2: Check Active Directory environment
    Write-Host "[Step 2] Checking Active Directory environment" -ForegroundColor Yellow

    $isDomainController = (Get-CimInstance -ClassName Win32_ComputerSystem).DomainRole -ge 4
    $domain = (Get-CimInstance -ClassName Win32_ComputerSystem).Domain

    Write-Host "Computer Domain: $domain" -ForegroundColor White
    Write-Host "Is Domain Controller: $isDomainController" -ForegroundColor White

    # Import AD module
    if (Get-Module -ListAvailable -Name ActiveDirectory) {
        Import-Module ActiveDirectory -ErrorAction SilentlyContinue
        Write-Host "[SUCCESS] Active Directory module loaded" -ForegroundColor Green
    } else {
        Write-Host "[WARNING] Active Directory module not available" -ForegroundColor Yellow
        Write-Host "Install with: Install-WindowsFeature RSAT-AD-PowerShell" -ForegroundColor White
    }
    Write-Host ""

    # Section 3: Prepare AD schema for LAPS (Legacy LAPS)
    Write-Host "[Step 3] Active Directory schema preparation for LAPS" -ForegroundColor Yellow

    Write-Host "`nFor Legacy LAPS (AdmPwd):" -ForegroundColor Cyan
    Write-Host "  1. Import the PowerShell module:" -ForegroundColor White
    Write-Host "     Import-Module AdmPwd.PS" -ForegroundColor White
    Write-Host "  2. Update AD schema:" -ForegroundColor White
    Write-Host "     Update-AdmPwdADSchema" -ForegroundColor White
    Write-Host "  3. Set permissions on OU:" -ForegroundColor White
    Write-Host "     Set-AdmPwdComputerSelfPermission -OrgUnit 'OU=Workstations,DC=domain,DC=com'" -ForegroundColor White
    Write-Host ""

    Write-Host "For Windows LAPS (built-in):" -ForegroundColor Cyan
    Write-Host "  1. Update AD schema (if needed):" -ForegroundColor White
    Write-Host "     Update-LapsADSchema" -ForegroundColor White
    Write-Host "  2. Grant permission to update password:" -ForegroundColor White
    Write-Host "     Set-LapsADComputerSelfPermission -Identity 'OU=Computers,DC=domain,DC=com'" -ForegroundColor White
    Write-Host ""

    # Section 4: Configure LAPS Group Policy
    Write-Host "[Step 4] LAPS Group Policy configuration" -ForegroundColor Yellow

    Write-Host "`nKey LAPS GPO Settings:" -ForegroundColor Cyan
    Write-Host "Computer Configuration > Policies > Administrative Templates > LAPS:" -ForegroundColor White
    Write-Host ""
    Write-Host "  1. Enable local admin password management" -ForegroundColor White
    Write-Host "     Setting: Enabled" -ForegroundColor White
    Write-Host ""
    Write-Host "  2. Password Settings:" -ForegroundColor White
    Write-Host "     - Password Complexity: Large letters + small letters + numbers + specials" -ForegroundColor White
    Write-Host "     - Password Length: 14 characters (minimum)" -ForegroundColor White
    Write-Host "     - Password Age (Days): 30" -ForegroundColor White
    Write-Host ""
    Write-Host "  3. Administrator account name (optional):" -ForegroundColor White
    Write-Host "     - Leave blank for built-in Administrator" -ForegroundColor White
    Write-Host "     - Or specify custom admin account name" -ForegroundColor White
    Write-Host ""

    Write-Host "[SUCCESS] GPO configuration guidance provided" -ForegroundColor Green
    Write-Host ""

    # Section 5: Demonstrate LAPS password retrieval
    Write-Host "[Step 5] LAPS password management" -ForegroundColor Yellow

    Write-Host "`nTo retrieve LAPS password for a computer:" -ForegroundColor Cyan
    Write-Host "  Legacy LAPS:" -ForegroundColor White
    Write-Host "    Get-AdmPwdPassword -ComputerName 'COMPUTER01'" -ForegroundColor White
    Write-Host ""
    Write-Host "  Windows LAPS:" -ForegroundColor White
    Write-Host "    Get-LapsADPassword -Identity 'COMPUTER01'" -ForegroundColor White
    Write-Host "    Get-LapsADPassword -Identity 'COMPUTER01' -AsPlainText" -ForegroundColor White
    Write-Host ""

    # If AD cmdlets available, demonstrate retrieval
    if (Get-Command Get-ADComputer -ErrorAction SilentlyContinue) {
        Write-Host "Example: Listing computers with LAPS attributes:" -ForegroundColor White

        # Get computers (limit to first 3 for demo)
        $computers = Get-ADComputer -Filter * -Properties ms-Mcs-AdmPwd, ms-Mcs-AdmPwdExpirationTime -ResultSetSize 3 -ErrorAction SilentlyContinue

        if ($computers) {
            foreach ($computer in $computers) {
                Write-Host "  Computer: $($computer.Name)" -ForegroundColor White
                if ($computer.'ms-Mcs-AdmPwdExpirationTime') {
                    $expiration = [DateTime]::FromFileTime($computer.'ms-Mcs-AdmPwdExpirationTime')
                    Write-Host "    Password Expiration: $expiration" -ForegroundColor White
                } else {
                    Write-Host "    LAPS not yet applied" -ForegroundColor Yellow
                }
            }
        }
    }

    Write-Host ""

    # Section 6: Configure LAPS permissions
    Write-Host "[Step 6] Configuring LAPS permissions in Active Directory" -ForegroundColor Yellow

    Write-Host "`nPermission Configuration:" -ForegroundColor Cyan
    Write-Host "  1. Computer Self-Permission (allow computers to update their own password):" -ForegroundColor White
    Write-Host "     Set-LapsADComputerSelfPermission -Identity 'OU=Computers,DC=contoso,DC=com'" -ForegroundColor White
    Write-Host ""
    Write-Host "  2. Grant read permission to specific group:" -ForegroundColor White
    Write-Host "     Set-LapsADReadPasswordPermission -Identity 'OU=Computers,DC=contoso,DC=com' `" -ForegroundColor White
    Write-Host "       -AllowedPrincipals 'CONTOSO\HelpDesk'" -ForegroundColor White
    Write-Host ""
    Write-Host "  3. Grant password reset permission:" -ForegroundColor White
    Write-Host "     Set-LapsADResetPasswordPermission -Identity 'OU=Computers,DC=contoso,DC=com' `" -ForegroundColor White
    Write-Host "       -AllowedPrincipals 'CONTOSO\LAPSAdmins'" -ForegroundColor White
    Write-Host ""

    Write-Host "[SUCCESS] Permission guidance provided" -ForegroundColor Green
    Write-Host ""

    # Section 7: Force LAPS password update
    Write-Host "[Step 7] Force LAPS password update" -ForegroundColor Yellow

    Write-Host "`nTo force immediate password update:" -ForegroundColor Cyan
    Write-Host "  Legacy LAPS:" -ForegroundColor White
    Write-Host "    Reset-AdmPwdPassword -ComputerName 'COMPUTER01'" -ForegroundColor White
    Write-Host ""
    Write-Host "  Windows LAPS:" -ForegroundColor White
    Write-Host "    Reset-LapsPassword -Identity 'COMPUTER01'" -ForegroundColor White
    Write-Host "    # Password will update at next Group Policy refresh" -ForegroundColor White
    Write-Host ""
    Write-Host "  On the client computer:" -ForegroundColor White
    Write-Host "    gpupdate /force" -ForegroundColor White
    Write-Host ""

    # Section 8: LAPS auditing and reporting
    Write-Host "[Step 8] LAPS auditing and reporting" -ForegroundColor Yellow

    Write-Host "`nMonitoring LAPS:" -ForegroundColor Cyan
    Write-Host "  Event Logs:" -ForegroundColor White
    Write-Host "    - Event Viewer > Applications and Services Logs > Microsoft > Windows > LAPS" -ForegroundColor White
    Write-Host "    - Event ID 10001: Password changed successfully" -ForegroundColor White
    Write-Host "    - Event ID 10002: Password change failed" -ForegroundColor White
    Write-Host ""
    Write-Host "  Reporting:" -ForegroundColor White
    Write-Host "    # Find computers where LAPS password expires soon" -ForegroundColor White
    Write-Host "    Get-LapsADPassword -Identity 'COMPUTER01' -IncludeHistory" -ForegroundColor White
    Write-Host ""

    # Section 9: Create LAPS deployment checklist
    Write-Host "[Step 9] LAPS deployment checklist" -ForegroundColor Yellow

    $checklist = @"
LAPS Deployment Checklist
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

=== Pre-Deployment ===
[ ] Determine LAPS version (Legacy AdmPwd or Windows LAPS)
[ ] Verify AD schema permissions (Schema Admins)
[ ] Plan OU structure for LAPS deployment
[ ] Identify administrators who need password read access
[ ] Document password policy requirements

=== Schema and Permissions ===
[ ] Update AD schema
    - Update-LapsADSchema (Windows LAPS)
    - Update-AdmPwdADSchema (Legacy LAPS)
[ ] Configure computer self-permissions on target OUs
[ ] Grant read permissions to authorized groups
[ ] Grant reset permissions to administrators

=== Group Policy Configuration ===
[ ] Create LAPS GPO
[ ] Configure password complexity settings
[ ] Set password length (minimum 14 characters)
[ ] Set password age (30 days recommended)
[ ] Link GPO to computer OUs
[ ] Verify GPO inheritance and filtering

=== Testing ===
[ ] Apply LAPS to test OU
[ ] Run gpupdate /force on test computers
[ ] Verify password stored in AD
[ ] Test password retrieval
[ ] Test password reset functionality
[ ] Verify audit logging

=== Production Rollout ===
[ ] Deploy to pilot group
[ ] Monitor for issues
[ ] Roll out to remaining computers
[ ] Document password retrieval procedures
[ ] Train help desk staff
[ ] Schedule regular audits

=== Monitoring and Maintenance ===
[ ] Monitor LAPS event logs
[ ] Review computers without LAPS
[ ] Audit password access
[ ] Regular permission reviews
[ ] Update documentation
"@

    $checklistPath = "$env:TEMP\LAPS-Deployment-Checklist.txt"
    $checklist | Out-File -FilePath $checklistPath -Encoding UTF8

    Write-Host "Deployment checklist saved to: $checklistPath" -ForegroundColor White
    Write-Host "[SUCCESS] Checklist created" -ForegroundColor Green
    Write-Host ""

    # Section 10: Educational notes
    Write-Host "[INFO] LAPS Best Practices:" -ForegroundColor Cyan
    Write-Host "  - Use Windows LAPS (built-in) for Windows Server 2022 and Windows 11" -ForegroundColor White
    Write-Host "  - Set password length to at least 14 characters" -ForegroundColor White
    Write-Host "  - Rotate passwords every 30 days" -ForegroundColor White
    Write-Host "  - Use role-based permissions (least privilege)" -ForegroundColor White
    Write-Host "  - Monitor password access through AD auditing" -ForegroundColor White
    Write-Host "  - Integrate with privileged access management (PAM) solutions" -ForegroundColor White
    Write-Host "  - Document emergency access procedures" -ForegroundColor White
    Write-Host "  - Regular security audits of LAPS permissions" -ForegroundColor White
    Write-Host ""

} catch {
    Write-Host "[ERROR] $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

Write-Host "Demo completed successfully!" -ForegroundColor Green
Write-Host "Next Steps: Deploy LAPS to pilot OU and verify functionality" -ForegroundColor Yellow
