<#
.SYNOPSIS
    Task 5.2 - Audit NTLM Authentication
.DESCRIPTION
    Comprehensive demonstration of auditing and restricting NTLM authentication in Windows domains.
    Covers auditing configuration, event monitoring, Group Policy settings, and migration to Kerberos.
.EXAMPLE
    .\task-5.2-audit-ntlm.ps1
.NOTES
    Module: Module 5 - Monitor and Defend with Microsoft Security Tools
    Task: 5.2 - Audit NTLM Authentication
    Prerequisites:
    - Domain Controller or domain-joined server
    - Administrative privileges
    - Active Directory module
    PowerShell Version: 5.1+
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

Write-Host "=== AZ-801 Module 5: Task 5.2 - Audit NTLM Authentication ===" -ForegroundColor Cyan
Write-Host ""

try {
    # Step 1: NTLM Authentication Overview
    Write-Host "[Step 1] NTLM Authentication Overview" -ForegroundColor Yellow

    Write-Host "Why audit NTLM:" -ForegroundColor Cyan
    Write-Host "  - Legacy protocol with security vulnerabilities" -ForegroundColor White
    Write-Host "  - Susceptible to pass-the-hash attacks" -ForegroundColor White
    Write-Host "  - Does not support MFA or modern authentication" -ForegroundColor White
    Write-Host "  - Microsoft recommends migrating to Kerberos" -ForegroundColor White
    Write-Host ""

    Write-Host "Audit strategy:" -ForegroundColor Cyan
    Write-Host "  1. Enable auditing to identify NTLM usage" -ForegroundColor White
    Write-Host "  2. Analyze which systems/apps use NTLM" -ForegroundColor White
    Write-Host "  3. Migrate applications to Kerberos" -ForegroundColor White
    Write-Host "  4. Block NTLM after migration" -ForegroundColor White
    Write-Host ""

    # Step 2: Check current NTLM audit settings
    Write-Host "[Step 2] Checking current NTLM audit settings" -ForegroundColor Yellow

    Write-Host "Querying audit policy for logon/logoff events..." -ForegroundColor Cyan
    try {
        $auditPolicy = auditpol /get /category:"Logon/Logoff"
        Write-Host $auditPolicy -ForegroundColor White
    } catch {
        Write-Host "Unable to query audit policy: $_" -ForegroundColor Yellow
    }
    Write-Host ""

    # Check NTLM registry settings
    Write-Host "Checking NTLM security settings in registry..." -ForegroundColor Cyan
    $ntlmSettings = @{
        "LmCompatibilityLevel" = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
        "RestrictNTLMInDomain" = "HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters"
        "AuditNTLMInDomain" = "HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters"
        "RestrictReceivingNTLMTraffic" = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\MSV1_0"
        "AuditReceivingNTLMTraffic" = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\MSV1_0"
    }

    foreach ($setting in $ntlmSettings.GetEnumerator()) {
        $value = Get-ItemProperty -Path $setting.Value -Name $setting.Key -ErrorAction SilentlyContinue
        if ($value) {
            Write-Host "  $($setting.Key): $($value.($setting.Key))" -ForegroundColor White
        } else {
            Write-Host "  $($setting.Key): Not configured" -ForegroundColor Gray
        }
    }
    Write-Host ""

    # Step 3: Enable NTLM auditing
    Write-Host "[Step 3] Enabling NTLM auditing" -ForegroundColor Yellow

    Write-Host "Enabling logon/logoff audit events..." -ForegroundColor Cyan
    try {
        $result = auditpol /set /subcategory:"Logon" /success:enable /failure:enable
        Write-Host "Logon events: Enabled" -ForegroundColor Green

        $result = auditpol /set /subcategory:"Credential Validation" /success:enable /failure:enable
        Write-Host "Credential Validation events: Enabled" -ForegroundColor Green
    } catch {
        Write-Host "Error enabling audit policy: $_" -ForegroundColor Yellow
    }
    Write-Host ""

    # Enable NTLM auditing in domain
    Write-Host "Configuring NTLM domain audit settings..." -ForegroundColor Cyan
    Write-Host "Setting AuditNTLMInDomain to enable auditing..." -ForegroundColor White

    $netlogonPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters"
    if (Test-Path $netlogonPath) {
        # Audit mode (value = 7 for audit all)
        Set-ItemProperty -Path $netlogonPath -Name "AuditNTLMInDomain" -Value 7 -Type DWord -ErrorAction SilentlyContinue
        Write-Host "AuditNTLMInDomain set to 7 (Audit all accounts)" -ForegroundColor Green

        Write-Host ""
        Write-Host "AuditNTLMInDomain values:" -ForegroundColor Cyan
        Write-Host "  0 = Disabled" -ForegroundColor Gray
        Write-Host "  1 = Audit domain accounts only" -ForegroundColor Gray
        Write-Host "  3 = Audit domain trust accounts" -ForegroundColor Gray
        Write-Host "  7 = Audit all accounts (recommended for discovery)" -ForegroundColor Gray
    } else {
        Write-Host "[INFO] Netlogon parameters path not found (may not be a DC)" -ForegroundColor Yellow
    }
    Write-Host ""

    # Step 4: Configure local NTLM auditing
    Write-Host "[Step 4] Configuring local NTLM auditing" -ForegroundColor Yellow

    $lsaPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\MSV1_0"
    if (-not (Test-Path $lsaPath)) {
        New-Item -Path $lsaPath -Force | Out-Null
    }

    Write-Host "Enabling NTLM incoming traffic audit..." -ForegroundColor Cyan
    Set-ItemProperty -Path $lsaPath -Name "AuditReceivingNTLMTraffic" -Value 2 -Type DWord
    Write-Host "AuditReceivingNTLMTraffic set to 2 (Enable auditing for all accounts)" -ForegroundColor Green

    Write-Host ""
    Write-Host "AuditReceivingNTLMTraffic values:" -ForegroundColor Cyan
    Write-Host "  0 = Disable" -ForegroundColor Gray
    Write-Host "  1 = Enable auditing for domain accounts" -ForegroundColor Gray
    Write-Host "  2 = Enable auditing for all accounts" -ForegroundColor Gray
    Write-Host ""

    # Step 5: Monitor NTLM events
    Write-Host "[Step 5] Monitoring NTLM authentication events" -ForegroundColor Yellow

    Write-Host "Key NTLM event IDs to monitor:" -ForegroundColor Cyan
    Write-Host "  Event 4624 - Successful logon (look for LogonType 3, Package NTLM)" -ForegroundColor White
    Write-Host "  Event 4625 - Failed logon attempt" -ForegroundColor White
    Write-Host "  Event 8001 - NTLM authentication blocked (when blocking enabled)" -ForegroundColor White
    Write-Host "  Event 8002 - NTLM authentication audit (when auditing enabled)" -ForegroundColor White
    Write-Host "  Event 8003 - NTLM authentication in domain blocked" -ForegroundColor White
    Write-Host "  Event 8004 - NTLM authentication in domain audit" -ForegroundColor White
    Write-Host ""

    Write-Host "Checking recent NTLM audit events..." -ForegroundColor Cyan
    try {
        # Check for NTLM-specific events
        $ntlmEvents = Get-WinEvent -FilterHashtable @{
            LogName = 'System'
            ID = 8001, 8002, 8003, 8004
        } -MaxEvents 10 -ErrorAction SilentlyContinue

        if ($ntlmEvents) {
            Write-Host "Recent NTLM audit events found:" -ForegroundColor Green
            foreach ($event in $ntlmEvents) {
                Write-Host "  [$($event.TimeCreated)] Event $($event.Id)" -ForegroundColor White
                Write-Host "    $($event.Message.Split("`n")[0])" -ForegroundColor Gray
            }
        } else {
            Write-Host "No NTLM audit events found yet (expected if just enabled)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "NTLM audit events not available yet" -ForegroundColor Yellow
    }
    Write-Host ""

    # Check for NTLM authentication in Security log
    Write-Host "Checking Security log for NTLM authentication (Event 4624)..." -ForegroundColor Cyan
    try {
        $securityEvents = Get-WinEvent -FilterHashtable @{
            LogName = 'Security'
            ID = 4624
        } -MaxEvents 5 -ErrorAction SilentlyContinue

        if ($securityEvents) {
            Write-Host "Recent logon events (check for NTLM package):" -ForegroundColor White
            foreach ($event in $securityEvents) {
                $eventXml = [xml]$event.ToXml()
                $logonType = ($eventXml.Event.EventData.Data | Where-Object {$_.Name -eq 'LogonType'}).'#text'
                $authPackage = ($eventXml.Event.EventData.Data | Where-Object {$_.Name -eq 'AuthenticationPackageName'}).'#text'
                $accountName = ($eventXml.Event.EventData.Data | Where-Object {$_.Name -eq 'TargetUserName'}).'#text'

                if ($authPackage -eq 'NTLM') {
                    Write-Host "  [$($event.TimeCreated)] User: $accountName, Type: $logonType, Package: $authPackage" -ForegroundColor Yellow
                }
            }
        }
    } catch {
        Write-Host "Unable to query Security log" -ForegroundColor Yellow
    }
    Write-Host ""

    # Step 6: Group Policy for NTLM restrictions
    Write-Host "[Step 6] Group Policy configuration for NTLM" -ForegroundColor Yellow

    Write-Host "Group Policy paths for NTLM settings:" -ForegroundColor Cyan
    Write-Host "  Computer Configuration > Windows Settings > Security Settings > Local Policies > Security Options" -ForegroundColor White
    Write-Host ""

    Write-Host "Key GPO settings:" -ForegroundColor Cyan
    Write-Host "  - Network security: LAN Manager authentication level" -ForegroundColor White
    Write-Host "  - Network security: Minimum session security for NTLM SSP" -ForegroundColor White
    Write-Host "  - Network security: Restrict NTLM: Audit NTLM authentication in this domain" -ForegroundColor White
    Write-Host "  - Network security: Restrict NTLM: Audit Incoming NTLM Traffic" -ForegroundColor White
    Write-Host "  - Network security: Restrict NTLM: Outgoing NTLM traffic to remote servers" -ForegroundColor White
    Write-Host ""

    Write-Host "Example: Create GPO for NTLM auditing (requires AD module and DC)" -ForegroundColor Cyan
    Write-Host '  $gpo = New-GPO -Name "NTLM Auditing Policy" -Comment "Audit NTLM usage"' -ForegroundColor Gray
    Write-Host '  Set-GPRegistryValue -Name "NTLM Auditing Policy" -Key "HKLM\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters" -ValueName "AuditNTLMInDomain" -Type DWord -Value 7' -ForegroundColor Gray
    Write-Host '  New-GPLink -Name "NTLM Auditing Policy" -Target "DC=contoso,DC=com"' -ForegroundColor Gray
    Write-Host ""

    # Step 7: LM Compatibility Level
    Write-Host "[Step 7] Configuring LM authentication level" -ForegroundColor Yellow

    Write-Host "LM Compatibility Level settings:" -ForegroundColor Cyan
    Write-Host "  0 = Send LM & NTLM (least secure)" -ForegroundColor White
    Write-Host "  1 = Send LM & NTLM - use NTLMv2 if negotiated" -ForegroundColor White
    Write-Host "  2 = Send NTLM only" -ForegroundColor White
    Write-Host "  3 = Send NTLMv2 only" -ForegroundColor White
    Write-Host "  4 = Send NTLMv2 only, refuse LM" -ForegroundColor White
    Write-Host "  5 = Send NTLMv2 only, refuse LM & NTLM (most secure)" -ForegroundColor White
    Write-Host ""

    $lsaPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
    $currentLevel = (Get-ItemProperty -Path $lsaPath -Name "LmCompatibilityLevel" -ErrorAction SilentlyContinue).LmCompatibilityLevel

    if ($null -ne $currentLevel) {
        Write-Host "Current LM Compatibility Level: $currentLevel" -ForegroundColor White
    } else {
        Write-Host "LM Compatibility Level not set (defaults to 3 on modern systems)" -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host "Recommended: Set to 5 for maximum security" -ForegroundColor Cyan
    Write-Host "  Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa' -Name 'LmCompatibilityLevel' -Value 5" -ForegroundColor Gray
    Write-Host ""

    # Step 8: Analyze NTLM usage
    Write-Host "[Step 8] Analyzing NTLM usage patterns" -ForegroundColor Yellow

    Write-Host "After enabling auditing, analyze logs to identify:" -ForegroundColor Cyan
    Write-Host "  - Which applications use NTLM" -ForegroundColor White
    Write-Host "  - Which servers receive NTLM authentication" -ForegroundColor White
    Write-Host "  - Which user accounts authenticate via NTLM" -ForegroundColor White
    Write-Host "  - Source IP addresses of NTLM traffic" -ForegroundColor White
    Write-Host ""

    Write-Host "PowerShell query to find NTLM logons:" -ForegroundColor Cyan
    Write-Host @'
  Get-WinEvent -FilterHashtable @{
      LogName = 'Security'
      ID = 4624
  } | ForEach-Object {
      $eventXml = [xml]$_.ToXml()
      $authPackage = ($eventXml.Event.EventData.Data | Where-Object {$_.Name -eq 'AuthenticationPackageName'}).'#text'
      if ($authPackage -eq 'NTLM') {
          $_ | Select-Object TimeCreated, @{N='User';E={
              ($eventXml.Event.EventData.Data | Where-Object {$_.Name -eq 'TargetUserName'}).'#text'
          }}, @{N='Source';E={
              ($eventXml.Event.EventData.Data | Where-Object {$_.Name -eq 'IpAddress'}).'#text'
          }}
      }
  }
'@ -ForegroundColor Gray
    Write-Host ""

    # Step 9: Progressively restrict NTLM
    Write-Host "[Step 9] Progressive NTLM restriction strategy" -ForegroundColor Yellow

    Write-Host "Phased approach to blocking NTLM:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Phase 1: Audit (Current)" -ForegroundColor White
    Write-Host "  - Enable audit mode to identify NTLM usage" -ForegroundColor Gray
    Write-Host "  - Collect data for 2-4 weeks" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Phase 2: Deny specific accounts/servers" -ForegroundColor White
    Write-Host "  - Create exception lists for systems that must use NTLM" -ForegroundColor Gray
    Write-Host "  - RestrictNTLMInDomain = 1 (Deny for domain accounts)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Phase 3: Deny all except exceptions" -ForegroundColor White
    Write-Host "  - RestrictNTLMInDomain = 2 (Deny all domain accounts)" -ForegroundColor Gray
    Write-Host "  - Use RestrictReceivingNTLMTraffic registry for incoming traffic" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Phase 4: Block NTLM completely" -ForegroundColor White
    Write-Host "  - After confirming no legitimate NTLM usage" -ForegroundColor Gray
    Write-Host "  - RestrictReceivingNTLMTraffic = 2 (Deny all)" -ForegroundColor Gray
    Write-Host ""

    # Step 10: Best practices and verification
    Write-Host "[Step 10] Best practices and verification" -ForegroundColor Yellow

    Write-Host "Best practices:" -ForegroundColor Cyan
    Write-Host "  1. Start with audit mode before blocking" -ForegroundColor White
    Write-Host "  2. Maintain exception lists for legacy applications" -ForegroundColor White
    Write-Host "  3. Coordinate with application teams before blocking" -ForegroundColor White
    Write-Host "  4. Monitor Event Viewer daily during audit phase" -ForegroundColor White
    Write-Host "  5. Document all systems that require NTLM" -ForegroundColor White
    Write-Host "  6. Use GPOs for centralized management" -ForegroundColor White
    Write-Host "  7. Test restrictions in non-production first" -ForegroundColor White
    Write-Host "  8. Keep audit logs for compliance" -ForegroundColor White
    Write-Host "  9. Integrate with SIEM for centralized monitoring" -ForegroundColor White
    Write-Host "  10. Regular review and updates to exception lists" -ForegroundColor White
    Write-Host ""

    Write-Host "Verification commands:" -ForegroundColor Cyan
    Write-Host '  Check audit settings: auditpol /get /category:"Logon/Logoff"' -ForegroundColor Gray
    Write-Host '  View NTLM events: Get-WinEvent -LogName System -MaxEvents 50 | Where-Object {$_.Id -in 8001..8004}' -ForegroundColor Gray
    Write-Host '  Check registry: Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters' -ForegroundColor Gray
    Write-Host '  Security log: Get-WinEvent -LogName Security -FilterXPath "*[System[EventID=4624]]"' -ForegroundColor Gray
    Write-Host ""

} catch {
    Write-Host "[ERROR] $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

Write-Host "Demo completed successfully!" -ForegroundColor Green
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Monitor Event Viewer for events 8001-8004 and 4624" -ForegroundColor White
Write-Host "  2. Analyze NTLM usage patterns over 2-4 weeks" -ForegroundColor White
Write-Host "  3. Identify applications requiring NTLM migration" -ForegroundColor White
Write-Host "  4. Create exception lists for legitimate NTLM usage" -ForegroundColor White
Write-Host "  5. Progressively restrict NTLM using phased approach" -ForegroundColor White
