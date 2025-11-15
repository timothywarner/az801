# Module 5: Monitor and Defend with Microsoft Security Tools

**Duration:** ~20 minutes

## Learning Objectives

After completing this module, you will be able to:

- Implement and manage Microsoft Defender for Identity
- Audit usage of and disable NTLM
- Implement ingestion of Windows Server data into Microsoft Sentinel
- Manage security for Windows Server by using Microsoft Defender for Cloud
- Manage security for Windows Server by using Microsoft Defender for Servers
- Implement hotpatching for Windows Server Azure Edition virtual machines

## Topics Covered

### 5.1. Implement and Manage Microsoft Defender for Identity
Deploy and configure Defender for Identity to detect and investigate security threats in your hybrid environment.

### 5.2. Audit Usage of and Disable NTLM
Monitor NTLM usage and migrate to Kerberos authentication.

### 5.3. Implement Ingestion of Windows Server Data into Microsoft Sentinel
Configure Windows Servers to send security logs and telemetry to Microsoft Sentinel.

### 5.4. Manage Security for Windows Server by Using Microsoft Defender for Cloud
Implement security recommendations and threat protection using Defender for Cloud.

### 5.5. Manage Security for Windows Server by Using Microsoft Defender for Servers
Deploy and configure Defender for Servers for enhanced threat protection.

### 5.6. Implement Hotpatching for Windows Server Azure Edition Virtual Machines
Enable hotpatching to apply security updates without rebooting.

## Supplemental Resources

- [Microsoft Defender for Identity](https://learn.microsoft.com/en-us/defender-for-identity/what-is)
- [NTLM Auditing and Restriction](https://learn.microsoft.com/en-us/windows-server/security/kerberos/ntlm-overview)
- [Microsoft Sentinel documentation](https://learn.microsoft.com/en-us/azure/sentinel/)
- [Microsoft Defender for Cloud](https://learn.microsoft.com/en-us/azure/defender-for-cloud/)
- [Hotpatching for Windows Server Azure Edition](https://learn.microsoft.com/en-us/azure/automanage/automanage-hotpatch)

## Hands-on Labs

Check the `/labs` subdirectory for hands-on exercises related to this module.

## Notes

- Defender for Identity requires domain controller sensors or standalone sensors
- NTLM should be audited before disabling to prevent authentication failures
- Microsoft Sentinel is Microsoft's cloud-native SIEM solution
- Hotpatching is only available for Windows Server Azure Edition VMs
