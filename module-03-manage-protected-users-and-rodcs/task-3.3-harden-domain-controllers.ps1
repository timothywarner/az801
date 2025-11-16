<#
.SYNOPSIS
    Task 3.3 - Harden Domain Controllers

.DESCRIPTION
    Demo script for AZ-801 Module 3: Manage Protected Users and RODCs
    Demonstrates domain controller hardening techniques, security configurations, and best practices
    for protecting the most critical infrastructure in Active Directory environments.

.NOTES
    Module: Module 3 - Manage Protected Users and RODCs
    Task: 3.3 - Harden Domain Controllers

    Prerequisites:
    - Domain Controller running Windows Server 2016 or later
    - Domain Administrator privileges
    - AD PowerShell module

    PowerShell Version: 5.1+
#>

#Requires -RunAsAdministrator

$ErrorActionPreference = 'Stop'

Write-Host "=== AZ-801 Module 3: Task 3.3 - Harden Domain Controllers ===" -ForegroundColor Cyan
Write-Host ""

try {
    # Section 1: Verify running on Domain Controller
    Write-Host "[Step 1] Verifying Domain Controller status" -ForegroundColor Yellow

    $computerSystem = Get-CimInstance -ClassName Win32_ComputerSystem
    $isDC = $computerSystem.DomainRole -ge 4

    Write-Host "Computer Name: $($env:COMPUTERNAME)" -ForegroundColor White
    Write-Host "Domain: $($computerSystem.Domain)" -ForegroundColor White
    Write-Host "Domain Role: $(
        switch ($computerSystem.DomainRole) {
            0 { 'Standalone Workstation' }
            1 { 'Member Workstation' }
            2 { 'Standalone Server' }
            3 { 'Member Server' }
            4 { 'Backup Domain Controller' }
            5 { 'Primary Domain Controller' }
        }
    )" -ForegroundColor White

    if ($isDC) {
        Write-Host "[SUCCESS] Running on Domain Controller" -ForegroundColor Green

        # Get OS information
        $os = Get-CimInstance -ClassName Win32_OperatingSystem
        Write-Host "OS: $($os.Caption)" -ForegroundColor White
        Write-Host "Build: $($os.BuildNumber)" -ForegroundColor White
    } else {
        Write-Host "[WARNING] Not running on Domain Controller" -ForegroundColor Yellow
        Write-Host "This script is designed for Domain Controllers" -ForegroundColor Yellow
    }
    Write-Host ""

    # Section 2: Check Windows Update status
    Write-Host "[Step 2] Checking Windows Update status" -ForegroundColor Yellow

    # Check for pending updates
    $updateSession = New-Object -ComObject Microsoft.Update.Session
    $updateSearcher = $updateSession.CreateUpdateSearcher()

    try {
        Write-Host "Searching for available updates..." -ForegroundColor White
        $searchResult = $updateSearcher.Search("IsInstalled=0")

        if ($searchResult.Updates.Count -eq 0) {
            Write-Host "[SUCCESS] No pending updates" -ForegroundColor Green
        } else {
            Write-Host "[WARNING] $($searchResult.Updates.Count) updates available" -ForegroundColor Yellow
            Write-Host "Critical security updates should be installed promptly" -ForegroundColor White
        }

        # Check last update install date
        $lastUpdate = Get-HotFix | Sort-Object -Property InstalledOn -Descending | Select-Object -First 1
        if ($lastUpdate) {
            Write-Host "Last update installed: $($lastUpdate.HotFixID) on $($lastUpdate.InstalledOn)" -ForegroundColor White
        }
    } catch {
        Write-Host "[INFO] Could not query Windows Update status" -ForegroundColor Yellow
    }
    Write-Host ""

    # Section 3: Configure Windows Firewall
    Write-Host "[Step 3] Configuring Windows Defender Firewall" -ForegroundColor Yellow

    $firewallProfiles = Get-NetFirewallProfile

    Write-Host "`nCurrent Firewall Status:" -ForegroundColor Cyan
    foreach ($profile in $firewallProfiles) {
        $status = if ($profile.Enabled) { "Enabled" } else { "Disabled" }
        $color = if ($profile.Enabled) { "Green" } else { "Red" }

        Write-Host "  $($profile.Name) Profile: " -NoNewline -ForegroundColor White
        Write-Host $status -ForegroundColor $color
        Write-Host "    Default Inbound Action: $($profile.DefaultInboundAction)" -ForegroundColor White
        Write-Host "    Default Outbound Action: $($profile.DefaultOutboundAction)" -ForegroundColor White
    }

    Write-Host "`nEnable firewall on all profiles:" -ForegroundColor Cyan
    Write-Host "  Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True" -ForegroundColor White
    Write-Host ""

    Write-Host "Configure default actions:" -ForegroundColor Cyan
    Write-Host "  Set-NetFirewallProfile -Profile Domain,Public,Private ``" -ForegroundColor White
    Write-Host "    -DefaultInboundAction Block ``" -ForegroundColor White
    Write-Host "    -DefaultOutboundAction Allow" -ForegroundColor White
    Write-Host ""

    Write-Host "[SUCCESS] Firewall status reviewed" -ForegroundColor Green
    Write-Host ""

    # Section 4: Configure SMB Signing
    Write-Host "[Step 4] Configuring SMB Signing" -ForegroundColor Yellow

    Write-Host "`nSMB Signing protects against man-in-the-middle attacks" -ForegroundColor Cyan

    # Get current SMB server configuration
    $smbServerConfig = Get-SmbServerConfiguration

    Write-Host "Current SMB Server Configuration:" -ForegroundColor White
    Write-Host "  SMB Signing Required: $($smbServerConfig.RequireSecuritySignature)" -ForegroundColor White
    Write-Host "  SMB Encryption Required: $($smbServerConfig.EncryptData)" -ForegroundColor White

    # Get current SMB client configuration
    $smbClientConfig = Get-SmbClientConfiguration

    Write-Host "Current SMB Client Configuration:" -ForegroundColor White
    Write-Host "  SMB Signing Required: $($smbClientConfig.RequireSecuritySignature)" -ForegroundColor White

    Write-Host "`nRecommended SMB hardening commands:" -ForegroundColor Cyan
    Write-Host "  # Require SMB signing on server" -ForegroundColor White
    Write-Host "  Set-SmbServerConfiguration -RequireSecuritySignature `$true -Force" -ForegroundColor White
    Write-Host ""
    Write-Host "  # Require SMB signing on client" -ForegroundColor White
    Write-Host "  Set-SmbClientConfiguration -RequireSecuritySignature `$true -Force" -ForegroundColor White
    Write-Host ""
    Write-Host "  # Enable SMB encryption (Windows Server 2022+)" -ForegroundColor White
    Write-Host "  Set-SmbServerConfiguration -EncryptData `$true -Force" -ForegroundColor White
    Write-Host ""

    Write-Host "[SUCCESS] SMB configuration reviewed" -ForegroundColor Green
    Write-Host ""

    # Section 5: Configure Advanced Audit Policy
    Write-Host "[Step 5] Configuring Advanced Audit Policy" -ForegroundColor Yellow

    Write-Host "`nEnable critical audit policies:" -ForegroundColor Cyan
    Write-Host "  auditpol /set /subcategory:'User Account Management' /success:enable /failure:enable" -ForegroundColor White
    Write-Host "  auditpol /set /subcategory:'Computer Account Management' /success:enable /failure:enable" -ForegroundColor White
    Write-Host "  auditpol /set /subcategory:'Security Group Management' /success:enable /failure:enable" -ForegroundColor White
    Write-Host "  auditpol /set /subcategory:'Directory Service Changes' /success:enable /failure:enable" -ForegroundColor White
    Write-Host "  auditpol /set /subcategory:'Directory Service Access' /success:enable /failure:enable" -ForegroundColor White
    Write-Host "  auditpol /set /subcategory:'Logon' /success:enable /failure:enable" -ForegroundColor White
    Write-Host "  auditpol /set /subcategory:'Account Lockout' /success:enable /failure:enable" -ForegroundColor White
    Write-Host "  auditpol /set /subcategory:'Credential Validation' /success:enable /failure:enable" -ForegroundColor White
    Write-Host ""

    # Get current audit policy
    Write-Host "Checking current audit policy configuration..." -ForegroundColor White
    $auditPolicy = auditpol /get /category:*

    Write-Host "[SUCCESS] Audit policy commands provided" -ForegroundColor Green
    Write-Host ""

    # Section 6: Disable unnecessary services
    Write-Host "[Step 6] Reviewing and disabling unnecessary services" -ForegroundColor Yellow

    Write-Host "`nServices to consider disabling on DCs:" -ForegroundColor Cyan

    $servicesToCheck = @(
        @{Name='Spooler'; DisplayName='Print Spooler'; Reason='Not needed unless DC is print server'}
        @{Name='RemoteRegistry'; DisplayName='Remote Registry'; Reason='Security risk if not required'}
        @{Name='SSDPSRV'; DisplayName='SSDP Discovery'; Reason='Not needed on DC'}
        @{Name='upnphost'; DisplayName='UPnP Device Host'; Reason='Not needed on DC'}
    )

    foreach ($svc in $servicesToCheck) {
        $service = Get-Service -Name $svc.Name -ErrorAction SilentlyContinue

        if ($service) {
            $statusColor = if ($service.Status -eq 'Running') { 'Yellow' } else { 'Green' }

            Write-Host "  $($svc.DisplayName) ($($svc.Name)):" -ForegroundColor White
            Write-Host "    Status: $($service.Status)" -ForegroundColor $statusColor
            Write-Host "    Startup Type: $($service.StartType)" -ForegroundColor White
            Write-Host "    Reason: $($svc.Reason)" -ForegroundColor White
            Write-Host ""
        }
    }

    Write-Host "Commands to disable services:" -ForegroundColor Cyan
    Write-Host "  # Stop and disable Print Spooler (if not print server)" -ForegroundColor White
    Write-Host "  Stop-Service -Name Spooler -Force" -ForegroundColor White
    Write-Host "  Set-Service -Name Spooler -StartupType Disabled" -ForegroundColor White
    Write-Host ""
    Write-Host "  # Disable Remote Registry" -ForegroundColor White
    Write-Host "  Stop-Service -Name RemoteRegistry -Force" -ForegroundColor White
    Write-Host "  Set-Service -Name RemoteRegistry -StartupType Disabled" -ForegroundColor White
    Write-Host ""

    Write-Host "[SUCCESS] Service review complete" -ForegroundColor Green
    Write-Host ""

    # Section 7: Local Administrator Account Security
    Write-Host "[Step 7] Securing Local Administrator Account" -ForegroundColor Yellow

    Write-Host "`nLocal Administrator Account Hardening:" -ForegroundColor Cyan

    # Get local administrator account
    $adminAccount = Get-LocalUser | Where-Object { $_.SID -like "*-500" }

    if ($adminAccount) {
        Write-Host "Built-in Administrator Account:" -ForegroundColor White
        Write-Host "  Name: $($adminAccount.Name)" -ForegroundColor White
        Write-Host "  Enabled: $($adminAccount.Enabled)" -ForegroundColor White
        Write-Host "  Password Last Set: $($adminAccount.PasswordLastSet)" -ForegroundColor White
    }

    Write-Host "`nRecommended actions:" -ForegroundColor Cyan
    Write-Host "  1. Rename the built-in Administrator account via GPO" -ForegroundColor White
    Write-Host "     GPO Path: Computer Configuration > Windows Settings > Security Settings >" -ForegroundColor White
    Write-Host "              Local Policies > Security Options" -ForegroundColor White
    Write-Host "     Setting: Accounts: Rename administrator account" -ForegroundColor White
    Write-Host ""
    Write-Host "  2. Use LAPS for local admin password management" -ForegroundColor White
    Write-Host "  3. Disable local administrator if not needed:" -ForegroundColor White
    Write-Host "     Disable-LocalUser -Name 'Administrator'" -ForegroundColor White
    Write-Host ""

    Write-Host "[SUCCESS] Administrator account reviewed" -ForegroundColor Green
    Write-Host ""

    # Section 8: Network Security Settings
    Write-Host "[Step 8] Reviewing Network Security Settings" -ForegroundColor Yellow

    Write-Host "`nCritical network security settings:" -ForegroundColor Cyan

    # Check LAN Manager authentication level
    $lmCompatibilityLevel = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "LmCompatibilityLevel" -ErrorAction SilentlyContinue

    if ($lmCompatibilityLevel) {
        Write-Host "LAN Manager Authentication Level: $($lmCompatibilityLevel.LmCompatibilityLevel)" -ForegroundColor White
        Write-Host "  0 = Send LM and NTLM" -ForegroundColor White
        Write-Host "  3 = Send NTLMv2 only" -ForegroundColor White
        Write-Host "  5 = Send NTLMv2 only, refuse LM and NTLM (Recommended)" -ForegroundColor White
    }

    Write-Host "`nRecommended network security configurations via GPO:" -ForegroundColor Cyan
    Write-Host "  Computer Configuration > Windows Settings > Security Settings >" -ForegroundColor White
    Write-Host "  Local Policies > Security Options" -ForegroundColor White
    Write-Host ""
    Write-Host "  Settings to configure:" -ForegroundColor White
    Write-Host "  - Network security: LAN Manager authentication level" -ForegroundColor White
    Write-Host "    Set to: Send NTLMv2 response only. Refuse LM & NTLM" -ForegroundColor White
    Write-Host ""
    Write-Host "  - Network security: Minimum session security for NTLM SSP based clients/servers" -ForegroundColor White
    Write-Host "    Enable: Require NTLMv2 session security, Require 128-bit encryption" -ForegroundColor White
    Write-Host ""
    Write-Host "  - Microsoft network server: Digitally sign communications (always)" -ForegroundColor White
    Write-Host "    Set to: Enabled" -ForegroundColor White
    Write-Host ""

    Write-Host "[SUCCESS] Network security settings reviewed" -ForegroundColor Green
    Write-Host ""

    # Section 9: Domain Controller specific hardening
    Write-Host "[Step 9] Domain Controller Specific Hardening" -ForegroundColor Yellow

    if ($isDC) {
        Write-Host "`nDomain Controller Hardening Checklist:" -ForegroundColor Cyan
        Write-Host "  ✓ Install only essential roles (DNS, AD DS)" -ForegroundColor White
        Write-Host "  ✓ Do NOT install IIS, File Services, or other workload roles" -ForegroundColor White
        Write-Host "  ✓ Enable Credential Guard (if hardware supports)" -ForegroundColor White
        Write-Host "  ✓ Configure Protected Users group for privileged accounts" -ForegroundColor White
        Write-Host "  ✓ Implement tiered administration model" -ForegroundColor White
        Write-Host "  ✓ Use separate admin accounts for DC management" -ForegroundColor White
        Write-Host "  ✓ Enable Advanced Audit Policy" -ForegroundColor White
        Write-Host "  ✓ Configure SIEM integration (Microsoft Sentinel)" -ForegroundColor White
        Write-Host "  ✓ Implement network segmentation for DCs" -ForegroundColor White
        Write-Host "  ✓ Use BitLocker for volume encryption" -ForegroundColor White
        Write-Host ""

        # Check installed roles
        Write-Host "Checking installed Windows features..." -ForegroundColor White
        $installedFeatures = Get-WindowsFeature | Where-Object { $_.InstallState -eq 'Installed' }

        Write-Host "`nCore DC roles (should be installed):" -ForegroundColor Cyan
        $coreRoles = @('AD-Domain-Services', 'DNS', 'RSAT-AD-Tools', 'GPMC')
        foreach ($role in $coreRoles) {
            $feature = $installedFeatures | Where-Object { $_.Name -eq $role }
            if ($feature) {
                Write-Host "  ✓ $($feature.DisplayName)" -ForegroundColor Green
            } else {
                Write-Host "  ✗ $role (not installed)" -ForegroundColor Yellow
            }
        }

        Write-Host "`nRoles that should NOT be on DC:" -ForegroundColor Cyan
        $avoidRoles = @('Web-Server', 'File-Services', 'Print-Services', 'SMTP-Server')
        foreach ($role in $avoidRoles) {
            $feature = $installedFeatures | Where-Object { $_.Name -eq $role }
            if ($feature) {
                Write-Host "  ✗ $($feature.DisplayName) - SHOULD BE REMOVED" -ForegroundColor Red
            } else {
                Write-Host "  ✓ $role (not installed)" -ForegroundColor Green
            }
        }
    }

    Write-Host ""
    Write-Host "[SUCCESS] DC-specific hardening reviewed" -ForegroundColor Green
    Write-Host ""

    # Section 10: Security Monitoring and Logging
    Write-Host "[Step 10] Security Monitoring and Logging" -ForegroundColor Yellow

    Write-Host "`nConfigure Event Log settings:" -ForegroundColor Cyan

    $securityLog = Get-WinEvent -ListLog Security

    Write-Host "Security Event Log:" -ForegroundColor White
    Write-Host "  Maximum Size: $([math]::Round($securityLog.MaximumSizeInBytes / 1MB, 0)) MB" -ForegroundColor White
    Write-Host "  Current Size: $([math]::Round($securityLog.FileSize / 1MB, 2)) MB" -ForegroundColor White
    Write-Host "  Retention: $($securityLog.LogMode)" -ForegroundColor White
    Write-Host "  Record Count: $($securityLog.RecordCount)" -ForegroundColor White

    Write-Host "`nIncrease Security log size:" -ForegroundColor Cyan
    Write-Host "  wevtutil sl Security /ms:2147483648  # 2GB" -ForegroundColor White
    Write-Host "  wevtutil sl 'Microsoft-Windows-PowerShell/Operational' /e:true" -ForegroundColor White
    Write-Host ""

    Write-Host "Critical events to monitor:" -ForegroundColor Cyan
    Write-Host "  Event ID 4624: Successful logon" -ForegroundColor White
    Write-Host "  Event ID 4625: Failed logon" -ForegroundColor White
    Write-Host "  Event ID 4720: User account created" -ForegroundColor White
    Write-Host "  Event ID 4728: Member added to security-enabled global group" -ForegroundColor White
    Write-Host "  Event ID 4732: Member added to security-enabled local group" -ForegroundColor White
    Write-Host "  Event ID 4740: User account locked out" -ForegroundColor White
    Write-Host "  Event ID 4756: Member added to security-enabled universal group" -ForegroundColor White
    Write-Host "  Event ID 5136: Directory service object modified" -ForegroundColor White
    Write-Host ""

    Write-Host "[SUCCESS] Monitoring and logging configuration reviewed" -ForegroundColor Green
    Write-Host ""

    # Section 11: Compliance and Best Practices Summary
    Write-Host "[Step 11] Domain Controller Hardening Compliance Summary" -ForegroundColor Yellow

    Write-Host "`nMicrosoft Best Practices for DC Hardening:" -ForegroundColor Cyan
    Write-Host "  1. Physical Security:" -ForegroundColor White
    Write-Host "     - DCs in secured server rooms" -ForegroundColor White
    Write-Host "     - Restricted physical access" -ForegroundColor White
    Write-Host "     - Security cameras and monitoring" -ForegroundColor White
    Write-Host ""

    Write-Host "  2. Network Security:" -ForegroundColor White
    Write-Host "     - DCs on separate VLANs/subnets" -ForegroundColor White
    Write-Host "     - Firewall rules restricting DC access" -ForegroundColor White
    Write-Host "     - IPsec for DC-to-DC communication" -ForegroundColor White
    Write-Host ""

    Write-Host "  3. Access Control:" -ForegroundColor White
    Write-Host "     - Limit Domain Admins group membership" -ForegroundColor White
    Write-Host "     - Use tiered administration model" -ForegroundColor White
    Write-Host "     - Implement Protected Users group" -ForegroundColor White
    Write-Host "     - Use JEA for delegated administration" -ForegroundColor White
    Write-Host ""

    Write-Host "  4. Monitoring:" -ForegroundColor White
    Write-Host "     - Deploy Microsoft Defender for Identity" -ForegroundColor White
    Write-Host "     - Configure Microsoft Sentinel" -ForegroundColor White
    Write-Host "     - Regular review of security logs" -ForegroundColor White
    Write-Host "     - Alert on critical AD changes" -ForegroundColor White
    Write-Host ""

    Write-Host "  5. Maintenance:" -ForegroundColor White
    Write-Host "     - Monthly security updates" -ForegroundColor White
    Write-Host "     - Regular security assessments" -ForegroundColor White
    Write-Host "     - AD backup and recovery testing" -ForegroundColor White
    Write-Host "     - Disaster recovery planning" -ForegroundColor White
    Write-Host ""

    Write-Host "[INFO] Additional Resources:" -ForegroundColor Cyan
    Write-Host "  - Microsoft Security Compliance Toolkit" -ForegroundColor White
    Write-Host "  - CIS Benchmarks for Windows Server" -ForegroundColor White
    Write-Host "  - NIST Cybersecurity Framework" -ForegroundColor White
    Write-Host "  - Microsoft Active Directory Security Best Practices" -ForegroundColor White
    Write-Host ""

} catch {
    Write-Host "[ERROR] $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

Write-Host "Demo completed successfully!" -ForegroundColor Green
Write-Host "Next Steps: Implement hardening measures and establish regular security audits" -ForegroundColor Yellow
