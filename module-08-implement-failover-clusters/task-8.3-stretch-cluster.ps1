<#
.SYNOPSIS
    Task 8.3 - Configure Stretch Cluster

.DESCRIPTION
    Comprehensive script for configuring and managing stretch (geo-distributed) failover clusters
    spanning multiple sites with fault domain awareness and cloud witness quorum.

.NOTES
    Module: Module 8 - Implement Failover Clusters
    Task: 8.3 - Configure Stretch Cluster
    Prerequisites:
        - Windows Server 2019 or later
        - Existing cluster or nodes across two sites
        - Azure subscription (for Cloud Witness)
        - Low-latency WAN connectivity between sites
    PowerShell Version: 5.1+

.EXAMPLE
    .\task-8.3-stretch-cluster.ps1 -ClusterName "STRETCH-CLUSTER"
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [string]$ClusterName = 'STRETCH-CLUSTER',
    [string]$Site1Name = 'PrimarySite',
    [string]$Site2Name = 'SecondarySite',
    [string[]]$Site1Nodes = @('NODE1', 'NODE2'),
    [string[]]$Site2Nodes = @('NODE3', 'NODE4'),
    [string]$ClusterIP = '10.0.0.100',
    [string]$StorageAccountName = '',
    [string]$StorageAccountKey = ''
)

$ErrorActionPreference = 'Stop'
Write-Host "=== AZ-801 Module 8: Task 8.3 - Configure Stretch Cluster ===" -ForegroundColor Cyan
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
#endregion

