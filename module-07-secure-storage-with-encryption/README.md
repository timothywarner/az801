# Module 7: Secure Storage with Encryption

**Duration:** ~15 minutes

## Learning Objectives

After completing this module, you will be able to:

- Manage Windows BitLocker Drive Encryption
- Enable storage encryption by using Azure Disk Encryption
- Manage and recover encrypted volumes
- Manage disk encryption keys for IaaS virtual machines
- Configure File Server Resource Manager (FSRM) and Storage QoS for workload governance

## Topics Covered

### 7.1. Manage Windows BitLocker Drive Encryption
Implement BitLocker to protect data at rest on Windows Server volumes.

### 7.2. Enable Storage Encryption by Using Azure Disk Encryption
Encrypt Azure VM disks using Azure Disk Encryption.

### 7.3. Manage and Recover Encrypted Volumes
Manage BitLocker-encrypted volumes and perform recovery operations.

### 7.4. Manage Disk Encryption Keys for IaaS Virtual Machines
Manage encryption keys in Azure Key Vault for Azure VM disk encryption.

### 7.5. Configure File Server Resource Manager (FSRM) and Storage QoS for Workload Governance
Implement FSRM for quota management and file screening, and configure Storage QoS for performance management.

## Supplemental Resources

- [BitLocker Overview](https://learn.microsoft.com/en-us/windows/security/operating-system-security/data-protection/bitlocker/)
- [Azure Disk Encryption](https://learn.microsoft.com/en-us/azure/virtual-machines/disk-encryption-overview)
- [Azure Key Vault](https://learn.microsoft.com/en-us/azure/key-vault/general/overview)
- [File Server Resource Manager](https://learn.microsoft.com/en-us/windows-server/storage/fsrm/fsrm-overview)
- [Storage Quality of Service](https://learn.microsoft.com/en-us/windows-server/storage/storage-qos/storage-qos-overview)

## Hands-on Labs

Check the `/labs` subdirectory for hands-on exercises related to this module.

## Notes

- BitLocker recovery keys should be backed up to Active Directory or Azure AD
- Azure Disk Encryption uses BitLocker for Windows VMs and dm-crypt for Linux VMs
- Azure Key Vault is used to manage and control disk encryption keys
- FSRM can prevent ransomware by blocking suspicious file types
