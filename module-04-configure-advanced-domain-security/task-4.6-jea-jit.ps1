<#
.SYNOPSIS
    Task 4.6 - Configure JEA and JIT Access
.DESCRIPTION
    Comprehensive demonstration of Just Enough Administration (JEA) and
    Just-In-Time (JIT) privileged access management.
.EXAMPLE
    .\task-4.6-jea-jit.ps1
.NOTES
    Module: Module 4 - Configure Advanced Domain Security
    Task: 4.6 - Configure JEA and JIT Access
    Prerequisites:
    - Windows Server 2016+ or Windows 10+
    - PowerShell 5.1+
    - Administrative privileges
    PowerShell Version: 5.1+
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

Write-Host "=== AZ-801 Module 4: Task 4.6 - Configure JEA and JIT Access ===" -ForegroundColor Cyan
Write-Host ""

try {
    # Step 1: Introduction to JEA
    Write-Host "[Step 1] Understanding Just Enough Administration (JEA)" -ForegroundColor Yellow

    Write-Host "JEA Benefits:" -ForegroundColor Cyan
    Write-Host "  - Reduces number of permanent administrators" -ForegroundColor White
    Write-Host "  - Limits what administrators can do during a session" -ForegroundColor White
    Write-Host "  - Provides detailed logging of all commands executed" -ForegroundColor White
    Write-Host "  - Enforces least privilege principle" -ForegroundColor White
    Write-Host "  - Prevents lateral movement in compromised environments" -ForegroundColor White
    Write-Host ""

    # Step 2: Check JEA prerequisites
    Write-Host "[Step 2] Checking JEA prerequisites" -ForegroundColor Yellow

    $psVersion = $PSVersionTable.PSVersion
    Write-Host "PowerShell Version: $($psVersion.Major).$($psVersion.Minor)" -ForegroundColor White

    if ($psVersion.Major -ge 5) {
        Write-Host "[SUCCESS] PowerShell 5.0+ is installed (JEA supported)" -ForegroundColor Green
    } else {
        Write-Host "[WARNING] JEA requires PowerShell 5.0 or later" -ForegroundColor Yellow
    }
    Write-Host ""

    # Step 3: Create JEA Role Capability File
    Write-Host "[Step 3] Creating JEA Role Capability File" -ForegroundColor Yellow

    $jeaModulePath = "C:\Program Files\WindowsPowerShell\Modules\JEA-Demo"
    $roleCapabilitiesPath = Join-Path $jeaModulePath "RoleCapabilities"

    Write-Host "JEA Module Path: $jeaModulePath" -ForegroundColor Cyan
    Write-Host "Role Capabilities Path: $roleCapabilitiesPath" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "Example: Creating a Help Desk role capability..." -ForegroundColor Cyan
    Write-Host ""

    $roleCapabilityExample = @'
# Create module and role capability directories
$modulePath = "C:\Program Files\WindowsPowerShell\Modules\JEA-HelpDesk"
$roleCapPath = Join-Path $modulePath "RoleCapabilities"

New-Item -Path $modulePath -ItemType Directory -Force
New-Item -Path $roleCapPath -ItemType Directory -Force

# Create role capability file
$roleCapParams = @{
    Path = Join-Path $roleCapPath "HelpDeskOperator.psrc"
    Author = "IT Security Team"
    Description = "Help Desk operators can reset passwords and unlock accounts"
    CompanyName = "Contoso"

    # Visible cmdlets - only these can be run
    VisibleCmdlets = @(
        "Get-ADUser",
        "Set-ADUser",
        "Unlock-ADAccount",
        @{
            Name = "Set-ADAccountPassword"
            Parameters = @{Name = "Identity"}, @{Name = "Reset"}
        }
    )

    # Visible functions
    VisibleFunctions = @("Get-UserInfo", "Reset-UserPassword")

    # Visible external commands (exe files)
    VisibleExternalCommands = @("C:\Windows\System32\whoami.exe")

    # Function definitions
    FunctionDefinitions = @{
        Name = "Reset-UserPassword"
        ScriptBlock = {
            param($Username)
            Set-ADAccountPassword -Identity $Username -Reset -NewPassword (Read-Host -AsSecureString -Prompt "New Password")
            Set-ADUser -Identity $Username -ChangePasswordAtLogon $true
        }
    }
}

New-PSRoleCapabilityFile @roleCapParams
'@

    Write-Host $roleCapabilityExample -ForegroundColor White
    Write-Host ""

    # Step 4: Create JEA Session Configuration File
    Write-Host "[Step 4] Creating JEA Session Configuration File" -ForegroundColor Yellow

    $sessionConfigExample = @'
# Create session configuration file
$sessionConfigPath = "C:\Program Files\WindowsPowerShell\JEA-HelpDesk.pssc"

$sessionParams = @{
    Path = $sessionConfigPath
    SessionType = "RestrictedRemoteServer"
    RunAsVirtualAccount = $true  # Run as virtual account
    TranscriptDirectory = "C:\ProgramData\JEA\Transcripts"

    # Role definitions - map AD groups to role capabilities
    RoleDefinitions = @{
        "CONTOSO\HelpDesk" = @{
            RoleCapabilities = "HelpDeskOperator"
        }
        "CONTOSO\JuniorAdmins" = @{
            RoleCapabilities = "HelpDeskOperator"
        }
    }

    # Additional security settings
    LanguageMode = "NoLanguage"  # Restrict PowerShell language features
    ExecutionPolicy = "RemoteSigned"
}

New-PSSessionConfigurationFile @sessionParams

# Register the JEA endpoint
Register-PSSessionConfiguration -Name "HelpDesk" -Path $sessionConfigPath -Force

# Restart WinRM to apply changes
Restart-Service WinRM
'@

    Write-Host $sessionConfigExample -ForegroundColor White
    Write-Host ""

    # Step 5: Test JEA endpoint
    Write-Host "[Step 5] Testing JEA endpoint" -ForegroundColor Yellow

    Write-Host "To test the JEA endpoint:" -ForegroundColor Cyan
    Write-Host '  # From another machine or as different user:' -ForegroundColor White
    Write-Host '  Enter-PSSession -ComputerName SERVER01 -ConfigurationName HelpDesk' -ForegroundColor White
    Write-Host ""
    Write-Host '  # Test available commands:' -ForegroundColor White
    Write-Host '  Get-Command' -ForegroundColor White
    Write-Host ""
    Write-Host '  # Test a permitted command:' -ForegroundColor White
    Write-Host '  Get-ADUser -Identity jdoe' -ForegroundColor White
    Write-Host ""
    Write-Host '  # Try a restricted command (should fail):' -ForegroundColor White
    Write-Host '  Get-Process' -ForegroundColor White
    Write-Host ""

    # Step 6: JEA with Virtual Accounts
    Write-Host "[Step 6] Understanding JEA Virtual Accounts" -ForegroundColor Yellow

    Write-Host "Virtual Account Benefits:" -ForegroundColor Cyan
    Write-Host "  - Temporary accounts created per session" -ForegroundColor White
    Write-Host "  - No password management required" -ForegroundColor White
    Write-Host "  - Automatic cleanup after session ends" -ForegroundColor White
    Write-Host "  - Can be granted specific AD permissions" -ForegroundColor White
    Write-Host ""

    Write-Host "Virtual Account format:" -ForegroundColor Cyan
    Write-Host "  Domain: DOMAIN\SERVERNAME$" -ForegroundColor White
    Write-Host "  Local: NT SERVICE\WinRM Virtual Users\{SessionID}" -ForegroundColor White
    Write-Host ""

    # Step 7: JEA with Group Managed Service Accounts
    Write-Host "[Step 7] Using Group Managed Service Accounts with JEA" -ForegroundColor Yellow

    $gmsaExample = @'
# Create gMSA for JEA
New-ADServiceAccount -Name "JEA-HelpDesk-gMSA" `
    -DNSHostName "JEA-HelpDesk.contoso.com" `
    -PrincipalsAllowedToRetrieveManagedPassword "JEAServers"

# Install gMSA on server
Install-ADServiceAccount -Identity "JEA-HelpDesk-gMSA"

# Update session configuration to use gMSA
$sessionParams = @{
    Path = "C:\JEA-HelpDesk.pssc"
    SessionType = "RestrictedRemoteServer"
    RunAsVirtualAccount = $false
    GroupManagedServiceAccount = "CONTOSO\JEA-HelpDesk-gMSA"
    RoleDefinitions = @{
        "CONTOSO\HelpDesk" = @{ RoleCapabilities = "HelpDeskOperator" }
    }
}

New-PSSessionConfigurationFile @sessionParams
'@

    Write-Host $gmsaExample -ForegroundColor White
    Write-Host ""

    # Step 8: JEA Logging and Auditing
    Write-Host "[Step 8] JEA Logging and Auditing" -ForegroundColor Yellow

    Write-Host "JEA provides comprehensive logging:" -ForegroundColor Cyan
    Write-Host "  1. Over-the-shoulder transcripts (complete session recording)" -ForegroundColor White
    Write-Host "  2. Module logging (detailed command logging)" -ForegroundColor White
    Write-Host "  3. PowerShell operational logs" -ForegroundColor White
    Write-Host ""

    Write-Host "Transcript locations:" -ForegroundColor Cyan
    Write-Host '  Default: C:\ProgramData\JEA\Transcripts' -ForegroundColor White
    Write-Host '  Custom: Specified in TranscriptDirectory parameter' -ForegroundColor White
    Write-Host ""

    Write-Host "Review transcripts:" -ForegroundColor Cyan
    Write-Host '  Get-ChildItem C:\ProgramData\JEA\Transcripts -Recurse | Select-Object FullName, CreationTime' -ForegroundColor White
    Write-Host ""

    # Step 9: Just-In-Time (JIT) Access
    Write-Host "[Step 9] Implementing Just-In-Time (JIT) Access" -ForegroundColor Yellow

    Write-Host "JIT Access Strategies:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. Azure AD Privileged Identity Management (PIM):" -ForegroundColor White
    Write-Host "   - Time-limited role activation" -ForegroundColor Gray
    Write-Host "   - Approval workflows" -ForegroundColor Gray
    Write-Host "   - MFA enforcement" -ForegroundColor Gray
    Write-Host "   - Audit logging" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. Time-based Group Membership (PowerShell):" -ForegroundColor White
    Write-Host "   - Add user to admin group temporarily" -ForegroundColor Gray
    Write-Host "   - Automatic removal after time period" -ForegroundColor Gray
    Write-Host "   - Scheduled tasks or Azure Automation" -ForegroundColor Gray
    Write-Host ""
    Write-Host "3. Microsoft Identity Manager (MIM):" -ForegroundColor White
    Write-Host "   - Time-based group membership" -ForegroundColor Gray
    Write-Host "   - Approval workflows" -ForegroundColor Gray
    Write-Host "   - Automated provisioning/deprovisioning" -ForegroundColor Gray
    Write-Host ""

    # JIT example script
    $jitExample = @'
# Example: Time-based admin group membership
function Grant-TemporaryAdminAccess {
    param(
        [string]$Username,
        [string]$AdminGroup,
        [int]$DurationMinutes = 60
    )

    # Add user to admin group
    Add-ADGroupMember -Identity $AdminGroup -Members $Username
    Write-Host "Added $Username to $AdminGroup"

    # Create scheduled task to remove user
    $action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
        -Argument "-Command Remove-ADGroupMember -Identity '$AdminGroup' -Members '$Username' -Confirm:`$false"

    $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes($DurationMinutes)

    Register-ScheduledTask -TaskName "RemoveJIT-$Username-$AdminGroup" `
        -Action $action -Trigger $trigger `
        -User "SYSTEM" -RunLevel Highest

    Write-Host "Access will expire in $DurationMinutes minutes"
}

# Usage:
# Grant-TemporaryAdminAccess -Username "jdoe" -AdminGroup "ServerAdmins" -DurationMinutes 120
'@

    Write-Host $jitExample -ForegroundColor White
    Write-Host ""

    # Step 10: Best practices
    Write-Host "[Step 10] JEA and JIT Best Practices" -ForegroundColor Yellow

    Write-Host "JEA Best Practices:" -ForegroundColor Cyan
    Write-Host "  1. Start Small: Begin with low-risk roles (help desk)" -ForegroundColor White
    Write-Host "  2. Use Virtual Accounts: Simplifies permission management" -ForegroundColor White
    Write-Host "  3. Enable Transcripts: Always log all JEA sessions" -ForegroundColor White
    Write-Host "  4. Limit Cmdlets: Only expose necessary commands" -ForegroundColor White
    Write-Host "  5. Test Thoroughly: Verify users can perform required tasks" -ForegroundColor White
    Write-Host "  6. Use NoLanguage Mode: Prevent script execution" -ForegroundColor White
    Write-Host "  7. Regular Audits: Review JEA sessions and capabilities" -ForegroundColor White
    Write-Host ""

    Write-Host "JIT Best Practices:" -ForegroundColor Cyan
    Write-Host "  1. Default Deny: No permanent admin access" -ForegroundColor White
    Write-Host "  2. Time Limits: Maximum 4-8 hours per elevation" -ForegroundColor White
    Write-Host "  3. Approval Workflow: Require manager or peer approval" -ForegroundColor White
    Write-Host "  4. MFA Required: Always require MFA for elevation" -ForegroundColor White
    Write-Host "  5. Audit Everything: Log all elevations and activities" -ForegroundColor White
    Write-Host "  6. Emergency Access: Maintain break-glass accounts" -ForegroundColor White
    Write-Host "  7. Regular Reviews: Analyze elevation patterns" -ForegroundColor White
    Write-Host ""

    Write-Host "[INFO] Additional Commands:" -ForegroundColor Cyan
    Write-Host '  List JEA endpoints: Get-PSSessionConfiguration' -ForegroundColor White
    Write-Host '  Remove JEA endpoint: Unregister-PSSessionConfiguration -Name "EndpointName"' -ForegroundColor White
    Write-Host '  View role capabilities: Get-PSSessionCapability -ConfigurationName "EndpointName" -Username "DOMAIN\User"' -ForegroundColor White
    Write-Host ""

} catch {
    Write-Host "[ERROR] $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

Write-Host "Demo completed successfully!" -ForegroundColor Green
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Design role capabilities based on job functions" -ForegroundColor White
Write-Host "  2. Create and test JEA endpoints in lab environment" -ForegroundColor White
Write-Host "  3. Implement transcript logging and retention policy" -ForegroundColor White
Write-Host "  4. Plan JIT access strategy (Azure PIM or custom solution)" -ForegroundColor White
Write-Host "  5. Train administrators on using JEA endpoints" -ForegroundColor White
