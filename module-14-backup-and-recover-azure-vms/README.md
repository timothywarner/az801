# Module 14: Backup and Recover Azure VMs

**Duration:** ~15 minutes

## Learning Objectives

After completing this module, you will be able to:

- Configure backup for Azure VM using the built-in backup agent
- Recover a VM using instant recovery snapshots
- Recover VMs to new Azure VMs
- Restore a VM, including encrypted VMs

## Topics Covered

### 14.1. Configure Backup for Azure VM Using the Built-in Backup Agent
Enable Azure Backup for virtual machines directly from the Azure portal.

### 14.2. Recover a VM Using Instant Recovery Snapshots
Restore VMs quickly using snapshot-based recovery.

### 14.3. Recover VMs to New Azure VMs
Create new VMs from backup restore points.

### 14.4. Restore a VM, Including Encrypted VMs
Restore VMs with Azure Disk Encryption enabled.

## Supplemental Resources

- [Azure VM Backup](https://learn.microsoft.com/en-us/azure/backup/backup-azure-vms-introduction)
- [Instant Restore](https://learn.microsoft.com/en-us/azure/backup/backup-instant-restore-capability)
- [Restore Azure VMs](https://learn.microsoft.com/en-us/azure/backup/backup-azure-arm-restore-vms)
- [Backup Encrypted VMs](https://learn.microsoft.com/en-us/azure/backup/backup-azure-vms-encryption)

## Hands-on Labs

Check the `/labs` subdirectory for hands-on exercises related to this module.

## Notes

- Azure VM backup is application-consistent for Windows VMs
- Instant restore uses locally stored snapshots for fast recovery
- Cross-region restore requires geo-redundant storage
- Encrypted VMs require Key Vault access for restore operations
- Selective disk backup can reduce costs
