# Module 26: Troubleshoot Active Directory

**Duration:** ~20 minutes

## Learning Objectives

After completing this module, you will be able to:

- Restore objects from AD recycle bin
- Recover Active Directory database using Directory Services Restore Mode
- Recover system volume (SYSVOL)
- Troubleshoot Active Directory replication
- Troubleshoot hybrid authentication and synchronization issues
- Troubleshoot on-premises Active Directory
- Troubleshoot hybrid identity synchronization with Microsoft Entra Connect

## Topics Covered

### 26.1. Restore Objects from AD Recycle Bin
Recover deleted AD objects without restoring from backup.

### 26.2. Recover Active Directory Database Using Directory Services Restore Mode
Perform authoritative and non-authoritative restores of AD DS.

### 26.3. Recover System Volume (SYSVOL)
Restore SYSVOL using authoritative and non-authoritative methods.

### 26.4. Troubleshoot Active Directory Replication
Diagnose and fix AD replication issues.

### 26.5. Troubleshoot Hybrid Authentication and Synchronization Issues
Resolve password hash sync, pass-through authentication, and federation issues.

### 26.6. Troubleshoot On-premises Active Directory
Fix common AD DS problems including FSMO role issues and authentication failures.

### 26.7. Troubleshoot Hybrid Identity Synchronization with Microsoft Entra Connect
Resolve Entra Connect synchronization errors.

## Supplemental Resources

- [AD Recycle Bin](https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/get-started/adac/introduction-to-active-directory-administrative-center-enhancements--level-100-#ad_recycle_bin_mgmt)
- [Directory Services Restore Mode](https://learn.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2012-R2-and-2012/cc771363(v=ws.11))
- [SYSVOL Replication](https://learn.microsoft.com/en-us/troubleshoot/windows-server/group-policy/force-authoritative-non-authoritative-synchronization)
- [Replication Troubleshooting](https://learn.microsoft.com/en-us/troubleshoot/windows-server/identity/troubleshoot-ad-replication-errors)
- [Microsoft Entra Connect](https://learn.microsoft.com/en-us/entra/identity/hybrid/connect/how-to-connect-health-operations)

## Hands-on Labs

Check the `/labs` subdirectory for hands-on exercises related to this module.

## Scripts

- `ad-recycle-bin.ps1` - Enable and use AD Recycle Bin
- `fsmo.ps1` - Check and transfer FSMO roles

## Notes

- AD Recycle Bin must be enabled proactively; cannot be enabled after deletion
- DSRM password should be changed regularly
- Use `repadmin` and `dcdiag` for replication troubleshooting
- Entra Connect Health provides monitoring and alerts
- USN rollback can cause serious replication issues
- Always check DNS when troubleshooting AD issues
