# Deploy the first domain controller in a child domain

# Install AD DS
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

# Create the DC
Import-Module ADDSDeployment
Install-ADDSDomain `
-NoGlobalCatalog:$false `
-CreateDnsDelegation:$true `
-Credential (Get-Credential) `
-DatabasePath "C:\Windows\NTDS" `
-DomainMode "WinThreshold" `
-DomainType "ChildDomain" `
-InstallDns:$true `
-LogPath "C:\Windows\NTDS" `
-NewDomainName "child" `
-NewDomainNetbiosName "CHILD" `
-ParentDomainName "<root-domain>" `
-NoRebootOnCompletion:$false `
-SiteName "Default-First-Site-Name" `
-SysvolPath "C:\Windows\SYSVOL" `
-SafeModeAdministratorPassword (ConvertTo-SecureString '<be-careful' -AsPlainText -Force)
-Force:$true