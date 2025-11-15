# Module 13: Implement Azure Backup

**Duration:** ~20 minutes

## Learning Objectives

After completing this module, you will be able to:

- Backup and restore files and folders to Azure Recovery Services Vault
- Deploy and manage Azure Backup Server
- Back up and recover using Azure Backup Server
- Manage backups in Azure Recovery Services Vault
- Create an Azure Recovery Services vault backup policy
- Implement ransomware-aware backup and recovery strategies, including immutable storage and recovery testing

## Topics Covered

### 13.1. Backup and Restore Files and Folders to Azure Recovery Services Vault
Use the MARS agent to backup files and folders to Azure.

### 13.2. Deploy and Manage Azure Backup Server
Install and configure Microsoft Azure Backup Server (MABS).

### 13.3. Back Up and Recover Using Azure Backup Server
Protect workloads using Azure Backup Server.

### 13.4. Manage Backups in Azure Recovery Services Vault
Monitor and manage backup jobs and restore points.

### 13.5. Create an Azure Recovery Services Vault Backup Policy
Define backup policies including schedule and retention.

### 13.6. Implement Ransomware-Aware Backup and Recovery Strategies
Implement immutable backups and recovery testing to protect against ransomware.

## Supplemental Resources

- [Azure Backup Overview](https://learn.microsoft.com/en-us/azure/backup/backup-overview)
- [Azure Backup Server](https://learn.microsoft.com/en-us/azure/backup/backup-azure-microsoft-azure-backup)
- [MARS Agent](https://learn.microsoft.com/en-us/azure/backup/backup-azure-file-folder-backup-faq)
- [Recovery Services Vault](https://learn.microsoft.com/en-us/azure/backup/backup-azure-recovery-services-vault-overview)
- [Ransomware Protection](https://learn.microsoft.com/en-us/azure/backup/backup-azure-security-feature)

## Hands-on Labs

Check the `/labs` subdirectory for hands-on exercises related to this module.

## Notes

- MARS agent is lightweight and suitable for file/folder backups
- Azure Backup Server supports application-aware backups
- Soft delete protects backups from accidental deletion
- Immutable vaults prevent backup deletion even by administrators
- Regular restore testing validates backup integrity
