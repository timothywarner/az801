# Module 1: Implement Core OS Security

**Duration:** ~20 minutes

## Learning Objectives

After completing this module, you will be able to:

- Configure and manage Exploit Protection
- Configure and manage Windows Defender Application Control (WDAC)
- Configure and manage Windows Defender Credential Guard
- Configure SmartScreen
- Implement operating system security by using Group Policies
- Manage Windows Server security baseline by using OSConfig
- Configure Secured-core Server features for high-security workloads

## Topics Covered

### 1.1. Configure and Manage Exploit Protection
Learn how to protect against common attack techniques by applying exploit mitigation settings at both the system and application level.

### 1.2. Configure and Manage Windows Defender Application Control
Implement application control policies to ensure only trusted applications can execute on your Windows Server infrastructure.

### 1.3. Configure and Manage Windows Defender Credential Guard
Protect domain credentials from credential theft attacks using virtualization-based security.

### 1.4. Configure SmartScreen
Configure SmartScreen to protect against malicious websites and applications.

### 1.5. Implement Operating System Security by Using Group Policies
Apply security configurations across your domain using Group Policy Objects (GPOs).

### 1.6. Manage Windows Server Security Baseline by Using OSConfig
Leverage OSConfig to apply and monitor security baselines for Windows Server.

### 1.7. Configure Secured-core Server Features for High-Security Workloads
Implement hardware-based security features for mission-critical workloads.

## Supplemental Resources

- [Windows Server Security documentation](https://learn.microsoft.com/en-us/windows-server/security/security-and-assurance)
- [Windows Defender Application Control](https://learn.microsoft.com/en-us/windows/security/application-security/application-control/windows-defender-application-control/wdac)
- [Credential Guard overview](https://learn.microsoft.com/en-us/windows/security/identity-protection/credential-guard/)
- [Secured-core server](https://learn.microsoft.com/en-us/windows-server/security/secured-core-server)
- [Windows Security Baselines](https://learn.microsoft.com/en-us/windows/security/operating-system-security/device-management/windows-security-configuration-framework/windows-security-baselines)

## Hands-on Labs

Check the `/labs` subdirectory for hands-on exercises related to this module.

## Notes

- Exploit Protection is the modern replacement for EMET (Enhanced Mitigation Experience Toolkit)
- WDAC is the recommended approach for application whitelisting, replacing AppLocker in modern scenarios
- Credential Guard requires UEFI 2.3.1 or greater and virtualization extensions
