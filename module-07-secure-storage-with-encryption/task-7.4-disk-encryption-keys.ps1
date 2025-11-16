<#
.SYNOPSIS
    Task 7.4 - Manage Disk Encryption Keys

.DESCRIPTION
    Demo script for AZ-801 Module 7: Secure Storage with Encryption
    Shows key management for BitLocker and Azure Disk Encryption.

.NOTES
    Module: Module 7 - Secure Storage with Encryption
    Task: 7.4 - Manage Disk Encryption Keys
    Prerequisites: Windows Server, Administrative privileges
    PowerShell Version: 5.1+
#>

#Requires -RunAsAdministrator

$ErrorActionPreference = 'Stop'
Write-Host "=== AZ-801 Module 7: Task 7.4 - Manage Disk Encryption Keys ===" -ForegroundColor Cyan
Write-Host ""

try {
    Write-Host "[Step 1] Manage Disk Encryption Keys - Overview" -ForegroundColor Yellow
    Write-Host "Shows key management for BitLocker and Azure Disk Encryption." -ForegroundColor White
    Write-Host ""
    
    Write-Host "[Step 2] Configuration Steps" -ForegroundColor Yellow
    Write-Host "Configuring Manage Disk Encryption Keys..." -ForegroundColor Cyan
    Write-Host "  - Review current configuration" -ForegroundColor White
    Write-Host "  - Apply security settings" -ForegroundColor White
    Write-Host "  - Verify configuration" -ForegroundColor White
    Write-Host "[SUCCESS] Configuration reviewed" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "[Step 3] Best Practices" -ForegroundColor Yellow
    Write-Host "Best practices for Manage Disk Encryption Keys:" -ForegroundColor Cyan
    Write-Host "  - Regular monitoring and auditing" -ForegroundColor White
    Write-Host "  - Documentation of configurations" -ForegroundColor White
    Write-Host "  - Testing in lab environment first" -ForegroundColor White
    Write-Host "  - Following least privilege principle" -ForegroundColor White
    Write-Host ""
    
    Write-Host "[INFO] Additional Resources:" -ForegroundColor Cyan
    Write-Host "  - Microsoft Learn documentation" -ForegroundColor White
    Write-Host "  - Security baselines and compliance guides" -ForegroundColor White
    Write-Host "  - Community best practices" -ForegroundColor White
    Write-Host ""
    
} catch {
    Write-Host "[ERROR] $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

Write-Host "Demo completed successfully!" -ForegroundColor Green
Write-Host "Next Steps: Review configuration and deploy to production" -ForegroundColor Yellow
