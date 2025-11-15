# Module 3: Manage Protected Users and RODCs

**Duration:** ~15 minutes

## Learning Objectives

After completing this module, you will be able to:

- Manage protected users
- Manage account security on a Read-Only Domain Controller (RODC)
- Harden domain controllers

## Topics Covered

### 3.1. Manage Protected Users
Configure and manage the Protected Users security group to provide additional protection for high-privilege accounts.

### 3.2. Manage Account Security on a Read-Only Domain Controller (RODC)
Implement and configure RODCs for branch office scenarios while maintaining security best practices.

### 3.3. Harden Domain Controllers
Apply security hardening techniques to protect domain controllers from attack.

## Supplemental Resources

- [Protected Users Security Group](https://learn.microsoft.com/en-us/windows-server/security/credentials-protection-and-management/protected-users-security-group)
- [Read-Only Domain Controllers](https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/deploy/rodc/read-only-domain-controller-updates)
- [Securing Domain Controllers Against Attack](https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/plan/security-best-practices/securing-domain-controllers-against-attack)
- [Best Practices for Securing Active Directory](https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/plan/security-best-practices/best-practices-for-securing-active-directory)

## Hands-on Labs

Check the `/labs` subdirectory for hands-on exercises related to this module.

## Notes

- Protected Users group membership provides automatic protections such as no NTLM authentication
- RODCs are ideal for branch offices where physical security cannot be guaranteed
- Domain controllers should not run other applications or services
- Consider implementing tiered administrative model for domain controller access
