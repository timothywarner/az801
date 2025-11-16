<#
.SYNOPSIS
    Task 26.6 - Troubleshoot On-Premises AD

.DESCRIPTION
    Demo script for AZ-801 Module 26: Troubleshoot Active Directory
    Shows common on-premises AD troubleshooting procedures using dcdiag, netdom, nltest.

    Covers:
    - dcdiag comprehensive diagnostics
    - netdom FSMO and trust management
    - nltest domain and DC queries
    - Database integrity checks
    - Common AD issues and resolutions

.NOTES
    Module: Module 26 - Troubleshoot Active Directory
    Task: 26.6 - Troubleshoot On-Premises AD
    Prerequisites: Domain Controller or domain-joined server, Administrative privileges
    PowerShell Version: 5.1+
#>

#Requires -RunAsAdministrator

$ErrorActionPreference = 'Stop'
Write-Host "=== AZ-801 Module 26: Task 26.6 - Troubleshoot On-Premises AD ===" -ForegroundColor Cyan
Write-Host ""

try {
    Write-Host "[Step 1] On-Premises AD Troubleshooting - Overview" -ForegroundColor Yellow
    Write-Host "Comprehensive Active Directory diagnostics and troubleshooting" -ForegroundColor White
    Write-Host ""

    # ============================================
    # STEP 2: dcdiag - Domain Controller Diagnostics
    # ============================================
    Write-Host "[Step 2] dcdiag - Comprehensive DC Diagnostics" -ForegroundColor Yellow

    Write-Host "`n[2.1] Basic dcdiag Tests..." -ForegroundColor Cyan
    Write-Host "  Run all tests on local DC:" -ForegroundColor White
    Write-Host "    dcdiag" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Run all tests on specific DC:" -ForegroundColor White
    Write-Host "    dcdiag /s:DC01" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Test all DCs in domain:" -ForegroundColor White
    Write-Host "    dcdiag /a" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Test all DCs in enterprise:" -ForegroundColor White
    Write-Host "    dcdiag /e" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[2.2] Specific dcdiag Tests..." -ForegroundColor Cyan
    Write-Host "  Connectivity test:" -ForegroundColor White
    Write-Host "    dcdiag /test:connectivity" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  DNS test:" -ForegroundColor White
    Write-Host "    dcdiag /test:dns /v" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Replication test:" -ForegroundColor White
    Write-Host "    dcdiag /test:replications /v" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  FSMO role test:" -ForegroundColor White
    Write-Host "    dcdiag /test:fsmocheck" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  System log test:" -ForegroundColor White
    Write-Host "    dcdiag /test:systemlog" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Services test:" -ForegroundColor White
    Write-Host "    dcdiag /test:services" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[2.3] Advanced dcdiag Options..." -ForegroundColor Cyan
    Write-Host "  Verbose output:" -ForegroundColor White
    Write-Host "    dcdiag /v" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Comprehensive test (verbose + fix):" -ForegroundColor White
    Write-Host "    dcdiag /v /c /d /e /f:dcdiag-report.txt" -ForegroundColor Yellow
    Write-Host "    # /c = comprehensive" -ForegroundColor Gray
    Write-Host "    # /d = detailed" -ForegroundColor Gray
    Write-Host "    # /e = enterprise" -ForegroundColor Gray
    Write-Host "    # /f = output to file" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Quiet mode (errors only):" -ForegroundColor White
    Write-Host "    dcdiag /q" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[SUCCESS] dcdiag commands documented" -ForegroundColor Green
    Write-Host ""

    # ============================================
    # STEP 3: netdom - Domain Management
    # ============================================
    Write-Host "[Step 3] netdom - Domain and Trust Management" -ForegroundColor Yellow

    Write-Host "`n[3.1] FSMO Role Management..." -ForegroundColor Cyan
    Write-Host "  Query FSMO roles:" -ForegroundColor White
    Write-Host "    netdom query fsmo" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Transfer FSMO roles:" -ForegroundColor White
    Write-Host "    # Use Active Directory Users and Computers or PowerShell" -ForegroundColor Gray
    Write-Host "    Move-ADDirectoryServerOperationMasterRole -Identity DC02 -OperationMasterRole SchemaMaster, DomainNamingMaster, PDCEmulator, RIDMaster, InfrastructureMaster" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[3.2] Trust Management..." -ForegroundColor Cyan
    Write-Host "  List all trusts:" -ForegroundColor White
    Write-Host "    netdom query trust" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Verify trust:" -ForegroundColor White
    Write-Host "    netdom trust contoso.com /domain:fabrikam.com /verify" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Reset secure channel:" -ForegroundColor White
    Write-Host "    netdom resetpwd /server:DC01 /userd:administrator /passwordd:*" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[3.3] Computer Account Management..." -ForegroundColor Cyan
    Write-Host "  Reset computer account:" -ForegroundColor White
    Write-Host "    netdom reset COMPUTER01 /domain:contoso.com /usero:admin /passwordo:*" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Join computer to domain:" -ForegroundColor White
    Write-Host "    netdom join COMPUTER01 /domain:contoso.com /userd:admin /passwordd:*" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[3.4] Query Domain Information..." -ForegroundColor Cyan
    Write-Host "  Query domain controllers:" -ForegroundColor White
    Write-Host "    netdom query dc" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Query workstations:" -ForegroundColor White
    Write-Host "    netdom query workstation" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Query servers:" -ForegroundColor White
    Write-Host "    netdom query server" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[SUCCESS] netdom commands documented" -ForegroundColor Green
    Write-Host ""

    # ============================================
    # STEP 4: nltest - Netlogon and Domain Tests
    # ============================================
    Write-Host "[Step 4] nltest - Netlogon Service Diagnostics" -ForegroundColor Yellow

    Write-Host "`n[4.1] Domain Controller Discovery..." -ForegroundColor Cyan
    Write-Host "  Find DC for domain:" -ForegroundColor White
    Write-Host "    nltest /dsgetdc:contoso.com" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Find PDC:" -ForegroundColor White
    Write-Host "    nltest /dsgetdc:contoso.com /pdc" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Find DC with specific role:" -ForegroundColor White
    Write-Host "    nltest /dsgetdc:contoso.com /gc   # Global Catalog" -ForegroundColor Yellow
    Write-Host "    nltest /dsgetdc:contoso.com /kdc  # Kerberos KDC" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[4.2] Secure Channel Testing..." -ForegroundColor Cyan
    Write-Host "  Test secure channel:" -ForegroundColor White
    Write-Host "    nltest /sc_query:contoso.com" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Reset secure channel:" -ForegroundColor White
    Write-Host "    nltest /sc_reset:contoso.com" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[4.3] Trust Relationships..." -ForegroundColor Cyan
    Write-Host "  List trusted domains:" -ForegroundColor White
    Write-Host "    nltest /domain_trusts" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  List trusted domains with details:" -ForegroundColor White
    Write-Host "    nltest /domain_trusts /all_trusts /v" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[4.4] Domain Controller List..." -ForegroundColor Cyan
    Write-Host "  List DCs in domain:" -ForegroundColor White
    Write-Host "    nltest /dclist:contoso.com" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Query DC name:" -ForegroundColor White
    Write-Host "    nltest /server:DC01 /dcname" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[SUCCESS] nltest commands documented" -ForegroundColor Green
    Write-Host ""

    # ============================================
    # STEP 5: Database Integrity
    # ============================================
    Write-Host "[Step 5] Active Directory Database Integrity" -ForegroundColor Yellow

    Write-Host "`n[5.1] Database Health Checks..." -ForegroundColor Cyan
    Write-Host "  Check database header (in DSRM):" -ForegroundColor White
    Write-Host "    esentutl /mh C:\Windows\NTDS\ntds.dit" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Check log files:" -ForegroundColor White
    Write-Host "    esentutl /ml C:\Windows\NTDS\edb.log" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[5.2] Semantic Database Analysis..." -ForegroundColor Cyan
    Write-Host "  Run semantic database analysis:" -ForegroundColor White
    Write-Host "    dcdiag /test:checksecurityerror" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[5.3] Database Maintenance..." -ForegroundColor Cyan
    Write-Host "  Online defrag (automatic):" -ForegroundColor White
    Write-Host "    - Runs automatically during garbage collection" -ForegroundColor Gray
    Write-Host "    - Default: Every 12 hours" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Offline defrag (manual, in DSRM):" -ForegroundColor White
    Write-Host "    ntdsutil -> activate instance ntds -> files -> compact to C:\Temp" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[SUCCESS] Database integrity procedures documented" -ForegroundColor Green
    Write-Host ""

    # ============================================
    # STEP 6: Common AD Issues
    # ============================================
    Write-Host "[Step 6] Common Active Directory Issues" -ForegroundColor Yellow

    Write-Host "`n[Issue 1] DNS Resolution Problems" -ForegroundColor Cyan
    Write-Host "  Symptoms: Cannot locate DCs, logon failures" -ForegroundColor White
    Write-Host "  Diagnosis:" -ForegroundColor White
    Write-Host "    dcdiag /test:dns /v" -ForegroundColor Yellow
    Write-Host "    nslookup -type=SRV _ldap._tcp.dc._msdcs.contoso.com" -ForegroundColor Yellow
    Write-Host "  Solution:" -ForegroundColor White
    Write-Host "    1. Verify DNS server settings on DCs and clients" -ForegroundColor Gray
    Write-Host "    2. Register DNS records: ipconfig /registerdns" -ForegroundColor Gray
    Write-Host "    3. Restart Netlogon service: Restart-Service Netlogon" -ForegroundColor Gray
    Write-Host "    4. Check DNS zones for _msdcs records" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[Issue 2] Time Synchronization Issues" -ForegroundColor Cyan
    Write-Host "  Symptoms: Kerberos authentication failures, event 5805" -ForegroundColor White
    Write-Host "  Diagnosis:" -ForegroundColor White
    Write-Host "    w32tm /query /status" -ForegroundColor Yellow
    Write-Host "    w32tm /query /configuration" -ForegroundColor Yellow
    Write-Host "  Solution:" -ForegroundColor White
    Write-Host "    # On PDC Emulator" -ForegroundColor Gray
    Write-Host "    w32tm /config /manualpeerlist:'time.windows.com' /syncfromflags:manual /reliable:yes /update" -ForegroundColor Yellow
    Write-Host "    Restart-Service w32time" -ForegroundColor Yellow
    Write-Host "    w32tm /resync /rediscover" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[Issue 3] Secure Channel Broken" -ForegroundColor Cyan
    Write-Host "  Symptoms: Workstation logon failures, trust relationship errors" -ForegroundColor White
    Write-Host "  Diagnosis:" -ForegroundColor White
    Write-Host "    nltest /sc_query:contoso.com" -ForegroundColor Yellow
    Write-Host "  Solution:" -ForegroundColor White
    Write-Host "    nltest /sc_reset:contoso.com" -ForegroundColor Yellow
    Write-Host "    # Or reset computer account password" -ForegroundColor Gray
    Write-Host "    netdom resetpwd /server:DC01 /userd:admin /passwordd:*" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[Issue 4] FSMO Role Holder Unavailable" -ForegroundColor Cyan
    Write-Host "  Symptoms: Cannot perform schema changes, add DCs, etc." -ForegroundColor White
    Write-Host "  Diagnosis:" -ForegroundColor White
    Write-Host "    netdom query fsmo" -ForegroundColor Yellow
    Write-Host "    dcdiag /test:fsmocheck" -ForegroundColor Yellow
    Write-Host "  Solution:" -ForegroundColor White
    Write-Host "    # Transfer roles if old DC available" -ForegroundColor Gray
    Write-Host "    Move-ADDirectoryServerOperationMasterRole -Identity DC02 -OperationMasterRole PDCEmulator" -ForegroundColor Yellow
    Write-Host "    # Seize roles if old DC permanently offline" -ForegroundColor Gray
    Write-Host "    Move-ADDirectoryServerOperationMasterRole -Identity DC02 -OperationMasterRole PDCEmulator -Force" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[Issue 5] Kerberos Authentication Failures" -ForegroundColor Cyan
    Write-Host "  Symptoms: Cannot authenticate, event 4 in System log" -ForegroundColor White
    Write-Host "  Diagnosis:" -ForegroundColor White
    Write-Host "    # Check Kerberos tickets" -ForegroundColor Gray
    Write-Host "    klist" -ForegroundColor Yellow
    Write-Host "    klist purge    # Clear cache" -ForegroundColor Yellow
    Write-Host "  Solution:" -ForegroundColor White
    Write-Host "    1. Verify time sync (max 5min difference)" -ForegroundColor Gray
    Write-Host "    2. Check DNS resolution" -ForegroundColor Gray
    Write-Host "    3. Verify SPNs: setspn -L <computername>" -ForegroundColor Gray
    Write-Host "    4. Check domain functional level" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[Issue 6] Group Policy Not Applying" -ForegroundColor Cyan
    Write-Host "  Symptoms: Policies not updating on clients" -ForegroundColor White
    Write-Host "  Diagnosis:" -ForegroundColor White
    Write-Host "    gpupdate /force" -ForegroundColor Yellow
    Write-Host "    gpresult /r" -ForegroundColor Yellow
    Write-Host "    gpresult /h gpreport.html" -ForegroundColor Yellow
    Write-Host "  Solution:" -ForegroundColor White
    Write-Host "    1. Check SYSVOL replication: dcdiag /test:netlogons" -ForegroundColor Gray
    Write-Host "    2. Verify client can access SYSVOL share" -ForegroundColor Gray
    Write-Host "    3. Check GPO permissions" -ForegroundColor Gray
    Write-Host "    4. Review filtering (security, WMI)" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[SUCCESS] Common issues and solutions documented" -ForegroundColor Green
    Write-Host ""

    # ============================================
    # STEP 7: PowerShell AD Cmdlets
    # ============================================
    Write-Host "[Step 7] PowerShell Active Directory Cmdlets" -ForegroundColor Yellow

    Write-Host "`n[7.1] Domain and Forest Information..." -ForegroundColor Cyan
    Write-Host "  Get domain info:" -ForegroundColor White
    Write-Host "    Get-ADDomain" -ForegroundColor Yellow
    Write-Host "    Get-ADDomain | Select-Object Name, DomainMode, PDCEmulator, RIDMaster" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Get forest info:" -ForegroundColor White
    Write-Host "    Get-ADForest" -ForegroundColor Yellow
    Write-Host "    Get-ADForest | Select-Object Name, ForestMode, SchemaMaster" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[7.2] Domain Controller Information..." -ForegroundColor Cyan
    Write-Host "  List all DCs:" -ForegroundColor White
    Write-Host "    Get-ADDomainController -Filter *" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Get specific DC info:" -ForegroundColor White
    Write-Host "    Get-ADDomainController -Identity DC01" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Check if server is Global Catalog:" -ForegroundColor White
    Write-Host "    (Get-ADDomainController).IsGlobalCatalog" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[7.3] User and Computer Queries..." -ForegroundColor Cyan
    Write-Host "  Find locked out users:" -ForegroundColor White
    Write-Host "    Search-ADAccount -LockedOut" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Find disabled accounts:" -ForegroundColor White
    Write-Host "    Search-ADAccount -AccountDisabled" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Find expired accounts:" -ForegroundColor White
    Write-Host "    Search-ADAccount -AccountExpired" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[7.4] Password and Account Management..." -ForegroundColor Cyan
    Write-Host "  Unlock user account:" -ForegroundColor White
    Write-Host "    Unlock-ADAccount -Identity jdoe" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Reset password:" -ForegroundColor White
    Write-Host "    Set-ADAccountPassword -Identity jdoe -Reset" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Force password change at next logon:" -ForegroundColor White
    Write-Host "    Set-ADUser -Identity jdoe -ChangePasswordAtLogon `$true" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[SUCCESS] PowerShell cmdlets documented" -ForegroundColor Green
    Write-Host ""

    # ============================================
    # STEP 8: Best Practices
    # ============================================
    Write-Host "[Step 8] AD Troubleshooting Best Practices" -ForegroundColor Yellow

    Write-Host "`n[Best Practice 1] Regular Health Checks" -ForegroundColor Cyan
    Write-Host "  Daily tasks:" -ForegroundColor White
    Write-Host "    - Review event logs (System, Directory Service, DNS)" -ForegroundColor Gray
    Write-Host "    - Check replication status: repadmin /replsummary" -ForegroundColor Gray
    Write-Host "    - Verify DC services are running" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[Best Practice 2] Automated Monitoring" -ForegroundColor Cyan
    Write-Host "  Set up automated checks for:" -ForegroundColor White
    Write-Host "    - Replication failures" -ForegroundColor Gray
    Write-Host "    - FSMO availability" -ForegroundColor Gray
    Write-Host "    - DNS health" -ForegroundColor Gray
    Write-Host "    - Disk space on DCs" -ForegroundColor Gray
    Write-Host "    - Time synchronization" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[Best Practice 3] Documentation" -ForegroundColor Cyan
    Write-Host "  Maintain documentation for:" -ForegroundColor White
    Write-Host "    - AD topology diagram" -ForegroundColor Gray
    Write-Host "    - FSMO role holders" -ForegroundColor Gray
    Write-Host "    - DNS configuration" -ForegroundColor Gray
    Write-Host "    - Site and subnet mappings" -ForegroundColor Gray
    Write-Host "    - Service accounts and their purposes" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[Best Practice 4] Proactive Maintenance" -ForegroundColor Cyan
    Write-Host "  Regular tasks:" -ForegroundColor White
    Write-Host "    - Apply security patches monthly" -ForegroundColor Gray
    Write-Host "    - Clean up tombstoned objects" -ForegroundColor Gray
    Write-Host "    - Review and clean up disabled accounts" -ForegroundColor Gray
    Write-Host "    - Test backups and restore procedures" -ForegroundColor Gray
    Write-Host "    - Update DNS scavenging settings" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[Monitoring Script Example]" -ForegroundColor Cyan
    Write-Host "  Daily health check:" -ForegroundColor White
    Write-Host "    `$report = @()" -ForegroundColor Yellow
    Write-Host "    # Check replication" -ForegroundColor Gray
    Write-Host "    `$report += repadmin /replsummary" -ForegroundColor Yellow
    Write-Host "    # Check FSMO" -ForegroundColor Gray
    Write-Host "    `$report += netdom query fsmo" -ForegroundColor Yellow
    Write-Host "    # Check DC services" -ForegroundColor Gray
    Write-Host "    `$report += dcdiag /q" -ForegroundColor Yellow
    Write-Host "    # Email report" -ForegroundColor Gray
    Write-Host "    Send-MailMessage -To 'admin@contoso.com' -Subject 'AD Health Report' -Body (`$report | Out-String)" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[INFO] Additional Resources:" -ForegroundColor Cyan
    Write-Host "  - AD Troubleshooting: https://docs.microsoft.com/troubleshoot/windows-server/identity/active-directory-overview" -ForegroundColor White
    Write-Host "  - dcdiag reference: https://docs.microsoft.com/windows-server/administration/windows-commands/dcdiag" -ForegroundColor White
    Write-Host ""

} catch {
    Write-Host "[ERROR] $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

Write-Host "On-premises AD troubleshooting demonstration completed successfully!" -ForegroundColor Green
Write-Host "Next Steps: Implement regular monitoring, document environment, train administrators" -ForegroundColor Yellow
