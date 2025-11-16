<#
.SYNOPSIS
    Task 3.3 - Harden Domain Controllers

.DESCRIPTION
    Demo script for AZ-801 Module 3: Manage Protected Users and RODCs
    Demonstrates domain controller hardening techniques and security best practices.

.NOTES
    Module: Module 3 - Manage Protected Users and RODCs
    Task: 3.3 - Harden Domain Controllers
    Prerequisites: Domain Controller, Domain Admin privileges
    PowerShell Version: 5.1+
#>

#Requires -RunAsAdministrator

$ErrorActionPreference = 'Stop'
Write-Host "=== AZ-801 Module 3: Task 3.3 - Harden Domain Controllers ===" -ForegroundColor Cyan

try {
    Write-Host "[Step 1] Check if running on Domain Controller" -ForegroundColor Yellow
    $isDC = (Get-CimInstance Win32_ComputerSystem).DomainRole -ge 4
    Write-Host "Is Domain Controller: $isDC" -ForegroundColor White
    
    Write-Host "`n[Step 2] Domain Controller Hardening Checklist" -ForegroundColor Yellow
    Write-Host "Security Hardening Steps:" -ForegroundColor Cyan
    Write-Host "  1. Install latest Windows Updates" -ForegroundColor White
    Write-Host "  2. Enable Windows Firewall on all profiles" -ForegroundColor White
    Write-Host "  3. Configure Advanced Audit Policy" -ForegroundColor White
    Write-Host "  4. Implement Protected Users for admins" -ForegroundColor White
    Write-Host "  5. Enable SMB signing" -ForegroundColor White
    Write-Host "  6. Disable unnecessary services" -ForegroundColor White
    Write-Host "  7. Configure security baselines" -ForegroundColor White
    
    Write-Host "`n[Step 3] Enable SMB Signing" -ForegroundColor Yellow
    Write-Host "Configure SMB signing:" -ForegroundColor Cyan
    Write-Host "  Set-SmbServerConfiguration -RequireSecuritySignature `$true -Force" -ForegroundColor White
    Write-Host "  Set-SmbClientConfiguration -RequireSecuritySignature `$true -Force" -ForegroundColor White
    
    Write-Host "`n[Step 4] Configure Advanced Audit Policy" -ForegroundColor Yellow
    Write-Host "Enable critical audit policies:" -ForegroundColor Cyan
    Write-Host "  auditpol /set /subcategory:'User Account Management' /success:enable /failure:enable" -ForegroundColor White
    Write-Host "  auditpol /set /subcategory:'Security Group Management' /success:enable /failure:enable" -ForegroundColor White
    Write-Host "  auditpol /set /subcategory:'Directory Service Changes' /success:enable /failure:enable" -ForegroundColor White
    
    Write-Host "`n[Step 5] Firewall Configuration" -ForegroundColor Yellow
    $firewallProfiles = Get-NetFirewallProfile
    Write-Host "Current Firewall Status:" -ForegroundColor Cyan
    foreach ($profile in $firewallProfiles) {
        Write-Host "  $($profile.Name): $($profile.Enabled)" -ForegroundColor White
    }
    
    Write-Host "`n[Step 6] Disable Unnecessary Services" -ForegroundColor Yellow
    Write-Host "Review and disable unused services:" -ForegroundColor Cyan
    Write-Host "  - Print Spooler (if not needed)" -ForegroundColor White
    Write-Host "  - Server service (reduce attack surface)" -ForegroundColor White
    Write-Host "  - Remote Registry (if not required)" -ForegroundColor White
    Write-Host "  Command: Stop-Service -Name Spooler; Set-Service -Name Spooler -StartupType Disabled" -ForegroundColor White
    
    Write-Host "`n[Step 7] Local Administrator Protection" -ForegroundColor Yellow
    Write-Host "Restrict local administrator access:" -ForegroundColor Cyan
    Write-Host "  - Use LAPS for local admin passwords" -ForegroundColor White
    Write-Host "  - Limit RDP access to specific groups" -ForegroundColor White
    Write-Host "  - Enable administrator account rename via GPO" -ForegroundColor White
    
    Write-Host "`n[INFO] DC Hardening Best Practices:" -ForegroundColor Cyan
    Write-Host "  - Keep DCs dedicated (no other roles)" -ForegroundColor White
    Write-Host "  - Regular security updates and patching" -ForegroundColor White
    Write-Host "  - Monitor security logs daily" -ForegroundColor White
    Write-Host "  - Implement tiered admin model" -ForegroundColor White
    Write-Host "  - Use Credential Guard where supported" -ForegroundColor White
    Write-Host "  - Regular vulnerability scanning" -ForegroundColor White
    Write-Host "  - Network segmentation for DCs" -ForegroundColor White
    
} catch {
    Write-Host "[ERROR] $_" -ForegroundColor Red
    exit 1
}

Write-Host "`nDemo completed successfully!" -ForegroundColor Green
