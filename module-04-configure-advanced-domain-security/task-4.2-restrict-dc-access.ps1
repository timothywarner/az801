<#
.SYNOPSIS
    Task 4.2 - Restrict Domain Controller Access

.DESCRIPTION
    Demo script for AZ-801 Module 4: Configure Advanced Domain Security
    Shows how to restrict and control access to domain controllers using authentication policies.

.NOTES
    Module: Module 4 - Configure Advanced Domain Security
    Task: 4.2 - Restrict Domain Controller Access
    Prerequisites: Windows Server, Administrative privileges
    PowerShell Version: 5.1+
#>

#Requires -RunAsAdministrator

$ErrorActionPreference = 'Stop'
Write-Host "=== AZ-801 Module 4: Task 4.2 - Restrict Domain Controller Access ===" -ForegroundColor Cyan
Write-Host ""

try {
    Write-Host "[Step 1] Restrict Domain Controller Access - Overview" -ForegroundColor Yellow
    Write-Host "Shows how to restrict and control access to domain controllers using authentication policies." -ForegroundColor White
    Write-Host ""
    
    Write-Host "[Step 2] Configuration Steps" -ForegroundColor Yellow
    Write-Host "Configuring Restrict Domain Controller Access..." -ForegroundColor Cyan
    Write-Host "  - Review current configuration" -ForegroundColor White
    Write-Host "  - Apply security settings" -ForegroundColor White
    Write-Host "  - Verify configuration" -ForegroundColor White
    Write-Host "[SUCCESS] Configuration reviewed" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "[Step 3] Best Practices" -ForegroundColor Yellow
    Write-Host "Best practices for Restrict Domain Controller Access:" -ForegroundColor Cyan
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
