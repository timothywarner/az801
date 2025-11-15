# Module 2: Secure Local Accounts and Passwords

**Duration:** ~15 minutes

## Learning Objectives

After completing this module, you will be able to:

- Implement Windows Local Administrator Password Solution (LAPS)
- Configure password policies
- Implement Microsoft Entra Password Protection for AD DS

## Topics Covered

### 2.1. Implement Windows Local Administrator Password Solution
Deploy and manage LAPS to secure local administrator accounts across your Windows Server infrastructure.

### 2.2. Configure Password Policies
Implement fine-grained password policies and domain-level password requirements.

### 2.3. Implement Microsoft Entra Password Protection for AD DS
Integrate Azure AD Password Protection to prevent users from using weak or compromised passwords.

## Supplemental Resources

- [Windows LAPS documentation](https://learn.microsoft.com/en-us/windows-server/identity/laps/laps-overview)
- [Password Policies and Account Lockout Policies](https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/get-started/adac/introduction-to-active-directory-administrative-center-enhancements--level-100-#fine_grained_pswd_policy_mgmt)
- [Microsoft Entra Password Protection](https://learn.microsoft.com/en-us/entra/identity/authentication/concept-password-ban-bad-on-premises)
- [Fine-Grained Password Policies](https://learn.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2008-R2-and-2008/cc770394(v=ws.10))

## Hands-on Labs

Check the `/labs` subdirectory for hands-on exercises related to this module.

## Notes

- Windows LAPS is the successor to the legacy Microsoft LAPS solution
- LAPS passwords are stored in Active Directory and automatically rotated
- Password Protection requires Azure AD Premium P1 or P2 licensing
- Custom banned password lists can be configured in Azure AD
