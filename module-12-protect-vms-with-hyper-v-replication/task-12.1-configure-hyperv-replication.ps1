<#
.SYNOPSIS
    Task 12.1 - Configure Hyper-V Replication

.DESCRIPTION
    Configure Hyper-V Replica for VM disaster recovery and business continuity.

.NOTES
    Module: Module 12 - Protect VMs with Hyper-V Replication
    Task: 12.1 - Configure Hyper-V Replication
    Prerequisites: Hyper-V role installed
    PowerShell Version: 5.1+
#>

#Requires -RunAsAdministrator

$ErrorActionPreference = 'Stop'
Write-Host "=== AZ-801 Module 12: Task 12.1 - Configure Hyper-V Replication ===" -ForegroundColor Cyan

function Write-Step { param([string]$Message); Write-Host "`n[STEP] $Message" -ForegroundColor Yellow }

try {
    Write-Step "Understanding Hyper-V Replica"
    Write-Host "  - Asynchronous replication for DR" -ForegroundColor White
    Write-Host "  - Block-level replication over HTTP/HTTPS" -ForegroundColor White
    Write-Host "  - Support for Kerberos and Certificate authentication" -ForegroundColor White
    Write-Host "  - Recovery points: 15 min to 24 hours" -ForegroundColor White

    Write-Step "Enable Hyper-V Replica on Server"
    Write-Host @"
  # Configure as replica server
  Set-VMReplicationServer -ReplicationEnabled `$true ``
      -AllowedAuthenticationType Kerberos ``
      -KerberosAuthenticationPort 80 ``
      -ReplicationAllowedFromAnyServer `$true ``
      -DefaultStorageLocation 'D:\ReplicaStorage'
  
  # Or use certificate authentication (more secure)
  Set-VMReplicationServer -ReplicationEnabled `$true ``
      -AllowedAuthenticationType Certificate ``
      -CertificateAuthenticationPort 443 ``
      -CertificateThumbprint '1234567890ABCDEF...' ``
      -DefaultStorageLocation 'D:\ReplicaStorage'
  
  # View configuration
  Get-VMReplicationServer
"@ -ForegroundColor Gray

    Write-Step "Configure Firewall for Replication"
    Write-Host @"
  # Enable firewall rules for HTTP (Kerberos)
  Enable-NetFirewallRule -DisplayName 'Hyper-V Replica HTTP Listener (TCP-In)'
  
  # Or for HTTPS (Certificate)
  Enable-NetFirewallRule -DisplayName 'Hyper-V Replica HTTPS Listener (TCP-In)'
  
  # Verify firewall rules
  Get-NetFirewallRule -DisplayName '*Hyper-V Replica*' | Format-Table Name, Enabled
"@ -ForegroundColor Gray

    Write-Step "Configure Replication Authorization"
    Write-Host @"
  # Add authorization entry (allow specific servers)
  New-VMReplicationAuthorizationEntry ``
      -AllowedPrimaryServer '*.contoso.com' ``
      -ReplicaStorageLocation 'D:\ReplicaStorage' ``
      -TrustGroup 'Production'
  
  # View authorization entries
  Get-VMReplicationAuthorizationEntry
  
  # Remove authorization
  Remove-VMReplicationAuthorizationEntry -AllowedPrimaryServer '*.contoso.com'
"@ -ForegroundColor Gray

    Write-Step "Test Replication Connectivity"
    Write-Host @"
  # Test connectivity to replica server
  Test-NetConnection -ComputerName REPLICA-SERVER -Port 80  # or 443 for HTTPS
  
  # Verify Hyper-V Replica service
  Get-Service vmms
  
  # Check event logs
  Get-WinEvent -LogName 'Microsoft-Windows-Hyper-V-VMMS-Admin' -MaxEvents 20 |
      Where-Object Message -like '*replica*'
"@ -ForegroundColor Gray

    Write-Step "Replication Best Practices"
    Write-Host "  1. Use certificate authentication for internet scenarios" -ForegroundColor White
    Write-Host "  2. Separate replication network from production" -ForegroundColor White
    Write-Host "  3. Use compression for WAN replication" -ForegroundColor White
    Write-Host "  4. Plan storage capacity (replica = 2x VM size)" -ForegroundColor White
    Write-Host "  5. Test failover regularly" -ForegroundColor White
    Write-Host "  6. Monitor replication health" -ForegroundColor White
    Write-Host "  7. Use extended replication for 3-site DR" -ForegroundColor White

    Write-Host "`n" + "="*80 -ForegroundColor Cyan
    Write-Host "[SUCCESS] Hyper-V Replication Configuration Complete" -ForegroundColor Green

} catch {
    Write-Host "`n[ERROR] $_" -ForegroundColor Red
    exit 1
}
