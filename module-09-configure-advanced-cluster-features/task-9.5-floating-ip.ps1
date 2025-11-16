<#
.SYNOPSIS
    Task 9.5 - Configure Floating IP Resources

.DESCRIPTION
    Comprehensive script for configuring cluster IP address resources and dependencies.
    Covers virtual IP configuration, network name resources, and client access points.

.NOTES
    Module: Module 9 - Configure Advanced Cluster Features
    Task: 9.5 - Configure Floating IP Resources
    Prerequisites:
        - Failover Clustering configured
        - Cluster networks configured
        - Administrative privileges
    PowerShell Version: 5.1+

.EXAMPLE
    .\task-9.5-floating-ip.ps1
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [string]$ResourceGroupName = "WebService",
    [string]$IPResourceName = "Web-IP",
    [string]$IPAddress = "192.168.1.50",
    [string]$NetworkName = "WebServer"
)

$ErrorActionPreference = 'Stop'
Write-Host "=== AZ-801 Module 9: Task 9.5 - Configure Floating IP Resources ===" -ForegroundColor Cyan
Write-Host ""

#region Helper Functions
function Write-Step {
    param([string]$Message)
    Write-Host "`n[STEP] $Message" -ForegroundColor Yellow
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Cyan
}
#endregion

try {
    #region Step 1: Understanding Cluster IP Resources
    Write-Step "Understanding Cluster IP Resources"

    Write-Info "Cluster IP resources provide:"
    Write-Host "  - Virtual IP addresses that move with cluster groups" -ForegroundColor White
    Write-Host "  - Client access points for cluster services" -ForegroundColor White
    Write-Host "  - Automatic failover of network identity" -ForegroundColor White
    Write-Host "  - Foundation for Network Name resources" -ForegroundColor White

    Write-Host "`nCommon Use Cases:" -ForegroundColor Yellow
    Write-Host "  - SQL Server failover cluster instances" -ForegroundColor White
    Write-Host "  - File server clusters" -ForegroundColor White
    Write-Host "  - Web application clusters" -ForegroundColor White
    Write-Host "  - Custom cluster applications" -ForegroundColor White
    #endregion

    #region Step 2: View Cluster Networks
    Write-Step "Viewing Cluster Network Configuration"

    if (Get-Command Get-ClusterNetwork -ErrorAction SilentlyContinue) {
        Write-Host "`nCluster Networks:" -ForegroundColor Yellow
        $networks = Get-ClusterNetwork
        $networks | Format-Table Name, Role, State, Address, AddressMask, Metric -AutoSize

        Write-Host "`nNetwork Roles:" -ForegroundColor Yellow
        Write-Host "  - ClusterAndClient (3): Both cluster and client traffic" -ForegroundColor White
        Write-Host "  - ClusterOnly (1): Cluster heartbeat only" -ForegroundColor White
        Write-Host "  - None (0): Disabled for cluster use" -ForegroundColor White
    } else {
        Write-Info "Failover Clustering cmdlets not available"
        $networks = @()
    }
    #endregion

    #region Step 3: Create IP Address Resource
    Write-Step "Creating IP Address Resource"

    Write-Host "`nCreate IP Address Resource:" -ForegroundColor Yellow
    Write-Host @"
  # Create resource group for the application
  Add-ClusterGroup -Name '$ResourceGroupName' -GroupType GenericService

  # Add IP Address resource
  Add-ClusterResource -Name '$IPResourceName' ``
      -ResourceType 'IP Address' ``
      -Group '$ResourceGroupName'

  # Configure IP parameters
  Get-ClusterResource -Name '$IPResourceName' | Set-ClusterParameter -Multiple @{
      Address = '$IPAddress'
      SubnetMask = '255.255.255.0'
      Network = 'Cluster Network 1'
      EnableDhcp = 0
  }

  # Bring IP resource online
  Start-ClusterResource -Name '$IPResourceName'

  # Verify configuration
  Get-ClusterResource -Name '$IPResourceName' | Get-ClusterParameter
"@ -ForegroundColor Gray

    # Display existing IP resources
    if ($networks.Count -gt 0) {
        $ipResources = Get-ClusterResource | Where-Object ResourceType -eq 'IP Address'
        if ($ipResources) {
            Write-Host "`nExisting IP Address Resources:" -ForegroundColor Yellow
            foreach ($ip in $ipResources) {
                $params = Get-ClusterParameter -InputObject $ip
                $address = ($params | Where-Object Name -eq 'Address').Value
                Write-Host "`n  Resource: $($ip.Name)" -ForegroundColor Cyan
                Write-Host "    State: $($ip.State)" -ForegroundColor White
                Write-Host "    Group: $($ip.OwnerGroup)" -ForegroundColor White
                Write-Host "    Address: $address" -ForegroundColor White
            }
        }
    }
    #endregion

    #region Step 4: Create Network Name Resource
    Write-Step "Creating Network Name Resource"

    Write-Host "`nNetwork Name (Client Access Point):" -ForegroundColor Yellow
    Write-Host @"
  # Add Network Name resource
  Add-ClusterResource -Name '$NetworkName' ``
      -ResourceType 'Network Name' ``
      -Group '$ResourceGroupName'

  # Configure network name
  Get-ClusterResource -Name '$NetworkName' | Set-ClusterParameter -Name Name -Value 'WEBCLUSTER'

  # Create dependency on IP address
  Add-ClusterResourceDependency -Resource '$NetworkName' -Provider '$IPResourceName'

  # Bring network name online
  Start-ClusterResource -Name '$NetworkName'

  # Verify DNS registration
  nslookup WEBCLUSTER
  ping WEBCLUSTER
"@ -ForegroundColor Gray

    Write-Host "`nNetwork Name Features:" -ForegroundColor Yellow
    Write-Host "  - Automatic DNS registration" -ForegroundColor White
    Write-Host "  - Computer object in Active Directory" -ForegroundColor White
    Write-Host "  - Kerberos authentication support" -ForegroundColor White
    Write-Host "  - Client connectivity via name instead of IP" -ForegroundColor White
    #endregion

    #region Step 5: Resource Dependencies
    Write-Step "Configuring Resource Dependencies"

    Write-Info "Dependencies ensure proper startup order"

    Write-Host "`nDependency Chain:" -ForegroundColor Yellow
    Write-Host @"
  IP Address Resource
      ↓
  Network Name Resource (depends on IP Address)
      ↓
  Application/Service Resource (depends on Network Name)
"@ -ForegroundColor White

    Write-Host "`nConfiguring Dependencies:" -ForegroundColor Yellow
    Write-Host @"
  # View current dependencies
  Get-ClusterResourceDependency -Resource '$NetworkName'

  # Add dependency
  Add-ClusterResourceDependency -Resource '$NetworkName' -Provider '$IPResourceName'

  # Set complex dependency (AND/OR logic)
  Set-ClusterResourceDependency -Resource 'MyApp' -Dependency '[$NetworkName]'

  # OR dependency (alternate IPs)
  Set-ClusterResourceDependency -Resource 'MyApp' -Dependency '[IP1] or [IP2]'

  # Remove dependency
  Remove-ClusterResourceDependency -Resource '$NetworkName' -Provider '$IPResourceName'
"@ -ForegroundColor Gray
    #endregion

    #region Step 6: IPv4 and IPv6 Configuration
    Write-Step "Configuring IPv4 and IPv6 Resources"

    Write-Host "`nDual-Stack Configuration:" -ForegroundColor Yellow
    Write-Host @"
  # IPv4 Address
  Add-ClusterResource -Name 'IPv4-Address' -ResourceType 'IP Address' -Group '$ResourceGroupName'
  Get-ClusterResource -Name 'IPv4-Address' | Set-ClusterParameter -Multiple @{
      Address = '192.168.1.50'
      SubnetMask = '255.255.255.0'
      Network = 'Cluster Network 1'
  }

  # IPv6 Address (if needed)
  Add-ClusterResource -Name 'IPv6-Address' -ResourceType 'IPv6 Address' -Group '$ResourceGroupName'
  Get-ClusterResource -Name 'IPv6-Address' | Set-ClusterParameter -Multiple @{
      Address = 'fe80::1234:5678:9abc:def0'
      Network = 'Cluster Network 1'
  }

  # Network name depends on both
  Set-ClusterResourceDependency -Resource '$NetworkName' -Dependency '[IPv4-Address] and [IPv6-Address]'
"@ -ForegroundColor Gray
    #endregion

    #region Step 7: DHCP vs Static IP
    Write-Step "DHCP vs Static IP Configuration"

    Write-Host "`nStatic IP (Recommended):" -ForegroundColor Yellow
    Write-Host @"
  # Configure static IP
  Get-ClusterResource -Name '$IPResourceName' | Set-ClusterParameter -Multiple @{
      Address = '$IPAddress'
      SubnetMask = '255.255.255.0'
      EnableDhcp = 0
  }
"@ -ForegroundColor Gray

    Write-Host "`nDHCP IP (Not Recommended for Production):" -ForegroundColor Yellow
    Write-Host @"
  # Configure DHCP
  Get-ClusterResource -Name '$IPResourceName' | Set-ClusterParameter EnableDhcp 1

  # Note: DHCP requires DHCP server with reservation to ensure consistent IP
"@ -ForegroundColor Gray

    Write-Host "`nBest Practice: Use static IP addresses for cluster resources" -ForegroundColor Cyan
    #endregion

    #region Step 8: Multiple IP Addresses
    Write-Step "Configuring Multiple IP Addresses"

    Write-Host "`nMulti-Site or Multi-Subnet Clusters:" -ForegroundColor Yellow
    Write-Host @"
  # Site A IP Address
  Add-ClusterResource -Name 'IP-SiteA' -ResourceType 'IP Address' -Group '$ResourceGroupName'
  Get-ClusterResource -Name 'IP-SiteA' | Set-ClusterParameter -Multiple @{
      Address = '10.1.1.50'
      SubnetMask = '255.255.255.0'
      Network = 'Site A Network'
  }

  # Site B IP Address
  Add-ClusterResource -Name 'IP-SiteB' -ResourceType 'IP Address' -Group '$ResourceGroupName'
  Get-ClusterResource -Name 'IP-SiteB' | Set-ClusterParameter -Multiple @{
      Address = '10.2.1.50'
      SubnetMask = '255.255.255.0'
      Network = 'Site B Network'
  }

  # Network name uses OR dependency (works with either IP)
  Set-ClusterResourceDependency -Resource '$NetworkName' -Dependency '[IP-SiteA] or [IP-SiteB]'

  # Only the IP in the active site will be online
"@ -ForegroundColor Gray
    #endregion

    #region Step 9: Troubleshooting IP Resources
    Write-Step "Troubleshooting Cluster IP Resources"

    Write-Host "`nCommon Issues and Solutions:" -ForegroundColor Yellow

    Write-Host "`n1. IP Address Conflict:" -ForegroundColor Cyan
    Write-Host @"
  # Check for IP conflicts
  Test-NetConnection -ComputerName $IPAddress

  # Verify IP is available before configuring
  ping $IPAddress

  # Check cluster event logs
  Get-WinEvent -LogName 'Microsoft-Windows-FailoverClustering/Operational' ``
      -MaxEvents 50 | Where-Object Message -like '*IP Address*'
"@ -ForegroundColor Gray

    Write-Host "`n2. Network Name Registration Issues:" -ForegroundColor Cyan
    Write-Host @"
  # Check DNS registration
  nslookup WEBCLUSTER

  # Check AD computer object
  Get-ADComputer -Identity WEBCLUSTER

  # Force DNS registration
  Stop-ClusterResource -Name '$NetworkName'
  Start-ClusterResource -Name '$NetworkName'

  # Check permissions (Cluster Name Object needs permissions)
"@ -ForegroundColor Gray

    Write-Host "`n3. Resource Won't Come Online:" -ForegroundColor Cyan
    Write-Host @"
  # Check resource state
  Get-ClusterResource -Name '$IPResourceName'

  # View resource parameters
  Get-ClusterResource -Name '$IPResourceName' | Get-ClusterParameter

  # Check dependencies
  Get-ClusterResourceDependency -Resource '$NetworkName'

  # Review cluster log
  Get-ClusterLog -TimeSpan 15 -Destination C:\Temp
"@ -ForegroundColor Gray
    #endregion

    #region Step 10: Testing and Validation
    Write-Step "Testing Cluster IP Resources"

    Write-Host "`nValidation Tests:" -ForegroundColor Yellow
    Write-Host @"
  # Test IP connectivity
  ping $IPAddress

  # Test name resolution
  nslookup $NetworkName

  # Test failover
  Move-ClusterGroup -Name '$ResourceGroupName' -Node 'NODE2'

  # Verify IP moves with group
  ping $IPAddress  # Should continue to respond

  # Check which node owns the IP
  Get-ClusterGroup -Name '$ResourceGroupName' | Select-Object Name, OwnerNode

  # Monitor resource during failover
  while (`$true) {
      Get-ClusterResource -Name '$IPResourceName' | Select-Object Name, State, OwnerNode
      Start-Sleep -Seconds 2
  }
"@ -ForegroundColor Gray
    #endregion

    #region Step 11: Best Practices
    Write-Step "Cluster IP Resource Best Practices"

    Write-Host "`nBest Practices:" -ForegroundColor Yellow
    Write-Host "  1. Use static IP addresses (not DHCP)" -ForegroundColor White
    Write-Host "  2. Document all cluster IP addresses" -ForegroundColor White
    Write-Host "  3. Reserve IPs in IPAM/documentation" -ForegroundColor White
    Write-Host "  4. Use appropriate cluster network for IP resources" -ForegroundColor White
    Write-Host "  5. Configure proper resource dependencies" -ForegroundColor White
    Write-Host "  6. Ensure cluster name object has permissions for DNS/AD" -ForegroundColor White
    Write-Host "  7. Use OR dependencies for multi-subnet clusters" -ForegroundColor White
    Write-Host "  8. Test failover scenarios regularly" -ForegroundColor White
    Write-Host "  9. Monitor IP resource health" -ForegroundColor White
    Write-Host "  10. Keep IP configurations consistent across sites" -ForegroundColor White

    Write-Host "`nNetwork Planning:" -ForegroundColor Yellow
    Write-Host "  - Separate cluster and client networks when possible" -ForegroundColor White
    Write-Host "  - Use dedicated VLANs for cluster traffic" -ForegroundColor White
    Write-Host "  - Plan IP addressing scheme before deployment" -ForegroundColor White
    Write-Host "  - Consider multi-subnet clusters for geographic distribution" -ForegroundColor White

    Write-Host "`nSecurity Considerations:" -ForegroundColor Yellow
    Write-Host "  - Limit access to cluster management networks" -ForegroundColor White
    Write-Host "  - Use IPsec for cluster communications (if required)" -ForegroundColor White
    Write-Host "  - Ensure proper firewall rules for cluster IPs" -ForegroundColor White
    Write-Host "  - Monitor for unauthorized IP address changes" -ForegroundColor White
    #endregion

    #region Summary
    Write-Host "`n" + "="*80 -ForegroundColor Cyan
    Write-Success "Cluster IP Resource Configuration Completed"
    Write-Host "="*80 -ForegroundColor Cyan

    Write-Host "`nConfiguration Summary:" -ForegroundColor Yellow
    Write-Host "  IP Address: $IPAddress" -ForegroundColor White
    Write-Host "  Network Name: $NetworkName" -ForegroundColor White
    Write-Host "  Resource Group: $ResourceGroupName" -ForegroundColor White

    if ($networks.Count -gt 0) {
        Write-Host "`nCluster Networks Available: $(($networks | Measure-Object).Count)" -ForegroundColor White
    }

    Write-Host "`nNext Steps:" -ForegroundColor Yellow
    Write-Host "  - Create IP address resources for your applications" -ForegroundColor Cyan
    Write-Host "  - Configure network name resources with proper dependencies" -ForegroundColor Cyan
    Write-Host "  - Test failover scenarios" -ForegroundColor Cyan
    Write-Host "  - Proceed to Module 10: Manage and Maintain Clusters" -ForegroundColor Cyan
    #endregion

} catch {
    Write-Host "`n[ERROR] Failed to configure cluster IP resources: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

Write-Host "`nScript completed successfully!" -ForegroundColor Green
