<#
.SYNOPSIS
    Task 8.6 - Configure Cluster Network Adapters

.DESCRIPTION
    Comprehensive script for configuring and managing cluster network adapters,
    network roles, metrics, and network teaming for failover clusters.

.NOTES
    Module: Module 8 - Implement Failover Clusters
    Task: 8.6 - Configure Cluster Network Adapters
    Prerequisites:
        - Existing failover cluster
        - Multiple network adapters on each node
        - Administrative privileges
    PowerShell Version: 5.1+

.EXAMPLE
    .\task-8.6-cluster-network-adapters.ps1
#>

#Requires -RunAsAdministrator

$ErrorActionPreference = 'Stop'
Write-Host "=== AZ-801 Module 8: Task 8.6 - Configure Cluster Network Adapters ===" -ForegroundColor Cyan
Write-Host ""

#region Helper Functions
function Write-Step {
    param([string]$Message)
    Write-Host "`n[STEP] $Message" -ForegroundColor Yellow
    Write-Host ("-" * 80) -ForegroundColor Gray
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Cyan
}

function Get-NetworkRoleName {
    param([int]$Role)
    switch ($Role) {
        0 { "None (Disabled)" }
        1 { "Cluster Only" }
        2 { "Client Only" }
        3 { "Cluster and Client" }
        default { "Unknown" }
    }
}
#endregion

