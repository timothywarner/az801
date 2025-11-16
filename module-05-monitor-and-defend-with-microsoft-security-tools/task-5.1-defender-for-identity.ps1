<#
.SYNOPSIS
    Task 5.1 - Configure Microsoft Defender for Identity
.DESCRIPTION
    Comprehensive demonstration of Microsoft Defender for Identity deployment and configuration.
    Covers sensor installation, configuration, and monitoring for AD threat detection.
.EXAMPLE
    .\task-5.1-defender-for-identity.ps1
.NOTES
    Module: Module 5 - Monitor and Defend with Microsoft Security Tools
    Task: 5.1 - Configure Microsoft Defender for Identity
    Prerequisites:
    - Azure AD tenant with appropriate license
    - Domain Controller access
    - Port 443 outbound to *.atp.azure.com
    PowerShell Version: 5.1+
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

Write-Host "=== AZ-801 Module 5: Task 5.1 - Configure Microsoft Defender for Identity ===" -ForegroundColor Cyan
Write-Host ""

try {
    # Step 1: Overview of Defender for Identity
    Write-Host "[Step 1] Microsoft Defender for Identity Overview" -ForegroundColor Yellow

    Write-Host "Defender for Identity protects against:" -ForegroundColor Cyan
    Write-Host "  - Reconnaissance attacks" -ForegroundColor White
    Write-Host "  - Compromised credentials" -ForegroundColor White
    Write-Host "  - Lateral movement" -ForegroundColor White
    Write-Host "  - Domain dominance attacks" -ForegroundColor White
    Write-Host "  - Privilege escalation" -ForegroundColor White
    Write-Host ""

    # Step 2: Prerequisites check
    Write-Host "[Step 2] Checking prerequisites" -ForegroundColor Yellow

    # Check if running on DC
    $isDC = (Get-WmiObject -Class Win32_ComputerSystem).DomainRole -ge 4
    Write-Host "Is Domain Controller: $isDC" -ForegroundColor White

    # Check .NET version
    $netVersion = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full").Release
    if ($netVersion -ge 461808) {
        Write-Host ".NET Framework: 4.7.2 or later [OK]" -ForegroundColor Green
    } else {
        Write-Host ".NET Framework: Version too old, need 4.7.2+" -ForegroundColor Yellow
    }

    # Check disk space
    $cDrive = Get-PSDrive C
    $freeSpaceGB = [math]::Round($cDrive.Free / 1GB, 2)
    Write-Host "Free disk space: $freeSpaceGB GB" -ForegroundColor White
    if ($freeSpaceGB -lt 6) {
        Write-Host "[WARNING] Minimum 6 GB free space required" -ForegroundColor Yellow
    }
    Write-Host ""

    # Step 3: Download sensor
    Write-Host "[Step 3] Defender for Identity Sensor Installation" -ForegroundColor Yellow

    Write-Host "Installation steps:" -ForegroundColor Cyan
    Write-Host "  1. Access Microsoft 365 Defender portal (security.microsoft.com)" -ForegroundColor White
    Write-Host "  2. Settings > Identities > Sensors" -ForegroundColor White
    Write-Host "  3. Download sensor installation package" -ForegroundColor White
    Write-Host "  4. Copy access key for installation" -ForegroundColor White
    Write-Host ""

    Write-Host "Silent installation command:" -ForegroundColor Cyan
    Write-Host '  Azure-ATP-Sensor-Setup.exe /quiet NetFrameworkCommandLineArguments="/q" AccessKey="<YourAccessKey>"' -ForegroundColor White
    Write-Host ""

    # Step 4: Configure sensor
    Write-Host "[Step 4] Sensor configuration" -ForegroundColor Yellow

    $sensorConfigPath = "C:\Program Files\Azure Advanced Threat Protection Sensor"
    if (Test-Path $sensorConfigPath) {
        Write-Host "Defender for Identity sensor is installed" -ForegroundColor Green
        Write-Host "Installation path: $sensorConfigPath" -ForegroundColor White

        # Check sensor service
        $sensorService = Get-Service -Name "AATPSensor*" -ErrorAction SilentlyContinue
        if ($sensorService) {
            Write-Host "Sensor service status: $($sensorService.Status)" -ForegroundColor White
        }
    } else {
        Write-Host "Defender for Identity sensor not detected" -ForegroundColor Yellow
        Write-Host "Install from: https://security.microsoft.com" -ForegroundColor Cyan
    }
    Write-Host ""

    # Step 5: Configure Directory Service account
    Write-Host "[Step 5] Directory Service Account configuration" -ForegroundColor Yellow

    Write-Host "DSA account requirements:" -ForegroundColor Cyan
    Write-Host "  - Read permissions on all objects in AD" -ForegroundColor White
    Write-Host "  - Read permissions on Deleted Objects container" -ForegroundColor White
    Write-Host "  - NOT a member of any privileged groups" -ForegroundColor White
    Write-Host ""

    Write-Host "Create DSA account:" -ForegroundColor Cyan
    Write-Host '  New-ADUser -Name "DefenderForIdentity-DSA" -AccountPassword (ConvertTo-SecureString "Pa$$w0rd" -AsPlainText -Force) -Enabled $true' -ForegroundColor White
    Write-Host '  Set-ADUser -Identity "DefenderForIdentity-DSA" -PasswordNeverExpires $true' -ForegroundColor White
    Write-Host ""

    # Step 6: Monitor detection alerts
    Write-Host "[Step 6] Monitoring alerts and detections" -ForegroundColor Yellow

    Write-Host "Common Defender for Identity alerts:" -ForegroundColor Cyan
    $alerts = @(
        "Reconnaissance using account enumeration",
        "Reconnaissance using SMB Session Enumeration",
        "Reconnaissance using directory services queries",
        "Suspected DCSync attack (replication of directory services)",
        "Suspected Golden Ticket usage (encryption downgrade)",
        "Suspected skeleton key attack (encryption downgrade)",
        "Suspicious modification of sensitive groups",
        "Suspected brute force attack (LDAP)",
        "Suspected DCShadow attack (domain controller replication request)",
        "Suspected overpass-the-hash attack (Kerberos)"
    )

    foreach ($alert in $alerts) {
        Write-Host "  - $alert" -ForegroundColor White
    }
    Write-Host ""

    # Step 7: Configure sensor settings
    Write-Host "[Step 7] Advanced sensor settings" -ForegroundColor Yellow

    Write-Host "Port mirroring vs Direct sensor:" -ForegroundColor Cyan
    Write-Host "  Direct Sensor (Recommended):" -ForegroundColor White
    Write-Host "    - Installed directly on DC" -ForegroundColor Gray
    Write-Host "    - No network tap required" -ForegroundColor Gray
    Write-Host "    - Captures Windows Events and network traffic" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Standalone Sensor (Legacy):" -ForegroundColor White
    Write-Host "    - Requires port mirroring/network TAP" -ForegroundColor Gray
    Write-Host "    - Installed on dedicated server" -ForegroundColor Gray
    Write-Host "    - More complex setup" -ForegroundColor Gray
    Write-Host ""

    # Step 8: Integration with Microsoft Defender
    Write-Host "[Step 8] Integration with Microsoft 365 Defender" -ForegroundColor Yellow

    Write-Host "Defender for Identity integrates with:" -ForegroundColor Cyan
    Write-Host "  - Microsoft Defender for Endpoint" -ForegroundColor White
    Write-Host "  - Microsoft Defender for Cloud Apps" -ForegroundColor White
    Write-Host "  - Microsoft Sentinel" -ForegroundColor White
    Write-Host "  - Azure AD Identity Protection" -ForegroundColor White
    Write-Host ""

    Write-Host "Enable integration in Microsoft 365 Defender portal" -ForegroundColor Cyan
    Write-Host "  Settings > Identities > Integration" -ForegroundColor White
    Write-Host ""

    # Step 9: Review sensor health
    Write-Host "[Step 9] Monitoring sensor health" -ForegroundColor Yellow

    Write-Host "Check sensor health in portal:" -ForegroundColor Cyan
    Write-Host "  - Sensor status (Online/Offline)" -ForegroundColor White
    Write-Host "  - Sensor version" -ForegroundColor White
    Write-Host "  - Last communication time" -ForegroundColor White
    Write-Host "  - Pending updates" -ForegroundColor White
    Write-Host "  - Captured activities" -ForegroundColor White
    Write-Host ""

    # Check Event Log for sensor events
    Write-Host "Checking Defender for Identity event logs..." -ForegroundColor Cyan
    try {
        $defenderEvents = Get-WinEvent -LogName "Microsoft-Azure-ATP-Sensor/Operational" -MaxEvents 5 -ErrorAction SilentlyContinue
        if ($defenderEvents) {
            Write-Host "Recent sensor events:" -ForegroundColor White
            foreach ($event in $defenderEvents) {
                Write-Host "  [$($event.TimeCreated)] ID $($event.Id): $($event.Message.Split("`n")[0])" -ForegroundColor Gray
            }
        }
    } catch {
        Write-Host "Defender for Identity event log not available (sensor may not be installed)" -ForegroundColor Yellow
    }
    Write-Host ""

    # Step 10: Best practices
    Write-Host "[Step 10] Best Practices" -ForegroundColor Yellow

    Write-Host "  1. Install sensors on all domain controllers" -ForegroundColor White
    Write-Host "  2. Use dedicated Directory Service Account (not admin)" -ForegroundColor White
    Write-Host "  3. Enable all detection rules in portal" -ForegroundColor White
    Write-Host "  4. Configure email notifications for high-severity alerts" -ForegroundColor White
    Write-Host "  5. Integrate with Microsoft Sentinel for SIEM" -ForegroundColor White
    Write-Host "  6. Regular review of alerts and suspicious activities" -ForegroundColor White
    Write-Host "  7. Keep sensors updated (automatic by default)" -ForegroundColor White
    Write-Host "  8. Monitor sensor health daily" -ForegroundColor White
    Write-Host "  9. Configure exclusions for known safe activities" -ForegroundColor White
    Write-Host "  10. Train SOC team on Defender for Identity alerts" -ForegroundColor White
    Write-Host ""

    Write-Host "[INFO] Additional Commands:" -ForegroundColor Cyan
    Write-Host '  Check sensor service: Get-Service AATPSensor*' -ForegroundColor White
    Write-Host '  View sensor logs: Get-WinEvent -LogName "Microsoft-Azure-ATP-Sensor/Operational"' -ForegroundColor White
    Write-Host '  Test connectivity: Test-NetConnection -ComputerName *.atp.azure.com -Port 443' -ForegroundColor White
    Write-Host ""

} catch {
    Write-Host "[ERROR] $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

Write-Host "Demo completed successfully!" -ForegroundColor Green
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Deploy sensors to all domain controllers" -ForegroundColor White
Write-Host "  2. Configure Directory Service Account" -ForegroundColor White
Write-Host "  3. Review and tune detection rules in portal" -ForegroundColor White
Write-Host "  4. Set up alert notifications and response procedures" -ForegroundColor White
Write-Host "  5. Integrate with Microsoft Sentinel for centralized monitoring" -ForegroundColor White
