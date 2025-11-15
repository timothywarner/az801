# Group Managed Service Accounts (gMSAs)

# Reference: https://timw.info/xu7
# Reference: https://timw.info/49f

Add-KdsRootKey –EffectiveImmediately

Add-KdsRootKey –EffectiveTime ((Get-Date).addhours(-10))

New-ADServiceAccount "Mygmsa1" -DNSHostName "web.your-domain.com" -ManagedPasswordIntervalInDays 30 –PrincipalsAllowedToRetrieveManagedPassword "IISFARM"

Get-ADServiceAccount "Mygmsa1"

Install-ADServiceAccount -Identity "Mygmsa1"
Invoke-Command -ComputerName "rootdc", "rootdc2" -ScriptBlock {}

Test-ADServiceAccount "Mygmsa1"

Remove-ADServiceAccount –identity “Mygmsa1”

$farm = Get-ADComputer -Filter 'Name -like "User01*"'

foreach($f in $farm) {
  Invoke-Command -ComputerName $f -ScriptBlock { Install-ADServiceAccount -Identity $f }
}