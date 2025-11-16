<#
.SYNOPSIS
    Task 11.2 - Configure S2D Networking

.DESCRIPTION
    Network configuration for Storage Spaces Direct including SET, RDMA, and QoS.

.NOTES
    Module: Module 11 - Implement Storage Spaces Direct
    Task: 11.2 - Configure S2D Networking
    Prerequisites: Storage Spaces Direct cluster
    PowerShell Version: 5.1+
#>

#Requires -RunAsAdministrator

$ErrorActionPreference = 'Stop'
Write-Host "=== AZ-801 Module 11: Task 11.2 - Configure S2D Networking ===" -ForegroundColor Cyan

function Write-Step { param([string]$Message); Write-Host "`n[STEP] $Message" -ForegroundColor Yellow }

try {
    Write-Step "S2D Network Requirements"
    Write-Host "  - Minimum 10 GbE (25/100 GbE recommended)" -ForegroundColor White
    Write-Host "  - RDMA support (iWARP, RoCE, or InfiniBand)" -ForegroundColor White
    Write-Host "  - Dedicated storage network" -ForegroundColor White
    Write-Host "  - Jumbo frames (MTU 9014)" -ForegroundColor White

    Write-Step "Configure SET (Switch Embedded Teaming)"
    Write-Host @"
  # Create SET team for converged networking
  New-VMSwitch -Name 'ConvergedSwitch' ``
      -NetAdapterName 'NIC1','NIC2' ``
      -EnableEmbeddedTeaming `$true ``
      -AllowManagementOS `$false
  
  # Add management vNIC
  Add-VMNetworkAdapter -ManagementOS -Name 'Management' -SwitchName 'ConvergedSwitch'
  Set-VMNetworkAdapterVlan -ManagementOS -VMNetworkAdapterName 'Management' -Access -VlanId 10
  
  # Add storage vNICs
  Add-VMNetworkAdapter -ManagementOS -Name 'SMB1' -SwitchName 'ConvergedSwitch'
  Add-VMNetworkAdapter -ManagementOS -Name 'SMB2' -SwitchName 'ConvergedSwitch'
  
  # Configure IP addresses
  New-NetIPAddress -InterfaceAlias 'vEthernet (SMB1)' -IPAddress 10.0.1.1 -PrefixLength 24
  New-NetIPAddress -InterfaceAlias 'vEthernet (SMB2)' -IPAddress 10.0.2.1 -PrefixLength 24
"@ -ForegroundColor Gray

    Write-Step "Enable RDMA on vNICs"
    Write-Host @"
  # Enable RDMA on storage vNICs
  Enable-NetAdapterRdma -Name 'vEthernet (SMB1)'
  Enable-NetAdapterRdma -Name 'vEthernet (SMB2)'
  
  # Verify RDMA
  Get-NetAdapterRdma | Format-Table Name, Enabled
  Get-SmbClientNetworkInterface | Format-Table FriendlyName, RdmaCapable, LinkSpeed
"@ -ForegroundColor Gray

    Write-Step "Configure QoS for Storage Traffic"
    Write-Host @"
  # Create QoS policy for SMB Direct
  New-NetQosPolicy -Name 'SMB' -NetDirectPortMatchCondition 445 -PriorityValue8021Action 3
  
  # Enable flow control for priority 3
  Enable-NetQosFlowControl -Priority 3
  
  # Disable flow control for other priorities
  Disable-NetQosFlowControl -Priority 0,1,2,4,5,6,7
  
  # Create traffic class
  New-NetQosTrafficClass -Name 'SMB' -Priority 3 -BandwidthPercentage 50 -Algorithm ETS
  
  # Verify QoS configuration
  Get-NetQosPolicy
  Get-NetQosFlowControl
  Get-NetQosTrafficClass
"@ -ForegroundColor Gray

    Write-Step "Configure Jumbo Frames"
    Write-Host @"
  # Set MTU to 9014 for storage adapters
  Get-NetAdapterAdvancedProperty -Name 'vEthernet (SMB*)' -RegistryKeyword '*JumboPacket' |
      Set-NetAdapterAdvancedProperty -RegistryValue 9014
  
  # Verify MTU
  Get-NetAdapter 'vEthernet (SMB*)' | Get-NetAdapterAdvancedProperty -RegistryKeyword '*JumboPacket'
"@ -ForegroundColor Gray

    Write-Step "Test S2D Network Performance"
    Write-Host @"
  # Test RDMA connectivity
  Test-NetConnection -ComputerName NODE2 -Port 445
  
  # Verify SMB Multichannel
  Get-SmbMultichannelConnection -IncludeNotSelected
  
  # Test SMB bandwidth
  # Copy large file and monitor:
  Get-SmbClientNetworkInterface
  Get-Counter '\SMB Client Shares(*)\*'
"@ -ForegroundColor Gray

    Write-Host "`n" + "="*80 -ForegroundColor Cyan
    Write-Host "[SUCCESS] S2D Networking Configuration Complete" -ForegroundColor Green

} catch {
    Write-Host "`n[ERROR] $_" -ForegroundColor Red
    exit 1
}
