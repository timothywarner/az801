<#
.SYNOPSIS
    Task 1.2 - Configure Windows Defender Application Control (WDAC)

.DESCRIPTION
    Demo script for AZ-801 Module 1: Implement Core OS Security
    This script demonstrates how to create and manage Windows Defender Application Control
    policies to control which applications can run on Windows Server.

.NOTES
    Module: Module 1 - Implement Core OS Security
    Task: 1.2 - Configure Windows Defender Application Control (WDAC)

    Prerequisites:
    - Windows Server 2016 or later
    - Administrative privileges
    - Understanding of code integrity policies

    Lab Environment:
    - Windows Server 2022 recommended
    - Test applications available

    PowerShell Version: 5.1+
#>

#Requires -RunAsAdministrator

# Script configuration
$ErrorActionPreference = 'Stop'

Write-Host "=== AZ-801 Module 1: Task 1.2 - Windows Defender Application Control (WDAC) ===" -ForegroundColor Cyan
Write-Host ""

try {
    # Section 1: Check WDAC capability
    Write-Host "[Step 1] Checking Windows Defender Application Control capability" -ForegroundColor Yellow

    $osVersion = [System.Environment]::OSVersion.Version
    Write-Host "Operating System Version: $($osVersion.Major).$($osVersion.Minor).$($osVersion.Build)" -ForegroundColor White

    if ($osVersion.Build -ge 14393) {
        Write-Host "[SUCCESS] WDAC is supported on this system" -ForegroundColor Green
    } else {
        Write-Host "[WARNING] WDAC requires Windows Server 2016 or later" -ForegroundColor Yellow
    }
    Write-Host ""

    # Section 2: Create WDAC policy directory
    Write-Host "[Step 2] Creating WDAC policy directory structure" -ForegroundColor Yellow

    $policyPath = "C:\WDAC\Policies"
    if (-not (Test-Path $policyPath)) {
        New-Item -Path $policyPath -ItemType Directory -Force | Out-Null
        Write-Host "Created policy directory: $policyPath" -ForegroundColor White
    }

    Write-Host "[SUCCESS] Policy directory ready" -ForegroundColor Green
    Write-Host ""

    # Section 3: Create initial WDAC policy (Audit mode)
    Write-Host "[Step 3] Creating initial WDAC policy in AUDIT mode" -ForegroundColor Yellow

    $initialPolicyPath = "$policyPath\InitialPolicy.xml"
    $scanPath = "C:\Windows\System32"  # Scan system files

    Write-Host "Scanning trusted files in: $scanPath" -ForegroundColor White
    Write-Host "This may take a few minutes..." -ForegroundColor White

    # Create a policy based on scanning system files
    New-CIPolicy -FilePath $initialPolicyPath `
                 -Level FilePublisher `
                 -Fallback Hash `
                 -ScanPath $scanPath `
                 -UserPEs `
                 -MultiplePolicyFormat

    Write-Host "[SUCCESS] Initial policy created: $initialPolicyPath" -ForegroundColor Green
    Write-Host ""

    # Section 4: Configure policy for Audit mode
    Write-Host "[Step 4] Configuring policy for Audit mode (non-blocking)" -ForegroundColor Yellow

    # Set policy to Audit mode - this allows monitoring without blocking
    Set-RuleOption -FilePath $initialPolicyPath -Option 3  # Audit Mode
    Set-RuleOption -FilePath $initialPolicyPath -Option 9  # Advanced Boot Menu
    Set-RuleOption -FilePath $initialPolicyPath -Option 10 # Boot Audit on Failure

    Write-Host "Enabled Rule Options:" -ForegroundColor White
    Write-Host "  Option 3: Audit Mode (Enabled)" -ForegroundColor White
    Write-Host "  Option 9: Advanced Boot Options Menu" -ForegroundColor White
    Write-Host "  Option 10: Boot Audit on Failure" -ForegroundColor White

    Write-Host "[SUCCESS] Policy configured for Audit mode" -ForegroundColor Green
    Write-Host ""

    # Section 5: Create supplemental policy example
    Write-Host "[Step 5] Creating example supplemental policy for custom applications" -ForegroundColor Yellow

    $supplementalPolicyPath = "$policyPath\SupplementalPolicy.xml"
    $customAppPath = "C:\Program Files"

    if (Test-Path $customAppPath) {
        Write-Host "Creating supplemental policy for: $customAppPath" -ForegroundColor White

        New-CIPolicy -FilePath $supplementalPolicyPath `
                     -Level FilePublisher `
                     -Fallback Hash `
                     -ScanPath $customAppPath `
                     -UserPEs `
                     -MultiplePolicyFormat

        Write-Host "[SUCCESS] Supplemental policy created" -ForegroundColor Green
    } else {
        Write-Host "[INFO] Custom application path not found, skipping supplemental policy" -ForegroundColor Yellow
    }
    Write-Host ""

    # Section 6: Convert policy to binary format
    Write-Host "[Step 6] Converting policy to binary format for deployment" -ForegroundColor Yellow

    $binaryPolicyPath = "$policyPath\InitialPolicy.bin"

    ConvertFrom-CIPolicy -XmlFilePath $initialPolicyPath -BinaryFilePath $binaryPolicyPath

    if (Test-Path $binaryPolicyPath) {
        Write-Host "Binary policy created: $binaryPolicyPath" -ForegroundColor White
        Write-Host "[SUCCESS] Policy converted to binary format" -ForegroundColor Green
    }
    Write-Host ""

    # Section 7: Display deployment instructions
    Write-Host "[Step 7] WDAC Policy Deployment Information" -ForegroundColor Yellow

    Write-Host "`nTo deploy this policy:" -ForegroundColor Cyan
    Write-Host "  1. Copy binary policy to: C:\Windows\System32\CodeIntegrity\CiPolicies\Active\" -ForegroundColor White
    Write-Host "  2. Rename to: {Policy-GUID}.cip" -ForegroundColor White
    Write-Host "  3. Reboot the system to activate" -ForegroundColor White
    Write-Host ""
    Write-Host "Current policy files:" -ForegroundColor Cyan
    Write-Host "  XML Policy: $initialPolicyPath" -ForegroundColor White
    Write-Host "  Binary Policy: $binaryPolicyPath" -ForegroundColor White
    Write-Host ""

    # Section 8: Check for existing WDAC policies
    Write-Host "[Step 8] Checking for existing deployed policies" -ForegroundColor Yellow

    $activePolicyPath = "C:\Windows\System32\CodeIntegrity\CiPolicies\Active"
    if (Test-Path $activePolicyPath) {
        $activePolicies = Get-ChildItem -Path $activePolicyPath -Filter "*.cip" -ErrorAction SilentlyContinue

        if ($activePolicies) {
            Write-Host "Active WDAC policies found:" -ForegroundColor White
            $activePolicies | ForEach-Object {
                Write-Host "  - $($_.Name)" -ForegroundColor White
            }
        } else {
            Write-Host "No active WDAC policies currently deployed" -ForegroundColor White
        }
    }

    Write-Host "[SUCCESS] Policy check complete" -ForegroundColor Green
    Write-Host ""

    # Section 9: Educational notes
    Write-Host "[INFO] WDAC Best Practices:" -ForegroundColor Cyan
    Write-Host "  - Always start with Audit mode to monitor impact" -ForegroundColor White
    Write-Host "  - Review event logs (Microsoft-Windows-CodeIntegrity/Operational)" -ForegroundColor White
    Write-Host "  - Use FilePublisher level when possible for flexibility" -ForegroundColor White
    Write-Host "  - Hash level is most restrictive (exact file match)" -ForegroundColor White
    Write-Host "  - Create supplemental policies for line-of-business apps" -ForegroundColor White
    Write-Host "  - Test thoroughly before enforcing in production" -ForegroundColor White
    Write-Host ""

} catch {
    Write-Host "[ERROR] $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

Write-Host "Demo completed successfully!" -ForegroundColor Green
Write-Host "Next Steps: Monitor audit logs and refine policy before enforcement" -ForegroundColor Yellow
