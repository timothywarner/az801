# Module 16: Migrate Storage Using SMS

**Duration:** ~15 minutes

## Learning Objectives

After completing this module, you will be able to:

- Transfer files, file shares, and security configurations by using Storage Migration Service (SMS)
- Cut over to a new server by using Storage Migration Service (SMS)
- Use Storage Migration Service to migrate to Azure VMs
- Migrate to Azure file shares

## Topics Covered

### 16.1. Transfer Files, File Shares, and Security Configurations by Using Storage Migration Service
Use SMS to inventory and migrate file server data and configuration.

### 16.2. Cut Over to a New Server by Using Storage Migration Service
Complete the migration by transferring the identity of the source server.

### 16.3. Use Storage Migration Service to Migrate to Azure VMs
Migrate on-premises file servers to Azure virtual machines.

### 16.4. Migrate to Azure File Shares
Move file server workloads to Azure Files.

## Supplemental Resources

- [Storage Migration Service Overview](https://learn.microsoft.com/en-us/windows-server/storage/storage-migration-service/overview)
- [Migrate to Azure VMs](https://learn.microsoft.com/en-us/windows-server/storage/storage-migration-service/migrate-data)
- [Migrate to Azure File Shares](https://learn.microsoft.com/en-us/azure/storage/files/storage-files-migration-overview)
- [SMS Requirements](https://learn.microsoft.com/en-us/windows-server/storage/storage-migration-service/overview#requirements)

## Hands-on Labs

Check the `/labs` subdirectory for hands-on exercises related to this module.

## Notes

- SMS requires Windows Server 2019 or later for the orchestrator
- SMS can migrate from Windows Server 2003 and later
- Cutover transfers the IP address and name from source to destination
- Azure File Sync can be used for hybrid scenarios
- SMS preserves permissions, shares, and security settings
