# Module 6: Secure Windows Server Networking

**Duration:** ~15 minutes

## Learning Objectives

After completing this module, you will be able to:

- Manage Windows Defender Firewall
- Implement domain isolation
- Implement connection security rules
- Create and configure network security groups (NSGs) for Windows Server virtual machines on Azure

## Topics Covered

### 6.1. Manage Windows Defender Firewall
Configure firewall rules and profiles for Windows Server.

### 6.2. Implement Domain Isolation
Use IPsec to isolate domain-joined computers from non-domain computers.

### 6.3. Implement Connection Security Rules
Configure IPsec connection security rules to encrypt network traffic.

### 6.4. Create and Configure Network Security Groups (NSGs) for Windows Server Virtual Machines on Azure
Implement network security groups to control inbound and outbound traffic to Azure VMs.

## Supplemental Resources

- [Windows Defender Firewall with Advanced Security](https://learn.microsoft.com/en-us/windows/security/operating-system-security/network-security/windows-firewall/)
- [Server and Domain Isolation](https://learn.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2008-R2-and-2008/cc753178(v=ws.10))
- [Connection Security Rules](https://learn.microsoft.com/en-us/windows/security/operating-system-security/network-security/windows-firewall/create-an-inbound-icmp-rule)
- [Azure Network Security Groups](https://learn.microsoft.com/en-us/azure/virtual-network/network-security-groups-overview)

## Hands-on Labs

Check the `/labs` subdirectory for hands-on exercises related to this module.

## Notes

- Windows Defender Firewall has three profiles: Domain, Private, and Public
- Domain isolation uses IPsec to authenticate and optionally encrypt traffic
- Connection security rules are separate from firewall rules
- NSGs can be associated with subnets or individual network interfaces
