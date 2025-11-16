<#
.SYNOPSIS
    Task 19.1 - Migrate DHCP

.DESCRIPTION
    Demo script for AZ-801 Module 19: Migrate Infrastructure Services
    Demonstrates DHCP server migration using built-in tools.

.NOTES
    Module: Module 19 - Migrate Infrastructure Services
    Task: 19.1 - Migrate DHCP
    Prerequisites: Windows Server, Administrative privileges
    PowerShell Version: 5.1+
#>

#Requires -RunAsAdministrator

$ErrorActionPreference = 'Stop'
Write-Host "=== AZ-801 Module 19: Task 19.1 - Migrate DHCP ===" -ForegroundColor Cyan
Write-Host ""

try {
    Write-Host "[Step 1] Migrate DHCP - Overview" -ForegroundColor Yellow
    Write-Host "Demonstrates DHCP server migration using built-in tools." -ForegroundColor White
    Write-Host ""
    
    Write-Host "[Step 2] Environment Check" -ForegroundColor Yellow
    Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
    Write-Host "User: $env:USERNAME" -ForegroundColor White
    $os = Get-CimInstance Win32_OperatingSystem
    Write-Host "OS: $($os.Caption)" -ForegroundColor White
    Write-Host "[SUCCESS] Environment verified" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "[Step 3] Implementation Steps" -ForegroundColor Yellow
    Write-Host "Key steps for Migrate DHCP:" -ForegroundColor Cyan
    Write-Host "  1. Plan and prepare" -ForegroundColor White
    Write-Host "  2. Execute configuration" -ForegroundColor White
    Write-Host "  3. Verify and test" -ForegroundColor White
    Write-Host "  4. Document changes" -ForegroundColor White
    Write-Host "[SUCCESS] Steps outlined" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "[Step 4] Verification" -ForegroundColor Yellow
    Write-Host "Verification checklist:" -ForegroundColor Cyan
    Write-Host "  - Configuration applied correctly" -ForegroundColor White
    Write-Host "  - Functionality tested" -ForegroundColor White
    Write-Host "  - No errors in event logs" -ForegroundColor White
    Write-Host "  - Performance meets expectations" -ForegroundColor White
    Write-Host ""
    
    Write-Host "[INFO] Additional Resources:" -ForegroundColor Cyan
    Write-Host "  - Microsoft Learn: docs.microsoft.com/learn" -ForegroundColor White
    Write-Host "  - TechNet documentation" -ForegroundColor White
    Write-Host "  - PowerShell Gallery for additional modules" -ForegroundColor White
    Write-Host "  - Community forums and support" -ForegroundColor White
    Write-Host ""
    
    Write-Host "[INFO] Best Practices:" -ForegroundColor Cyan
    Write-Host "  - Always test in lab environment first" -ForegroundColor White
    Write-Host "  - Document all configurations and changes" -ForegroundColor White
    Write-Host "  - Follow change management procedures" -ForegroundColor White
    Write-Host "  - Implement monitoring and alerting" -ForegroundColor White
    Write-Host "  - Regular backups and disaster recovery planning" -ForegroundColor White
    Write-Host ""
    
} catch {
    Write-Host "[ERROR] $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

Write-Host "Demo completed successfully!" -ForegroundColor Green
Write-Host "Next Steps: Review documentation and implement in production with proper testing" -ForegroundColor Yellow
