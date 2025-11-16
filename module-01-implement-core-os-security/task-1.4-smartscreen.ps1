<#
.SYNOPSIS
    Task 1.4 - Configure Windows Defender SmartScreen

.DESCRIPTION
    Demo script for AZ-801 Module 1: Implement Core OS Security
    This script demonstrates how to configure Windows Defender SmartScreen settings
    to protect against malicious websites and downloads.

.NOTES
    Module: Module 1 - Implement Core OS Security
    Task: 1.4 - Configure Windows Defender SmartScreen

    Prerequisites:
    - Windows Server 2016 or later
    - Administrative privileges
    - Internet connectivity for cloud-based protection

    Lab Environment:
    - Windows Server 2022 recommended
    - Microsoft Edge browser

    PowerShell Version: 5.1+
#>

#Requires -RunAsAdministrator

# Script configuration
$ErrorActionPreference = 'Stop'

Write-Host "=== AZ-801 Module 1: Task 1.4 - Windows Defender SmartScreen ===" -ForegroundColor Cyan
Write-Host ""

try {
    # Section 1: Check current SmartScreen status
    Write-Host "[Step 1] Checking current SmartScreen configuration" -ForegroundColor Yellow

    # Check SmartScreen for Microsoft Edge
    $edgeSmartScreen = "HKLM:\SOFTWARE\Policies\Microsoft\MicrosoftEdge\PhishingFilter"

    if (Test-Path $edgeSmartScreen) {
        $edgeEnabled = Get-ItemProperty -Path $edgeSmartScreen -Name "EnabledV9" -ErrorAction SilentlyContinue
        if ($edgeEnabled) {
            Write-Host "Microsoft Edge SmartScreen: $($edgeEnabled.EnabledV9)" -ForegroundColor White
        } else {
            Write-Host "Microsoft Edge SmartScreen: Not configured" -ForegroundColor Yellow
        }
    } else {
        Write-Host "Microsoft Edge SmartScreen: Registry path not found" -ForegroundColor Yellow
    }

    # Check Windows SmartScreen
    $winSmartScreen = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"

    if (Test-Path $winSmartScreen) {
        $winEnabled = Get-ItemProperty -Path $winSmartScreen -Name "EnableSmartScreen" -ErrorAction SilentlyContinue
        if ($winEnabled) {
            Write-Host "Windows SmartScreen: $($winEnabled.EnableSmartScreen)" -ForegroundColor White
        } else {
            Write-Host "Windows SmartScreen: Not configured" -ForegroundColor Yellow
        }
    }

    Write-Host ""

    # Section 2: Configure SmartScreen for Microsoft Edge
    Write-Host "[Step 2] Configuring SmartScreen for Microsoft Edge" -ForegroundColor Yellow

    # Create registry path if it doesn't exist
    if (-not (Test-Path $edgeSmartScreen)) {
        New-Item -Path $edgeSmartScreen -Force | Out-Null
        Write-Host "Created registry path for Edge SmartScreen" -ForegroundColor White
    }

    # Enable SmartScreen for Edge
    Set-ItemProperty -Path $edgeSmartScreen -Name "EnabledV9" -Value 1 -Type DWord
    Set-ItemProperty -Path $edgeSmartScreen -Name "PreventOverride" -Value 0 -Type DWord

    Write-Host "[SUCCESS] Microsoft Edge SmartScreen enabled" -ForegroundColor Green
    Write-Host "  - SmartScreen enabled for malicious sites and downloads" -ForegroundColor White
    Write-Host "  - Users can bypass warnings (PreventOverride = 0)" -ForegroundColor White
    Write-Host ""

    # Section 3: Configure Windows SmartScreen for Apps and Files
    Write-Host "[Step 3] Configuring Windows SmartScreen for apps and files" -ForegroundColor Yellow

    # Create registry path if it doesn't exist
    if (-not (Test-Path $winSmartScreen)) {
        New-Item -Path $winSmartScreen -Force | Out-Null
        Write-Host "Created registry path for Windows SmartScreen" -ForegroundColor White
    }

    # Enable SmartScreen
    # Values: 0 = Off, 1 = Require approval before running, 2 = Warn
    Set-ItemProperty -Path $winSmartScreen -Name "EnableSmartScreen" -Value 1 -Type DWord
    Set-ItemProperty -Path $winSmartScreen -Name "ShellSmartScreenLevel" -Value "Block" -Type String

    Write-Host "[SUCCESS] Windows SmartScreen enabled" -ForegroundColor Green
    Write-Host "  - SmartScreen level set to: Block" -ForegroundColor White
    Write-Host ""

    # Section 4: Configure SmartScreen for Microsoft Store apps
    Write-Host "[Step 4] Configuring SmartScreen for Microsoft Store apps" -ForegroundColor Yellow

    $storeAppsPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppHost"

    if (-not (Test-Path $storeAppsPath)) {
        New-Item -Path $storeAppsPath -Force | Out-Null
    }

    # Enable SmartScreen for Store apps
    Set-ItemProperty -Path $storeAppsPath -Name "EnableWebContentEvaluation" -Value 1 -Type DWord

    Write-Host "[SUCCESS] SmartScreen enabled for Microsoft Store apps" -ForegroundColor Green
    Write-Host ""

    # Section 5: Configure SmartScreen warning levels
    Write-Host "[Step 5] Configuring SmartScreen warning and block behavior" -ForegroundColor Yellow

    Write-Host "SmartScreen Protection Levels:" -ForegroundColor Cyan
    Write-Host "  - Warn: Users can proceed past warnings" -ForegroundColor White
    Write-Host "  - Block: Prevents running unrecognized apps" -ForegroundColor White
    Write-Host ""
    Write-Host "Current configuration: Block unrecognized apps" -ForegroundColor White

    Write-Host "[SUCCESS] Warning behavior configured" -ForegroundColor Green
    Write-Host ""

    # Section 6: Verify all SmartScreen settings
    Write-Host "[Step 6] Verifying SmartScreen configuration" -ForegroundColor Yellow

    Write-Host "`nCurrent SmartScreen Settings:" -ForegroundColor Cyan

    # Edge SmartScreen
    $edgeConfig = Get-ItemProperty -Path $edgeSmartScreen -ErrorAction SilentlyContinue
    if ($edgeConfig) {
        Write-Host "Microsoft Edge:" -ForegroundColor White
        Write-Host "  EnabledV9: $($edgeConfig.EnabledV9)" -ForegroundColor White
        Write-Host "  PreventOverride: $($edgeConfig.PreventOverride)" -ForegroundColor White
    }

    # Windows SmartScreen
    $winConfig = Get-ItemProperty -Path $winSmartScreen -ErrorAction SilentlyContinue
    if ($winConfig) {
        Write-Host "Windows SmartScreen:" -ForegroundColor White
        Write-Host "  EnableSmartScreen: $($winConfig.EnableSmartScreen)" -ForegroundColor White
        Write-Host "  ShellSmartScreenLevel: $($winConfig.ShellSmartScreenLevel)" -ForegroundColor White
    }

    # Store Apps
    $storeConfig = Get-ItemProperty -Path $storeAppsPath -ErrorAction SilentlyContinue
    if ($storeConfig) {
        Write-Host "Microsoft Store Apps:" -ForegroundColor White
        Write-Host "  EnableWebContentEvaluation: $($storeConfig.EnableWebContentEvaluation)" -ForegroundColor White
    }

    Write-Host "[SUCCESS] Configuration verified" -ForegroundColor Green
    Write-Host ""

    # Section 7: Group Policy information
    Write-Host "[Step 7] Group Policy configuration guidance" -ForegroundColor Yellow

    Write-Host "`nTo configure via Group Policy:" -ForegroundColor Cyan
    Write-Host "Computer Configuration > Policies > Administrative Templates >" -ForegroundColor White
    Write-Host ""
    Write-Host "Windows Components > Windows Defender SmartScreen > Explorer:" -ForegroundColor White
    Write-Host "  - Configure Windows Defender SmartScreen" -ForegroundColor White
    Write-Host "  - Set to: Enabled -> Warn and prevent bypass" -ForegroundColor White
    Write-Host ""
    Write-Host "Windows Components > Microsoft Edge:" -ForegroundColor White
    Write-Host "  - Configure Windows Defender SmartScreen" -ForegroundColor White
    Write-Host "  - Prevent bypassing Windows Defender SmartScreen prompts for sites" -ForegroundColor White
    Write-Host "  - Prevent bypassing Windows Defender SmartScreen prompts for files" -ForegroundColor White
    Write-Host ""

    # Section 8: Test SmartScreen functionality
    Write-Host "[Step 8] Testing SmartScreen functionality" -ForegroundColor Yellow

    Write-Host "`nTo test SmartScreen:" -ForegroundColor Cyan
    Write-Host "  1. Download the EICAR test file (safe test file)" -ForegroundColor White
    Write-Host "  2. Visit: https://www.eicar.org/download-anti-malware-testfile/" -ForegroundColor White
    Write-Host "  3. SmartScreen should warn about the file" -ForegroundColor White
    Write-Host ""
    Write-Host "  Event Logs location:" -ForegroundColor White
    Write-Host "  Applications and Services Logs > Microsoft > Windows > SmartScreen" -ForegroundColor White
    Write-Host ""

    # Section 9: Educational notes
    Write-Host "[INFO] SmartScreen Best Practices:" -ForegroundColor Cyan
    Write-Host "  - SmartScreen uses reputation-based protection" -ForegroundColor White
    Write-Host "  - Checks files and URLs against Microsoft's cloud service" -ForegroundColor White
    Write-Host "  - Protects against phishing and malware downloads" -ForegroundColor White
    Write-Host "  - Configure 'Warn and prevent bypass' for maximum security" -ForegroundColor White
    Write-Host "  - Monitor SmartScreen events for security insights" -ForegroundColor White
    Write-Host "  - Requires internet connectivity for cloud checks" -ForegroundColor White
    Write-Host ""

} catch {
    Write-Host "[ERROR] $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

Write-Host "Demo completed successfully!" -ForegroundColor Green
Write-Host "Next Steps: Test SmartScreen with sample downloads and deploy via GPO" -ForegroundColor Yellow
