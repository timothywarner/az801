<#
.SYNOPSIS
    Task 1.6 - Configure Security Baseline with Microsoft Security Compliance Toolkit

.DESCRIPTION
    Demo script for AZ-801 Module 1: Implement Core OS Security
    This script demonstrates how to work with Microsoft Security Compliance Toolkit
    and apply security baselines to Windows Server.

.NOTES
    Module: Module 1 - Implement Core OS Security
    Task: 1.6 - Configure Security Baseline with OS Configuration

    Prerequisites:
    - Windows Server 2019 or later
    - Administrative privileges
    - Microsoft Security Compliance Toolkit (SCT)
    - Policy Analyzer and LGPO tools

    Lab Environment:
    - Windows Server 2022 recommended
    - Download SCT from Microsoft

    PowerShell Version: 5.1+
#>

#Requires -RunAsAdministrator

# Script configuration
$ErrorActionPreference = 'Stop'

Write-Host "=== AZ-801 Module 1: Task 1.6 - Security Baseline Configuration ===" -ForegroundColor Cyan
Write-Host ""

try {
    # Section 1: Check for Security Compliance Toolkit
    Write-Host "[Step 1] Checking for Microsoft Security Compliance Toolkit" -ForegroundColor Yellow

    $sctPath = "C:\SecurityCompliance"
    $lgpoPath = "$sctPath\LGPO\LGPO.exe"

    if (Test-Path $lgpoPath) {
        Write-Host "Security Compliance Toolkit found at: $sctPath" -ForegroundColor White
        Write-Host "[SUCCESS] LGPO tool available" -ForegroundColor Green
    } else {
        Write-Host "[INFO] Security Compliance Toolkit not found" -ForegroundColor Yellow
        Write-Host "Download from: https://www.microsoft.com/en-us/download/details.aspx?id=55319" -ForegroundColor White
        Write-Host "Extract to: $sctPath" -ForegroundColor White
    }
    Write-Host ""

    # Section 2: Create baseline directory structure
    Write-Host "[Step 2] Creating security baseline directory structure" -ForegroundColor Yellow

    $baselinePath = "C:\SecurityBaseline"
    $directories = @(
        "$baselinePath\Exports",
        "$baselinePath\Backups",
        "$baselinePath\Reports",
        "$baselinePath\CustomBaselines"
    )

    foreach ($dir in $directories) {
        if (-not (Test-Path $dir)) {
            New-Item -Path $dir -ItemType Directory -Force | Out-Null
            Write-Host "Created: $dir" -ForegroundColor White
        }
    }

    Write-Host "[SUCCESS] Directory structure created" -ForegroundColor Green
    Write-Host ""

    # Section 3: Export current GPO settings
    Write-Host "[Step 3] Exporting current Group Policy settings" -ForegroundColor Yellow

    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backupPath = "$baselinePath\Backups\GPO-Backup-$timestamp"

    if (-not (Test-Path $backupPath)) {
        New-Item -Path $backupPath -ItemType Directory -Force | Out-Null
    }

    # Export current security policy
    $secPolExport = "$backupPath\secedit-export.cfg"
    secedit /export /cfg $secPolExport /quiet

    if (Test-Path $secPolExport) {
        Write-Host "Security policy backed up to: $secPolExport" -ForegroundColor White
    }

    # Export registry-based policies (if LGPO available)
    if (Test-Path $lgpoPath) {
        Write-Host "Exporting registry policies with LGPO..." -ForegroundColor White
        & $lgpoPath /b $backupPath /n "PreBaseline-Backup"
    }

    Write-Host "[SUCCESS] Current settings backed up" -ForegroundColor Green
    Write-Host ""

    # Section 4: Display Windows Server security baseline categories
    Write-Host "[Step 4] Windows Server 2022 Security Baseline Categories" -ForegroundColor Yellow

    Write-Host "`nMicrosoft Security Baseline includes:" -ForegroundColor Cyan
    Write-Host "  1. Windows Defender Antivirus" -ForegroundColor White
    Write-Host "  2. Windows Defender Exploit Guard" -ForegroundColor White
    Write-Host "  3. Windows Defender Application Control" -ForegroundColor White
    Write-Host "  4. Windows Defender Firewall" -ForegroundColor White
    Write-Host "  5. Credential Guard and Device Guard" -ForegroundColor White
    Write-Host "  6. BitLocker Drive Encryption" -ForegroundColor White
    Write-Host "  7. Advanced Audit Policy" -ForegroundColor White
    Write-Host "  8. User Rights Assignment" -ForegroundColor White
    Write-Host "  9. Security Options" -ForegroundColor White
    Write-Host "  10. Internet Explorer/Microsoft Edge settings" -ForegroundColor White
    Write-Host ""

    # Section 5: Create custom baseline template
    Write-Host "[Step 5] Creating custom security baseline template" -ForegroundColor Yellow

    $customBaseline = @"
# Windows Server 2022 Custom Security Baseline
# AZ-801 Security Configuration
# Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## Password Policy
- Minimum Password Length: 14 characters
- Password Complexity: Enabled
- Maximum Password Age: 90 days
- Password History: 24 passwords

## Account Lockout Policy
- Account Lockout Threshold: 5 invalid attempts
- Account Lockout Duration: 30 minutes
- Reset Account Lockout Counter: 30 minutes

## Audit Policy
- Audit Logon Events: Success and Failure
- Audit Account Logon Events: Success and Failure
- Audit Account Management: Success and Failure
- Audit Policy Change: Success and Failure
- Audit Privilege Use: Success and Failure

## User Rights Assignment
- Allow log on locally: Administrators
- Allow log on through RDS: Administrators, Remote Desktop Users
- Access this computer from network: Administrators, Authenticated Users

## Security Options
- Interactive logon: Do not display last user name: Enabled
- Network security: LAN Manager authentication level: Send NTLMv2 response only
- Network security: Minimum session security for NTLM SSP: Require NTLMv2, 128-bit
- User Account Control: Admin Approval Mode: Enabled
- User Account Control: Behavior of elevation prompt: Prompt for credentials

## Windows Defender
- Real-time Protection: Enabled
- Cloud-delivered Protection: Enabled
- Automatic Sample Submission: Enabled
- PUA Protection: Enabled

## Windows Firewall
- Domain Profile: Enabled
- Private Profile: Enabled
- Public Profile: Enabled
- Inbound Connections: Block by default
- Outbound Connections: Allow by default
"@

    $customBaselinePath = "$baselinePath\CustomBaselines\AZ801-Baseline.txt"
    $customBaseline | Out-File -FilePath $customBaselinePath -Encoding UTF8

    Write-Host "Custom baseline template created: $customBaselinePath" -ForegroundColor White
    Write-Host "[SUCCESS] Baseline template ready" -ForegroundColor Green
    Write-Host ""

    # Section 6: Analyze current security posture
    Write-Host "[Step 6] Analyzing current security configuration" -ForegroundColor Yellow

    # Check key security settings
    Write-Host "`nCurrent Security Status:" -ForegroundColor Cyan

    # Check Windows Defender status
    $defenderStatus = Get-MpComputerStatus -ErrorAction SilentlyContinue
    if ($defenderStatus) {
        Write-Host "Windows Defender:" -ForegroundColor White
        Write-Host "  Real-time Protection: $($defenderStatus.RealTimeProtectionEnabled)" -ForegroundColor White
        Write-Host "  Antivirus Enabled: $($defenderStatus.AntivirusEnabled)" -ForegroundColor White
        Write-Host "  Antimalware Enabled: $($defenderStatus.AntimalwareEnabled)" -ForegroundColor White
    }

    # Check firewall status
    $firewallProfiles = Get-NetFirewallProfile
    Write-Host "Windows Firewall:" -ForegroundColor White
    foreach ($profile in $firewallProfiles) {
        Write-Host "  $($profile.Name) Profile: $($profile.Enabled)" -ForegroundColor White
    }

    # Check UAC settings
    $uacKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
    $uacEnabled = Get-ItemProperty -Path $uacKey -Name "EnableLUA" -ErrorAction SilentlyContinue
    if ($uacEnabled) {
        Write-Host "User Account Control:" -ForegroundColor White
        Write-Host "  UAC Enabled: $($uacEnabled.EnableLUA -eq 1)" -ForegroundColor White
    }

    Write-Host "[SUCCESS] Security analysis complete" -ForegroundColor Green
    Write-Host ""

    # Section 7: Apply baseline recommendations
    Write-Host "[Step 7] Applying security baseline recommendations" -ForegroundColor Yellow

    Write-Host "`nTo apply Microsoft Security Baseline:" -ForegroundColor Cyan
    Write-Host "  1. Download latest baseline from Microsoft" -ForegroundColor White
    Write-Host "  2. Extract to $sctPath" -ForegroundColor White
    Write-Host "  3. Navigate to GPOs folder" -ForegroundColor White
    Write-Host "  4. Use LGPO.exe to apply:" -ForegroundColor White
    Write-Host "     LGPO.exe /g <path-to-baseline-GPOs>" -ForegroundColor White
    Write-Host ""
    Write-Host "For domain environments:" -ForegroundColor Cyan
    Write-Host "  1. Import baseline GPO into Active Directory" -ForegroundColor White
    Write-Host "  2. Link to appropriate OUs" -ForegroundColor White
    Write-Host "  3. Test in pilot environment first" -ForegroundColor White
    Write-Host ""

    # Section 8: Generate compliance report
    Write-Host "[Step 8] Generating security compliance report" -ForegroundColor Yellow

    $reportPath = "$baselinePath\Reports\SecurityReport-$timestamp.txt"

    $report = @"
Windows Server Security Baseline Compliance Report
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Computer: $env:COMPUTERNAME
OS Version: $((Get-CimInstance Win32_OperatingSystem).Caption)

=== Security Features Status ===
Windows Defender: $($defenderStatus.AntivirusEnabled)
Real-time Protection: $($defenderStatus.RealTimeProtectionEnabled)
Firewall Enabled: $(($firewallProfiles | Where-Object {$_.Enabled -eq $true}).Count -eq 3)
UAC Enabled: $($uacEnabled.EnableLUA -eq 1)

=== Recommendations ===
1. Review and apply Microsoft Security Baseline
2. Enable advanced audit policies
3. Configure Windows Defender Exploit Guard
4. Implement Credential Guard (if supported)
5. Regular review of security event logs
6. Deploy security baseline via Group Policy

=== Next Steps ===
1. Download latest Microsoft Security Compliance Toolkit
2. Test baseline in lab environment
3. Create custom baseline for organization needs
4. Deploy to production using phased approach
5. Monitor compliance with Policy Analyzer
"@

    $report | Out-File -FilePath $reportPath -Encoding UTF8

    Write-Host "Compliance report generated: $reportPath" -ForegroundColor White
    Write-Host "[SUCCESS] Report created" -ForegroundColor Green
    Write-Host ""

    # Section 9: Educational notes
    Write-Host "[INFO] Security Baseline Best Practices:" -ForegroundColor Cyan
    Write-Host "  - Always backup current configuration before applying baseline" -ForegroundColor White
    Write-Host "  - Test baselines in non-production environment first" -ForegroundColor White
    Write-Host "  - Use Policy Analyzer to compare baselines" -ForegroundColor White
    Write-Host "  - Customize baselines for organizational requirements" -ForegroundColor White
    Write-Host "  - Apply baselines using LGPO for local, GPO for domain" -ForegroundColor White
    Write-Host "  - Document all deviations from Microsoft baseline" -ForegroundColor White
    Write-Host "  - Regularly update baselines with new Microsoft releases" -ForegroundColor White
    Write-Host "  - Monitor compliance using Group Policy Results" -ForegroundColor White
    Write-Host ""

} catch {
    Write-Host "[ERROR] $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

Write-Host "Demo completed successfully!" -ForegroundColor Green
Write-Host "Next Steps: Download Microsoft Security Baseline and apply using LGPO" -ForegroundColor Yellow
