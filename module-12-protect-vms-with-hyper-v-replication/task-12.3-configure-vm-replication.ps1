<#
.SYNOPSIS
    Task 12.3 - Configure VM Replication

.DESCRIPTION
    Enable and configure replication for specific virtual machines.

.NOTES
    Module: Module 12 - Protect VMs with Hyper-V Replication
    Task: 12.3 - Configure VM Replication
    Prerequisites: Hyper-V Replica configured, VMs running
    PowerShell Version: 5.1+
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param([string]$VMName = "TestVM", [string]$ReplicaServer = "REPLICA-HV01")

$ErrorActionPreference = 'Stop'
Write-Host "=== AZ-801 Module 12: Task 12.3 - Configure VM Replication ===" -ForegroundColor Cyan

function Write-Step { param([string]$Message); Write-Host "`n[STEP] $Message" -ForegroundColor Yellow }

try {
    Write-Step "Enable Replication for VM"
    Write-Host @"
  # Enable replication with basic settings
  Enable-VMReplication -VMName '$VMName' ``
      -ReplicaServerName '$ReplicaServer' ``
      -ReplicaServerPort 80 ``
      -AuthenticationType Kerberos ``
      -CompressionEnabled `$true ``
      -RecoveryHistory 24  # Keep 24 hourly recovery points
  
  # With certificate authentication
  Enable-VMReplication -VMName '$VMName' ``
      -ReplicaServerName '$ReplicaServer' ``
      -ReplicaServerPort 443 ``
      -AuthenticationType Certificate ``
      -CertificateThumbprint 'THUMBPRINT' ``
      -CompressionEnabled `$true
  
  # Exclude specific VHDs from replication
  Enable-VMReplication -VMName '$VMName' ``
      -ReplicaServerName '$ReplicaServer' ``
      -ReplicaServerPort 80 ``
      -AuthenticationType Kerberos ``
      -ExcludedVhd 'C:\VMs\TestVM\TempDisk.vhdx'
"@ -ForegroundColor Gray

    Write-Step "Start Initial Replication"
    Write-Host @"
  # Start initial replication immediately (over network)
  Start-VMInitialReplication -VMName '$VMName'
  
  # Schedule initial replication for off-hours
  Start-VMInitialReplication -VMName '$VMName' ``
      -DestinationPath '\\REPLICA-HV01\Replicas' ``
      -InitialReplicationStartTime (Get-Date).AddHours(8)
  
  # Use external media for initial replication (large VMs)
  Start-VMInitialReplication -VMName '$VMName' ``
      -UseBackup ``
      -InitialReplicationExportLocation 'E:\InitialReplica'
  # Then copy to replica server and import
  
  # Monitor initial replication
  Get-VMReplication -VMName '$VMName' | Format-List Name, State, Health, LastReplicationTime
"@ -ForegroundColor Gray

    Write-Step "Configure Replication Settings"
    Write-Host @"
  # Change replication frequency
  Set-VMReplication -VMName '$VMName' -ReplicationFrequencySec 300  # 5 minutes
  # Options: 30, 300, 900 (30 sec, 5 min, 15 min)
  
  # Change recovery history
  Set-VMReplication -VMName '$VMName' -RecoveryHistory 12  # 12 hourly points
  
  # Enable VSS snapshots for app-consistent recovery
  Set-VMReplication -VMName '$VMName' -VSSSnapshotFrequencyHour 4
  
  # Modify compression
  Set-VMReplication -VMName '$VMName' -CompressionEnabled `$false
"@ -ForegroundColor Gray

    Write-Step "Extended Replication (3-Site DR)"
    Write-Host @"
  # Configure extended replication (replica to 3rd site)
  # On the replica server:
  Enable-VMReplication -VMName '$VMName' ``
      -ReplicaServerName 'EXTENDED-HV01' ``
      -ReplicaServerPort 80 ``
      -AuthenticationType Kerberos ``
      -AsReplica  # Mark as extended replica
  
  Start-VMInitialReplication -VMName '$VMName' -AsReplica
"@ -ForegroundColor Gray

    Write-Step "Monitor VM Replication"
    Write-Host @"
  # View replication status
  Get-VMReplication -VMName '$VMName'
  
  # View replication statistics
  Measure-VMReplication -VMName '$VMName'
  
  # View recovery points
  Get-VMSnapshot -VMName '$VMName' | Where-Object SnapshotType -eq 'Replica'
  
  # Test replication health
  Test-VMReplication -VMName '$VMName'
"@ -ForegroundColor Gray

    Write-Host "`n" + "="*80 -ForegroundColor Cyan
    Write-Host "[SUCCESS] VM Replication Configuration Complete" -ForegroundColor Green

} catch {
    Write-Host "`n[ERROR] $_" -ForegroundColor Red
    exit 1
}
