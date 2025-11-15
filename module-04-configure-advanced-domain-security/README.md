# Module 4: Configure Advanced Domain Security

**Duration:** ~20 minutes

## Learning Objectives

After completing this module, you will be able to:

- Configure authentication policy silos
- Restrict access to domain controllers
- Configure security options for user accounts
- Configure security options for built-in administrative groups
- Manage AD delegation
- Implement Just Enough Administration (JEA) and Just-In-Time (JIT) privileged access

## Topics Covered

### 4.1. Configure Authentication Policy Silos
Implement authentication policy silos to isolate and protect high-value accounts and resources.

### 4.2. Restrict Access to Domain Controllers
Configure firewall rules and access controls to limit who can access domain controllers.

### 4.3. Configure Security Options for User Accounts
Apply security settings to user accounts including account expiration, login restrictions, and more.

### 4.4. Configure Security Options for Built-in Administrative Groups
Secure built-in groups like Domain Admins, Enterprise Admins, and Schema Admins.

### 4.5. Manage AD Delegation
Delegate administrative tasks in Active Directory while maintaining security.

### 4.6. Implement Just Enough Administration (JEA) and Just-In-Time (JIT) Privileged Access
Implement JEA to limit administrative capabilities and JIT to provide temporary elevated access.

## Supplemental Resources

- [Authentication Policies and Authentication Policy Silos](https://learn.microsoft.com/en-us/windows-server/security/credentials-protection-and-management/authentication-policies-and-authentication-policy-silos)
- [Just Enough Administration (JEA)](https://learn.microsoft.com/en-us/powershell/scripting/security/remoting/jea/overview)
- [Privileged Access Management](https://learn.microsoft.com/en-us/microsoft-identity-manager/pam/privileged-identity-management-for-active-directory-domain-services)
- [Active Directory Delegation Best Practices](https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/plan/security-best-practices/implementing-least-privilege-administrative-models)

## Hands-on Labs

Check the `/labs` subdirectory for hands-on exercises related to this module.

## Notes

- Authentication policy silos require Windows Server 2012 R2 domain functional level or higher
- JEA is PowerShell-based and provides role-based access control
- Consider implementing a tiered administrative model
- Use time-based group membership for JIT access scenarios
