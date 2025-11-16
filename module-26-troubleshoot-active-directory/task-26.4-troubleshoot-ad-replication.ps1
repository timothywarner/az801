<#
.SYNOPSIS
    Task 26.4 - Troubleshoot AD Replication

.DESCRIPTION
    Demo script for AZ-801 Module 26: Troubleshoot Active Directory
    Shows Active Directory replication troubleshooting using repadmin and dcdiag.

    Covers:
    - repadmin commands for replication monitoring
    - dcdiag tests for replication health
    - Force replication procedures
    - Common replication issues and fixes
    - Metadata cleanup

.NOTES
    Module: Module 26 - Troubleshoot Active Directory
    Task: 26.4 - Troubleshoot AD Replication
    Prerequisites: Domain Controller, Administrative privileges
    PowerShell Version: 5.1+
#>

#Requires -RunAsAdministrator
#Requires -Modules ActiveDirectory

$ErrorActionPreference = 'Stop'
Write-Host "=== AZ-801 Module 26: Task 26.4 - Troubleshoot AD Replication ===" -ForegroundColor Cyan
Write-Host ""

try {
    Write-Host "[Step 1] AD Replication Troubleshooting - Overview" -ForegroundColor Yellow
    Write-Host "Active Directory replication ensures consistency across domain controllers" -ForegroundColor White
    Write-Host ""

    # ============================================
    # STEP 2: repadmin Commands
    # ============================================
    Write-Host "[Step 2] Using repadmin for Replication Monitoring" -ForegroundColor Yellow

    Write-Host "`n[2.1] View Replication Status..." -ForegroundColor Cyan
    Write-Host "  Show replication partners and status:" -ForegroundColor White
    Write-Host "    repadmin /showrepl" -ForegroundColor Yellow
    Write-Host "    repadmin /showrepl DC01" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[2.2] Replication Summary..." -ForegroundColor Cyan
    Write-Host "  Get summary across all DCs:" -ForegroundColor White
    Write-Host "    repadmin /replsummary" -ForegroundColor Yellow
    Write-Host "    repadmin /replsummary /bysrc /bydest /sort:delta" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[2.3] Force Replication..." -ForegroundColor Cyan
    Write-Host "  Sync from specific DC:" -ForegroundColor White
    Write-Host "    repadmin /replicate DC02 DC01 DC=contoso,DC=com" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Sync all partitions from all partners:" -ForegroundColor White
    Write-Host "    repadmin /syncall /AdeP" -ForegroundColor Yellow
    Write-Host "    # /A = all partitions" -ForegroundColor Gray
    Write-Host "    # /d = identify servers by DN" -ForegroundColor Gray
    Write-Host "    # /e = enterprise (all DCs)" -ForegroundColor Gray
    Write-Host "    # /P = push changes outward" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[2.4] View Replication Metadata..." -ForegroundColor Cyan
    Write-Host "  Show object replication metadata:" -ForegroundColor White
    Write-Host "    repadmin /showobjmeta DC01 'CN=JohnDoe,OU=Users,DC=contoso,DC=com'" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[2.5] Queue and Backlog..." -ForegroundColor Cyan
    Write-Host "  Show replication queue:" -F:parameter>    Write-Host "    repadmin /queue" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Check replication backlog:" -ForegroundColor White
    Write-Host "    repadmin /showbackup" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[SUCCESS] repadmin commands documented" -ForegroundColor Green
    Write-Host ""

    # ============================================
    # STEP 3: dcdiag Commands
    # ============================================
    Write-Host "[Step 3] Using dcdiag for Replication Testing" -ForegroundColor Yellow

    Write-Host "`n[3.1] Test Replication Health..." -ForegroundColor Cyan
    Write-Host "  Run replication tests:" -ForegroundColor White
    Write-Host "    dcdiag /test:replications" -ForegroundColor Yellow
    Write-Host "    dcdiag /test:replications /v" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[3.2] Comprehensive DC Tests..." -ForegroundColor Cyan
    Write-Host "  Test all DCs in domain:" -ForegroundColor White
    Write-Host "    dcdiag /a" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Test all DCs in enterprise:" -ForegroundColor White
    Write-Host "    dcdiag /e" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Quiet mode (errors only):" -ForegroundColor White
    Write-Host "    dcdiag /q" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[3.3] Specific Replication Tests..." -ForegroundColor Cyan
    Write-Host "  Test intersite replication:" -ForegroundColor White
    Write-Host "    dcdiag /test:connectivity" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Test Knowledge Consistency Checker:" -ForegroundColor White
    Write-Host "    dcdiag /test:kccevent" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Test replication latency:" -ForegroundColor White
    Write-Host "    dcdiag /test:replications /v | Select-String 'replication latency'" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[SUCCESS] dcdiag commands documented" -ForegroundColor Green
    Write-Host ""

    # ============================================
    # STEP 4: PowerShell Replication Cmdlets
    # ============================================
    Write-Host "[Step 4] PowerShell AD Replication Cmdlets" -ForegroundColor Yellow

    Write-Host "`n[4.1] Get Replication Failures..." -ForegroundColor Cyan
    Write-Host "  View replication failures:" -ForegroundColor White
    Write-Host "    Get-ADReplicationFailure -Target DC01" -ForegroundColor Yellow
    Write-Host "    Get-ADReplicationFailure -Scope Domain" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[4.2] Get Replication Partner Metadata..." -ForegroundColor Cyan
    Write-Host "  View replication partner information:" -ForegroundColor White
    Write-Host "    Get-ADReplicationPartnerMetadata -Target DC01" -ForegroundColor Yellow
    Write-Host "    Get-ADReplicationPartnerMetadata -Target DC01 -Scope Domain" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[4.3] Sync AD Replication..." -ForegroundColor Cyan
    Write-Host "  Force sync with PowerShell:" -ForegroundColor White
    Write-Host "    Sync-ADObject -Object 'CN=JohnDoe,OU=Users,DC=contoso,DC=com' -Source DC01 -Destination DC02" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[4.4] Get Replication Site Link..." -ForegroundColor Cyan
    Write-Host "  View site links and costs:" -ForegroundColor White
    Write-Host "    Get-ADReplicationSiteLink -Filter *" -ForegroundColor Yellow
    Write-Host "    Get-ADReplicationSite -Filter * | Format-Table Name, Description" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[SUCCESS] PowerShell cmdlets documented" -ForegroundColor Green
    Write-Host ""

    # ============================================
    # STEP 5: Common Replication Event IDs
    # ============================================
    Write-Host "[Step 5] Key Replication Event IDs" -ForegroundColor Yellow

    Write-Host "`n[5.1] Critical Event IDs to Monitor..." -ForegroundColor Cyan
    Write-Host "  Event 1388: Replication lingering objects" -ForegroundColor White
    Write-Host "  Event 1925: Replication link failure" -ForegroundColor White
    Write-Host "  Event 2042: Too long since last replication" -ForegroundColor White
    Write-Host "  Event 5805: Authentication failure" -ForegroundColor White
    Write-Host "  Event 1311: KCC encountered problems" -ForegroundColor White
    Write-Host ""

    Write-Host "[5.2] Check for Replication Errors..." -ForegroundColor Cyan
    Write-Host "  Search Directory Service log:" -ForegroundColor White
    Write-Host "    Get-WinEvent -LogName 'Directory Service' -MaxEvents 100 | Where-Object {`$_.Id -in 1388,1925,2042,5805}" -ForegroundColor Yellow
    Write-Host ""

    # Check for actual replication errors
    $replErrors = Get-WinEvent -FilterHashtable @{
        LogName = 'Directory Service'
        ID = 1388,1925,2042,5805
    } -MaxEvents 10 -ErrorAction SilentlyContinue

    if ($replErrors) {
        Write-Host "  [WARNING] Found $($replErrors.Count) replication-related events" -ForegroundColor Yellow
        $replErrors | ForEach-Object {
            Write-Host "    Event $($_.Id) at $($_.TimeCreated)" -ForegroundColor Gray
        }
    } else {
        Write-Host "  [SUCCESS] No critical replication events found" -ForegroundColor Green
    }
    Write-Host ""

    Write-Host "[SUCCESS] Event monitoring documented" -ForegroundColor Green
    Write-Host ""

    # ============================================
    # STEP 6: Common Replication Issues
    # ============================================
    Write-Host "[Step 6] Common Replication Issues and Solutions" -ForegroundColor Yellow

    Write-Host "`n[Issue 1] DNS Resolution Problems" -ForegroundColor Cyan
    Write-Host "  Symptoms: Cannot contact replication partners" -ForegroundColor White
    Write-Host "  Diagnosis:" -ForegroundColor White
    Write-Host "    nslookup DC01" -ForegroundColor Yellow
    Write-Host "    dcdiag /test:dns" -ForegroundColor Yellow
    Write-Host "  Solution:" -ForegroundColor White
    Write-Host "    1. Verify DNS settings on all DCs" -ForegroundColor Gray
    Write-Host "    2. Register DC records: ipconfig /registerdns" -ForegroundColor Gray
    Write-Host "    3. Check DNS zones for missing records" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[Issue 2] Time Synchronization Problems" -ForegroundColor Cyan
    Write-Host "  Symptoms: Event 5805, Kerberos failures" -ForegroundColor White
    Write-Host "  Diagnosis:" -ForegroundColor White
    Write-Host "    w32tm /query /status" -ForegroundColor Yellow
    Write-Host "    w32tm /stripchart /computer:DC01" -ForegroundColor Yellow
    Write-Host "  Solution:" -ForegroundColor White
    Write-Host "    1. Configure PDC as authoritative time source" -ForegroundColor Gray
    Write-Host "    2. Force time sync: w32tm /resync /rediscover" -ForegroundColor Gray
    Write-Host "    3. Verify time configuration: w32tm /query /configuration" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[Issue 3] Lingering Objects" -ForegroundColor Cyan
    Write-Host "  Symptoms: Event 1388" -ForegroundColor White
    Write-Host "  Diagnosis:" -ForegroundColor White
    Write-Host "    repadmin /removelingeringobjects DC01 <GUID> DC=contoso,DC=com /advisory_mode" -ForegroundColor Yellow
    Write-Host "  Solution:" -ForegroundColor White
    Write-Host "    repadmin /removelingeringobjects DC01 <GUID> DC=contoso,DC=com" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[Issue 4] Replication Connection Failure" -ForegroundColor Cyan
    Write-Host "  Symptoms: Event 1925, repadmin shows 'Last attempt failed'" -ForegroundColor White
    Write-Host "  Diagnosis:" -ForegroundColor White
    Write-Host "    repadmin /showrepl" -ForegroundColor Yellow
    Write-Host "    Test-NetConnection DC01 -Port 389" -ForegroundColor Yellow
    Write-Host "  Solution:" -ForegroundColor White
    Write-Host "    1. Check firewall rules (allow 389, 636, 3268, 3269)" -ForegroundColor Gray
    Write-Host "    2. Verify network connectivity" -ForegroundColor Gray
    Write-Host "    3. Force KCC to rebuild topology: repadmin /kcc" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[Issue 5] USN Rollback" -ForegroundColor Cyan
    Write-Host "  Symptoms: Event 2095, replication stops" -ForegroundColor White
    Write-Host "  Cause: VM snapshot restore" -ForegroundColor White
    Write-Host "  Solution:" -ForegroundColor White
    Write-Host "    1. Demote affected DC" -ForegroundColor Gray
    Write-Host "    2. Clean metadata: ntdsutil metadata cleanup" -ForegroundColor Gray
    Write-Host "    3. Repromote DC" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[SUCCESS] Common issues and solutions documented" -ForegroundColor Green
    Write-Host ""

    # ============================================
    # STEP 7: Metadata Cleanup
    # ============================================
    Write-Host "[Step 7] Metadata Cleanup for Dead DCs" -ForegroundColor Yellow

    Write-Host "`n[7.1] When to Perform Metadata Cleanup..." -ForegroundColor Cyan
    Write-Host "  Perform cleanup when:" -ForegroundColor White
    Write-Host "    - DC forcefully removed without proper demotion" -ForegroundColor Gray
    Write-Host "    - DC is permanently offline" -ForegroundColor Gray
    Write-Host "    - DC cannot be recovered" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[7.2] Metadata Cleanup using ntdsutil..." -ForegroundColor Cyan
    Write-Host "  Interactive ntdsutil method:" -ForegroundColor White
    Write-Host "    ntdsutil" -ForegroundColor Yellow
    Write-Host "    metadata cleanup" -ForegroundColor Yellow
    Write-Host "    connections" -ForegroundColor Yellow
    Write-Host "    connect to server <good DC>" -ForegroundColor Yellow
    Write-Host "    quit" -ForegroundColor Yellow
    Write-Host "    select operation target" -ForegroundColor Yellow
    Write-Host "    list sites" -ForegroundColor Yellow
    Write-Host "    select site <number>" -ForegroundColor Yellow
    Write-Host "    list servers in site" -ForegroundColor Yellow
    Write-Host "    select server <number>" -ForegroundColor Yellow
    Write-Host "    quit" -ForegroundColor Yellow
    Write-Host "    remove selected server" -ForegroundColor Yellow
    Write-Host "    quit" -ForegroundColor Yellow
    Write-Host "    quit" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[7.3] Metadata Cleanup using PowerShell..." -ForegroundColor Cyan
    Write-Host "  Remove server object:" -ForegroundColor White
    Write-Host "    # Get the dead DC object" -ForegroundColor Gray
    Write-Host "    `$deadDC = Get-ADObject -Filter {Name -eq 'DeadDC'} -SearchBase (Get-ADRootDSE).ConfigurationNamingContext" -ForegroundColor Yellow
    Write-Host "    # Remove it" -ForegroundColor Gray
    Write-Host "    Remove-ADObject -Identity `$deadDC -Recursive -Confirm:`$false" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[7.4] Post-Cleanup Steps..." -ForegroundColor Cyan
    Write-Host "  After metadata cleanup:" -ForegroundColor White
    Write-Host "    1. Force KCC to recalculate topology: repadmin /kcc" -ForegroundColor Gray
    Write-Host "    2. Force replication: repadmin /syncall /AdeP" -ForegroundColor Gray
    Write-Host "    3. Clean DNS records for dead DC" -ForegroundColor Gray
    Write-Host "    4. Transfer/seize FSMO roles if needed" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[SUCCESS] Metadata cleanup procedures documented" -ForegroundColor Green
    Write-Host ""

    # ============================================
    # STEP 8: Best Practices
    # ============================================
    Write-Host "[Step 8] AD Replication Best Practices" -ForegroundColor Yellow

    Write-Host "`n[Best Practice 1] Regular Monitoring" -ForegroundColor Cyan
    Write-Host "  - Run repadmin /replsummary daily" -ForegroundColor White
    Write-Host "  - Monitor Event IDs 1388, 1925, 2042, 5805" -ForegroundColor White
    Write-Host "  - Set up automated alerts for replication failures" -ForegroundColor White
    Write-Host "  - Document replication topology" -ForegroundColor White
    Write-Host ""

    Write-Host "[Best Practice 2] Proactive Maintenance" -ForegroundColor Cyan
    Write-Host "  - Keep all DCs at same patch level" -ForegroundColor White
    Write-Host "  - Ensure proper time synchronization" -ForegroundColor White
    Write-Host "  - Maintain working DNS infrastructure" -ForegroundColor White
    Write-Host "  - Regular backup of System State" -ForegroundColor White
    Write-Host ""

    Write-Host "[Best Practice 3] Site Topology Design" -ForegroundColor Cyan
    Write-Host "  - Design sites to match network topology" -ForegroundColor White
    Write-Host "  - Configure appropriate site link costs" -ForegroundColor White
    Write-Host "  - Set replication schedules for WAN links" -ForegroundColor White
    Write-Host "  - Use bridge all site links carefully" -ForegroundColor White
    Write-Host ""

    Write-Host "[Best Practice 4] VM Considerations" -ForegroundColor Cyan
    Write-Host "  - Use Windows Server 2012+ for VM-GenerationID support" -ForegroundColor White
    Write-Host "  - Never restore DC from VM snapshot" -ForegroundColor White
    Write-Host "  - Disable VM snapshotting on production DCs" -ForegroundColor White
    Write-Host "  - Use proper backup/restore procedures" -ForegroundColor White
    Write-Host ""

    Write-Host "[Monitoring Script Example]" -ForegroundColor Cyan
    Write-Host "  Daily health check script:" -ForegroundColor White
    Write-Host "    `$errors = @()" -ForegroundColor Yellow
    Write-Host "    Get-ADReplicationFailure -Scope Forest | ForEach-Object {" -ForegroundColor Yellow
    Write-Host "        `$errors += `$_" -ForegroundColor Yellow
    Write-Host "    }" -ForegroundColor Yellow
    Write-Host "    if (`$errors.Count -gt 0) {" -ForegroundColor Yellow
    Write-Host "        Send-MailMessage -To 'admin@contoso.com' -Subject 'AD Replication Errors' -Body (`$errors | Out-String)" -ForegroundColor Yellow
    Write-Host "    }" -ForegroundColor Yellow
    Write-Host ""

} catch {
    Write-Host "[ERROR] $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

Write-Host "AD replication troubleshooting demonstration completed successfully!" -ForegroundColor Green
Write-Host "Next Steps: Implement monitoring, document topology, train team on repadmin/dcdiag" -ForegroundColor Yellow