try {
    #region Step 1: Understanding Cluster Networks
    Write-Step "Understanding Cluster Network Configuration"

    Write-Host "Cluster Network Roles:" -ForegroundColor Yellow
    Write-Host "  0 = None: Network not used by cluster" -ForegroundColor White
    Write-Host "  1 = Cluster Only: Heartbeat and cluster communication only" -ForegroundColor White
    Write-Host "  2 = Client Only: Client access only (not used)" -ForegroundColor White
    Write-Host "  3 = Cluster and Client: Both heartbeat and client access (default)" -ForegroundColor White

    Write-Host "`nBest Practices:" -ForegroundColor Yellow
    Write-Host "  - Separate heartbeat network from client/storage traffic" -ForegroundColor White
    Write-Host "  - Use network teaming for redundancy" -ForegroundColor White
    Write-Host "  - Configure appropriate metrics for network priorities" -ForegroundColor White
    Write-Host "  - Use dedicated networks for Storage (CSV, iSCSI, SMB)" -ForegroundColor White

    # Get cluster
    $cluster = Get-Cluster
    Write-Info "Cluster: $($cluster.Name)"
    #endregion

    #region Step 2: Display Current Network Configuration
    Write-Step "Current Cluster Network Configuration"

    # Get cluster networks
    $networks = Get-ClusterNetwork

    Write-Host "`nCluster Networks:" -ForegroundColor Yellow
    $networks | Select-Object Name, @{
        Name='Role'
        Expression={Get-NetworkRoleName -Role $_.Role}
    }, State, Address, AddressMask, Metric, AutoMetric | Format-Table -AutoSize

    # Detailed view
    Write-Host "`nDetailed Network Information:" -ForegroundColor Yellow
    foreach ($network in $networks) {
        Write-Host "`nNetwork: $($network.Name)" -ForegroundColor Cyan
        Write-Host "  Role: $(Get-NetworkRoleName -Role $network.Role)" -ForegroundColor White
        Write-Host "  State: $($network.State)" -ForegroundColor $(if ($network.State -eq 'Up') { 'Green' } else { 'Red' })
        Write-Host "  Subnet: $($network.Address)/$($network.AddressMask)" -ForegroundColor White
        Write-Host "  Metric: $($network.Metric)" -ForegroundColor White
        Write-Host "  Auto Metric: $($network.AutoMetric)" -ForegroundColor White
    }
    #endregion

    #region Step 3: Network Adapters on Cluster Nodes
    Write-Step "Network Adapters on Cluster Nodes"

    $nodes = Get-ClusterNode

    foreach ($node in $nodes) {
        Write-Host "`nNode: $($node.Name)" -ForegroundColor Yellow

        try {
            $adapters = Get-NetAdapter -CimSession $node.Name -ErrorAction Stop

            $adapters | Select-Object Name, InterfaceDescription, Status, LinkSpeed, @{
                Name='IP'
                Expression={(Get-NetIPAddress -InterfaceIndex $_.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue).IPAddress}
            } | Format-Table -AutoSize

        } catch {
            Write-Host "  Unable to query network adapters: $_" -ForegroundColor Yellow
        }
    }
    #endregion

    #region Step 4: Configure Network Roles
    Write-Step "Configuring Cluster Network Roles"

    Write-Host "Network Role Configuration Examples:" -ForegroundColor Yellow

    Write-Host "`nExample 1: Dedicated Heartbeat Network" -ForegroundColor Cyan
    Write-Host "  # Set a network for cluster heartbeat only (recommended)" -ForegroundColor Gray
    Write-Host "  (Get-ClusterNetwork 'Cluster Network 1').Role = 1" -ForegroundColor Gray

    Write-Host "`nExample 2: Client and Cluster Network" -ForegroundColor Cyan
    Write-Host "  # Default configuration for production network" -ForegroundColor Gray
    Write-Host "  (Get-ClusterNetwork 'Cluster Network 2').Role = 3" -ForegroundColor Gray

    Write-Host "`nExample 3: Disable Network for Cluster" -ForegroundColor Cyan
    Write-Host "  # Prevent cluster from using a specific network" -ForegroundColor Gray
    Write-Host "  (Get-ClusterNetwork 'Management Network').Role = 0" -ForegroundColor Gray

    Write-Host "`nRecommended Configuration:" -ForegroundColor Yellow
    Write-Host "  1. Production/Client: Role = 3 (Cluster and Client)" -ForegroundColor White
    Write-Host "  2. Heartbeat: Role = 1 (Cluster Only)" -ForegroundColor White
    Write-Host "  3. Storage (iSCSI/SMB): Role = 0 or 3 depending on architecture" -ForegroundColor White
    Write-Host "  4. Management: Role = 0 (if separate from production)" -ForegroundColor White

    # Interactive configuration
    Write-Host "`nCurrent Networks:" -ForegroundColor Yellow
    $networkList = @()
    $i = 1
    foreach ($network in $networks) {
        Write-Host "  [$i] $($network.Name) - Role: $(Get-NetworkRoleName -Role $network.Role)" -ForegroundColor White
        $networkList += $network
        $i++
    }
    #endregion

    #region Step 5: Configure Network Metrics
    Write-Step "Configuring Network Metrics (Priority)"

    Write-Host "Network Metric Overview:" -ForegroundColor Yellow
    Write-Host "  - Lower metric = higher priority" -ForegroundColor White
    Write-Host "  - Cluster uses lowest metric network first" -ForegroundColor White
    Write-Host "  - Default: Auto-calculated based on link speed" -ForegroundColor White
    Write-Host "  - Manual: Set specific priorities for networks" -ForegroundColor White

    Write-Host "`nCurrent Network Metrics:" -ForegroundColor Yellow
    $networks | Select-Object Name, Metric, AutoMetric, @{
        Name='Priority'
        Expression={
            switch ($_.Metric) {
                {$_ -lt 1000} { "Highest" }
                {$_ -lt 5000} { "High" }
                {$_ -lt 10000} { "Medium" }
                default { "Low" }
            }
        }
    } | Format-Table -AutoSize

    Write-Host "`nMetric Configuration Examples:" -ForegroundColor Yellow

    Write-Host "`nExample 1: Set High Priority for Heartbeat Network" -ForegroundColor Cyan
    Write-Host "  \$network = Get-ClusterNetwork 'Heartbeat'" -ForegroundColor Gray
    Write-Host "  \$network.Metric = 100" -ForegroundColor Gray

    Write-Host "`nExample 2: Set Medium Priority for Production Network" -ForegroundColor Cyan
    Write-Host "  \$network = Get-ClusterNetwork 'Production'" -ForegroundColor Gray
    Write-Host "  \$network.Metric = 1000" -ForegroundColor Gray

    Write-Host "`nExample 3: Disable Auto Metric" -ForegroundColor Cyan
    Write-Host "  \$network = Get-ClusterNetwork 'Storage'" -ForegroundColor Gray
    Write-Host "  \$network.AutoMetric = 0" -ForegroundColor Gray
    Write-Host "  \$network.Metric = 5000" -ForegroundColor Gray

    Write-Host "`nRecommended Metrics:" -ForegroundColor Yellow
    Write-Host "  1. Heartbeat Network: 100-500 (highest priority)" -ForegroundColor White
    Write-Host "  2. Production/Client: 1000-2000" -ForegroundColor White
    Write-Host "  3. Storage Network: 3000-5000" -ForegroundColor White
    Write-Host "  4. Backup Network: 10000+ (lowest priority)" -ForegroundColor White
    #endregion

    #region Step 6: Network Teaming (NIC Teaming)
    Write-Step "Network Teaming Configuration"

    Write-Host "NIC Teaming Benefits:" -ForegroundColor Yellow
    Write-Host "  - Network redundancy" -ForegroundColor White
    Write-Host "  - Increased bandwidth" -ForegroundColor White
    Write-Host "  - Automatic failover" -ForegroundColor White
    Write-Host "  - Load balancing" -ForegroundColor White

    # Check for network teams on each node
    foreach ($node in $nodes) {
        Write-Host "`nNetwork Teams on $($node.Name):" -ForegroundColor Yellow

        try {
            $teams = Get-NetLbfoTeam -CimSession $node.Name -ErrorAction SilentlyContinue

            if ($teams) {
                $teams | Format-Table Name, TeamingMode, LoadBalancingAlgorithm, Status -AutoSize

                foreach ($team in $teams) {
                    $members = Get-NetLbfoTeamMember -Team $team.Name -CimSession $node.Name
                    Write-Host "  Members: $($members.Name -join ', ')" -ForegroundColor White
                }
            } else {
                Write-Info "No network teams configured on $($node.Name)"
            }
        } catch {
            Write-Info "Unable to query network teams: $_"
        }
    }

    Write-Host "`nNIC Teaming Configuration Example:" -ForegroundColor Yellow
    Write-Host "  # Create a new team" -ForegroundColor Gray
    Write-Host "  New-NetLbfoTeam -Name 'ClusterTeam' ``" -ForegroundColor Gray
    Write-Host "    -TeamMembers 'Ethernet 1','Ethernet 2' ``" -ForegroundColor Gray
    Write-Host "    -TeamingMode SwitchIndependent ``" -ForegroundColor Gray
    Write-Host "    -LoadBalancingAlgorithm Dynamic" -ForegroundColor Gray

    Write-Host "`nTeaming Modes:" -ForegroundColor Yellow
    Write-Host "  - SwitchIndependent: No switch configuration required (recommended)" -ForegroundColor White
    Write-Host "  - LACP: IEEE 802.3ad Link Aggregation (requires switch support)" -ForegroundColor White
    Write-Host "  - Static: Manual switch configuration" -ForegroundColor White

    Write-Host "`nLoad Balancing Algorithms:" -ForegroundColor Yellow
    Write-Host "  - Dynamic: Best for mixed workloads (recommended)" -ForegroundColor White
    Write-Host "  - HyperVPort: Best for Hyper-V workloads" -ForegroundColor White
    Write-Host "  - TransportPorts: Hash-based on IP/Port" -ForegroundColor White
    #endregion

    #region Step 7: Test Cluster Network Communication
    Write-Step "Testing Cluster Network Communication"

    Write-Info "Running network validation tests..."

    # Test cluster network connectivity
    Write-Host "`nCluster Network Health:" -ForegroundColor Yellow

    foreach ($network in $networks) {
        $status = $network.State
        $color = if ($status -eq 'Up') { 'Green' } else { 'Red' }

        Write-Host "  $($network.Name): $status" -ForegroundColor $color

        if ($status -ne 'Up') {
            Write-Host "    [WARNING] Network is not operational!" -ForegroundColor Yellow
        }
    }

    # Run cluster validation for networks
    Write-Host "`nTo run comprehensive network validation:" -ForegroundColor Yellow
    Write-Host "  Test-Cluster -Include Network" -ForegroundColor Gray

    Write-Host "`nTo test network bandwidth:" -ForegroundColor Yellow
    Write-Host "  # On source node:" -ForegroundColor Gray
    Write-Host "  ntttcp -s" -ForegroundColor Gray
    Write-Host "  # On destination node:" -ForegroundColor Gray
    Write-Host "  ntttcp -r -m 4,*,<source-ip>" -ForegroundColor Gray
    #endregion

    #region Step 8: Network Performance Monitoring
    Write-Step "Network Performance Monitoring"

    Write-Info "Network performance counters..."

    Write-Host "`nKey Performance Counters:" -ForegroundColor Yellow
    Write-Host "  - Network Interface: Bytes Total/sec" -ForegroundColor White
    Write-Host "  - Network Interface: Packets/sec" -ForegroundColor White
    Write-Host "  - Network Interface: Output Queue Length" -ForegroundColor White
    Write-Host "  - TCPv4: Connection Failures" -ForegroundColor White

    Write-Host "`nMonitoring Commands:" -ForegroundColor Yellow
    Write-Host "  # Network statistics" -ForegroundColor Gray
    Write-Host "  Get-NetAdapterStatistics" -ForegroundColor Gray

    Write-Host "`n  # Real-time bandwidth usage" -ForegroundColor Gray
    Write-Host "  Get-Counter '\\Network Interface(*)\\Bytes Total/sec' -Continuous" -ForegroundColor Gray

    Write-Host "`n  # Cluster network events" -ForegroundColor Gray
    Write-Host "  Get-WinEvent -LogName 'Microsoft-Windows-FailoverClustering/Operational' | ``" -ForegroundColor Gray
    Write-Host "    Where-Object { \$_.Id -in @(1126,1127,1128,1129) }" -ForegroundColor Gray
    #endregion

    #region Step 9: Advanced Network Configuration
    Write-Step "Advanced Network Configuration"

    Write-Host "`nCluster Network Parameters:" -ForegroundColor Yellow

    # Display all cluster network parameters
    $networks | ForEach-Object {
        Write-Host "`nNetwork: $($_.Name)" -ForegroundColor Cyan
        $_ | Get-ClusterParameter | Format-Table Name, Value -AutoSize
    }

    Write-Host "`nAdvanced Configuration Options:" -ForegroundColor Yellow

    Write-Host "`n1. Live Migration Network Priority:" -ForegroundColor Cyan
    Write-Host "  Get-ClusterResourceType 'Virtual Machine' | ``" -ForegroundColor Gray
    Write-Host "    Set-ClusterParameter -Name MigrationNetworkOrder ``" -ForegroundColor Gray
    Write-Host "    -Value 'Cluster Network 1','Cluster Network 2'" -ForegroundColor Gray

    Write-Host "`n2. CSV Network Configuration:" -ForegroundColor Cyan
    Write-Host "  (Get-ClusterNetwork 'CSV Network').Metric = 3000" -ForegroundColor Gray

    Write-Host "`n3. Heartbeat Configuration:" -ForegroundColor Cyan
    Write-Host "  (Get-Cluster).SameSubnetDelay = 1000  # milliseconds" -ForegroundColor Gray
    Write-Host "  (Get-Cluster).SameSubnetThreshold = 5  # missed heartbeats" -ForegroundColor Gray
    Write-Host "  (Get-Cluster).CrossSubnetDelay = 1000" -ForegroundColor Gray
    Write-Host "  (Get-Cluster).CrossSubnetThreshold = 5" -ForegroundColor Gray

    Write-Host "`n4. Network Encryption (SMB):" -ForegroundColor Cyan
    Write-Host "  Set-SmbServerConfiguration -EncryptData \$true" -ForegroundColor Gray
    #endregion

    #region Step 10: Best Practices Summary
    Write-Step "Cluster Networking Best Practices"

    Write-Host "`nBest Practices:" -ForegroundColor Yellow
    Write-Host "  1. Use at least 2 network adapters per node (redundancy)" -ForegroundColor White
    Write-Host "  2. Separate heartbeat traffic from client/storage traffic" -ForegroundColor White
    Write-Host "  3. Configure dedicated storage networks (CSV, iSCSI, SMB)" -ForegroundColor White
    Write-Host "  4. Use NIC teaming for critical networks" -ForegroundColor White
    Write-Host "  5. Set appropriate network metrics/priorities" -ForegroundColor White
    Write-Host "  6. Use static IP addresses for cluster networks" -ForegroundColor White
    Write-Host "  7. Use separate VLANs for different network types" -ForegroundColor White
    Write-Host "  8. Monitor network performance regularly" -ForegroundColor White
    Write-Host "  9. Test network failover scenarios" -ForegroundColor White
    Write-Host "  10. Document network configuration" -ForegroundColor White

    Write-Host "`nRecommended Network Layout:" -ForegroundColor Yellow
    Write-Host "  Network 1: Production/Client (Role=3, Metric=1000, Teamed)" -ForegroundColor White
    Write-Host "  Network 2: Heartbeat (Role=1, Metric=100, Teamed)" -ForegroundColor White
    Write-Host "  Network 3: Storage/CSV (Role=0 or 3, Metric=3000, Teamed)" -ForegroundColor White
    Write-Host "  Network 4: Live Migration (Role=0, Metric=2000, Optional)" -ForegroundColor White

    Write-Host "`nFirewall Ports for Clustering:" -ForegroundColor Yellow
    Write-Host "  - UDP 3343: Cluster Network Driver" -ForegroundColor White
    Write-Host "  - TCP 445: SMB (CSV, file shares)" -ForegroundColor White
    Write-Host "  - RPC Dynamic Ports: 49152-65535" -ForegroundColor White
    Write-Host "  - ICMP: Allow (for network health checks)" -ForegroundColor White
    #endregion

    #region Summary
    Write-Host "`n" + "="*80 -ForegroundColor Cyan
    Write-Success "Cluster Network Configuration Review Completed"
    Write-Host "="*80 -ForegroundColor Cyan

    Write-Host "`nNetwork Summary:" -ForegroundColor Yellow
    Write-Host "  Cluster: $($cluster.Name)" -ForegroundColor White
    Write-Host "  Networks: $($networks.Count)" -ForegroundColor White
    Write-Host "  Nodes: $($nodes.Count)" -ForegroundColor White

    $upNetworks = ($networks | Where-Object { $_.State -eq 'Up' }).Count
    Write-Host "  Networks Online: $upNetworks / $($networks.Count)" -ForegroundColor $(if ($upNetworks -eq $networks.Count) { 'Green' } else { 'Yellow' })
    #endregion

} catch {
    Write-Host "`n[ERROR] Failed to configure cluster networks: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red

    Write-Host "`nTroubleshooting:" -ForegroundColor Yellow
    Write-Host "  1. Verify cluster service is running" -ForegroundColor White
    Write-Host "  2. Check network adapter status on all nodes" -ForegroundColor White
    Write-Host "  3. Verify network connectivity between nodes" -ForegroundColor White
    Write-Host "  4. Check firewall settings" -ForegroundColor White
    Write-Host "  5. Review cluster logs: Get-ClusterLog" -ForegroundColor White

    exit 1
}

Write-Host "`nScript completed successfully!" -ForegroundColor Green