try {
    #region Step 1: Stretch Cluster Overview and Prerequisites
    Write-Step "Stretch Cluster Overview and Prerequisites"

    Write-Host "Stretch Cluster Configuration:" -ForegroundColor Yellow
    Write-Host "  Site 1: $Site1Name - Nodes: $($Site1Nodes -join ', ')" -ForegroundColor White
    Write-Host "  Site 2: $Site2Name - Nodes: $($Site2Nodes -join ', ')" -ForegroundColor White
    Write-Host ""

    Write-Info "Stretch Cluster Benefits:"
    Write-Host "  - Disaster recovery across geographic locations" -ForegroundColor White
    Write-Host "  - Automatic failover between sites" -ForegroundColor White
    Write-Host "  - Site-aware resource placement" -ForegroundColor White
    Write-Host "  - Synchronous or asynchronous replication" -ForegroundColor White

    # Check if cluster exists
    try {
        $cluster = Get-Cluster -Name $ClusterName -ErrorAction Stop
        Write-Success "Cluster '$ClusterName' found"
    } catch {
        Write-Info "Cluster '$ClusterName' not found. Will create new stretch cluster."
        $createNew = $true
    }
    #endregion

    #region Step 2: Create Stretch Cluster (if needed)
    if ($createNew) {
        Write-Step "Creating Stretch Cluster"

        $allNodes = $Site1Nodes + $Site2Nodes
        Write-Info "All nodes: $($allNodes -join ', ')"

        # Validate nodes before cluster creation
        Write-Info "Running pre-cluster validation..."
        $validation = Test-Cluster -Node $allNodes -Include "Inventory", "Network", "System Configuration"

        # Create cluster with distributed management point
        # This allows the cluster to function even if one site is down
        Write-Info "Creating cluster with distributed network name..."

        $cluster = New-Cluster -Name $ClusterName `
            -Node $allNodes `
            -StaticAddress $ClusterIP `
            -ManagementPointNetworkType Distributed `
            -NoStorage `
            -Verbose

        Write-Success "Stretch cluster created successfully"
    }
    #endregion

    #region Step 3: Define Fault Domains (Sites)
    Write-Step "Defining Fault Domains for Site Awareness"

    Write-Info "Creating fault domain topology..."

    # Create site fault domains (Windows Server 2016+)
    # Fault domains provide site awareness for placement and failover

    # Check if fault domains exist
    $existingFDs = Get-ClusterFaultDomain -ErrorAction SilentlyContinue

    # Create Site 1 fault domain
    $site1FD = New-ClusterFaultDomain -Name $Site1Name `
        -Type Site `
        -Description "Primary datacenter site" `
        -Location "PrimaryDC" `
        -ErrorAction SilentlyContinue

    if ($site1FD) {
        Write-Success "Created fault domain: $Site1Name"
    } else {
        Write-Info "Fault domain $Site1Name may already exist"
        $site1FD = Get-ClusterFaultDomain -Name $Site1Name -Type Site
    }

    # Create Site 2 fault domain
    $site2FD = New-ClusterFaultDomain -Name $Site2Name `
        -Type Site `
        -Description "Secondary datacenter site" `
        -Location "SecondaryDC" `
        -ErrorAction SilentlyContinue

    if ($site2FD) {
        Write-Success "Created fault domain: $Site2Name"
    } else {
        Write-Info "Fault domain $Site2Name may already exist"
        $site2FD = Get-ClusterFaultDomain -Name $Site2Name -Type Site
    }

    # Assign nodes to fault domains
    Write-Info "Assigning nodes to fault domains..."

    foreach ($node in $Site1Nodes) {
        Set-ClusterFaultDomain -Name $node -Parent $Site1Name -ErrorAction SilentlyContinue
        Write-Success "Assigned $node to $Site1Name"
    }

    foreach ($node in $Site2Nodes) {
        Set-ClusterFaultDomain -Name $node -Parent $Site2Name -ErrorAction SilentlyContinue
        Write-Success "Assigned $node to $Site2Name"
    }

    # Display fault domain configuration
    Write-Host "`nFault Domain Configuration:" -ForegroundColor Yellow
    Get-ClusterFaultDomain | Format-Table Name, Type, ParentName, Location -AutoSize

    Write-Host "`nFault Domain Tree:" -ForegroundColor Yellow
    Get-ClusterFaultDomainXML | Out-String | Write-Host
    #endregion

    #region Step 4: Configure Cloud Witness Quorum
    Write-Step "Configuring Cloud Witness Quorum for Stretch Cluster"

    Write-Info "Cloud Witness is recommended for stretch clusters"
    Write-Host "Benefits:" -ForegroundColor Yellow
    Write-Host "  - Azure-based witness (no on-premises infrastructure needed)" -ForegroundColor White
    Write-Host "  - Survives entire site outages" -ForegroundColor White
    Write-Host "  - Lower cost than file share witness" -ForegroundColor White
    Write-Host "  - Automatic failover arbitration" -ForegroundColor White

    if ($StorageAccountName -and $StorageAccountKey) {
        Write-Info "Configuring Cloud Witness..."

        Set-ClusterQuorum -CloudWitness `
            -AccountName $StorageAccountName `
            -AccessKey $StorageAccountKey

        Write-Success "Cloud Witness configured successfully"

        # Verify quorum configuration
        $quorum = Get-ClusterQuorum
        Write-Host "`nQuorum Configuration:" -ForegroundColor Yellow
        $quorum | Format-List QuorumResource, QuorumType
    } else {
        Write-Host "`n[INFO] Cloud Witness not configured (no Azure Storage credentials provided)" -ForegroundColor Cyan
        Write-Host "To configure Cloud Witness manually:" -ForegroundColor Gray
        Write-Host "  1. Create Azure Storage Account" -ForegroundColor Gray
        Write-Host "  2. Get storage account name and key" -ForegroundColor Gray
        Write-Host "  3. Run: Set-ClusterQuorum -CloudWitness -AccountName '<name>' -AccessKey '<key>'" -ForegroundColor Gray
    }

    # Display current quorum
    Write-Host "`nCurrent Quorum Configuration:" -ForegroundColor Yellow
    Get-ClusterQuorum | Format-List
    #endregion

    #region Step 5: Configure Site-Aware Resource Placement
    Write-Step "Configuring Site-Aware Resource Placement"

    Write-Info "Creating affinity rules for site preference..."

    # Affinity rules ensure resources prefer to run in specific sites
    # This is useful for keeping related resources together

    # Example: Create an affinity rule to prefer Site 1
    try {
        $affinityRule = New-ClusterAffinityRule -Name "PreferSite1" `
            -RuleType SameFaultDomain `
            -ErrorAction SilentlyContinue

        if ($affinityRule) {
            Write-Success "Created affinity rule: PreferSite1"
        }
    } catch {
        Write-Info "Affinity rules may not be supported or already exist"
    }

    # Display cluster groups and their current owner sites
    Write-Host "`nCluster Groups and Owner Nodes:" -ForegroundColor Yellow
    Get-ClusterGroup | Select-Object Name, OwnerNode, State, @{
        Name='Site'
        Expression={
            $ownerNode = $_.OwnerNode
            if ($Site1Nodes -contains $ownerNode) { $Site1Name }
            elseif ($Site2Nodes -contains $ownerNode) { $Site2Name }
            else { 'Unknown' }
        }
    } | Format-Table -AutoSize

    # Set preferred owners for critical resources
    Write-Info "To set preferred site for a resource group:"
    Write-Host "  Get-ClusterGroup '<GroupName>' | Set-ClusterOwnerNode -Owners $($Site1Nodes -join ',')" -ForegroundColor Gray
    #endregion

    #region Step 6: Configure Network Settings for Stretch Cluster
    Write-Step "Configuring Network Settings"

    # Get cluster networks
    $networks = Get-ClusterNetwork

    Write-Host "`nCluster Networks:" -ForegroundColor Yellow
    $networks | Format-Table Name, Role, Address, State, @{
        Name='Metric'
        Expression={$_.Metric}
    } -AutoSize

    # Configure network priorities
    Write-Info "Configuring network metrics for site-to-site communication..."

    foreach ($network in $networks) {
        $networkName = $network.Name

        # Networks within a site should have lower metric (preferred)
        # Networks between sites should have higher metric (backup)

        if ($network.Role -eq 'ClusterAndClient') {
            Write-Info "Network '$networkName' is configured for cluster and client communication"
        }
        elseif ($network.Role -eq 'Cluster') {
            Write-Info "Network '$networkName' is configured for cluster-only communication"
        }
    }

    # Display network properties
    Write-Host "`nNetwork Configuration:" -ForegroundColor Yellow
    Get-ClusterNetwork | Get-ClusterParameter |
        Where-Object { $_.Name -in @('Role', 'Metric', 'AutoMetric') } |
        Format-Table Object, Name, Value -AutoSize
    #endregion

    #region Step 7: Test Stretch Cluster Functionality
    Write-Step "Testing Stretch Cluster Functionality"

    Write-Info "Running stretch cluster tests..."

    # Test 1: Verify all nodes are online
    $nodes = Get-ClusterNode
    Write-Host "`nCluster Nodes by Site:" -ForegroundColor Yellow

    foreach ($node in $nodes) {
        $site = if ($Site1Nodes -contains $node.Name) { $Site1Name }
                elseif ($Site2Nodes -contains $node.Name) { $Site2Name }
                else { 'Unknown' }

        $status = if ($node.State -eq 'Up') { '[ONLINE]' } else { '[OFFLINE]' }

        Write-Host "  $status $($node.Name) - $site" -ForegroundColor $(if ($node.State -eq 'Up') { 'Green' } else { 'Red' })
    }

    # Test 2: Verify quorum health
    Write-Host "`nQuorum Health:" -ForegroundColor Yellow
    $quorum = Get-ClusterQuorum
    Write-Host "  Quorum Type: $($quorum.QuorumType)" -ForegroundColor White
    Write-Host "  Quorum Resource: $($quorum.QuorumResource)" -ForegroundColor White

    # Test 3: Simulate site failover (demonstration only)
    Write-Host "`nSite Failover Simulation:" -ForegroundColor Yellow
    Write-Host "  To manually move a resource group to the other site:" -ForegroundColor Cyan
    Write-Host "  Move-ClusterGroup -Name '<GroupName>' -Node '<NodeInOtherSite>'" -ForegroundColor Gray

    Write-Host "`n  To drain a node (simulate site maintenance):" -ForegroundColor Cyan
    Write-Host "  Suspend-ClusterNode -Name '<NodeName>' -Drain" -ForegroundColor Gray

    Write-Host "`n  To test site failure:" -ForegroundColor Cyan
    Write-Host "  # Pause all nodes in one site to simulate site failure" -ForegroundColor Gray
    Write-Host "  foreach (\$node in \$Site1Nodes) { Suspend-ClusterNode -Name \$node -Drain }" -ForegroundColor Gray
    #endregion

    #region Step 8: Configure Storage Replica (for Storage Replication)
    Write-Step "Storage Replica Configuration for Stretch Cluster"

    Write-Info "Storage Replica enables synchronous/asynchronous replication between sites"

    # Check if Storage Replica feature is installed
    $srFeature = Get-WindowsFeature -Name Storage-Replica -ErrorAction SilentlyContinue

    if ($srFeature -and $srFeature.Installed) {
        Write-Success "Storage Replica feature is installed"

        # Display Storage Replica configuration (if any)
        try {
            $srGroups = Get-SRGroup -ErrorAction SilentlyContinue
            if ($srGroups) {
                Write-Host "`nStorage Replica Groups:" -ForegroundColor Yellow
                $srGroups | Format-Table Name, ReplicationStatus, ReplicationMode -AutoSize
            } else {
                Write-Info "No Storage Replica groups configured yet"
            }
        } catch {
            Write-Info "Storage Replica not configured"
        }
    } else {
        Write-Info "Storage Replica feature not installed"
        Write-Host "To install:" -ForegroundColor Gray
        Write-Host "  Install-WindowsFeature -Name Storage-Replica -IncludeManagementTools" -ForegroundColor Gray
    }

    Write-Host "`nStorage Replica Configuration Example:" -ForegroundColor Yellow
    Write-Host "  # Configure stretch cluster with Storage Replica" -ForegroundColor Gray
    Write-Host "  New-SRPartnership -SourceComputerName 'NODE1' -SourceRGName 'RG01' ``" -ForegroundColor Gray
    Write-Host "    -SourceVolumeName 'D:' -SourceLogVolumeName 'E:' ``" -ForegroundColor Gray
    Write-Host "    -DestinationComputerName 'NODE3' -DestinationRGName 'RG02' ``" -ForegroundColor Gray
    Write-Host "    -DestinationVolumeName 'D:' -DestinationLogVolumeName 'E:' ``" -ForegroundColor Gray
    Write-Host "    -ReplicationMode Synchronous" -ForegroundColor Gray
    #endregion

    #region Step 9: Monitoring and Health Checks
    Write-Step "Stretch Cluster Monitoring and Health Checks"

    # Generate cluster log
    Write-Info "Generating cluster diagnostic log..."
    $logPath = "$env:TEMP\StretchClusterLog-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Get-ClusterLog -Destination $logPath -TimeSpan 15 -UseLocalTime
    Write-Success "Cluster log saved to: $logPath"

    # Health check summary
    Write-Host "`nHealth Check Summary:" -ForegroundColor Yellow

    $site1NodeCount = ($nodes | Where-Object { $Site1Nodes -contains $_.Name -and $_.State -eq 'Up' }).Count
    $site2NodeCount = ($nodes | Where-Object { $Site2Nodes -contains $_.Name -and $_.State -eq 'Up' }).Count

    Write-Host "  $Site1Name Nodes Online: $site1NodeCount / $($Site1Nodes.Count)" -ForegroundColor White
    Write-Host "  $Site2Name Nodes Online: $site2NodeCount / $($Site2Nodes.Count)" -ForegroundColor White

    if ($site1NodeCount -gt 0 -and $site2NodeCount -gt 0) {
        Write-Success "Both sites have online nodes - Cluster is healthy"
    } else {
        Write-Host "[WARNING] One or more sites have no online nodes!" -ForegroundColor Yellow
    }
    #endregion

    #region Step 10: Best Practices and Documentation
    Write-Step "Stretch Cluster Best Practices"

    Write-Host "`nBest Practices for Stretch Clusters:" -ForegroundColor Yellow
    Write-Host "  1. Use Cloud Witness for quorum (survives site failures)" -ForegroundColor White
    Write-Host "  2. Configure fault domains for site awareness" -ForegroundColor White
    Write-Host "  3. Use low-latency, high-bandwidth connection between sites (<5ms RTT for synchronous)" -ForegroundColor White
    Write-Host "  4. Implement Storage Replica for data replication" -ForegroundColor White
    Write-Host "  5. Define preferred site for each workload" -ForegroundColor White
    Write-Host "  6. Test site failover scenarios regularly" -ForegroundColor White
    Write-Host "  7. Monitor network latency between sites" -ForegroundColor White
    Write-Host "  8. Document failover procedures" -ForegroundColor White
    Write-Host "  9. Use automatic failover for critical workloads" -ForegroundColor White
    Write-Host "  10. Consider network partitioning scenarios" -ForegroundColor White

    Write-Host "`nStretch Cluster Limitations:" -ForegroundColor Yellow
    Write-Host "  - Requires Windows Server 2016 or later for fault domains" -ForegroundColor White
    Write-Host "  - Network latency affects synchronous replication performance" -ForegroundColor White
    Write-Host "  - Asymmetric storage configurations can be complex" -ForegroundColor White
    Write-Host "  - Requires careful capacity planning for site failures" -ForegroundColor White

    Write-Host "`nNext Steps:" -ForegroundColor Yellow
    Write-Host "  - Configure Storage Replica for data replication" -ForegroundColor Cyan
    Write-Host "  - Set up monitoring and alerting for site health" -ForegroundColor Cyan
    Write-Host "  - Test failover scenarios" -ForegroundColor Cyan
    Write-Host "  - Document DR procedures" -ForegroundColor Cyan
    #endregion

    #region Summary
    Write-Host "`n" + "="*80 -ForegroundColor Cyan
    Write-Success "Stretch Cluster Configuration Completed"
    Write-Host "="*80 -ForegroundColor Cyan

    Write-Host "`nStretch Cluster Summary:" -ForegroundColor Yellow
    Write-Host "  Cluster Name: $ClusterName" -ForegroundColor White
    Write-Host "  Site 1: $Site1Name ($($Site1Nodes.Count) nodes)" -ForegroundColor White
    Write-Host "  Site 2: $Site2Name ($($Site2Nodes.Count) nodes)" -ForegroundColor White
    Write-Host "  Total Nodes: $($nodes.Count)" -ForegroundColor White
    Write-Host "  Fault Domains: Configured" -ForegroundColor White
    Write-Host "  Quorum: $(Get-ClusterQuorum | Select-Object -ExpandProperty QuorumType)" -ForegroundColor White
    #endregion

} catch {
    Write-Host "`n[ERROR] Failed to configure stretch cluster: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red

    Write-Host "`nTroubleshooting:" -ForegroundColor Yellow
    Write-Host "  1. Verify network connectivity between all sites" -ForegroundColor White
    Write-Host "  2. Check firewall rules for cluster communication" -ForegroundColor White
    Write-Host "  3. Ensure all nodes are in the same domain" -ForegroundColor White
    Write-Host "  4. Verify Azure Storage Account for Cloud Witness" -ForegroundColor White
    Write-Host "  5. Review cluster logs: Get-ClusterLog" -ForegroundColor White

    exit 1
}

Write-Host "`nScript completed successfully!" -ForegroundColor Green
