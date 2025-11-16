<#
.SYNOPSIS
    Task 26.5 - Troubleshoot Hybrid Authentication

.DESCRIPTION
    Demo script for AZ-801 Module 26: Troubleshoot Active Directory
    Demonstrates troubleshooting for hybrid identity scenarios with Azure AD Connect.

    Covers:
    - Azure AD Connect sync troubleshooting
    - Password hash synchronization validation
    - Connector space errors
    - Synchronization Service Manager usage
    - Common sync errors and resolutions

.NOTES
    Module: Module 26 - Troubleshoot Active Directory
    Task: 26.5 - Troubleshoot Hybrid Authentication
    Prerequisites: Azure AD Connect installed, Administrative privileges
    PowerShell Version: 5.1+
#>

#Requires -RunAsAdministrator

$ErrorActionPreference = 'Stop'
Write-Host "=== AZ-801 Module 26: Task 26.5 - Troubleshoot Hybrid Authentication ===" -ForegroundColor Cyan
Write-Host ""

try {
    Write-Host "[Step 1] Hybrid Authentication Troubleshooting - Overview" -ForegroundColor Yellow
    Write-Host "Troubleshoot Azure AD Connect and hybrid identity synchronization" -ForegroundColor White
    Write-Host ""

    # ============================================
    # STEP 2: Check Azure AD Connect Status
    # ============================================
    Write-Host "[Step 2] Azure AD Connect Health Check" -ForegroundColor Yellow

    Write-Host "`n[2.1] Get Sync Scheduler Status..." -ForegroundColor Cyan
    Write-Host "  Check sync scheduler configuration:" -ForegroundColor White
    Write-Host "    Get-ADSyncScheduler" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Key properties to check:" -ForegroundColor White
    Write-Host "    - AllowedSyncCycleInterval: Min sync interval" -ForegroundColor Gray
    Write-Host "    - CurrentlyEffectiveSyncCycleInterval: Current interval" -ForegroundColor Gray
    Write-Host "    - SyncCycleEnabled: Is sync enabled" -ForegroundColor Gray
    Write-Host "    - MaintenanceEnabled: Maintenance mode status" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[2.2] Trigger Manual Sync..." -ForegroundColor Cyan
    Write-Host "  Delta sync (changes only):" -ForegroundColor White
    Write-Host "    Start-ADSyncSyncCycle -PolicyType Delta" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Full sync (all objects):" -ForegroundColor White
    Write-Host "    Start-ADSyncSyncCycle -PolicyType Initial" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[2.3] Check Service Status..." -ForegroundColor Cyan
    $syncService = Get-Service -Name "ADSync" -ErrorAction SilentlyContinue
    if ($syncService) {
        $color = if ($syncService.Status -eq 'Running') { 'Green' } else { 'Red' }
        Write-Host "  Azure AD Sync Service: $($syncService.Status)" -ForegroundColor $color
    } else {
        Write-Host "  [INFO] Azure AD Connect not installed on this server" -ForegroundColor Gray
    }
    Write-Host ""

    Write-Host "[SUCCESS] Health check commands documented" -ForegroundColor Green
    Write-Host ""

    # ============================================
    # STEP 3: Password Hash Synchronization
    # ============================================
    Write-Host "[Step 3] Password Hash Synchronization" -ForegroundColor Yellow

    Write-Host "`n[3.1] Verify PHS Configuration..." -ForegroundColor Cyan
    Write-Host "  Check if PHS is enabled:" -ForegroundColor White
    Write-Host "    Get-ADSyncScheduler | Select-Object SyncCycleEnabled" -ForegroundColor Yellow
    Write-Host "    Get-ADSyncAADPasswordSyncConfiguration -SourceConnector contoso.com" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[3.2] Force Password Sync..." -ForegroundColor Cyan
    Write-Host "  Trigger password hash sync:" -ForegroundColor White
    Write-Host "    Import-Module ADSync" -ForegroundColor Yellow
    Write-Host "    Start-ADSyncSyncCycle -PolicyType Delta" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[3.3] Test Password Hash Sync..." -ForegroundColor Cyan
    Write-Host "  Validate specific user:" -ForegroundColor White
    Write-Host "    # Change password in AD" -ForegroundColor Gray
    Write-Host "    Set-ADAccountPassword -Identity 'jdoe' -Reset" -ForegroundColor Yellow
    Write-Host "    # Trigger sync" -ForegroundColor Gray
    Write-Host "    Start-ADSyncSyncCycle -PolicyType Delta" -ForegroundColor Yellow
    Write-Host "    # Wait 5-10 minutes, then test Azure AD login" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[3.4] Common PHS Issues..." -ForegroundColor Cyan
    Write-Host "  Issue: Passwords not syncing" -ForegroundColor White
    Write-Host "  Solutions:" -ForegroundColor White
    Write-Host "    1. Verify PHS feature is enabled in Azure AD Connect" -ForegroundColor Gray
    Write-Host "    2. Check ADSync service is running" -ForegroundColor Gray
    Write-Host "    3. Review event logs (Event Viewer -> Applications and Services -> Azure AD Connect)" -ForegroundColor Gray
    Write-Host "    4. Ensure user is in scope for synchronization" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[SUCCESS] PHS troubleshooting documented" -ForegroundColor Green
    Write-Host ""

    # ============================================
    # STEP 4: Synchronization Service Manager
    # ============================================
    Write-Host "[Step 4] Synchronization Service Manager" -ForegroundColor Yellow

    Write-Host "`n[4.1] Accessing Sync Service Manager..." -ForegroundColor Cyan
    Write-Host "  Open Synchronization Service Manager:" -ForegroundColor White
    Write-Host "    Start -> Azure AD Connect -> Synchronization Service" -ForegroundColor Gray
    Write-Host "    Or: miisclient.exe" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[4.2] Operations Tab..." -ForegroundColor Cyan
    Write-Host "  View recent sync operations:" -ForegroundColor White
    Write-Host "    - Full Import: Imports all objects from connector" -ForegroundColor Gray
    Write-Host "    - Delta Import: Imports changes only" -ForegroundColor Gray
    Write-Host "    - Full Sync: Syncs all objects" -ForegroundColor Gray
    Write-Host "    - Delta Sync: Syncs changes only" -ForegroundColor Gray
    Write-Host "    - Export: Exports changes to Azure AD" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Check for errors:" -ForegroundColor White
    Write-Host "    - Look for red X or warning icons" -ForegroundColor Gray
    Write-Host "    - Click on operation to view details" -ForegroundColor Gray
    Write-Host "    - Review connector statistics" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[4.3] Connectors Tab..." -ForegroundColor Cyan
    Write-Host "  Review connector configuration:" -ForegroundColor White
    Write-Host "    - On-Premises AD Connector" -ForegroundColor Gray
    Write-Host "    - Azure AD Connector" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Common tasks:" -ForegroundColor White
    Write-Host "    - Right-click connector -> Run" -ForegroundColor Gray
    Write-Host "    - View properties and connection info" -ForegroundColor Gray
    Write-Host "    - Check partition and hierarchy settings" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[4.4] Metaverse Search..." -ForegroundColor Cyan
    Write-Host "  Search for synced objects:" -ForegroundColor White
    Write-Host "    1. Go to Metaverse Search tab" -ForegroundColor Gray
    Write-Host "    2. Select object type (person, group, etc.)" -ForegroundColor Gray
    Write-Host "    3. Add search criteria" -ForegroundColor Gray
    Write-Host "    4. Click Search" -ForegroundColor Gray
    Write-Host "    5. View object properties and lineage" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[SUCCESS] Sync Service Manager usage documented" -ForegroundColor Green
    Write-Host ""

    # ============================================
    # STEP 5: Common Sync Errors
    # ============================================
    Write-Host "[Step 5] Common Synchronization Errors" -ForegroundColor Yellow

    Write-Host "`n[Error 1] Duplicate Attribute (Object Already Exists)" -ForegroundColor Cyan
    Write-Host "  Symptoms: 'AttributeValueMustBeUnique' error" -ForegroundColor White
    Write-Host "  Cause: ProxyAddresses or UserPrincipalName conflict" -ForegroundColor White
    Write-Host "  Solution:" -ForegroundColor White
    Write-Host "    1. Identify conflicting objects in Azure AD" -ForegroundColor Gray
    Write-Host "    2. Resolve conflict (change UPN or proxy address)" -ForegroundColor Gray
    Write-Host "    3. Re-run sync" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  PowerShell check:" -ForegroundColor White
    Write-Host "    Get-ADUser -Filter {UserPrincipalName -eq 'jdoe@contoso.com'}" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[Error 2] Sync Rule Conflict" -ForegroundColor Cyan
    Write-Host "  Symptoms: Objects not syncing, precedence errors" -ForegroundColor White
    Write-Host "  Solution:" -ForegroundColor White
    Write-Host "    1. Review sync rules in Sync Rules Editor" -ForegroundColor Gray
    Write-Host "    2. Check rule precedence (lower number = higher priority)" -ForegroundColor Gray
    Write-Host "    3. Disable or modify conflicting rules" -ForegroundColor Gray
    Write-Host "    4. Run full sync" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[Error 3] Large Object Deletions" -ForegroundColor Cyan
    Write-Host "  Symptoms: Sync stops after detecting many deletions" -ForegroundColor White
    Write-Host "  Cause: Deletion threshold exceeded (default 500)" -ForegroundColor White
    Write-Host "  Solution:" -ForegroundColor White
    Write-Host "    1. Review what objects are being deleted" -ForegroundColor Gray
    Write-Host "    2. If intentional, disable deletion prevention temporarily:" -ForegroundColor Gray
    Write-Host "       Disable-ADSyncExportDeletionThreshold" -ForegroundColor Yellow
    Write-Host "    3. Run sync" -ForegroundColor Gray
    Write-Host "    4. Re-enable protection:" -ForegroundColor Gray
    Write-Host "       Enable-ADSyncExportDeletionThreshold -DeletionThreshold 500" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[Error 4] Connector Space Errors" -ForegroundColor Cyan
    Write-Host "  Symptoms: Objects show errors in connector space" -ForegroundColor White
    Write-Host "  Diagnosis:" -ForegroundColor White
    Write-Host "    1. Open Synchronization Service Manager" -ForegroundColor Gray
    Write-Host "    2. Click on failed operation" -ForegroundColor Gray
    Write-Host "    3. Review 'Connector Space Object Properties'" -ForegroundColor Gray
    Write-Host "  Common causes:" -ForegroundColor White
    Write-Host "    - Missing required attributes" -ForegroundColor Gray
    Write-Host "    - Invalid attribute values" -ForegroundColor Gray
    Write-Host "    - Permission issues" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[Error 5] Azure AD Connection Issues" -ForegroundColor Cyan
    Write-Host "  Symptoms: Cannot connect to Azure AD" -ForegroundColor White
    Write-Host "  Solutions:" -ForegroundColor White
    Write-Host "    1. Verify internet connectivity" -ForegroundColor Gray
    Write-Host "    2. Check proxy settings" -ForegroundColor Gray
    Write-Host "    3. Verify Azure AD credentials:" -ForegroundColor Gray
    Write-Host "       Test-AzureADConnectConnectivity" -ForegroundColor Yellow
    Write-Host "    4. Check firewall rules (allow *.microsoftonline.com)" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[SUCCESS] Common errors documented" -ForegroundColor Green
    Write-Host ""

    # ============================================
    # STEP 6: Advanced Troubleshooting
    # ============================================
    Write-Host "[Step 6] Advanced Troubleshooting Tools" -ForegroundColor Yellow

    Write-Host "`n[6.1] Get Connector Statistics..." -ForegroundColor Cyan
    Write-Host "  View sync statistics:" -ForegroundColor White
    Write-Host "    Get-ADSyncConnectorStatistics -ConnectorName 'contoso.com'" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[6.2] CSExport Analysis..." -ForegroundColor Cyan
    Write-Host "  Export connector space for analysis:" -ForegroundColor White
    Write-Host "    # Export errors only" -ForegroundColor Gray
    Write-Host "    csexport 'contoso.com' 'C:\Temp\cs-export.xml' /f:e" -ForegroundColor Yellow
    Write-Host "    # Export all objects" -ForegroundColor Gray
    Write-Host "    csexport 'contoso.com' 'C:\Temp\cs-export.xml' /f:x" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[6.3] Sync Rule Precedence..." -ForegroundColor Cyan
    Write-Host "  View and manage sync rules:" -ForegroundColor White
    Write-Host "    1. Open 'Synchronization Rules Editor'" -ForegroundColor Gray
    Write-Host "    2. View Inbound/Outbound rules" -ForegroundColor Gray
    Write-Host "    3. Check precedence (0-99: higher priority)" -ForegroundColor Gray
    Write-Host "    4. Review transformations and attribute flows" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[6.4] Troubleshooting Cmdlets..." -ForegroundColor Cyan
    Write-Host "  Useful PowerShell commands:" -ForegroundColor White
    Write-Host "    # Get all sync errors" -ForegroundColor Gray
    Write-Host "    Get-ADSyncScheduler" -ForegroundColor Yellow
    Write-Host "    # Check connector run history" -ForegroundColor Gray
    Write-Host "    Get-ADSyncRunProfileResult -ConnectorName 'contoso.com' -NumberOfResults 10" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[SUCCESS] Advanced tools documented" -ForegroundColor Green
    Write-Host ""

    # ============================================
    # STEP 7: Best Practices
    # ============================================
    Write-Host "[Step 7] Hybrid Authentication Best Practices" -ForegroundColor Yellow

    Write-Host "`n[Best Practice 1] Regular Monitoring" -ForegroundColor Cyan
    Write-Host "  - Monitor sync cycles daily" -ForegroundColor White
    Write-Host "  - Set up alerts for sync failures" -ForegroundColor White
    Write-Host "  - Review Azure AD Connect Health portal" -ForegroundColor White
    Write-Host "  - Check event logs regularly" -ForegroundColor White
    Write-Host ""

    Write-Host "[Best Practice 2] Maintenance" -ForegroundColor Cyan
    Write-Host "  - Keep Azure AD Connect updated" -ForegroundColor White
    Write-Host "  - Review and clean up sync rules periodically" -ForegroundColor White
    Write-Host "  - Document custom sync rules" -ForegroundColor White
    Write-Host "  - Test changes in staging mode first" -ForegroundColor White
    Write-Host ""

    Write-Host "[Best Practice 3] Security" -ForegroundColor Cyan
    Write-Host "  - Use dedicated service account for AD Connect" -ForegroundColor White
    Write-Host "  - Implement least privilege access" -ForegroundColor White
    Write-Host "  - Enable Azure AD Connect Health" -ForegroundColor White
    Write-Host "  - Monitor for suspicious sync activities" -ForegroundColor White
    Write-Host ""

    Write-Host "[Best Practice 4] Disaster Recovery" -ForegroundColor Cyan
    Write-Host "  - Backup AD Connect configuration regularly" -ForegroundColor White
    Write-Host "  - Document recovery procedures" -ForegroundColor White
    Write-Host "  - Have staging server ready" -ForegroundColor White
    Write-Host "  - Test failover procedures" -ForegroundColor White
    Write-Host ""

    Write-Host "[INFO] Additional Resources:" -ForegroundColor Cyan
    Write-Host "  - Azure AD Connect docs: https://docs.microsoft.com/azure/active-directory/hybrid/" -ForegroundColor White
    Write-Host "  - Troubleshooting guide: https://docs.microsoft.com/azure/active-directory/hybrid/tshoot-connect-sync-errors" -ForegroundColor White
    Write-Host ""

} catch {
    Write-Host "[ERROR] $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

Write-Host "Hybrid authentication troubleshooting demonstration completed successfully!" -ForegroundColor Green
Write-Host "Next Steps: Configure monitoring, document procedures, train team on sync troubleshooting" -ForegroundColor Yellow
