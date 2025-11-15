# Module 25: Troubleshoot Advanced Issues

**Duration:** ~15 minutes

## Learning Objectives

After completing this module, you will be able to:

- Troubleshoot performance issues
- Troubleshoot VM and Azure Arc extension issues
- Troubleshoot disk encryption issues
- Troubleshoot storage
- Troubleshoot Azure Arc server extension issues

## Topics Covered

### 25.1. Troubleshoot Performance Issues
Diagnose and resolve CPU, memory, disk, and network performance problems.

### 25.2. Troubleshoot VM and Azure Arc Extension Issues
Resolve problems with Azure VM extensions and Azure Arc extensions.

### 25.3. Troubleshoot Disk Encryption Issues
Fix BitLocker and Azure Disk Encryption problems.

### 25.4. Troubleshoot Storage
Diagnose storage-related issues including disk failures and file system corruption.

### 25.5. Troubleshoot Azure Arc Server Extension Issues
Resolve Azure Arc agent and extension problems.

## Supplemental Resources

- [Performance Troubleshooting](https://learn.microsoft.com/en-us/windows-server/administration/performance-tuning/)
- [VM Extensions](https://learn.microsoft.com/en-us/azure/virtual-machines/extensions/overview)
- [BitLocker Troubleshooting](https://learn.microsoft.com/en-us/windows/security/operating-system-security/data-protection/bitlocker/troubleshoot)
- [Storage Troubleshooting](https://learn.microsoft.com/en-us/windows-server/storage/storage-spaces/troubleshooting-storage-spaces)
- [Azure Arc Troubleshooting](https://learn.microsoft.com/en-us/azure/azure-arc/servers/troubleshoot-agent-onboard)

## Hands-on Labs

Check the `/labs` subdirectory for hands-on exercises related to this module.

## Notes

- Resource Monitor provides detailed performance analysis
- Extension logs are typically in C:\WindowsAzure\Logs
- BitLocker recovery keys are stored in AD or Azure AD
- CHKDSK and SFC can repair file system corruption
- Azure Arc agent logs help diagnose connectivity issues
