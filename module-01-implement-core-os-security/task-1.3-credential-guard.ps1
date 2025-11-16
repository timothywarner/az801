<#
.SYNOPSIS
    Task 1.3 - Enable and Configure Windows Defender Credential Guard

.DESCRIPTION
    Demo script for AZ-801 Module 1: Implement Core OS Security
    This script demonstrates how to check requirements for and enable Windows Defender
    Credential Guard to protect domain credentials from theft.

.NOTES
    Module: Module 1 - Implement Core OS Security
    Task: 1.3 - Enable Windows Defender Credential Guard

    Prerequisites:
    - Windows Server 2016 or later
    - UEFI firmware with Secure Boot
    - Virtualization extensions (Intel VT-x or AMD-V)
    - Administrative privileges

    Lab Environment:
    - Windows Server 2022 recommended
    - Hyper-V capable hardware

    PowerShell Version: 5.1+
#>

#Requires -RunAsAdministrator

# Script configuration
$ErrorActionPreference = 'Stop'

Write-Host "=== AZ-801 Module 1: Task 1.3 - Windows Defender Credential Guard ===" -ForegroundColor Cyan
Write-Host ""

try {
    # Section 1: Check hardware and firmware requirements
    Write-Host "[Step 1] Checking Credential Guard requirements" -ForegroundColor Yellow

    # Check OS version
    $osVersion = [System.Environment]::OSVersion.Version
    Write-Host "Operating System Version: $($osVersion.Major).$($osVersion.Minor).$($osVersion.Build)" -ForegroundColor White

    # Check for UEFI firmware
    try {
        $firmwareType = (Get-ComputerInfo).BiosFirmwareType
        Write-Host "Firmware Type: $firmwareType" -ForegroundColor White

        if ($firmwareType -eq "Uefi") {
            Write-Host "[SUCCESS] UEFI firmware detected" -ForegroundColor Green
        } else {
            Write-Host "[WARNING] Legacy BIOS detected - UEFI required for Credential Guard" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "[WARNING] Could not determine firmware type" -ForegroundColor Yellow
    }

    # Check virtualization support
    $vmExtensions = (Get-CimInstance -ClassName Win32_Processor).VirtualizationFirmwareEnabled
    Write-Host "Virtualization Extensions Enabled: $vmExtensions" -ForegroundColor White

    # Check Secure Boot status
    try {
        $secureBootEnabled = Confirm-SecureBootUEFI
        Write-Host "Secure Boot Enabled: $secureBootEnabled" -ForegroundColor White

        if ($secureBootEnabled) {
            Write-Host "[SUCCESS] Secure Boot is enabled" -ForegroundColor Green
        } else {
            Write-Host "[WARNING] Secure Boot is not enabled - required for Credential Guard" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "[WARNING] Could not determine Secure Boot status (may be running in VM)" -ForegroundColor Yellow
    }

    Write-Host ""

    # Section 2: Check current Credential Guard status
    Write-Host "[Step 2] Checking current Credential Guard status" -ForegroundColor Yellow

    $deviceGuard = Get-CimInstance -ClassName Win32_DeviceGuard -Namespace root\Microsoft\Windows\DeviceGuard -ErrorAction SilentlyContinue

    if ($deviceGuard) {
        Write-Host "Security Services Configured:" -ForegroundColor White
        if ($deviceGuard.SecurityServicesConfigured -contains 1) {
            Write-Host "  - Credential Guard: Configured" -ForegroundColor Green
        } else {
            Write-Host "  - Credential Guard: Not Configured" -ForegroundColor Yellow
        }

        Write-Host "Security Services Running:" -ForegroundColor White
        if ($deviceGuard.SecurityServicesRunning -contains 1) {
            Write-Host "  - Credential Guard: Running" -ForegroundColor Green
        } else {
            Write-Host "  - Credential Guard: Not Running" -ForegroundColor Yellow
        }
    } else {
        Write-Host "[INFO] Device Guard information not available" -ForegroundColor Yellow
    }

    Write-Host ""

    # Section 3: Enable Hyper-V and required features
    Write-Host "[Step 3] Enabling required Windows features" -ForegroundColor Yellow

    # Check if Hyper-V is installed
    $hypervFeature = Get-WindowsFeature -Name Hyper-V -ErrorAction SilentlyContinue

    if ($hypervFeature -and $hypervFeature.InstallState -ne 'Installed') {
        Write-Host "Installing Hyper-V feature..." -ForegroundColor White
        Install-WindowsFeature -Name Hyper-V -IncludeManagementTools -Verbose
        Write-Host "[SUCCESS] Hyper-V feature installed (reboot required)" -ForegroundColor Green
    } elseif ($hypervFeature) {
        Write-Host "Hyper-V feature is already installed" -ForegroundColor White
    } else {
        Write-Host "[WARNING] Hyper-V feature not available on this system" -ForegroundColor Yellow
    }

    Write-Host ""

    # Section 4: Enable Credential Guard via Registry
    Write-Host "[Step 4] Configuring Credential Guard via registry" -ForegroundColor Yellow

    $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard"

    if (-not (Test-Path $regPath)) {
        New-Item -Path $regPath -Force | Out-Null
        Write-Host "Created registry path: $regPath" -ForegroundColor White
    }

    # Enable Virtualization Based Security
    Set-ItemProperty -Path $regPath -Name "EnableVirtualizationBasedSecurity" -Value 1 -Type DWord
    Set-ItemProperty -Path $regPath -Name "RequirePlatformSecurityFeatures" -Value 1 -Type DWord

    Write-Host "Enabled Virtualization Based Security" -ForegroundColor White

    # Enable Credential Guard
    $regPathLsa = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"

    if (-not (Test-Path $regPathLsa)) {
        New-Item -Path $regPathLsa -Force | Out-Null
    }

    Set-ItemProperty -Path $regPathLsa -Name "LsaCfgFlags" -Value 1 -Type DWord

    Write-Host "Enabled Credential Guard with UEFI lock" -ForegroundColor White
    Write-Host "[SUCCESS] Registry configuration complete" -ForegroundColor Green
    Write-Host ""

    # Section 5: Configure via Group Policy (示example)
    Write-Host "[Step 5] Group Policy configuration guidance" -ForegroundColor Yellow

    Write-Host "`nTo enable via Group Policy:" -ForegroundColor Cyan
    Write-Host "  Path: Computer Configuration > Policies > Administrative Templates >" -ForegroundColor White
    Write-Host "        System > Device Guard" -ForegroundColor White
    Write-Host ""
    Write-Host "  Setting: Turn On Virtualization Based Security" -ForegroundColor White
    Write-Host "    - Set to: Enabled" -ForegroundColor White
    Write-Host "    - Select Platform Security Level: Secure Boot and DMA Protection" -ForegroundColor White
    Write-Host "    - Credential Guard Configuration: Enabled with UEFI lock" -ForegroundColor White
    Write-Host ""

    # Section 6: Verify registry settings
    Write-Host "[Step 6] Verifying registry configuration" -ForegroundColor Yellow

    $vbsEnabled = Get-ItemProperty -Path $regPath -Name "EnableVirtualizationBasedSecurity" -ErrorAction SilentlyContinue
    $cgEnabled = Get-ItemProperty -Path $regPathLsa -Name "LsaCfgFlags" -ErrorAction SilentlyContinue

    Write-Host "Current Registry Settings:" -ForegroundColor White
    Write-Host "  VBS Enabled: $($vbsEnabled.EnableVirtualizationBasedSecurity)" -ForegroundColor White
    Write-Host "  Credential Guard: $($cgEnabled.LsaCfgFlags)" -ForegroundColor White

    Write-Host "[SUCCESS] Configuration verified" -ForegroundColor Green
    Write-Host ""

    # Section 7: Check for required reboot
    Write-Host "[Step 7] System reboot requirement" -ForegroundColor Yellow

    Write-Host "[IMPORTANT] A system reboot is REQUIRED for Credential Guard to take effect" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "After reboot, verify with:" -ForegroundColor White
    Write-Host "  Get-CimInstance -ClassName Win32_DeviceGuard -Namespace root\Microsoft\Windows\DeviceGuard" -ForegroundColor White
    Write-Host ""

    # Section 8: Educational notes
    Write-Host "[INFO] Credential Guard Best Practices:" -ForegroundColor Cyan
    Write-Host "  - Protects NTLM password hashes and Kerberos TGTs" -ForegroundColor White
    Write-Host "  - Uses virtualization-based security (VBS)" -ForegroundColor White
    Write-Host "  - Requires UEFI, Secure Boot, and virtualization extensions" -ForegroundColor White
    Write-Host "  - UEFI lock prevents disabling via registry" -ForegroundColor White
    Write-Host "  - Deploy via Group Policy for enterprise rollout" -ForegroundColor White
    Write-Host "  - Monitor Event Viewer: Applications and Services Logs > Microsoft > Windows > LSA" -ForegroundColor White
    Write-Host ""

} catch {
    Write-Host "[ERROR] $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

Write-Host "Demo completed successfully!" -ForegroundColor Green
Write-Host "Next Steps: Reboot the system and verify Credential Guard is running" -ForegroundColor Yellow
