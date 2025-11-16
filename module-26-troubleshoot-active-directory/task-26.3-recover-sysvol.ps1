<#
.SYNOPSIS
    Task 26.3 - Recover SYSVOL

.DESCRIPTION
    Demo script for AZ-801 Module 26: Troubleshoot Active Directory
    Demonstrates SYSVOL recovery and repair procedures.

    Covers:
    - DFSR SYSVOL health checks
    - Authoritative and non-authoritative SYSVOL restore
    - SYSVOL replication troubleshooting
    - D2 and D4 restore procedures

.NOTES
    Module: Module 26 - Troubleshoot Active Directory
    Task: 26.3 - Recover SYSVOL
    Prerequisites: Domain Controller, Administrative privileges
    PowerShell Version: 5.1+
#>

#Requires -RunAsAdministrator

$ErrorActionPreference = 'Stop'
Write-Host "=== AZ-801 Module 26: Task 26.3 - Recover SYSVOL ===" -ForegroundColor Cyan
Write-Host ""

try {
    Write-Host "[Step 1] SYSVOL Recovery - Overview" -ForegroundColor Yellow
    Write-Host "SYSVOL contains Group Policy Objects and login scripts" -ForegroundColor White
    Write-Host ""

    # ============================================
    # STEP 2: SYSVOL Health Assessment
    # ============================================
    Write-Host "[Step 2] Checking SYSVOL Health" -ForegroundColor Yellow

    Write-Host "`n[2.1] Verifying SYSVOL Share..." -ForegroundColor Cyan
    $sysvolShare = Get-SmbShare -Name "SYSVOL" -ErrorAction SilentlyContinue
    if ($sysvolShare) {
        Write-Host "  SYSVOL Share: Available" -ForegroundColor Green
        Write-Host "  Path: $($sysvolShare.Path)" -ForegroundColor Gray
    } else {
        Write-Host "  [WARNING] SYSVOL share not found!" -ForegroundColor Red
    }

    $netlogonShare = Get-SmbShare -Name "NETLOGON" -ErrorAction SilentlyContinue
    if ($netlogonShare) {
        Write-Host "  NETLOGON Share: Available" -ForegroundColor Green
        Write-Host "  Path: $($netlogonShare.Path)" -ForegroundColor Gray
    } else {
        Write-Host "  [WARNING] NETLOGON share not found!" -ForegroundColor Red
    }
    Write-Host ""

    Write-Host "[2.2] Check DFSR Service..." -ForegroundColor Cyan
    $dfsrService = Get-Service -Name DFSR -ErrorAction SilentlyContinue
    if ($dfsrService) {
        $color = if ($dfsrService.Status -eq 'Running') { 'Green' } else { 'Red' }
        Write-Host "  DFSR Service: $($dfsrService.Status)" -ForegroundColor $color
    } else {
        Write-Host "  [WARNING] DFSR service not found" -ForegroundColor Yellow
    }
    Write-Host ""

    Write-Host "[2.3] DFSR Health Check Commands..." -ForegroundColor Cyan
    Write-Host "  Check DFSR health:" -ForegroundColor White
    Write-Host "    dfsrdiag /testdfsrhealth" -ForegroundColor Yellow
    Write-Host "    dfsrdiag /pollad" -ForegroundColor Yellow
    Write-Host "    repadmin /showrepl" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[SUCCESS] SYSVOL health assessment completed" -ForegroundColor Green
    Write-Host ""

    # ============================================
    # STEP 3: Non-Authoritative SYSVOL Restore (D4)
    # ============================================
    Write-Host "[Step 3] Non-Authoritative SYSVOL Restore (D4)" -ForegroundColor Yellow

    Write-Host "`n[3.1] When to Use D4 (Non-Authoritative)..." -ForegroundColor Cyan
    Write-Host "  Use D4 when:" -ForegroundColor White
    Write-Host "    - One DC needs to resync SYSVOL from partners" -ForegroundColor Gray
    Write-Host "    - SYSVOL corruption on single DC" -ForegroundColor Gray
    Write-Host "    - Want to pull latest SYSVOL from other DCs" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[3.2] D4 Restore Procedure..." -ForegroundColor Cyan
    Write-Host "  Step 1: Stop DFSR service" -ForegroundColor White
    Write-Host "    Stop-Service DFSR" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Step 2: Set BurFlags to 272 (D4)" -ForegroundColor White
    Write-Host "    `$regPath = 'HKLM:\SYSTEM\CurrentControlSet\Services\DFSR\Parameters\SysVols\Migrating Journals'" -ForegroundColor Yellow
    Write-Host "    Get-ChildItem `$regPath | ForEach-Object {" -ForegroundColor Yellow
    Write-Host "        Set-ItemProperty -Path `$_.PSPath -Name 'BurFlags' -Value 272" -ForegroundColor Yellow
    Write-Host "    }" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Step 3: Start DFSR service" -ForegroundColor White
    Write-Host "    Start-Service DFSR" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Step 4: Monitor event logs (Event ID 4114)" -ForegroundColor White
    Write-Host "    Get-WinEvent -LogName 'DFS Replication' -MaxEvents 20 | Where-Object {`$_.Id -eq 4114}" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[SUCCESS] D4 procedure documented" -ForegroundColor Green
    Write-Host ""

    # ============================================
    # STEP 4: Authoritative SYSVOL Restore (D2)
    # ============================================
    Write-Host "[Step 4] Authoritative SYSVOL Restore (D2)" -ForegroundColor Yellow

    Write-Host "`n[4.1] When to Use D2 (Authoritative)..." -ForegroundColor Cyan
    Write-Host "  Use D2 when:" -ForegroundColor White
    Write-Host "    - Need to force this DC's SYSVOL to all other DCs" -ForegroundColor Gray
    Write-Host "    - Recovered from backup and SYSVOL is authoritative" -ForegroundColor Gray
    Write-Host "    - SYSVOL corruption across multiple DCs" -ForegroundColor Gray
    Write-Host "  WARNING: Use with caution - overwrites SYSVOL on all DCs!" -ForegroundColor Red
    Write-Host ""

    Write-Host "[4.2] D2 Restore Procedure..." -ForegroundColor Cyan
    Write-Host "  Step 1: Stop DFSR on PRIMARY DC" -ForegroundColor White
    Write-Host "    Stop-Service DFSR" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Step 2: Set BurFlags to 208 (D2) on PRIMARY DC" -ForegroundColor White
    Write-Host "    `$regPath = 'HKLM:\SYSTEM\CurrentControlSet\Services\DFSR\Parameters\SysVols\Migrating Journals'" -ForegroundColor Yellow
    Write-Host "    Get-ChildItem `$regPath | ForEach-Object {" -ForegroundColor Yellow
    Write-Host "        Set-ItemProperty -Path `$_.PSPath -Name 'BurFlags' -Value 208" -ForegroundColor Yellow
    Write-Host "    }" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Step 3: Start DFSR on PRIMARY DC" -ForegroundColor White
    Write-Host "    Start-Service DFSR" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Step 4: Set D4 on ALL other DCs (see Step 3)" -ForegroundColor White
    Write-Host ""
    Write-Host "  Step 5: Monitor replication" -ForegroundColor White
    Write-Host "    dfsrdiag /pollad" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[SUCCESS] D2 procedure documented" -ForegroundColor Green
    Write-Host ""

    # ============================================
    # STEP 5: Monitoring and Verification
    # ============================================
    Write-Host "[Step 5] SYSVOL Replication Monitoring" -ForegroundColor Yellow

    Write-Host "`n[5.1] DFSR Diagnostic Commands..." -ForegroundColor Cyan
    Write-Host "  Test DFSR health:" -ForegroundColor White
    Write-Host "    dfsrdiag /testdfsrhealth /member:DC01 /rgname:'Domain System Volume'" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Poll AD for replication info:" -ForegroundColor White
    Write-Host "    dfsrdiag /pollad" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Check backlog:" -ForegroundColor White
    Write-Host "    dfsrdiag /backlog /rgname:'Domain System Volume' /rfname:'SYSVOL Share' /sendingmember:DC01 /receivingmember:DC02" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[5.2] Event Log Monitoring..." -ForegroundColor Cyan
    Write-Host "  Key Event IDs:" -ForegroundColor White
    Write-Host "    4114 - SYSVOL replication initialized" -ForegroundColor Gray
    Write-Host "    4604 - SYSVOL ready for sharing" -ForegroundColor Gray
    Write-Host "    5012 - SYSVOL replication warning" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Check recent DFSR events:" -ForegroundColor White
    $dfsrEvents = Get-WinEvent -LogName 'DFS Replication' -MaxEvents 20 -ErrorAction SilentlyContinue
    if ($dfsrEvents) {
        Write-Host "  Found $($dfsrEvents.Count) recent DFSR events" -ForegroundColor Green
    }
    Write-Host ""

    Write-Host "[SUCCESS] Monitoring procedures documented" -ForegroundColor Green
    Write-Host ""

    # ============================================
    # STEP 6: Troubleshooting Common Issues
    # ============================================
    Write-Host "[Step 6] Common SYSVOL Issues" -ForegroundColor Yellow

    Write-Host "`n[Issue 1] SYSVOL Not Sharing" -ForegroundColor Cyan
    Write-Host "  Diagnosis:" -ForegroundColor White
    Write-Host "    Get-SmbShare | Where-Object {`$_.Name -match 'SYSVOL|NETLOGON'}" -ForegroundColor Yellow
    Write-Host "  Solution:" -ForegroundColor White
    Write-Host "    1. Check DFSR service" -ForegroundColor Gray
    Write-Host "    2. Perform D4 restore" -ForegroundColor Gray
    Write-Host "    3. Check Event ID 4604 for SYSVOL ready" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[Issue 2] SYSVOL Replication Stopped" -ForegroundColor Cyan
    Write-Host "  Diagnosis:" -ForegroundColor White
    Write-Host "    dfsrdiag /testdfsrhealth" -ForegroundColor Yellow
    Write-Host "    repadmin /showrepl" -ForegroundColor Yellow
    Write-Host "  Solution:" -ForegroundColor White
    Write-Host "    1. Check DFSR service status" -ForegroundColor Gray
    Write-Host "    2. Force AD replication" -ForegroundColor Gray
    Write-Host "    3. Restart DFSR service" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[Issue 3] Group Policy Not Updating" -ForegroundColor Cyan
    Write-Host "  Diagnosis:" -ForegroundColor White
    Write-Host "    gpupdate /force" -ForegroundColor Yellow
    Write-Host "    gpresult /r" -ForegroundColor Yellow
    Write-Host "  Solution:" -ForegroundColor White
    Write-Host "    1. Check SYSVOL share accessibility" -ForegroundColor Gray
    Write-Host "    2. Verify GPO files in SYSVOL" -ForegroundColor Gray
    Write-Host "    3. Check DFSR replication" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[SUCCESS] Troubleshooting guide provided" -ForegroundColor Green
    Write-Host ""

    Write-Host "[INFO] Best Practices:" -ForegroundColor Cyan
    Write-Host "  - Always use D4 before D2" -ForegroundColor White
    Write-Host "  - Only one DC should use D2 at a time" -ForegroundColor White
    Write-Host "  - Monitor Event ID 4604 for completion" -ForegroundColor White
    Write-Host "  - Document which DC is authoritative" -ForegroundColor White
    Write-Host ""

} catch {
    Write-Host "[ERROR] $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

Write-Host "SYSVOL recovery demonstration completed successfully!" -ForegroundColor Green
Write-Host "Next Steps: Monitor SYSVOL replication and document recovery procedures" -ForegroundColor Yellow
