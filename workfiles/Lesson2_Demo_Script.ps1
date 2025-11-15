<#
Lesson 2 Demo Script: Secure Local Accounts and Passwords
Covers: LAPS, Fine-Grained Password Policies, Entra Password Protection
Environment: corp.techtrainertim.com (dc1 + mem1)
#>

# === Section 1: Windows LAPS ===

# Extend AD schema for LAPS (run on dc1 as Schema Admin)
Import-Module AdmPwd.PS
Update-AdmPwdADSchema

# Create security group for delegated readers
New-ADGroup -Name "LAPS_Readers" -GroupScope Global -GroupCategory Security -Path "CN=Users,DC=corp,DC=techtrainertim,DC=com"

# Grant read permission and self-update rights
Set-LapsADReadPasswordPermission -Identity "OU=Computers,DC=corp,DC=techtrainertim,DC=com" -AllowedPrincipals "corp\LAPS_Readers"
Set-LapsADComputerSelfPermission -Identity "OU=Computers,DC=corp,DC=techtrainertim,DC=com"

# Retrieve password for demo verification
Get-LapsADPassword -Identity mem1 -AsPlainText

# === Section 2: Fine-Grained Password Policies (FGPP) ===

# Create groups for different user categories
New-ADGroup -Name "PrivilegedUsers" -GroupScope Global -GroupCategory Security -Path "OU=Users,DC=corp,DC=techtrainertim,DC=com"
New-ADGroup -Name "StandardUsers" -GroupScope Global -GroupCategory Security -Path "OU=Users,DC=corp,DC=techtrainertim,DC=com"

# Create stricter PSO for privileged users
New-ADFineGrainedPasswordPolicy -Name "PrivilegedPSO" -Precedence 10 -ComplexityEnabled $true -MinPasswordLength 14 -PasswordHistoryCount 24 -LockoutThreshold 5 -LockoutDuration (New-TimeSpan -Minutes 30) -LockoutObservationWindow (New-TimeSpan -Minutes 30)

# Create standard PSO for standard users
New-ADFineGrainedPasswordPolicy -Name "StandardPSO" -Precedence 20 -ComplexityEnabled $true -MinPasswordLength 8 -PasswordHistoryCount 10 -LockoutThreshold 5 -LockoutDuration (New-TimeSpan -Minutes 15) -LockoutObservationWindow (New-TimeSpan -Minutes 15)

# Apply PSOs to groups
Add-ADFineGrainedPasswordPolicySubject -Identity "PrivilegedPSO" -Subjects "PrivilegedUsers"
Add-ADFineGrainedPasswordPolicySubject -Identity "StandardPSO" -Subjects "StandardUsers"

# Verify resultant password policy for a test user
Get-ADUserResultantPasswordPolicy -Identity userPriv

# === Section 3: Microsoft Entra Password Protection ===

# Install Proxy service on member server (mem1)
msiexec.exe /i C:\demos\PasswordProtection\AzureADPasswordProtectionProxySetup.msi /quiet /norestart

# Register proxy and forest with Entra (replace with your Global Admin UPN)
Import-Module AzureADPasswordProtection
Register-AzureADPasswordProtectionProxy -AccountUpn "admin@yourtenant.onmicrosoft.com"
Register-AzureADPasswordProtectionForest -AccountUpn "admin@yourtenant.onmicrosoft.com"

# Install DC Agent on domain controller (dc1)
msiexec.exe /i C:\demos\PasswordProtection\AzureADPasswordProtectionDCAgentSetup.msi /quiet /qn /norestart

# After this step, configure Audit → Enforce and Custom banned list in the Entra portal
