# Deploy the first domain controller in a new forest

# Install the server role
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

# Create forest root domain
Import-Module ADDSDeployment
Install-ADDSForest `
-CreateDnsDelegation:$false `
-DatabasePath "C:\Windows\NTDS" `
-DomainMode "WinThreshold" `
-DomainName "<your-domain>" `
-DomainNetbiosName "TIMW" `
-ForestMode "WinThreshold" `
-InstallDns:$true `
-LogPath "C:\Windows\NTDS" `
-NoRebootOnCompletion:$false `
-SysvolPath "C:\Windows\SYSVOL" `
  -SafeModeAdministratorPassword (ConvertTo-SecureString '<be-careful' -AsPlainText -Force)
-Force:$true