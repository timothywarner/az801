# Set the time zone
Set-TimeZone -Name "Central Standard Time"

# Disable Server Manager auto-start
Get-ScheduledTask -TaskName ServerManager | Disable-ScheduledTask

# Disable Firewall
Set-NetFirewallProfile -Profile Domain, Public, Private -Enabled False

Set-ExecutionPolicy -ExecutionPolicy Bypass -Force

#Install Chocolatey
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

#Install Software
choco install git azurepowershell azure-cli bicep vscode sysinternals microsoftazurestorageexplorer windows-admin-center -y

# Hide clock
New-Item -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies' -Name 'Explorer'
New-Item -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies' -Name 'Explorer'
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer' -Name 'HideClock' -Value 1
Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer' -Name 'HideClock' -Value 1
Stop-Process -Name 'explorer'

# Show system files and extensions
$key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
Set-ItemProperty $key Hidden 1
Set-ItemProperty $key HideFileExt 0
Set-ItemProperty $key ShowSuperHidden 1
Stop-Process -processname explorer

# Disable Task View button and search box
Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name ShowTaskViewButton -Value 0 -Type DWord -Force
Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search -Name SearchBoxTaskbarMode -Value 0 -Type DWord -Force
Stop-Process -ProcessName Explorer

# Mount tools drive from Azure Files
$connectTestResult = Test-NetConnection -ComputerName timstorage001.file.core.windows.net -Port 445
if ($connectTestResult.TcpTestSucceeded) {
  # Save the password so the drive will persist on reboot
  cmd.exe /C "cmdkey /add:`"timstorage001.file.core.windows.net`" /user:`"`" /pass:`"`""
  # Mount the drive
  New-PSDrive -Name Z -PSProvider FileSystem -Root "\\.file.core.windows.net\az800" -Persist
}
else {
  Write-Error -Message "Unable to reach the Azure storage account via port 445. Check to make sure your organization or ISP is not blocking port 445, or use Azure P2S VPN, Azure S2S VPN, or Express Route to tunnel SMB traffic over a different port." }
