# Lesson 2 Demo Runbook: Secure Local Accounts and Passwords
**Course:** Exam AZ-801: Configuring Windows Server Hybrid Advanced Services  
**Lesson 2 Objectives:**  
- Implement Windows Local Administrator Password Solution (LAPS)  
- Configure password policies (Fine-Grained Password Policies)  
- Implement Microsoft Entra Password Protection for AD DS  

**Lab Environment:**  
- Domain: corp.techtrainertim.com  
- Domain Controller: dc1.corp.techtrainertim.com  
- Member Server: mem1.corp.techtrainertim.com  
- Working directory: C:\demos  

---

## Section 1: Windows LAPS (Local Administrator Password Solution)

**Purpose:** Show how to automatically manage and rotate local Administrator passwords.

**Talk Track:**  
LAPS eliminates the risk of a shared local admin password across machines. Each computer gets its own strong, rotating password stored securely in AD or Microsoft Entra ID. Retrieval is limited to authorized accounts.

### Steps:
1. On **dc1**, extend the schema:  
   ```powershell
   Import-Module AdmPwd.PS
   Update-AdmPwdADSchema
   ```

2. Create a security group `LAPS_Readers` for delegated password retrieval.

3. Assign permissions:  
   ```powershell
   Set-LapsADReadPasswordPermission -Identity "OU=Computers,DC=corp,DC=techtrainertim,DC=com" -AllowedPrincipals "corp\\LAPS_Readers"
   Set-LapsADComputerSelfPermission -Identity "OU=Computers,DC=corp,DC=techtrainertim,DC=com"
   ```

4. Configure Group Policy:  
   - **Computer Configuration → Administrative Templates → LAPS**  
   - Set password length (e.g. 16), complexity = Enabled, rotation = 30 days, and admin account name.

5. Test retrieval:  
   ```powershell
   Get-LapsADPassword -Identity mem1 -AsPlainText
   ```

---

## Section 2: Fine-Grained Password Policies (FGPP)

**Purpose:** Demonstrate how PSOs allow different password requirements for different groups.

**Talk Track:**  
Default domain password policy applies to everyone, but executives may need stronger protection while service accounts may need different settings. FGPPs (via PSOs) provide that flexibility, with precedence resolving conflicts.

### Steps:
1. Create groups `PrivilegedUsers` and `StandardUsers`.  

2. Define PSOs:  
   ```powershell
   New-ADFineGrainedPasswordPolicy -Name "PrivilegedPSO" -Precedence 10 -ComplexityEnabled $true -MinPasswordLength 14 -PasswordHistoryCount 24 -LockoutThreshold 5 -LockoutDuration (New-TimeSpan -Minutes 30) -LockoutObservationWindow (New-TimeSpan -Minutes 30)

   New-ADFineGrainedPasswordPolicy -Name "StandardPSO" -Precedence 20 -ComplexityEnabled $true -MinPasswordLength 8 -PasswordHistoryCount 10 -LockoutThreshold 5 -LockoutDuration (New-TimeSpan -Minutes 15) -LockoutObservationWindow (New-TimeSpan -Minutes 15)
   ```

3. Apply PSOs:  
   ```powershell
   Add-ADFineGrainedPasswordPolicySubject -Identity "PrivilegedPSO" -Subjects "PrivilegedUsers"
   Add-ADFineGrainedPasswordPolicySubject -Identity "StandardPSO" -Subjects "StandardUsers"
   ```

4. Verify with test users:  
   ```powershell
   Get-ADUserResultantPasswordPolicy -Identity userPriv
   ```

---

## Section 3: Microsoft Entra Password Protection

**Purpose:** Block weak or breached passwords with cloud intelligence.

**Talk Track:**  
Entra Password Protection enforces Microsoft’s global banned list and your own custom banned terms. Deploy proxy + DC agents, start in audit mode to monitor, then enforce for stronger security.

### Steps:
1. On `mem1`, install Proxy:  
   ```powershell
   msiexec.exe /i C:\demos\PasswordProtection\AzureADPasswordProtectionProxySetup.msi /quiet /norestart
   ```

2. Register proxy and forest:  
   ```powershell
   Import-Module AzureADPasswordProtection
   Register-AzureADPasswordProtectionProxy -AccountUpn "admin@yourtenant.onmicrosoft.com"
   Register-AzureADPasswordProtectionForest -AccountUpn "admin@yourtenant.onmicrosoft.com"
   ```

3. On `dc1`, install DC Agent:  
   ```powershell
   msiexec.exe /i C:\demos\PasswordProtection\AzureADPasswordProtectionDCAgentSetup.msi /quiet /qn /norestart
   ```

4. In the Entra Admin Center:  
   - Go to **Authentication methods → Password Protection**.  
   - Start in **Audit** mode, then move to **Enforced**.  
   - Add custom banned passwords.

5. Test with a weak password:  
   - Audit mode logs an event but allows the change.  
   - Enforce mode rejects the password.  

---

## Wrap-Up

- LAPS: removes shared local admin credentials.  
- FGPP: applies group-specific password settings.  
- Entra Password Protection: blocks weak or banned passwords with intelligence.  

**Exam Tip:** Expect scenario-based questions: “How do you stop users from picking weak passwords on-prem?” → Entra Password Protection. “How to stop shared local admin password reuse?” → Windows LAPS.
