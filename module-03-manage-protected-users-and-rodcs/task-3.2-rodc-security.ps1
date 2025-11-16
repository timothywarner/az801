<#
.SYNOPSIS
    Task 3.2 - Configure Read-Only Domain Controller Security

.DESCRIPTION
    Demo script for AZ-801 Module 3: Manage Protected Users and RODCs
    Demonstrates RODC configuration, password replication policies, and security.

.NOTES
    Module: Module 3 - Manage Protected Users and RODCs
    Task: 3.2 - Configure RODC Security
    Prerequisites: Active Directory, Domain Admin privileges
    PowerShell Version: 5.1+
#>

#Requires -RunAsAdministrator

$ErrorActionPreference = 'Stop'
Write-Host "=== AZ-801 Module 3: Task 3.2 - RODC Security ===" -ForegroundColor Cyan

try {
    Write-Host "[Step 1] Checking RODC capabilities" -ForegroundColor Yellow
    
    if (Get-Module -ListAvailable -Name ActiveDirectory) {
        Import-Module ActiveDirectory
        
        $rodcs = Get-ADDomainController -Filter {IsReadOnly -eq $true} -ErrorAction SilentlyContinue
        if ($rodcs) {
            Write-Host "Found $($rodcs.Count) RODC(s):" -ForegroundColor Cyan
            $rodcs | ForEach-Object { Write-Host "  - $($_.Name)" -ForegroundColor White }
        } else {
            Write-Host "[INFO] No RODCs found in domain" -ForegroundColor Yellow
        }
    }
    
    Write-Host "`n[Step 2] RODC Password Replication Policy" -ForegroundColor Yellow
    Write-Host "Configure Password Replication Policy (PRP):" -ForegroundColor Cyan
    Write-Host "  Allowed RODC Password Replication Group: Add specific users/groups" -ForegroundColor White
    Write-Host "  Denied RODC Password Replication Group: Add sensitive accounts" -ForegroundColor White
    Write-Host ""
    Write-Host "Commands:" -ForegroundColor Cyan
    Write-Host "  # Add to allowed list" -ForegroundColor White
    Write-Host "  Add-ADGroupMember -Identity 'Allowed RODC Password Replication Group' -Members 'BranchUsers'" -ForegroundColor White
    Write-Host ""
    Write-Host "  # Check revealed passwords" -ForegroundColor White
    Write-Host "  Get-ADDomainControllerPasswordReplicationPolicy -Identity 'RODC01' -Revealed" -ForegroundColor White
    
    Write-Host "`n[Step 3] RODC Security Best Practices" -ForegroundColor Yellow
    Write-Host "Security considerations:" -ForegroundColor Cyan
    Write-Host "  - Deploy RODCs in branch offices and DMZ" -ForegroundColor White
    Write-Host "  - Minimize password replication (least privilege)" -ForegroundColor White
    Write-Host "  - Add privileged accounts to Denied PRP group" -ForegroundColor White
    Write-Host "  - Regular audit of revealed passwords" -ForegroundColor White
    Write-Host "  - Implement admin role separation" -ForegroundColor White
    
    Write-Host "`n[INFO] RODC Features:" -ForegroundColor Cyan
    Write-Host "  - Read-only AD database" -ForegroundColor White
    Write-Host "  - Filtered attribute set" -ForegroundColor White
    Write-Host "  - Credential caching (controlled by PRP)" -ForegroundColor White
    Write-Host "  - Administrator role separation" -ForegroundColor White
    Write-Host "  - DNS read-only mode" -ForegroundColor White
    
} catch {
    Write-Host "[ERROR] $_" -ForegroundColor Red
    exit 1
}

Write-Host "`nDemo completed successfully!" -ForegroundColor Green
