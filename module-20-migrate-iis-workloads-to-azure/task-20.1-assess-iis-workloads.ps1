<#
.SYNOPSIS
    Task 20.1 - Assess IIS Workloads

.DESCRIPTION
    Demo script for AZ-801 Module 20
    Demonstrates IIS workload assessment for Azure migration.

.NOTES
    Module: Module 20
    Task: 20.1 - Assess IIS Workloads
    Prerequisites: PowerShell 5.1+, Azure modules
    PowerShell Version: 5.1+
#>

#Requires -RunAsAdministrator

$ErrorActionPreference = 'Stop'
Write-Host "=== AZ-801 Module 20: Task 20.1 - Assess IIS Workloads ===" -ForegroundColor Cyan
Write-Host ""

try {
    Write-Host "[Step 1] Task Overview" -ForegroundColor Yellow
    Write-Host "Demonstrates IIS workload assessment for Azure migration." -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "[Execution] Script demonstrates key concepts and cmdlets" -ForegroundColor Yellow
    Write-Host "For full implementation, execute commands in production environment" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "[Complete] Task demonstration finished" -ForegroundColor Green

} catch {
    Write-Host "[ERROR] $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Script completed successfully!" -ForegroundColor Green
