<#
.SYNOPSIS
    Task 26.7 - Troubleshoot Microsoft Entra Connect

.DESCRIPTION
    Demo script for AZ-801 Module 26: Troubleshoot Active Directory
    Demonstrates Entra Connect (Azure AD Connect) synchronization troubleshooting.

    Covers:
    - Azure AD Connect Health installation and monitoring
    - Synchronization Service Manager troubleshooting
    - Connector statistics and diagnostics
    - Object sync issues (CSExport errors, metaverse joins)
    - Sync rule precedence troubleshooting
    - Upgrade procedures

.NOTES
    Module: Module 26 - Troubleshoot Active Directory
    Task: 26.7 - Troubleshoot Microsoft Entra Connect
    Prerequisites: Azure AD Connect server, Administrative privileges
    PowerShell Version: 5.1+
#>

#Requires -RunAsAdministrator

$ErrorActionPreference = 'Stop'
Write-Host "=== AZ-801 Module 26: Task 26.7 - Troubleshoot Microsoft Entra Connect ===" -ForegroundColor Cyan
Write-Host ""

try {
    Write-Host "[Step 1] Entra Connect Troubleshooting - Overview" -ForegroundColor Yellow
    Write-Host "Microsoft Entra Connect (Azure AD Connect) hybrid identity troubleshooting" -ForegroundColor White
    Write-Host ""

    # ============================================
    # STEP 2: Azure AD Connect Health
    # ============================================
    Write-Host "[Step 2] Azure AD Connect Health Monitoring" -ForegroundColor Yellow

    Write-Host "`n[2.1] Install Azure AD Connect Health Agent..." -ForegroundColor Cyan
    Write-Host "  Download and install:" -ForegroundColor White
    Write-Host "    1. Download from: https://www.microsoft.com/download/details.aspx?id=47594" -ForegroundColor Gray
    Write-Host "    2. Run: AzureADConnectHealthSyncSetup.exe" -ForegroundColor Gray
    Write-Host "    3. Sign in with Global Administrator credentials" -ForegroundColor Gray
    Write-Host "    4. Agent registers with Azure AD" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[2.2] Configure Health Monitoring..." -ForegroundColor Cyan
    Write-Host "  Access Health Portal:" -ForegroundColor White
    Write-Host "    https://portal.azure.com -> Azure AD Connect Health" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Monitor key metrics:" -ForegroundColor White
    Write-Host "    - Sync latency" -ForegroundColor Gray
    Write-Host "    - Sync errors" -ForegroundColor Gray
    Write-Host "    - Export/Import errors" -ForegroundColor Gray
    Write-Host "    - Object sync failures" -ForegroundColor Gray
    Write-Host "    - Duplicate attribute errors" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[2.3] Health Alerts..." -ForegroundColor Cyan
    Write-Host "  Configure alert notifications:" -ForegroundColor White
    Write-Host "    1. Navigate to Azure AD Connect Health" -ForegroundColor Gray
    Write-Host "    2. Select Sync service" -ForegroundColor Gray
    Write-Host "    3. Configure alert settings" -ForegroundColor Gray
    Write-Host "    4. Add email recipients" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[SUCCESS] Health monitoring configured" -ForegroundColor Green
    Write-Host ""

    # ============================================
    # STEP 3: Synchronization Service Manager
    # ============================================
    Write-Host "[Step 3] Synchronization Service Manager Deep Dive" -ForegroundColor Yellow

    Write-Host "`n[3.1] Operations Tab Troubleshooting..." -ForegroundColor Cyan
    Write-Host "  Launch Sync Service Manager:" -ForegroundColor White
    Write-Host "    Start -> Azure AD Connect -> Synchronization Service" -ForegroundColor Gray
    Write-Host "    Or execute: miisclient.exe" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Analyze sync operations:" -ForegroundColor White
    Write-Host "    - Look for operations with errors (red X)" -ForegroundColor Gray
    Write-Host "    - Check operation duration (slow=problem)" -ForegroundColor Gray
    Write-Host "    - Review object statistics" -ForegroundColor Gray
    Write-Host "    - Export error details to CSV" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[3.2] Common Operation Errors..." -ForegroundColor Cyan
    Write-Host "  Export-Error (Azure AD):" -ForegroundColor White
    Write-Host "    - AttributeValueMustBeUnique: Duplicate UPN or ProxyAddress" -ForegroundColor Gray
    Write-Host "    - InvalidSoftMatch: Matching logic issue" -ForegroundColor Gray
    Write-Host "    - LargeObject: Object exceeds size limit" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Import-Error (On-Premises AD):" -ForegroundColor White
    Write-Host "    - PermissionError: Connector account lacks permissions" -ForegroundColor Gray
    Write-Host "    - ConnectionError: Cannot reach domain controller" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[3.3] Connector Space Objects..." -ForegroundColor Cyan
    Write-Host "  Search connector space:" -ForegroundColor White
    Write-Host "    1. Select Connectors tab" -ForegroundColor Gray
    Write-Host "    2. Right-click connector -> Search Connector Space" -ForegroundColor Gray
    Write-Host "    3. Enter search criteria" -ForegroundColor Gray
    Write-Host "    4. View object properties and lineage" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Connector Space Object Properties:" -ForegroundColor White
    Write-Host "    - Attribute Values: Current values" -ForegroundColor Gray
    Write-Host "    - Connector Space Object Preview: How object will sync" -ForegroundColor Gray
    Write-Host "    - Lineage: Source and destination information" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[3.4] Metaverse Objects..." -ForegroundColor Cyan
    Write-Host "  Search metaverse:" -ForegroundColor White
    Write-Host "    1. Select Metaverse Search tab" -ForegroundColor Gray
    Write-Host "    2. Choose object type (person, group, contact)" -ForegroundColor Gray
    Write-Host "    3. Add attribute filters" -ForegroundColor Gray
    Write-Host "    4. View joined connector space objects" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[SUCCESS] Sync Service Manager usage documented" -ForegroundColor Green
    Write-Host ""

    # ============================================
    # STEP 4: Connector Statistics
    # ============================================
    Write-Host "[Step 4] Connector Statistics and Diagnostics" -ForegroundColor Yellow

    Write-Host "`n[4.1] Get Connector Statistics..." -ForegroundColor Cyan
    Write-Host "  PowerShell command:" -ForegroundColor White
    Write-Host "    Get-ADSyncConnectorStatistics -ConnectorName 'contoso.com'" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Key metrics:" -ForegroundColor White
    Write-Host "    - Total objects in connector space" -ForegroundColor Gray
    Write-Host "    - Pending import adds/updates/deletes" -ForegroundColor Gray
    Write-Host "    - Pending export adds/updates/deletes" -ForegroundColor Gray
    Write-Host "    - Error count" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[4.2] Check Run Profile Results..." -ForegroundColor Cyan
    Write-Host "  View recent run history:" -ForegroundColor White
    Write-Host "    Get-ADSyncRunProfileResult -ConnectorName 'contoso.com' -NumberOfResults 10" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Analyze results:" -ForegroundColor White
    Write-Host "    - Start and end time (duration)" -ForegroundColor Gray
    Write-Host "    - Number of objects processed" -ForegroundColor Gray
    Write-Host "    - Errors encountered" -ForegroundColor Gray
    Write-Host "    - Result status" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[4.3] Export Connector Space Errors..." -ForegroundColor Cyan
    Write-Host "  Export errors to XML:" -ForegroundColor White
    Write-Host "    csexport 'contoso.com' 'C:\Temp\errors.xml' /f:e" -ForegroundColor Yellow
    Write-Host "    # /f:e = export errors only" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Export all objects:" -ForegroundColor White
    Write-Host "    csexport 'contoso.com' 'C:\Temp\all-objects.xml' /f:x" -ForegroundColor Yellow
    Write-Host "    # /f:x = export all" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[SUCCESS] Connector diagnostics documented" -ForegroundColor Green
    Write-Host ""

    # ============================================
    # STEP 5: Object Sync Issues
    # ============================================
    Write-Host "[Step 5] Troubleshooting Object Sync Issues" -ForegroundColor Yellow

    Write-Host "`n[5.1] CSExport Errors..." -ForegroundColor Cyan
    Write-Host "  Common CSExport errors and resolutions:" -ForegroundColor White
    Write-Host ""
    Write-Host "  Error: duplicate-attribute-resiliency" -ForegroundColor White
    Write-Host "    Cause: Duplicate ProxyAddresses or UPN" -ForegroundColor Gray
    Write-Host "    Resolution:" -ForegroundColor Gray
    Write-Host "      1. Identify duplicate: Get-ADUser -Filter {proxyAddresses -like '*smtp:user@domain.com*'}" -ForegroundColor Yellow
    Write-Host "      2. Remove or change duplicate attribute" -ForegroundColor Yellow
    Write-Host "      3. Re-run sync" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Error: data-validation-failed" -ForegroundColor White
    Write-Host "    Cause: Invalid attribute value format" -ForegroundColor Gray
    Write-Host "    Resolution: Correct attribute value in source directory" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Error: AttributeValueMustBeUnique" -ForegroundColor White
    Write-Host "    Cause: Another object already uses this value" -ForegroundColor Gray
    Write-Host "    Resolution: Change to unique value or remove from other object" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[5.2] Metaverse Join Issues..." -ForegroundColor Cyan
    Write-Host "  Diagnosis:" -ForegroundColor White
    Write-Host "    1. Search metaverse for object" -ForegroundColor Gray
    Write-Host "    2. Check if multiple connector space objects joined" -ForegroundColor Gray
    Write-Host "    3. Review join rules in Sync Rules Editor" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Resolution:" -ForegroundColor White
    Write-Host "    - Adjust join rules if incorrect" -ForegroundColor Gray
    Write-Host "    - Disconnect and reconnect objects" -ForegroundColor Gray
    Write-Host "    - Delete metaverse object if orphaned" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[5.3] Missing Objects..." -ForegroundColor Cyan
    Write-Host "  Troubleshooting workflow:" -ForegroundColor White
    Write-Host "    1. Verify object exists in source (Get-ADUser)" -ForegroundColor Gray
    Write-Host "    2. Check if in scope for sync (OU filtering)" -ForegroundColor Gray
    Write-Host "    3. Search connector space (should be there)" -ForegroundColor Gray
    Write-Host "    4. Check sync rules (inbound and outbound)" -ForegroundColor Gray
    Write-Host "    5. Look for errors in Sync Service Manager" -ForegroundColor Gray
    Write-Host "    6. Run full sync if needed" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[5.4] Soft Delete vs Hard Delete..." -ForegroundColor Cyan
    Write-Host "  Soft delete (default):" -ForegroundColor White
    Write-Host "    - Object marked for deletion but not immediately removed" -ForegroundColor Gray
    Write-Host "    - Allows accidental deletion recovery" -ForegroundColor Gray
    Write-Host "    - Automatically purged after 30 days" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Hard delete:" -ForegroundColor White
    Write-Host "    - Immediate permanent deletion" -ForegroundColor Gray
    Write-Host "    - Use only when intentional" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[SUCCESS] Object sync troubleshooting documented" -ForegroundColor Green
    Write-Host ""

    # ============================================
    # STEP 6: Sync Rule Precedence
    # ============================================
    Write-Host "[Step 6] Sync Rule Precedence Troubleshooting" -ForegroundColor Yellow

    Write-Host "`n[6.1] Understanding Precedence..." -ForegroundColor Cyan
    Write-Host "  Precedence rules:" -ForegroundColor White
    Write-Host "    - Lower number = higher priority (0-99)" -ForegroundColor Gray
    Write-Host "    - Out-of-box rules: 100-999" -ForegroundColor Gray
    Write-Host "    - Custom rules: 0-99 (recommended: 50-99)" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[6.2] View Sync Rules..." -ForegroundColor Cyan
    Write-Host "  Launch Sync Rules Editor:" -ForegroundColor White
    Write-Host "    Start -> Azure AD Connect -> Synchronization Rules Editor" -ForegroundColor Gray
    Write-Host "    Or execute: SynchronizationRulesEditor.exe" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Filter and sort:" -ForegroundColor White
    Write-Host "    - Direction: Inbound (from AD) or Outbound (to Azure AD)" -ForegroundColor Gray
    Write-Host "    - Connected System: Select specific connector" -ForegroundColor Gray
    Write-Host "    - Sort by Precedence column" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[6.3] Analyzing Rule Conflicts..." -ForegroundColor Cyan
    Write-Host "  Identify conflicts:" -ForegroundColor White
    Write-Host "    1. Look for multiple rules with same scope" -ForegroundColor Gray
    Write-Host "    2. Check attribute flow mappings" -ForegroundColor Gray
    Write-Host "    3. Review join conditions" -ForegroundColor Gray
    Write-Host "    4. Check precedence ordering" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Resolution:" -ForegroundColor White
    Write-Host "    - Disable conflicting rules (don't delete out-of-box rules)" -ForegroundColor Gray
    Write-Host "    - Adjust precedence numbers" -ForegroundColor Gray
    Write-Host "    - Create custom rules at correct precedence" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[6.4] Custom Sync Rules Best Practices..." -ForegroundColor Cyan
    Write-Host "  Guidelines:" -ForegroundColor White
    Write-Host "    - Never modify out-of-box rules (create custom instead)" -ForegroundColor Gray
    Write-Host "    - Use precedence 50-99 for custom rules" -ForegroundColor Gray
    Write-Host "    - Document custom rules thoroughly" -ForegroundColor Gray
    Write-Host "    - Test in staging mode first" -ForegroundColor Gray
    Write-Host "    - Run full sync after rule changes" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[SUCCESS] Sync rule troubleshooting documented" -ForegroundColor Green
    Write-Host ""

    # ============================================
    # STEP 7: Upgrade Procedures
    # ============================================
    Write-Host "[Step 7] Azure AD Connect Upgrade Procedures" -ForegroundColor Yellow

    Write-Host "`n[7.1] Check Current Version..." -ForegroundColor Cyan
    Write-Host "  Determine installed version:" -ForegroundColor White
    Write-Host "    Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Azure AD Connect\' -Name 'Version'" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Or check in:" -ForegroundColor White
    Write-Host "    Control Panel -> Programs and Features -> Azure AD Connect" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[7.2] Upgrade Methods..." -ForegroundColor Cyan
    Write-Host "  Auto-upgrade (recommended):" -ForegroundColor White
    Write-Host "    - Automatically downloads and installs updates" -ForegroundColor Gray
    Write-Host "    - Enabled by default for Express installations" -ForegroundColor Gray
    Write-Host "    - Check status: Get-ADSyncAutoUpgrade" -ForegroundColor Yellow
    Write-Host "    - Enable: Set-ADSyncAutoUpgrade -AutoUpgradeState Enabled" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Manual upgrade:" -ForegroundColor White
    Write-Host "    1. Download latest version from Microsoft" -ForegroundColor Gray
    Write-Host "    2. Backup AD Connect server" -ForegroundColor Gray
    Write-Host "    3. Run installer (in-place upgrade)" -ForegroundColor Gray
    Write-Host "    4. Verify sync after upgrade" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[7.3] Pre-Upgrade Checklist..." -ForegroundColor Cyan
    Write-Host "  Before upgrading:" -ForegroundColor White
    Write-Host "    1. Backup AD Connect server (VM snapshot or full backup)" -ForegroundColor Gray
    Write-Host "    2. Document current configuration" -ForegroundColor Gray
    Write-Host "    3. Export sync rules: Get-ADSyncRule | Export-Csv rules.csv" -ForegroundColor Gray
    Write-Host "    4. Review release notes" -ForegroundColor Gray
    Write-Host "    5. Schedule maintenance window" -ForegroundColor Gray
    Write-Host "    6. Notify users of potential sync delays" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[7.4] Post-Upgrade Verification..." -ForegroundColor Cyan
    Write-Host "  After upgrade:" -ForegroundColor White
    Write-Host "    1. Verify sync service is running: Get-Service ADSync" -ForegroundColor Gray
    Write-Host "    2. Check scheduler: Get-ADSyncScheduler" -ForegroundColor Gray
    Write-Host "    3. Run manual sync: Start-ADSyncSyncCycle -PolicyType Delta" -ForegroundColor Gray
    Write-Host "    4. Monitor operations in Sync Service Manager" -ForegroundColor Gray
    Write-Host "    5. Check Azure AD Connect Health portal" -ForegroundColor Gray
    Write-Host "    6. Verify sample objects synced correctly" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[SUCCESS] Upgrade procedures documented" -ForegroundColor Green
    Write-Host ""

    # ============================================
    # STEP 8: Advanced Troubleshooting
    # ============================================
    Write-Host "[Step 8] Advanced Troubleshooting Techniques" -ForegroundColor Yellow

    Write-Host "`n[8.1] Staging Mode..." -ForegroundColor Cyan
    Write-Host "  Use staging mode to test changes:" -ForegroundColor White
    Write-Host "    - Staging server imports and syncs but doesn't export" -ForegroundColor Gray
    Write-Host "    - Use for testing rule changes" -ForegroundColor Gray
    Write-Host "    - Switch to production when ready" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Enable staging mode:" -ForegroundColor White
    Write-Host "    Set-ADSyncScheduler -StagingModeEnabled `$true" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[8.2] Connector Run Profiles..." -ForegroundColor Cyan
    Write-Host "  Manual run profiles:" -ForegroundColor White
    Write-Host "    - Full Import: Import all objects" -ForegroundColor Gray
    Write-Host "    - Delta Import: Import changes only" -ForegroundColor Gray
    Write-Host "    - Full Synchronization: Sync all objects" -ForegroundColor Gray
    Write-Host "    - Delta Synchronization: Sync changes only" -ForegroundColor Gray
    Write-Host "    - Export: Push changes to target" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[8.3] Troubleshooting Tools..." -ForegroundColor Cyan
    Write-Host "  csexport.exe: Export connector space data" -ForegroundColor White
    Write-Host "  csanalyzer.exe: Analyze CSExport files" -ForegroundColor White
    Write-Host "  miisserver.exe.config: Configuration file" -ForegroundColor White
    Write-Host "  Synchronization Service Manager: GUI tool" -ForegroundColor White
    Write-Host "  PowerShell Module: ADSync" -ForegroundColor White
    Write-Host ""

    Write-Host "[8.4] Event Log Analysis..." -ForegroundColor Cyan
    Write-Host "  Key event logs:" -ForegroundColor White
    Write-Host "    Application log:" -ForegroundColor Gray
    Write-Host "      Get-WinEvent -LogName Application -ProviderName 'Azure AD Connect' -MaxEvents 50" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Important event IDs:" -ForegroundColor White
    Write-Host "    6100: Sync cycle started" -ForegroundColor Gray
    Write-Host "    6101: Sync cycle completed" -ForegroundColor Gray
    Write-Host "    6102: Sync cycle error" -ForegroundColor Gray
    Write-Host "    6301: Unhandled exception" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[SUCCESS] Advanced troubleshooting documented" -ForegroundColor Green
    Write-Host ""

    # ============================================
    # STEP 9: Best Practices
    # ============================================
    Write-Host "[Step 9] Entra Connect Best Practices" -ForegroundColor Yellow

    Write-Host "`n[Best Practice 1] Regular Monitoring" -ForegroundColor Cyan
    Write-Host "  Daily monitoring:" -ForegroundColor White
    Write-Host "    - Check Azure AD Connect Health portal" -ForegroundColor Gray
    Write-Host "    - Review sync operations in Service Manager" -ForegroundColor Gray
    Write-Host "    - Monitor event logs for errors" -ForegroundColor Gray
    Write-Host "    - Verify sync scheduler is enabled" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[Best Practice 2] Change Management" -ForegroundColor Cyan
    Write-Host "  Before making changes:" -ForegroundColor White
    Write-Host "    - Document current state" -ForegroundColor Gray
    Write-Host "    - Test in staging mode" -ForegroundColor Gray
    Write-Host "    - Schedule maintenance window" -ForegroundColor Gray
    Write-Host "    - Have rollback plan ready" -ForegroundColor Gray
    Write-Host "    - Never modify out-of-box rules directly" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[Best Practice 3] High Availability" -ForegroundColor Cyan
    Write-Host "  HA recommendations:" -ForegroundColor White
    Write-Host "    - Deploy staging server" -ForegroundColor Gray
    Write-Host "    - Regular backups of AD Connect server" -ForegroundColor Gray
    Write-Host "    - Document configuration" -ForegroundColor Gray
    Write-Host "    - Test failover procedures" -ForegroundColor Gray
    Write-Host "    - Keep auto-upgrade enabled" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[Best Practice 4] Security" -ForegroundColor Cyan
    Write-Host "  Security considerations:" -ForegroundColor White
    Write-Host "    - Use dedicated service account" -ForegroundColor Gray
    Write-Host "    - Implement least privilege" -ForegroundColor Gray
    Write-Host "    - Enable Azure AD Connect Health" -ForegroundColor Gray
    Write-Host "    - Monitor for suspicious activities" -ForegroundColor Gray
    Write-Host "    - Regular security audits" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[Monitoring Script]" -ForegroundColor Cyan
    Write-Host "  Automated health check:" -ForegroundColor White
    Write-Host "    `$scheduler = Get-ADSyncScheduler" -ForegroundColor Yellow
    Write-Host "    `$lastSync = `$scheduler.LastSyncCycleEndTimestamp" -ForegroundColor Yellow
    Write-Host "    `$hoursSinceSync = ((Get-Date) - `$lastSync).TotalHours" -ForegroundColor Yellow
    Write-Host "    if (`$hoursSinceSync -gt 24) {" -ForegroundColor Yellow
    Write-Host "        Send-MailMessage -To 'admin@contoso.com' -Subject 'AD Connect Sync Alert' -Body 'No sync in 24 hours'" -ForegroundColor Yellow
    Write-Host "    }" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[INFO] Additional Resources:" -ForegroundColor Cyan
    Write-Host "  - Entra Connect docs: https://learn.microsoft.com/entra/identity/hybrid/connect/whatis-azure-ad-connect-v2" -ForegroundColor White
    Write-Host "  - Troubleshooting: https://learn.microsoft.com/entra/identity/hybrid/connect/tshoot-connect-sync-errors" -ForegroundColor White
    Write-Host "  - Health monitoring: https://learn.microsoft.com/entra/identity/hybrid/connect/whatis-azure-ad-connect" -ForegroundColor White
    Write-Host ""

} catch {
    Write-Host "[ERROR] $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

Write-Host "Microsoft Entra Connect troubleshooting demonstration completed successfully!" -ForegroundColor Green
Write-Host "Next Steps: Configure Health monitoring, implement regular maintenance, document procedures" -ForegroundColor Yellow
Write-Host ""
Write-Host "====================================================================================" -ForegroundColor Green
Write-Host "CONGRATULATIONS! You have completed ALL scripts in the AZ-801 repository!" -ForegroundColor Green
Write-Host "====================================================================================" -ForegroundColor Green
