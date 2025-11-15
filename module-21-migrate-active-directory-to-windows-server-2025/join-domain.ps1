# Join a Windows system to an AD DS domain
Add-Computer -DomainName "<domain-name>" `
  -Credential Get-Credential `
  -Verbose -Restart -Force