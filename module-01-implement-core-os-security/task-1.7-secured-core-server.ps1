<#
.SYNOPSIS
    Task 1.7 - Configure and Verify Secured-core Server

.DESCRIPTION
    Demo script for AZ-801 Module 1: Implement Core OS Security
    This script demonstrates how to verify and configure Secured-core Server
    features including hardware-based security, virtualization-based security,
    and advanced threat protection.

.NOTES
    Module: Module 1 - Implement Core OS Security
    Task: 1.7 - Configure Secured-core Server

    Prerequisites:
    - Windows Server 2022 or later
    - Secured-core capable hardware
    - UEFI firmware with Secure Boot
    - TPM 2.0
    - Virtualization extensions enabled

    Lab Environment:
    - Secured-core certified server hardware
    - Windows Server 2022 Datacenter Edition

    PowerShell Version: 5.1+
#>

#Requires -RunAsAdministrator

# Script configuration
$ErrorActionPreference = 'Stop'

Write-Host "=== AZ-801 Module 1: Task 1.7 - Secured-core Server ===" -ForegroundColor Cyan
Write-Host ""

try {
    # Section 1: Check Secured-core Server requirements
    Write-Host "[Step 1] Checking Secured-core Server hardware requirements" -ForegroundColor Yellow

    # Check OS version
    $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
    Write-Host "Operating System: $($osInfo.Caption)" -ForegroundColor White
    Write-Host "Build Number: $($osInfo.BuildNumber)" -ForegroundColor White

    # Secured-core requires Windows Server 2022 (Build 20348 or higher)
    if ($osInfo.BuildNumber -ge 20348) {
        Write-Host "[SUCCESS] OS version supports Secured-core Server" -ForegroundColor Green
    } else {
        Write-Host "[WARNING] Secured-core Server requires Windows Server 2022 or later" -ForegroundColor Yellow
    }
    Write-Host ""

    # Section 2: Check TPM status
    Write-Host "[Step 2] Checking TPM (Trusted Platform Module) status" -ForegroundColor Yellow

    try {
        $tpm = Get-Tpm
        Write-Host "TPM Present: $($tpm.TpmPresent)" -ForegroundColor White
        Write-Host "TPM Ready: $($tpm.TpmReady)" -ForegroundColor White
        Write-Host "TPM Enabled: $($tpm.TpmEnabled)" -ForegroundColor White
        Write-Host "TPM Activated: $($tpm.TpmActivated)" -ForegroundColor White

        if ($tpm.TpmPresent -and $tpm.TpmReady) {
            # Get TPM version
            $tpmVersion = (Get-CimInstance -Namespace "Root\CIMv2\Security\MicrosoftTpm" -ClassName Win32_Tpm).SpecVersion
            Write-Host "TPM Specification Version: $tpmVersion" -ForegroundColor White

            if ($tpmVersion -like "2.0*") {
                Write-Host "[SUCCESS] TPM 2.0 detected - required for Secured-core" -ForegroundColor Green
            } else {
                Write-Host "[WARNING] TPM 2.0 required for Secured-core Server" -ForegroundColor Yellow
            }
        } else {
            Write-Host "[WARNING] TPM not present or not ready" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "[WARNING] Unable to query TPM status: $_" -ForegroundColor Yellow
    }
    Write-Host ""

    # Section 3: Check UEFI and Secure Boot
    Write-Host "[Step 3] Checking UEFI firmware and Secure Boot status" -ForegroundColor Yellow

    try {
        $computerInfo = Get-ComputerInfo
        Write-Host "Firmware Type: $($computerInfo.BiosFirmwareType)" -ForegroundColor White

        if ($computerInfo.BiosFirmwareType -eq "Uefi") {
            Write-Host "[SUCCESS] UEFI firmware detected" -ForegroundColor Green

            # Check Secure Boot
            $secureBootEnabled = Confirm-SecureBootUEFI
            Write-Host "Secure Boot Enabled: $secureBootEnabled" -ForegroundColor White

            if ($secureBootEnabled) {
                Write-Host "[SUCCESS] Secure Boot is enabled" -ForegroundColor Green
            } else {
                Write-Host "[WARNING] Secure Boot must be enabled for Secured-core" -ForegroundColor Yellow
            }
        } else {
            Write-Host "[WARNING] UEFI firmware required for Secured-core Server" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "[WARNING] Could not determine firmware type (may be in VM)" -ForegroundColor Yellow
    }
    Write-Host ""

    # Section 4: Check virtualization extensions
    Write-Host "[Step 4] Checking virtualization extensions" -ForegroundColor Yellow

    $processor = Get-CimInstance -ClassName Win32_Processor | Select-Object -First 1
    Write-Host "Processor: $($processor.Name)" -ForegroundColor White

    if ($processor.VirtualizationFirmwareEnabled) {
        Write-Host "Virtualization Extensions: Enabled" -ForegroundColor White
        Write-Host "[SUCCESS] Virtualization extensions are enabled in firmware" -ForegroundColor Green
    } else {
        Write-Host "Virtualization Extensions: Disabled" -ForegroundColor White
        Write-Host "[WARNING] Enable virtualization extensions (Intel VT-x or AMD-V) in BIOS/UEFI" -ForegroundColor Yellow
    }
    Write-Host ""

    # Section 5: Check Device Guard and Credential Guard
    Write-Host "[Step 5] Checking Virtualization-Based Security (VBS) status" -ForegroundColor Yellow

    $deviceGuard = Get-CimInstance -ClassName Win32_DeviceGuard -Namespace root\Microsoft\Windows\DeviceGuard -ErrorAction SilentlyContinue

    if ($deviceGuard) {
        Write-Host "VBS Status:" -ForegroundColor Cyan

        # Available Security Properties
        Write-Host "  Available Security Properties:" -ForegroundColor White
        $availableProperties = @{
            1 = "BaseVirtualizationSupport"
            2 = "SecureBoot"
            3 = "DMAProtection"
            4 = "SecureMemoryOverwrite"
            5 = "NXProtections"
            6 = "SMM Security Mitigations"
            7 = "ModeBasedExecution"
        }

        foreach ($prop in $deviceGuard.AvailableSecurityProperties) {
            if ($availableProperties.ContainsKey($prop)) {
                Write-Host "    - $($availableProperties[$prop])" -ForegroundColor White
            }
        }

        # Security Services Configured
        Write-Host "  Security Services Configured:" -ForegroundColor White
        $securityServices = @{
            1 = "Credential Guard"
            2 = "Hypervisor Enforced Code Integrity (HVCI)"
            3 = "System Guard Secure Launch"
            4 = "SMM Firmware Protection"
        }

        if ($deviceGuard.SecurityServicesConfigured) {
            foreach ($service in $deviceGuard.SecurityServicesConfigured) {
                if ($securityServices.ContainsKey($service)) {
                    Write-Host "    - $($securityServices[$service])" -ForegroundColor Green
                }
            }
        } else {
            Write-Host "    - None configured" -ForegroundColor Yellow
        }

        # Security Services Running
        Write-Host "  Security Services Running:" -ForegroundColor White
        if ($deviceGuard.SecurityServicesRunning) {
            foreach ($service in $deviceGuard.SecurityServicesRunning) {
                if ($securityServices.ContainsKey($service)) {
                    Write-Host "    - $($securityServices[$service])" -ForegroundColor Green
                }
            }
        } else {
            Write-Host "    - None running" -ForegroundColor Yellow
        }

        # VBS Running
        if ($deviceGuard.VirtualizationBasedSecurityStatus -eq 2) {
            Write-Host "[SUCCESS] Virtualization Based Security is running" -ForegroundColor Green
        } else {
            Write-Host "[INFO] VBS Status Code: $($deviceGuard.VirtualizationBasedSecurityStatus)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "[WARNING] Device Guard information not available" -ForegroundColor Yellow
    }
    Write-Host ""

    # Section 6: Check HVCI (Hypervisor-protected Code Integrity)
    Write-Host "[Step 6] Checking HVCI (Memory Integrity) status" -ForegroundColor Yellow

    $hvciKey = "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity"

    if (Test-Path $hvciKey) {
        $hvciEnabled = Get-ItemProperty -Path $hvciKey -Name "Enabled" -ErrorAction SilentlyContinue

        if ($hvciEnabled -and $hvciEnabled.Enabled -eq 1) {
            Write-Host "HVCI (Memory Integrity): Enabled" -ForegroundColor White
            Write-Host "[SUCCESS] Hypervisor-protected Code Integrity is enabled" -ForegroundColor Green
        } else {
            Write-Host "HVCI (Memory Integrity): Not Enabled" -ForegroundColor White
            Write-Host "[INFO] Enable in Windows Security > Device Security > Core isolation" -ForegroundColor Yellow
        }
    } else {
        Write-Host "[INFO] HVCI registry key not found" -ForegroundColor Yellow
    }
    Write-Host ""

    # Section 7: Check System Guard Secure Launch
    Write-Host "[Step 7] Checking System Guard Secure Launch (Dynamic Root of Trust)" -ForegroundColor Yellow

    Write-Host "`nSystem Guard Secure Launch provides:" -ForegroundColor Cyan
    Write-Host "  - Dynamic Root of Trust for Measurement (DRTM)" -ForegroundColor White
    Write-Host "  - Protection against firmware-level attacks" -ForegroundColor White
    Write-Host "  - Measured boot with runtime attestation" -ForegroundColor White
    Write-Host ""
    Write-Host "Requires:" -ForegroundColor Cyan
    Write-Host "  - Intel TXT or AMD Secure Startup capable processor" -ForegroundColor White
    Write-Host "  - Compatible firmware" -ForegroundColor White
    Write-Host "  - Windows Server 2022 Datacenter Edition" -ForegroundColor White
    Write-Host ""

    # Section 8: Generate Secured-core compliance report
    Write-Host "[Step 8] Generating Secured-core Server compliance report" -ForegroundColor Yellow

    $complianceReport = @"
Secured-core Server Compliance Report
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Computer: $env:COMPUTERNAME

=== Hardware Requirements ===
Processor: $($processor.Name)
Firmware Type: $($computerInfo.BiosFirmwareType)
TPM Present: $($tpm.TpmPresent)
TPM Version: $(if ($tpm.TpmPresent) { "2.0" } else { "Not Available" })
Virtualization Enabled: $($processor.VirtualizationFirmwareEnabled)

=== Security Features ===
Secure Boot: $(try { Confirm-SecureBootUEFI } catch { "Unknown" })
VBS Running: $(if ($deviceGuard.VirtualizationBasedSecurityStatus -eq 2) { "Yes" } else { "No" })
Credential Guard: $(if ($deviceGuard.SecurityServicesRunning -contains 1) { "Running" } else { "Not Running" })
HVCI: $(if ($hvciEnabled.Enabled -eq 1) { "Enabled" } else { "Not Enabled" })

=== Secured-core Pillars ===
1. Hardware Root of Trust: TPM 2.0 - $($tpm.TpmPresent -and $tpm.TpmReady)
2. Firmware Protection: Secure Boot - $(try { Confirm-SecureBootUEFI } catch { $false })
3. Virtualization-based Security: VBS - $(if ($deviceGuard.VirtualizationBasedSecurityStatus -eq 2) { "Running" } else { "Not Running" })

=== Recommendations ===
- Enable all Secured-core Server features
- Configure System Guard Secure Launch (if supported)
- Enable Memory Integrity (HVCI)
- Enable Credential Guard
- Keep firmware updated
- Monitor Windows Security Center

=== Secured-core Server Benefits ===
- Advanced threat protection at hardware level
- Protection against firmware attacks
- Isolation of sensitive processes
- Enhanced malware resistance
- Trusted platform attestation
"@

    $reportPath = "$env:TEMP\SecuredCoreReport-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"
    $complianceReport | Out-File -FilePath $reportPath -Encoding UTF8

    Write-Host "Compliance report saved to: $reportPath" -ForegroundColor White
    Write-Host "[SUCCESS] Report generated" -ForegroundColor Green
    Write-Host ""

    # Section 9: Configuration guidance
    Write-Host "[Step 9] Secured-core Server configuration guidance" -ForegroundColor Yellow

    Write-Host "`nTo fully enable Secured-core Server:" -ForegroundColor Cyan
    Write-Host "  1. Verify hardware compatibility (Secured-core certified)" -ForegroundColor White
    Write-Host "  2. Enable TPM 2.0 in firmware" -ForegroundColor White
    Write-Host "  3. Enable Secure Boot in firmware" -ForegroundColor White
    Write-Host "  4. Enable virtualization extensions in firmware" -ForegroundColor White
    Write-Host "  5. Install Windows Server 2022 Datacenter Edition" -ForegroundColor White
    Write-Host "  6. Enable VBS and Credential Guard via GPO or registry" -ForegroundColor White
    Write-Host "  7. Enable Memory Integrity (HVCI) in Windows Security" -ForegroundColor White
    Write-Host "  8. Enable System Guard Secure Launch (if supported)" -ForegroundColor White
    Write-Host "  9. Configure Windows Defender and security baselines" -ForegroundColor White
    Write-Host "  10. Monitor with Microsoft Defender for Cloud" -ForegroundColor White
    Write-Host ""

    # Section 10: Educational notes
    Write-Host "[INFO] Secured-core Server Best Practices:" -ForegroundColor Cyan
    Write-Host "  - Use only Secured-core certified hardware" -ForegroundColor White
    Write-Host "  - Keep firmware and microcode up to date" -ForegroundColor White
    Write-Host "  - Enable all VBS-based security features" -ForegroundColor White
    Write-Host "  - Use System Guard runtime attestation" -ForegroundColor White
    Write-Host "  - Monitor security events and attestation reports" -ForegroundColor White
    Write-Host "  - Deploy security baselines via Group Policy" -ForegroundColor White
    Write-Host "  - Integrate with Microsoft Defender for Cloud" -ForegroundColor White
    Write-Host "  - Regular compliance audits and vulnerability assessments" -ForegroundColor White
    Write-Host ""

} catch {
    Write-Host "[ERROR] $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

Write-Host "Demo completed successfully!" -ForegroundColor Green
Write-Host "Next Steps: Enable remaining Secured-core features and verify compliance" -ForegroundColor Yellow
