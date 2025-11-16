<#
.SYNOPSIS
    Task 12.2 - Manage Hyper-V Replica Servers

.DESCRIPTION
    Manage and maintain Hyper-V Replica server configurations and settings.

.NOTES
    Module: Module 12 - Protect VMs with Hyper-V Replication
    Task: 12.2 - Manage Replica Servers
    Prerequisites: Hyper-V Replica configured
    PowerShell Version: 5.1+
#>

#Requires -RunAsAdministrator

$ErrorActionPreference = 'Stop'
Write-Host "=== AZ-801 Module 12: Task 12.2 - Manage Replica Servers ===" -ForegroundColor Cyan

function Write-Step { param([string]$Message); Write-Host "`n[STEP] $Message" -ForegroundColor Yellow }

try {
    Write-Step "View Replica Server Configuration"
    Write-Host @"
  # Get replica server settings
  Get-VMReplicationServer | Format-List *
  
  # View authentication settings
  (Get-VMReplicationServer).AllowedAuthenticationType
  
  # View storage locations
  (Get-VMReplicationServer).DefaultStorageLocation
"@ -ForegroundColor Gray

    Write-Step "Modify Replica Server Settings"
    Write-Host @"
  # Change storage location
  Set-VMReplicationServer -DefaultStorageLocation 'E:\ReplicaVMs'
  
  # Change replication port
  Set-VMReplicationServer -KerberosAuthenticationPort 8080
  
  # Enable compression (reduces bandwidth usage)
  Set-VMReplicationServer -CertificateAuthenticationPort 443 ``
      -CertificateThumbprint 'THUMBPRINT'
"@ -ForegroundColor Gray

    Write-Step "Manage Authorization Entries"
    Write-Host @"
  # List all authorization entries
  Get-VMReplicationAuthorizationEntry | Format-Table AllowedPrimaryServer, TrustGroup
  
  # Add authorization for specific servers
  New-VMReplicationAuthorizationEntry ``
      -AllowedPrimaryServer 'PRIMARY-HV01.contoso.com' ``
      -ReplicaStorageLocation 'D:\Replicas\HV01' ``
      -TrustGroup 'ProdServers'
  
  # Add wildcard authorization
  New-VMReplicationAuthorizationEntry ``
      -AllowedPrimaryServer '*.contoso.com' ``
      -ReplicaStorageLocation 'D:\Replicas' ``
      -TrustGroup 'AllServers'
  
  # Remove authorization
  Remove-VMReplicationAuthorizationEntry -AllowedPrimaryServer 'PRIMARY-HV01.contoso.com'
"@ -ForegroundColor Gray

    Write-Step "Monitor Replication Health"
    Write-Host @"
  # View all replica VMs
  Get-VMReplication | Format-Table Name, State, Health, PrimaryServer
  
  # Check replication statistics
  Measure-VMReplication | Format-Table VMName, AvgRplSize, PendingReplicationSize
  
  # View replication health
  Get-VMReplication | Where-Object Health -ne 'Normal'
  
  # Get detailed statistics
  Get-VMReplication | Format-List Name, State, Health, LastReplicationTime
"@ -ForegroundColor Gray

    Write-Step "Troubleshooting Replication"
    Write-Host @"
  # Resynchronize VM
  Resume-VMReplication -VMName VM1 -Resynchronize
  
  # Reset replication statistics
  Reset-VMReplicationStatistics -VMName VM1
  
  # View replication errors
  Get-WinEvent -LogName 'Microsoft-Windows-Hyper-V-VMMS-Admin' |
      Where-Object {`$_.Id -eq 32022 -or `$_.Id -eq 32032}
  
  # Remove broken replication
  Remove-VMReplication -VMName VM1
"@ -ForegroundColor Gray

    Write-Host "`n" + "="*80 -ForegroundColor Cyan
    Write-Host "[SUCCESS] Replica Server Management Complete" -ForegroundColor Green

} catch {
    Write-Host "`n[ERROR] $_" -ForegroundColor Red
    exit 1
}
