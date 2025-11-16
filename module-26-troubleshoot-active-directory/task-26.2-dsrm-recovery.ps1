<#
.SYNOPSIS
    Task 26.2 - Perform DSRM Recovery

.DESCRIPTION
    Demo script for AZ-801 Module 26: Troubleshoot Active Directory
    Shows Directory Services Restore Mode recovery procedures.

    Covers:
    - DSRM password management
    - Booting into DSRM
    - Authoritative vs non-authoritative restore
    - Database integrity verification
    - SYSVOL coordination
    - Recovery procedures

.NOTES
    Module: Module 26 - Troubleshoot Active Directory
    Task: 26.2 - Perform DSRM Recovery
    Prerequisites: Domain Controller, Administrative privileges
    PowerShell Version: 5.1+

    WARNING: DSRM operations are critical - use only in disaster recovery scenarios!
#>

#Requires -RunAsAdministrator

$ErrorActionPreference = 'Stop'
Write-Host "=== AZ-801 Module 26: Task 26.2 - Perform DSRM Recovery ===" -ForegroundColor Cyan
Write-Host ""

try {
    Write-Host "[Step 1] DSRM Recovery - Overview" -ForegroundColor Yellow
    Write-Host "Directory Services Restore Mode is used for critical AD recovery operations" -ForegroundColor White
    Write-Host "WARNING: DSRM procedures should only be performed during disaster recovery!" -ForegroundColor Red
    Write-Host ""

    # ============================================
    # STEP 2: DSRM Password Management
    # ============================================
    Write-Host "[Step 2] DSRM Password Management" -ForegroundColor Yellow

    Write-Host "`n[2.1] Understanding the DSRM Password..." -ForegroundColor Cyan
    Write-Host "  The DSRM password:" -ForegroundColor White
    Write-Host "    - Set during DC promotion (dcpromo)" -ForegroundColor Gray
    Write-Host "    - Local administrator account for DSRM" -ForegroundColor Gray
    Write-Host "    - Not the domain admin password" -ForegroundColor Gray
    Write-Host "    - Should be managed and documented securely" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[2.2] Checking DSRM Password Status..." -ForegroundColor Cyan
    Write-Host "  View DSRM account information:" -ForegroundColor White
    Write-Host "    ntdsutil" -ForegroundColor Yellow
    Write-Host "    set dsrm password" -ForegroundColor Yellow
    Write-Host "    reset password on server <servername>" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[2.3] Resetting DSRM Password..." -ForegroundColor Cyan
    Write-Host "  Method 1: Using ntdsutil (interactive)" -ForegroundColor White
    Write-Host "    ntdsutil" -ForegroundColor Yellow
    Write-Host "    set dsrm password" -ForegroundColor Yellow
    Write-Host "    reset password on server null" -ForegroundColor Yellow
    Write-Host "    <enter new password when prompted>" -ForegroundColor Yellow
    Write-Host "    quit" -ForegroundColor Yellow
    Write-Host "    quit" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "  Method 2: Using PowerShell with ntdsutil" -ForegroundColor White
    Write-Host "    # Run ntdsutil in batch mode (requires manual intervention)" -ForegroundColor Gray
    Write-Host "    `$commands = @(" -ForegroundColor Yellow
    Write-Host "        'set dsrm password'" -ForegroundColor Yellow
    Write-Host "        'reset password on server null'" -ForegroundColor Yellow
    Write-Host "        'quit'" -ForegroundColor Yellow
    Write-Host "        'quit'" -ForegroundColor Yellow
    Write-Host "    )" -ForegroundColor Yellow
    Write-Host "    `$commands | ntdsutil" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "  Method 3: Sync with domain admin password" -ForegroundColor White
    Write-Host "    ntdsutil" -ForegroundColor Yellow
    Write-Host "    set dsrm password" -ForegroundColor Yellow
    Write-Host "    sync from domain account <DomainName>\<Username>" -ForegroundColor Yellow
    Write-Host "    quit" -ForegroundColor Yellow
    Write-Host "    quit" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[2.4] DSRM Password Best Practices..." -ForegroundColor Cyan
    Write-Host "  Recommendations:" -ForegroundColor White
    Write-Host "    - Change DSRM password regularly (quarterly recommended)" -ForegroundColor Gray
    Write-Host "    - Store in secure password vault" -ForegroundColor Gray
    Write-Host "    - Document password reset procedures" -ForegroundColor Gray
    Write-Host "    - Test password periodically (boot to DSRM)" -ForegroundColor Gray
    Write-Host "    - Ensure all admins know where password is stored" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[SUCCESS] DSRM password management documented" -ForegroundColor Green
    Write-Host ""

    # ============================================
    # STEP 3: Booting into DSRM
    # ============================================
    Write-Host "[Step 3] Booting into Directory Services Restore Mode" -ForegroundColor Yellow

    Write-Host "`n[3.1] Methods to Enter DSRM..." -ForegroundColor Cyan
    Write-Host "  Method 1: Using bcdedit (one-time boot)" -ForegroundColor White
    Write-Host "    # Set boot to safe mode with Directory Services Repair" -ForegroundColor Gray
    Write-Host "    bcdedit /set safeboot dsrepair" -ForegroundColor Yellow
    Write-Host "    # Reboot the server" -ForegroundColor Gray
    Write-Host "    Restart-Computer -Force" -ForegroundColor Yellow
    Write-Host "    # After work is done, remove safe boot" -ForegroundColor Gray
    Write-Host "    bcdedit /deletevalue safeboot" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "  Method 2: Using System Configuration (msconfig)" -ForegroundColor White
    Write-Host "    1. Run: msconfig" -ForegroundColor Gray
    Write-Host "    2. Boot tab -> Safe boot -> Active Directory repair" -ForegroundColor Gray
    Write-Host "    3. Apply and restart" -ForegroundColor Gray
    Write-Host "    4. After recovery, uncheck Safe boot" -ForegroundColor Gray
    Write-Host ""

    Write-Host "  Method 3: F8 during boot (older servers)" -ForegroundColor White
    Write-Host "    1. Restart server" -ForegroundColor Gray
    Write-Host "    2. Press F8 during boot" -ForegroundColor Gray
    Write-Host "    3. Select 'Directory Services Restore Mode'" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[3.2] Verifying DSRM Boot..." -ForegroundColor Cyan
    Write-Host "  After booting into DSRM:" -ForegroundColor White
    Write-Host "    - Server boots to safe mode with networking" -ForegroundColor Gray
    Write-Host "    - AD DS service is STOPPED" -ForegroundColor Gray
    Write-Host "    - Login with DSRM password (local admin)" -ForegroundColor Gray
    Write-Host "    - Background will indicate Safe Mode" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Verify AD DS is stopped:" -ForegroundColor White
    Write-Host "    Get-Service NTDS" -ForegroundColor Yellow
    Write-Host "    # Status should be 'Stopped' in DSRM" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[3.3] Returning to Normal Mode..." -ForegroundColor Cyan
    Write-Host "  Remove safe boot configuration:" -ForegroundColor White
    Write-Host "    bcdedit /deletevalue safeboot" -ForegroundColor Yellow
    Write-Host "    Restart-Computer -Force" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[SUCCESS] DSRM boot procedures documented" -ForegroundColor Green
    Write-Host ""

    # ============================================
    # STEP 4: Database Integrity Check
    # ============================================
    Write-Host "[Step 4] Active Directory Database Integrity" -ForegroundColor Yellow

    Write-Host "`n[4.1] Database File Locations..." -ForegroundColor Cyan
    Write-Host "  Default AD database locations:" -ForegroundColor White
    Write-Host "    Database: C:\Windows\NTDS\ntds.dit" -ForegroundColor Gray
    Write-Host "    Logs: C:\Windows\NTDS\*.log" -ForegroundColor Gray
    Write-Host "    Working folder: C:\Windows\NTDS" -ForegroundColor Gray
    Write-Host ""

    # Check if NTDS database exists
    $ntdsPath = "C:\Windows\NTDS\ntds.dit"
    if (Test-Path $ntdsPath) {
        Write-Host "  [SUCCESS] AD database found at: $ntdsPath" -ForegroundColor Green
        $dbSize = [math]::Round((Get-Item $ntdsPath).Length / 1MB, 2)
        Write-Host "  Database size: $dbSize MB" -ForegroundColor Gray
    } else {
        Write-Host "  [INFO] AD database not found (not running on DC or different path)" -ForegroundColor Gray
    }
    Write-Host ""

    Write-Host "[4.2] Database Integrity Check with esentutl..." -ForegroundColor Cyan
    Write-Host "  Check database integrity (must be in DSRM):" -ForegroundColor White
    Write-Host "    esentutl /g C:\Windows\NTDS\ntds.dit" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Parameters:" -ForegroundColor White
    Write-Host "    /g = integrity check" -ForegroundColor Gray
    Write-Host "    /mh = dump database header" -ForegroundColor Gray
    Write-Host "    /ml = dump log file header" -ForegroundColor Gray
    Write-Host "    /p = repair (use with extreme caution!)" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[4.3] View Database Header..." -ForegroundColor Cyan
    Write-Host "  Display database metadata:" -ForegroundColor White
    Write-Host "    esentutl /mh C:\Windows\NTDS\ntds.dit" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Important values to check:" -ForegroundColor White
    Write-Host "    - State: Should be 'Clean Shutdown' or 'Dirty Shutdown'" -ForegroundColor Gray
    Write-Host "    - Log Required: Log files needed for consistency" -ForegroundColor Gray
    Write-Host "    - DB Signature: Database identifier" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[4.4] Compact Database (if needed)..." -ForegroundColor Cyan
    Write-Host "  Offline defragmentation (DSRM only):" -ForegroundColor White
    Write-Host "    # Step 1: Create a copy" -ForegroundColor Gray
    Write-Host "    Copy-Item C:\Windows\NTDS\ntds.dit C:\Temp\ntds_backup.dit" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "    # Step 2: Compact to new location" -ForegroundColor Gray
    Write-Host "    ntdsutil" -ForegroundColor Yellow
    Write-Host "    activate instance ntds" -ForegroundColor Yellow
    Write-Host "    files" -ForegroundColor Yellow
    Write-Host "    compact to C:\Temp" -ForegroundColor Yellow
    Write-Host "    quit" -ForegroundColor Yellow
    Write-Host "    quit" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "    # Step 3: Replace old database" -ForegroundColor Gray
    Write-Host "    Move-Item C:\Windows\NTDS\ntds.dit C:\Windows\NTDS\ntds.dit.old" -ForegroundColor Yellow
    Write-Host "    Move-Item C:\Temp\ntds.dit C:\Windows\NTDS\ntds.dit" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[SUCCESS] Database integrity procedures documented" -ForegroundColor Green
    Write-Host ""

    # ============================================
    # STEP 5: Non-Authoritative Restore
    # ============================================
    Write-Host "[Step 5] Non-Authoritative Restore" -ForegroundColor Yellow

    Write-Host "`n[5.1] When to Use Non-Authoritative Restore..." -ForegroundColor Cyan
    Write-Host "  Use cases:" -ForegroundColor White
    Write-Host "    - DC database corruption" -ForegroundColor Gray
    Write-Host "    - Hardware failure requiring system state restore" -ForegroundColor Gray
    Write-Host "    - Want DC to sync latest changes from other DCs" -ForegroundColor Gray
    Write-Host "    - Recovering a single DC in multi-DC environment" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[5.2] Non-Authoritative Restore Process..." -ForegroundColor Cyan
    Write-Host "  Step 1: Boot into DSRM" -ForegroundColor White
    Write-Host "    bcdedit /set safeboot dsrepair" -ForegroundColor Yellow
    Write-Host "    Restart-Computer -Force" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Step 2: Restore System State from backup" -ForegroundColor White
    Write-Host "    wbadmin start systemstaterecovery -version:<backup-version> -quiet" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Step 3: Reboot normally (remove safe boot)" -ForegroundColor White
    Write-Host "    bcdedit /deletevalue safeboot" -ForegroundColor Yellow
    Write-Host "    Restart-Computer -Force" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Step 4: DC syncs with other DCs and receives latest changes" -ForegroundColor White
    Write-Host ""

    Write-Host "[5.3] Verifying Restore Success..." -ForegroundColor Cyan
    Write-Host "  After reboot, check:" -ForegroundColor White
    Write-Host "    # AD DS service status" -ForegroundColor Gray
    Write-Host "    Get-Service NTDS" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "    # Replication status" -ForegroundColor Gray
    Write-Host "    repadmin /showrepl" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "    # Force immediate sync" -ForegroundColor Gray
    Write-Host "    repadmin /syncall /AdeP" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[SUCCESS] Non-authoritative restore documented" -ForegroundColor Green
    Write-Host ""

    # ============================================
    # STEP 6: Authoritative Restore
    # ============================================
    Write-Host "[Step 6] Authoritative Restore" -ForegroundColor Yellow

    Write-Host "`n[6.1] When to Use Authoritative Restore..." -ForegroundColor Cyan
    Write-Host "  Use cases:" -ForegroundColor White
    Write-Host "    - Accidentally deleted OU with many objects" -ForegroundColor Gray
    Write-Host "    - Need to restore specific objects/subtrees" -ForegroundColor Gray
    Write-Host "    - Want restored data to replicate to all DCs" -ForegroundColor Gray
    Write-Host "    - Overwrite current AD data with backup data" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  WARNING: Authoritative restore will:" -ForegroundColor Red
    Write-Host "    - Increment USN numbers on restored objects" -ForegroundColor Gray
    Write-Host "    - Force restored data to replicate to all DCs" -ForegroundColor Gray
    Write-Host "    - Overwrite current data in AD" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[6.2] Authoritative Restore Process..." -ForegroundColor Cyan
    Write-Host "  Step 1: Perform non-authoritative restore first" -ForegroundColor White
    Write-Host "    (See Step 5 above)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Step 2: While still in DSRM, mark objects as authoritative" -ForegroundColor White
    Write-Host "    ntdsutil" -ForegroundColor Yellow
    Write-Host "    activate instance ntds" -ForegroundColor Yellow
    Write-Host "    authoritative restore" -ForegroundColor Yellow
    Write-Host "    # Restore entire database (rare)" -ForegroundColor Gray
    Write-Host "    restore database" -ForegroundColor Yellow
    Write-Host "    # OR restore specific subtree (common)" -ForegroundColor Gray
    Write-Host "    restore subtree 'OU=Sales,DC=contoso,DC=com'" -ForegroundColor Yellow
    Write-Host "    # OR restore specific object" -ForegroundColor Gray
    Write-Host "    restore object 'CN=JohnDoe,OU=Users,DC=contoso,DC=com'" -ForegroundColor Yellow
    Write-Host "    quit" -ForegroundColor Yellow
    Write-Host "    quit" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Step 3: Remove safe boot and restart" -ForegroundColor White
    Write-Host "    bcdedit /deletevalue safeboot" -ForegroundColor Yellow
    Write-Host "    Restart-Computer -Force" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[6.3] Verifying Authoritative Restore..." -ForegroundColor Cyan
    Write-Host "  Check replication of restored objects:" -ForegroundColor White
    Write-Host "    # Monitor replication" -ForegroundColor Gray
    Write-Host "    repadmin /showrepl" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "    # Verify object exists" -ForegroundColor Gray
    Write-Host "    Get-ADObject -Identity 'OU=Sales,DC=contoso,DC=com'" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "    # Force replication to all DCs" -ForegroundColor Gray
    Write-Host "    repadmin /syncall /AdeP" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[6.4] Post-Restore Considerations..." -ForegroundColor Cyan
    Write-Host "  Important points:" -ForegroundColor White
    Write-Host "    - Allow time for replication to complete" -ForegroundColor Gray
    Write-Host "    - Monitor event logs for replication errors" -ForegroundColor Gray
    Write-Host "    - Verify restored objects on other DCs" -ForegroundColor Gray
    Write-Host "    - Check SYSVOL replication if restoring Group Policy" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[SUCCESS] Authoritative restore documented" -ForegroundColor Green
    Write-Host ""

    # ============================================
    # STEP 7: SYSVOL Coordination
    # ============================================
    Write-Host "[Step 7] SYSVOL Coordination After Restore" -ForegroundColor Yellow

    Write-Host "`n[7.1] Understanding SYSVOL Restore..." -ForegroundColor Cyan
    Write-Host "  SYSVOL contains:" -ForegroundColor White
    Write-Host "    - Group Policy Objects (GPOs)" -ForegroundColor Gray
    Write-Host "    - Login scripts" -ForegroundColor Gray
    Write-Host "    - Other domain-wide files" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  SYSVOL replicates via:" -ForegroundColor White
    Write-Host "    - DFSR (Windows Server 2008+)" -ForegroundColor Gray
    Write-Host "    - FRS (legacy, deprecated)" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[7.2] SYSVOL Authoritative Restore (DFSR)..." -ForegroundColor Cyan
    Write-Host "  If SYSVOL needs authoritative restore:" -ForegroundColor White
    Write-Host ""
    Write-Host "  Step 1: Stop DFSR service" -ForegroundColor Gray
    Write-Host "    Stop-Service DFSR" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Step 2: Mark as authoritative (D2 flag)" -ForegroundColor Gray
    Write-Host "    wmic /namespace:\\\\root\\microsoftdfs path dfsrMachineConfig set IsAuthoritative=true" -ForegroundColor Yellow
    Write-Host "    # OR using registry:" -ForegroundColor Gray
    Write-Host "    Set-ItemProperty 'HKLM:\System\CurrentControlSet\Services\DFSR\Parameters\Sysvols\*\*' -Name 'BurFlags' -Value 208" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Step 3: Start DFSR service" -ForegroundColor Gray
    Write-Host "    Start-Service DFSR" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Step 4: Verify SYSVOL share is available" -ForegroundColor Gray
    Write-Host "    Get-SmbShare | Where-Object {`$_.Name -eq 'SYSVOL'}" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[7.3] SYSVOL Non-Authoritative Restore (DFSR)..." -ForegroundColor Cyan
    Write-Host "  For non-authoritative SYSVOL restore:" -ForegroundColor White
    Write-Host ""
    Write-Host "  Step 1: Stop DFSR" -ForegroundColor Gray
    Write-Host "    Stop-Service DFSR" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Step 2: Mark as non-authoritative (D4 flag)" -ForegroundColor Gray
    Write-Host "    Set-ItemProperty 'HKLM:\System\CurrentControlSet\Services\DFSR\Parameters\Sysvols\*\*' -Name 'BurFlags' -Value 272" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Step 3: Start DFSR" -ForegroundColor Gray
    Write-Host "    Start-Service DFSR" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[7.4] Verifying SYSVOL Replication..." -ForegroundColor Cyan
    Write-Host "  Check SYSVOL share:" -ForegroundColor White
    Write-Host "    Get-SmbShare SYSVOL" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Check NETLOGON share:" -ForegroundColor White
    Write-Host "    Get-SmbShare NETLOGON" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Check DFSR status:" -ForegroundColor White
    Write-Host "    dfsrdiag /testdfsrhealth" -ForegroundColor Yellow
    Write-Host "    dfsrdiag /pollad" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[SUCCESS] SYSVOL coordination documented" -ForegroundColor Green
    Write-Host ""

    # ============================================
    # STEP 8: Recovery Verification
    # ============================================
    Write-Host "[Step 8] Post-Recovery Verification" -ForegroundColor Yellow

    Write-Host "`n[8.1] Service Status Checks..." -ForegroundColor Cyan
    Write-Host "  Verify critical AD services:" -ForegroundColor White
    $adServices = @('NTDS', 'DNS', 'DFSR', 'Netlogon', 'KDC', 'W32Time')

    foreach ($svc in $adServices) {
        $service = Get-Service -Name $svc -ErrorAction SilentlyContinue
        if ($service) {
            $color = if ($service.Status -eq 'Running') { 'Green' } else { 'Red' }
            Write-Host "    $($svc): $($service.Status)" -ForegroundColor $color
        } else {
            Write-Host "    $($svc): Not found" -ForegroundColor Gray
        }
    }
    Write-Host ""

    Write-Host "[8.2] Replication Health..." -ForegroundColor Cyan
    Write-Host "  Check replication status:" -ForegroundColor White
    Write-Host "    repadmin /showrepl" -ForegroundColor Yellow
    Write-Host "    repadmin /replsummary" -ForegroundColor Yellow
    Write-Host "    repadmin /syncall /AdeP" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[8.3] Event Log Verification..." -ForegroundColor Cyan
    Write-Host "  Check for errors:" -ForegroundColor White
    Write-Host "    Get-WinEvent -LogName 'Directory Service' -MaxEvents 50 | Where-Object {`$_.Level -le 3}" -ForegroundColor Yellow
    Write-Host "    Get-WinEvent -LogName 'DFS Replication' -MaxEvents 50 | Where-Object {`$_.Level -le 3}" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[8.4] Database Health..." -ForegroundColor Cyan
    Write-Host "  Run semantic database analysis:" -ForegroundColor White
    Write-Host "    dcdiag /test:checksecurityerror" -ForegroundColor Yellow
    Write-Host "    dcdiag /test:systemlog" -ForegroundColor Yellow
    Write-Host "    dcdiag /v" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[SUCCESS] Verification procedures documented" -ForegroundColor Green
    Write-Host ""

    # ============================================
    # STEP 9: Troubleshooting Common Issues
    # ============================================
    Write-Host "[Step 9] Troubleshooting Common DSRM Issues" -ForegroundColor Yellow

    Write-Host "`n[Issue 1] Cannot Log In to DSRM" -ForegroundColor Cyan
    Write-Host "  Symptom: DSRM password not working" -ForegroundColor White
    Write-Host "  Solution:" -ForegroundColor White
    Write-Host "    1. Boot normally and reset DSRM password with ntdsutil" -ForegroundColor Gray
    Write-Host "    2. Reboot to DSRM with new password" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[Issue 2] Database Won't Start After Restore" -ForegroundColor Cyan
    Write-Host "  Symptom: NTDS service fails to start" -ForegroundColor White
    Write-Host "  Diagnosis:" -ForegroundColor White
    Write-Host "    - Check Event Viewer -> Directory Service log" -ForegroundColor Gray
    Write-Host "    - Run: esentutl /mh C:\Windows\NTDS\ntds.dit" -ForegroundColor Yellow
    Write-Host "  Solutions:" -ForegroundColor White
    Write-Host "    - Database integrity check: esentutl /g ntds.dit" -ForegroundColor Gray
    Write-Host "    - Soft recovery: esentutl /r edb /l C:\Windows\NTDS" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[Issue 3] SYSVOL Not Sharing" -ForegroundColor Cyan
    Write-Host "  Symptom: SYSVOL or NETLOGON shares not available" -ForegroundColor White
    Write-Host "  Solutions:" -ForegroundColor White
    Write-Host "    - Check DFSR service: Get-Service DFSR" -ForegroundColor Gray
    Write-Host "    - Verify registry: Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters'" -ForegroundColor Gray
    Write-Host "    - Perform non-authoritative SYSVOL sync (D4)" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[Issue 4] Replication Not Working" -ForegroundColor Cyan
    Write-Host "  Symptom: Changes not replicating between DCs" -ForegroundColor White
    Write-Host "  Diagnosis:" -ForegroundColor White
    Write-Host "    repadmin /showrepl" -ForegroundColor Yellow
    Write-Host "    dcdiag /test:replications" -ForegroundColor Yellow
    Write-Host "  Solutions:" -ForegroundColor White
    Write-Host "    - Force replication: repadmin /syncall /AdeP" -ForegroundColor Gray
    Write-Host "    - Check DNS: nslookup <dcname>" -ForegroundColor Gray
    Write-Host "    - Verify time sync: w32tm /query /status" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[SUCCESS] Troubleshooting guide provided" -ForegroundColor Green
    Write-Host ""

    # ============================================
    # STEP 10: Best Practices
    # ============================================
    Write-Host "[Step 10] DSRM and Recovery Best Practices" -ForegroundColor Yellow

    Write-Host "`n[Best Practice 1] Regular Backups" -ForegroundColor Cyan
    Write-Host "  - Backup System State daily" -ForegroundColor White
    Write-Host "  - Test restore procedures quarterly" -ForegroundColor White
    Write-Host "  - Keep backups beyond tombstone lifetime (180 days)" -ForegroundColor White
    Write-Host "  - Store backups offsite/off-server" -ForegroundColor White
    Write-Host ""

    Write-Host "[Best Practice 2] DSRM Password Management" -ForegroundColor Cyan
    Write-Host "  - Change DSRM password quarterly" -ForegroundColor White
    Write-Host "  - Store in enterprise password vault" -ForegroundColor White
    Write-Host "  - Document reset procedures" -ForegroundColor White
    Write-Host "  - Test password during maintenance windows" -ForegroundColor White
    Write-Host ""

    Write-Host "[Best Practice 3] Documentation" -ForegroundColor Cyan
    Write-Host "  - Document recovery procedures (runbook)" -ForegroundColor White
    Write-Host "  - Keep contact list for emergency" -ForegroundColor White
    Write-Host "  - Document DC configuration and roles" -ForegroundColor White
    Write-Host "  - Maintain network diagrams" -ForegroundColor White
    Write-Host ""

    Write-Host "[Best Practice 4] Multiple Domain Controllers" -ForegroundColor Cyan
    Write-Host "  - Always have at least 2 DCs per domain" -ForegroundColor White
    Write-Host "  - Distribute DCs across sites/datacenters" -ForegroundColor White
    Write-Host "  - Use virtual DCs with snapshots (carefully!)" -ForegroundColor White
    Write-Host "  - Designate primary DC for backups" -ForegroundColor White
    Write-Host ""

    Write-Host "[Best Practice 5] Pre-Disaster Preparation" -ForegroundColor Cyan
    Write-Host "  - Practice recovery in lab environment" -ForegroundColor White
    Write-Host "  - Create detailed runbooks" -ForegroundColor White
    Write-Host "  - Train multiple administrators" -ForegroundColor White
    Write-Host "  - Have offline copies of critical tools" -ForegroundColor White
    Write-Host ""

    Write-Host "[WARNING] Common Mistakes to Avoid:" -ForegroundColor Red
    Write-Host "  - Never use VM snapshots on production DCs without proper procedures" -ForegroundColor White
    Write-Host "  - Don't forget to coordinate SYSVOL restore" -ForegroundColor White
    Write-Host "  - Avoid authoritative restore unless absolutely necessary" -ForegroundColor White
    Write-Host "  - Don't ignore replication errors after restore" -ForegroundColor White
    Write-Host ""

    Write-Host "[INFO] Additional Resources:" -ForegroundColor Cyan
    Write-Host "  - AD Backup and Recovery: https://docs.microsoft.com/windows-server/identity/ad-ds/manage/ad-forest-recovery-guide" -ForegroundColor White
    Write-Host "  - DSRM documentation: https://docs.microsoft.com/troubleshoot/windows-server/identity/reset-dsrm-administrator-password" -ForegroundColor White
    Write-Host ""

} catch {
    Write-Host "[ERROR] $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

Write-Host "DSRM recovery demonstration completed successfully!" -ForegroundColor Green
Write-Host "Next Steps: Document DSRM password, test backup/restore procedures, train team" -ForegroundColor Yellow
Write-Host "REMINDER: Always test recovery procedures in lab before production use!" -ForegroundColor Red
