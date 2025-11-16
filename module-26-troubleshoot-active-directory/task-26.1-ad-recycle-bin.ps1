<#
.SYNOPSIS
    Task 26.1 - Use AD Recycle Bin

.DESCRIPTION
    Demo script for AZ-801 Module 26: Troubleshoot Active Directory
    Demonstrates Active Directory Recycle Bin for object recovery.

    Covers:
    - Enabling AD Recycle Bin feature
    - Searching for deleted AD objects
    - Restoring deleted users, groups, and OUs
    - Viewing tombstone lifetime
    - Best practices for object recovery

.NOTES
    Module: Module 26 - Troubleshoot Active Directory
    Task: 26.1 - Use AD Recycle Bin
    Prerequisites: Domain Controller, AD PowerShell module, Enterprise Admin rights
    PowerShell Version: 5.1+
#>

#Requires -RunAsAdministrator
#Requires -Modules ActiveDirectory

$ErrorActionPreference = 'Stop'
Write-Host "=== AZ-801 Module 26: Task 26.1 - Use AD Recycle Bin ===" -ForegroundColor Cyan
Write-Host ""

try {
    Write-Host "[Step 1] AD Recycle Bin - Overview" -ForegroundColor Yellow
    Write-Host "Active Directory Recycle Bin enables recovery of deleted objects" -ForegroundColor White
    Write-Host ""

    # ============================================
    # STEP 2: Check Current Environment
    # ============================================
    Write-Host "[Step 2] Checking Active Directory Environment" -ForegroundColor Yellow

    # Get domain information
    Write-Host "`n[2.1] Getting Domain Information..." -ForegroundColor Cyan
    try {
        $domain = Get-ADDomain
        Write-Host "  Domain Name: $($domain.DNSRoot)" -ForegroundColor White
        Write-Host "  NetBIOS Name: $($domain.NetBIOSName)" -ForegroundColor Gray
        Write-Host "  Domain Functional Level: $($domain.DomainMode)" -ForegroundColor Gray
        Write-Host "  Forest Functional Level: $((Get-ADForest).ForestMode)" -ForegroundColor Gray
        Write-Host ""

        # Check if forest level supports Recycle Bin
        $forest = Get-ADForest
        $forestMode = $forest.ForestMode

        if ($forestMode -match "Windows2008R2Forest" -or
            $forestMode -match "Windows2012" -or
            $forestMode -match "Windows2016" -or
            $forestMode -match "WinThreshold") {
            Write-Host "  [SUCCESS] Forest functional level supports AD Recycle Bin" -ForegroundColor Green
        } else {
            Write-Host "  [WARNING] Forest must be at Windows Server 2008 R2 or higher for Recycle Bin" -ForegroundColor Yellow
            Write-Host "  Current level: $forestMode" -ForegroundColor Gray
        }
    } catch {
        Write-Host "  [WARNING] Not running on a domain controller or AD module not available" -ForegroundColor Yellow
        Write-Host "  [INFO] This script demonstrates AD Recycle Bin usage in educational mode" -ForegroundColor Cyan
    }

    Write-Host "[SUCCESS] Environment check completed" -ForegroundColor Green
    Write-Host ""

    # ============================================
    # STEP 3: Check Recycle Bin Status
    # ============================================
    Write-Host "[Step 3] Checking AD Recycle Bin Status" -ForegroundColor Yellow

    Write-Host "`n[3.1] Checking if Recycle Bin is Enabled..." -ForegroundColor Cyan

    try {
        $recycleBinFeature = Get-ADOptionalFeature -Filter 'Name -like "Recycle Bin Feature"'

        if ($recycleBinFeature) {
            Write-Host "  Feature Name: $($recycleBinFeature.Name)" -ForegroundColor White
            Write-Host "  Feature GUID: $($recycleBinFeature.FeatureGUID)" -ForegroundColor Gray
            Write-Host "  Required Forest Mode: $($recycleBinFeature.RequiredForestMode)" -ForegroundColor Gray

            # Check if enabled
            $scope = $recycleBinFeature.EnabledScopes
            if ($scope.Count -gt 0) {
                Write-Host "  Status: ENABLED" -ForegroundColor Green
                Write-Host "  Enabled for: $($scope -join ', ')" -ForegroundColor Gray
            } else {
                Write-Host "  Status: NOT ENABLED" -ForegroundColor Yellow
                Write-Host "  [INFO] Enable procedure shown in Step 4" -ForegroundColor Cyan
            }
        }
    } catch {
        Write-Host "  [INFO] Cannot check Recycle Bin status (not on DC or insufficient permissions)" -ForegroundColor Gray
        Write-Host "  [INFO] Showing educational commands for reference" -ForegroundColor Cyan
    }

    Write-Host "`n[3.2] Understanding Tombstone Lifetime..." -ForegroundColor Cyan
    Write-Host "  Tombstone Lifetime determines how long deleted objects are retained" -ForegroundColor White
    Write-Host ""
    Write-Host "  Check tombstone lifetime with:" -ForegroundColor Gray
    Write-Host "    Get-ADObject -Identity 'CN=Directory Service,CN=Windows NT,CN=Services,CN=Configuration,DC=contoso,DC=com' -Properties tombstoneLifetime" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Default values:" -ForegroundColor White
    Write-Host "    - Windows Server 2003 SP1+: 180 days" -ForegroundColor Gray
    Write-Host "    - Earlier versions: 60 days" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[SUCCESS] Recycle Bin status checked" -ForegroundColor Green
    Write-Host ""

    # ============================================
    # STEP 4: Enable AD Recycle Bin
    # ============================================
    Write-Host "[Step 4] Enabling AD Recycle Bin" -ForegroundColor Yellow
    Write-Host "Note: This is a ONE-WAY operation that cannot be reversed!" -ForegroundColor Red
    Write-Host ""

    Write-Host "[4.1] Prerequisites for Enabling Recycle Bin..." -ForegroundColor Cyan
    Write-Host "  Required:" -ForegroundColor White
    Write-Host "    - Forest functional level: Windows Server 2008 R2 or higher" -ForegroundColor Gray
    Write-Host "    - Enterprise Admin credentials" -ForegroundColor Gray
    Write-Host "    - All domain controllers should be Windows Server 2008 R2 or higher" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  WARNING: Once enabled, this feature cannot be disabled!" -ForegroundColor Red
    Write-Host ""

    Write-Host "[4.2] Command to Enable Recycle Bin..." -ForegroundColor Cyan
    Write-Host "  PowerShell Command:" -ForegroundColor White
    Write-Host "    Enable-ADOptionalFeature -Identity 'Recycle Bin Feature' -Scope ForestOrConfigurationSet -Target 'contoso.com' -Confirm:`$false" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Or interactively with confirmation:" -ForegroundColor White
    Write-Host "    Enable-ADOptionalFeature 'Recycle Bin Feature' -Scope ForestOrConfigurationSet -Target 'contoso.com'" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[4.3] Using Active Directory Administrative Center..." -ForegroundColor Cyan
    Write-Host "  GUI Method:" -ForegroundColor White
    Write-Host "    1. Open Active Directory Administrative Center (dsac.exe)" -ForegroundColor Gray
    Write-Host "    2. Right-click domain in navigation pane" -ForegroundColor Gray
    Write-Host "    3. Click 'Enable Recycle Bin...'" -ForegroundColor Gray
    Write-Host "    4. Confirm the operation" -ForegroundColor Gray
    Write-Host "    5. Refresh the console" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[4.4] Post-Enablement Steps..." -ForegroundColor Cyan
    Write-Host "  After enabling:" -ForegroundColor White
    Write-Host "    - Feature replicates to all domain controllers" -ForegroundColor Gray
    Write-Host "    - No restart required" -ForegroundColor Gray
    Write-Host "    - Changes are immediately effective" -ForegroundColor Gray
    Write-Host "    - Deleted objects from this point forward can be fully restored" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[INFO] In this demo, we'll show recovery commands without enabling" -ForegroundColor Cyan
    Write-Host "[SUCCESS] Enable procedure documented" -ForegroundColor Green
    Write-Host ""

    # ============================================
    # STEP 5: Finding Deleted Objects
    # ============================================
    Write-Host "[Step 5] Finding Deleted AD Objects" -ForegroundColor Yellow

    Write-Host "`n[5.1] Searching for All Deleted Objects..." -ForegroundColor Cyan
    Write-Host "  Command to list all deleted objects:" -ForegroundColor White
    Write-Host "    Get-ADObject -Filter {isDeleted -eq `$true} -IncludeDeletedObjects -Properties * | Select-Object Name, ObjectClass, WhenChanged, DistinguishedName" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[5.2] Finding Specific Deleted Users..." -ForegroundColor Cyan
    Write-Host "  Search for deleted user by name:" -ForegroundColor White
    Write-Host "    Get-ADObject -Filter {(isDeleted -eq `$true) -and (Name -like '*John*')} -IncludeDeletedObjects -Properties *" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Search for deleted users only:" -ForegroundColor White
    Write-Host "    Get-ADObject -Filter {(isDeleted -eq `$true) -and (ObjectClass -eq 'user')} -IncludeDeletedObjects" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[5.3] Finding Deleted Groups..." -ForegroundColor Cyan
    Write-Host "  Search for deleted groups:" -ForegroundColor White
    Write-Host "    Get-ADObject -Filter {(isDeleted -eq `$true) -and (ObjectClass -eq 'group')} -IncludeDeletedObjects -Properties Name, WhenChanged" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[5.4] Finding Deleted OUs..." -ForegroundColor Cyan
    Write-Host "  Search for deleted organizational units:" -ForegroundColor White
    Write-Host "    Get-ADObject -Filter {(isDeleted -eq `$true) -and (ObjectClass -eq 'organizationalUnit')} -IncludeDeletedObjects" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[5.5] Using Advanced Filters..." -ForegroundColor Cyan
    Write-Host "  Find objects deleted in last 7 days:" -ForegroundColor White
    Write-Host "    `$cutoffDate = (Get-Date).AddDays(-7)" -ForegroundColor Yellow
    Write-Host "    Get-ADObject -Filter {(isDeleted -eq `$true) -and (WhenChanged -gt `$cutoffDate)} -IncludeDeletedObjects -Properties WhenChanged" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Find deleted objects in specific OU:" -ForegroundColor White
    Write-Host "    Get-ADObject -Filter {isDeleted -eq `$true} -IncludeDeletedObjects -SearchBase 'OU=Users,DC=contoso,DC=com'" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[SUCCESS] Search commands demonstrated" -ForegroundColor Green
    Write-Host ""

    # ============================================
    # STEP 6: Restoring Deleted Objects
    # ============================================
    Write-Host "[Step 6] Restoring Deleted Objects" -ForegroundColor Yellow

    Write-Host "`n[6.1] Restore Single Object by Identity..." -ForegroundColor Cyan
    Write-Host "  Basic restore command:" -ForegroundColor White
    Write-Host "    Restore-ADObject -Identity '<ObjectGUID>'" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Example workflow:" -ForegroundColor White
    Write-Host "    # 1. Find the deleted object" -ForegroundColor Gray
    Write-Host "    `$deletedUser = Get-ADObject -Filter {(isDeleted -eq `$true) -and (Name -like '*JohnDoe*')} -IncludeDeletedObjects -Properties *" -ForegroundColor Yellow
    Write-Host "    # 2. Restore using ObjectGUID" -ForegroundColor Gray
    Write-Host "    Restore-ADObject -Identity `$deletedUser.ObjectGUID" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[6.2] Restore to Different Location..." -ForegroundColor Cyan
    Write-Host "  Restore object to specific OU:" -ForegroundColor White
    Write-Host "    Restore-ADObject -Identity '<ObjectGUID>' -TargetPath 'OU=Restored,OU=Users,DC=contoso,DC=com'" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[6.3] Restore Multiple Objects..." -ForegroundColor Cyan
    Write-Host "  Restore all deleted users from specific OU:" -ForegroundColor White
    Write-Host "    Get-ADObject -Filter {(isDeleted -eq `$true) -and (ObjectClass -eq 'user')} -SearchBase 'OU=Sales,DC=contoso,DC=com' -IncludeDeletedObjects | Restore-ADObject" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Restore all objects deleted today:" -ForegroundColor White
    Write-Host "    `$today = (Get-Date).Date" -ForegroundColor Yellow
    Write-Host "    Get-ADObject -Filter {(isDeleted -eq `$true) -and (WhenChanged -ge `$today)} -IncludeDeletedObjects | Restore-ADObject" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[6.4] Restore User with Nested Objects..." -ForegroundColor Cyan
    Write-Host "  When restoring container objects (OUs), you may need to restore in order:" -ForegroundColor White
    Write-Host "    # 1. First restore the parent OU" -ForegroundColor Gray
    Write-Host "    Restore-ADObject -Identity '<OU-GUID>'" -ForegroundColor Yellow
    Write-Host "    # 2. Then restore child objects" -ForegroundColor Gray
    Write-Host "    Get-ADObject -Filter {isDeleted -eq `$true} -SearchBase 'OU=Sales,DC=contoso,DC=com' -IncludeDeletedObjects | Restore-ADObject" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[6.5] Restore with Pipeline..." -ForegroundColor Cyan
    Write-Host "  Powerful pipeline example:" -ForegroundColor White
    Write-Host "    Get-ADObject -Filter {(isDeleted -eq `$true) -and (Name -like 'Sales*')} -IncludeDeletedObjects | \" -ForegroundColor Yellow
    Write-Host "        Where-Object {`$_.WhenChanged -gt (Get-Date).AddDays(-30)} | \" -ForegroundColor Yellow
    Write-Host "        Restore-ADObject -Verbose" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[SUCCESS] Restore procedures documented" -ForegroundColor Green
    Write-Host ""

    # ============================================
    # STEP 7: Using AD Administrative Center
    # ============================================
    Write-Host "[Step 7] Using Active Directory Administrative Center (GUI)" -ForegroundColor Yellow

    Write-Host "`n[7.1] Accessing Deleted Objects in GUI..." -ForegroundColor Cyan
    Write-Host "  Steps to view deleted objects:" -ForegroundColor White
    Write-Host "    1. Open Active Directory Administrative Center (dsac.exe)" -ForegroundColor Gray
    Write-Host "    2. Navigate to your domain" -ForegroundColor Gray
    Write-Host "    3. Select 'Deleted Objects' container" -ForegroundColor Gray
    Write-Host "    4. View all deleted objects with properties" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[7.2] Restoring Objects via GUI..." -ForegroundColor Cyan
    Write-Host "  Restore process:" -ForegroundColor White
    Write-Host "    1. In Deleted Objects container, right-click object" -ForegroundColor Gray
    Write-Host "    2. Select 'Restore' to restore to original location" -ForegroundColor Gray
    Write-Host "    3. Or select 'Restore To...' to choose different OU" -ForegroundColor Gray
    Write-Host "    4. Confirm the restoration" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[7.3] GUI Search Capabilities..." -ForegroundColor Cyan
    Write-Host "  In Deleted Objects container:" -ForegroundColor White
    Write-Host "    - Use search box to filter by name" -ForegroundColor Gray
    Write-Host "    - Add columns to view: WhenChanged, ObjectClass, LastKnownParent" -ForegroundColor Gray
    Write-Host "    - Sort by deletion date to find recent deletions" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[SUCCESS] GUI procedures documented" -ForegroundColor Green
    Write-Host ""

    # ============================================
    # STEP 8: Advanced Scenarios
    # ============================================
    Write-Host "[Step 8] Advanced Recovery Scenarios" -ForegroundColor Yellow

    Write-Host "`n[8.1] Viewing Object Attributes Before Restore..." -ForegroundColor Cyan
    Write-Host "  Check all properties of deleted object:" -ForegroundColor White
    Write-Host "    `$deletedObj = Get-ADObject -Filter {(isDeleted -eq `$true) -and (Name -like '*JohnDoe*')} -IncludeDeletedObjects -Properties *" -ForegroundColor Yellow
    Write-Host "    `$deletedObj | Format-List *" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Important properties to check:" -ForegroundColor White
    Write-Host "    - LastKnownParent: Original OU location" -ForegroundColor Gray
    Write-Host "    - WhenChanged: Deletion timestamp" -ForegroundColor Gray
    Write-Host "    - ObjectClass: Type of object" -ForegroundColor Gray
    Write-Host "    - msDS-LastKnownRDN: Original name" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[8.2] Handling Naming Conflicts..." -ForegroundColor Cyan
    Write-Host "  If object with same name exists in target OU:" -ForegroundColor White
    Write-Host "    - Restore will fail with conflict error" -ForegroundColor Gray
    Write-Host "    - Option 1: Rename existing object first" -ForegroundColor Gray
    Write-Host "    - Option 2: Restore to different OU" -ForegroundColor Gray
    Write-Host "    - Option 3: Rename after restoration" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Rename during restore:" -ForegroundColor White
    Write-Host "    Restore-ADObject -Identity '<GUID>' -NewName 'JohnDoe-Restored'" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[8.3] Restoring Entire OU Hierarchy..." -ForegroundColor Cyan
    Write-Host "  Multi-step process for nested OUs:" -ForegroundColor White
    Write-Host "    # Step 1: Get all deleted OUs, sorted by depth (parent first)" -ForegroundColor Gray
    Write-Host "    `$deletedOUs = Get-ADObject -Filter {(isDeleted -eq `$true) -and (ObjectClass -eq 'organizationalUnit')} -IncludeDeletedObjects -Properties *" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "    # Step 2: Restore parent OU first" -ForegroundColor Gray
    Write-Host "    `$parentOU = `$deletedOUs | Where-Object {`$_.Name -eq 'ParentOU'}" -ForegroundColor Yellow
    Write-Host "    Restore-ADObject -Identity `$parentOU.ObjectGUID" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "    # Step 3: Restore child OUs" -ForegroundColor Gray
    Write-Host "    `$deletedOUs | Where-Object {`$_.LastKnownParent -like '*ParentOU*'} | Restore-ADObject" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "    # Step 4: Restore all objects within" -ForegroundColor Gray
    Write-Host "    Get-ADObject -Filter {isDeleted -eq `$true} -SearchBase 'OU=ParentOU,DC=contoso,DC=com' -IncludeDeletedObjects | Restore-ADObject" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[8.4] Export Deleted Objects Report..." -ForegroundColor Cyan
    Write-Host "  Create report before restoration:" -ForegroundColor White
    Write-Host "    Get-ADObject -Filter {isDeleted -eq `$true} -IncludeDeletedObjects -Properties * | \" -ForegroundColor Yellow
    Write-Host "        Select-Object Name, ObjectClass, WhenChanged, LastKnownParent, ObjectGUID | \" -ForegroundColor Yellow
    Write-Host "        Export-Csv -Path 'C:\Reports\DeletedObjects.csv' -NoTypeInformation" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[SUCCESS] Advanced scenarios documented" -ForegroundColor Green
    Write-Host ""

    # ============================================
    # STEP 9: Limitations and Considerations
    # ============================================
    Write-Host "[Step 9] Limitations and Important Considerations" -ForegroundColor Yellow

    Write-Host "`n[9.1] Recycle Bin Limitations..." -ForegroundColor Cyan
    Write-Host "  What you CAN restore:" -ForegroundColor White
    Write-Host "    - User accounts (with all attributes)" -ForegroundColor Green
    Write-Host "    - Groups (with memberships)" -ForegroundColor Green
    Write-Host "    - Computer accounts" -ForegroundColor Green
    Write-Host "    - Organizational Units" -ForegroundColor Green
    Write-Host "    - Contacts and other AD objects" -ForegroundColor Green
    Write-Host ""
    Write-Host "  What you CANNOT restore:" -ForegroundColor Red
    Write-Host "    - Objects older than tombstone lifetime" -ForegroundColor Gray
    Write-Host "    - Objects deleted before Recycle Bin was enabled" -ForegroundColor Gray
    Write-Host "    - Attributes that were changed before deletion (only restore point is deletion time)" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[9.2] Tombstone Lifetime Impact..." -ForegroundColor Cyan
    Write-Host "  Understanding retention:" -ForegroundColor White
    Write-Host "    - Default: 180 days (Windows Server 2003 SP1+)" -ForegroundColor Gray
    Write-Host "    - After tombstone lifetime expires, objects are permanently removed" -ForegroundColor Gray
    Write-Host "    - Cannot be recovered after expiration" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Modify tombstone lifetime (carefully!):" -ForegroundColor Yellow
    Write-Host "    Set-ADObject 'CN=Directory Service,CN=Windows NT,CN=Services,CN=Configuration,DC=contoso,DC=com' -Replace @{tombstoneLifetime=365}" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[9.3] Replication Considerations..." -ForegroundColor Cyan
    Write-Host "  Important points:" -ForegroundColor White
    Write-Host "    - Deleted objects replicate to all DCs" -ForegroundColor Gray
    Write-Host "    - Restoration also replicates" -ForegroundColor Gray
    Write-Host "    - May take time depending on replication topology" -ForegroundColor Gray
    Write-Host "    - Check replication status after major restorations" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[9.4] Performance Impact..." -ForegroundColor Cyan
    Write-Host "  Considerations:" -ForegroundColor White
    Write-Host "    - Large numbers of deleted objects increase database size" -ForegroundColor Gray
    Write-Host "    - Searches on deleted objects require -IncludeDeletedObjects parameter" -ForegroundColor Gray
    Write-Host "    - No significant performance impact on normal operations" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[SUCCESS] Limitations documented" -ForegroundColor Green
    Write-Host ""

    # ============================================
    # STEP 10: Best Practices
    # ============================================
    Write-Host "[Step 10] Best Practices for AD Recycle Bin" -ForegroundColor Yellow

    Write-Host "`n[Best Practice 1] Enable Recycle Bin Early" -ForegroundColor Cyan
    Write-Host "  - Enable as soon as forest reaches Windows Server 2008 R2" -ForegroundColor White
    Write-Host "  - Only protects objects deleted AFTER enablement" -ForegroundColor White
    Write-Host "  - Cannot be disabled once enabled" -ForegroundColor White
    Write-Host ""

    Write-Host "[Best Practice 2] Document Recovery Procedures" -ForegroundColor Cyan
    Write-Host "  - Create runbooks for common recovery scenarios" -ForegroundColor White
    Write-Host "  - Train help desk on basic recovery procedures" -ForegroundColor White
    Write-Host "  - Test recovery procedures periodically" -ForegroundColor White
    Write-Host "  - Document who has permissions to restore objects" -ForegroundColor White
    Write-Host ""

    Write-Host "[Best Practice 3] Regular Monitoring" -ForegroundColor Cyan
    Write-Host "  - Monitor deletion events in AD" -ForegroundColor White
    Write-Host "  - Review deleted objects periodically" -ForegroundColor White
    Write-Host "  - Alert on unusual deletion patterns" -ForegroundColor White
    Write-Host "  - Export reports of deleted objects monthly" -ForegroundColor White
    Write-Host ""

    Write-Host "[Best Practice 4] Permissions Management" -ForegroundColor Cyan
    Write-Host "  - Limit who can delete AD objects" -ForegroundColor White
    Write-Host "  - Restrict restore permissions to senior admins" -ForegroundColor White
    Write-Host "  - Audit both deletions and restorations" -ForegroundColor White
    Write-Host "  - Use Protected from Accidental Deletion flag on critical OUs" -ForegroundColor White
    Write-Host ""

    Write-Host "[Best Practice 5] Complement with Backups" -ForegroundColor Cyan
    Write-Host "  - Recycle Bin is NOT a replacement for backups" -ForegroundColor White
    Write-Host "  - Maintain regular AD backups (System State)" -ForegroundColor White
    Write-Host "  - Test authoritative restore procedures" -ForegroundColor White
    Write-Host "  - Keep backups beyond tombstone lifetime" -ForegroundColor White
    Write-Host ""

    Write-Host "[Monitoring Command]" -ForegroundColor Cyan
    Write-Host "  Create daily report of deleted objects:" -ForegroundColor White
    Write-Host "    `$yesterday = (Get-Date).AddDays(-1).Date" -ForegroundColor Yellow
    Write-Host "    Get-ADObject -Filter {(isDeleted -eq `$true) -and (WhenChanged -ge `$yesterday)} -IncludeDeletedObjects -Properties * | \" -ForegroundColor Yellow
    Write-Host "        Select-Object Name, ObjectClass, WhenChanged, LastKnownParent | \" -ForegroundColor Yellow
    Write-Host "        Format-Table -AutoSize" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[INFO] Additional Resources:" -ForegroundColor Cyan
    Write-Host "  - AD Recycle Bin documentation: https://docs.microsoft.com/windows-server/identity/ad-ds/get-started/adac/introduction-to-active-directory-administrative-center-enhancements--level-100-" -ForegroundColor White
    Write-Host "  - Step-by-step guide: https://docs.microsoft.com/windows-server/identity/ad-ds/get-started/adac/introduction-to-active-directory-recycle-bin" -ForegroundColor White
    Write-Host ""

} catch {
    Write-Host "[ERROR] $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

Write-Host "AD Recycle Bin demonstration completed successfully!" -ForegroundColor Green
Write-Host "Next Steps: Enable Recycle Bin in production and train administrators on recovery procedures" -ForegroundColor Yellow
