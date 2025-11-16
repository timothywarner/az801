<#
.SYNOPSIS
    Task 8.5 - Configure Quorum Options

.DESCRIPTION
    Comprehensive script for configuring and managing cluster quorum settings including
    disk witness, file share witness, cloud witness, and node majority configurations.

.NOTES
    Module: Module 8 - Implement Failover Clusters
    Task: 8.5 - Configure Quorum Options
    Prerequisites:
        - Existing failover cluster
        - Administrative privileges
        - Azure Storage Account (for Cloud Witness)
    PowerShell Version: 5.1+

.EXAMPLE
    .\task-8.5-quorum-options.ps1 -QuorumType CloudWitness
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [ValidateSet('NodeMajority', 'NodeAndDiskMajority', 'NodeAndFileShareMajority', 'CloudWitness', 'Auto')]
    [string]$QuorumType = 'Auto',
    [string]$WitnessPath = '',
    [string]$AzureStorageAccountName = '',
    [string]$AzureStorageAccountKey = ''
)

$ErrorActionPreference = 'Stop'
Write-Host "=== AZ-801 Module 8: Task 8.5 - Configure Quorum Options ===" -ForegroundColor Cyan
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

function Get-RecommendedQuorum {
    param([int]$NodeCount)

    if ($NodeCount % 2 -eq 1) {
        # Odd number of nodes
        return "NodeMajority"
    } else {
        # Even number of nodes
        return "NodeAndWitnessM ajority (Disk, File Share, or Cloud)"
    }
}
#endregion

try {
    #region Step 1: Understanding Quorum
    Write-Step "Understanding Cluster Quorum"

    Write-Host "Quorum Overview:" -ForegroundColor Yellow
    Write-Host "  Quorum determines the number of failures a cluster can sustain while remaining online" -ForegroundColor White
    Write-Host "  Prevents 'split-brain' scenarios where multiple partitions run independently" -ForegroundColor White
    Write-Host "  Requires a majority of voting members to keep the cluster running" -ForegroundColor White

    Write-Host "`nQuorum Voting Formula:" -ForegroundColor Yellow
    Write-Host "  Votes Needed = (Total Votes / 2) + 1" -ForegroundColor White
    Write-Host "  Example: 5 nodes = need 3 votes minimum" -ForegroundColor White

    # Get current cluster information
    $cluster = Get-Cluster
    $nodes = Get-ClusterNode
    $nodeCount = $nodes.Count

    Write-Host "`nCurrent Cluster:" -ForegroundColor Yellow
    Write-Host "  Name: $($cluster.Name)" -ForegroundColor White
    Write-Host "  Nodes: $nodeCount" -ForegroundColor White
    Write-Host "  Recommended Quorum: $(Get-RecommendedQuorum -NodeCount $nodeCount)" -ForegroundColor White
    #endregion

    #region Step 2: Current Quorum Configuration
    Write-Step "Current Quorum Configuration"

    $currentQuorum = Get-ClusterQuorum

    Write-Host "Current Quorum Settings:" -ForegroundColor Yellow
    $currentQuorum | Format-List Cluster, QuorumResource, QuorumType

    # Get node votes
    Write-Host "`nNode Voting Configuration:" -ForegroundColor Yellow
    $nodes | Select-Object Name, State, NodeWeight, @{
        Name='HasVote'
        Expression={if ($_.NodeWeight -gt 0) { 'Yes' } else { 'No' }}
    }, Id | Format-Table -AutoSize

    # Calculate current votes
    $totalVotes = ($nodes | Measure-Object -Property NodeWeight -Sum).Sum
    if ($currentQuorum.QuorumResource) {
        $totalVotes += 1  # Add witness vote
    }
    $votesNeeded = [Math]::Floor($totalVotes / 2) + 1

    Write-Host "`nQuorum Vote Summary:" -ForegroundColor Yellow
    Write-Host "  Total Possible Votes: $totalVotes" -ForegroundColor White
    Write-Host "  Votes Needed for Quorum: $votesNeeded" -ForegroundColor White
    Write-Host "  Current Active Votes: $(($nodes | Where-Object { $_.State -eq 'Up' } | Measure-Object -Property NodeWeight -Sum).Sum)" -ForegroundColor White
    #endregion

    #region Step 3: Quorum Type Options
    Write-Step "Available Quorum Types"

    Write-Host "`n1. Node Majority (No Witness):" -ForegroundColor Cyan
    Write-Host "  - Best for: ODD number of nodes (3, 5, 7)" -ForegroundColor White
    Write-Host "  - Votes: Each node = 1 vote" -ForegroundColor White
    Write-Host "  - Survives: (N-1)/2 node failures" -ForegroundColor White
    Write-Host "  - Example: 5 nodes can lose 2 nodes" -ForegroundColor White

    Write-Host "`n2. Node and Disk Majority:" -ForegroundColor Cyan
    Write-Host "  - Best for: EVEN number of nodes with shared storage" -ForegroundColor White
    Write-Host "  - Votes: Each node + witness disk = 1 vote each" -ForegroundColor White
    Write-Host "  - Survives: Half of nodes if witness is available" -ForegroundColor White
    Write-Host "  - Requires: Dedicated small LUN for witness" -ForegroundColor White

    Write-Host "`n3. Node and File Share Majority:" -ForegroundColor Cyan
    Write-Host "  - Best for: EVEN number of nodes, multi-site, or no shared storage" -ForegroundColor White
    Write-Host "  - Votes: Each node + file share witness = 1 vote each" -ForegroundColor White
    Write-Host "  - Requires: SMB file share accessible by all nodes" -ForegroundColor White
    Write-Host "  - Location: File share should be in different failure domain" -ForegroundColor White

    Write-Host "`n4. Cloud Witness (Azure):" -ForegroundColor Cyan
    Write-Host "  - Best for: Any cluster, especially multi-site or Azure hybrid" -ForegroundColor White
    Write-Host "  - Votes: Each node + cloud witness = 1 vote each" -ForegroundColor White
    Write-Host "  - Requires: Azure Storage Account" -ForegroundColor White
    Write-Host "  - Benefits: No on-prem infrastructure, survives site failures" -ForegroundColor White
    Write-Host "  - Cost: Very low (pennies per month)" -ForegroundColor White

    Write-Host "`n5. Disk Only (Not Recommended):" -ForegroundColor Cyan
    Write-Host "  - Legacy mode, creates single point of failure" -ForegroundColor White
    Write-Host "  - Only use for 2-node clusters with specific requirements" -ForegroundColor White
    #endregion

    #region Step 4: Configure Node Majority
    if ($QuorumType -eq 'NodeMajority' -or ($QuorumType -eq 'Auto' -and $nodeCount % 2 -eq 1)) {
        Write-Step "Configuring Node Majority Quorum"

        Write-Info "Setting quorum to Node Majority..."
        Set-ClusterQuorum -NodeMajority

        Write-Success "Node Majority quorum configured"

        # Verify
        $newQuorum = Get-ClusterQuorum
        Write-Host "`nNew Quorum Configuration:" -ForegroundColor Yellow
        $newQuorum | Format-List QuorumType, QuorumResource
    }
    #endregion

    #region Step 5: Configure Disk Witness
    if ($QuorumType -eq 'NodeAndDiskMajority') {
        Write-Step "Configuring Node and Disk Majority Quorum"

        if (-not $WitnessPath) {
            # Try to find an available cluster disk
            $availableDisks = Get-ClusterResource | Where-Object {
                $_.ResourceType -eq 'Physical Disk' -and
                $_.OwnerGroup -eq 'Available Storage'
            }

            if ($availableDisks) {
                Write-Host "`nAvailable Disks for Witness:" -ForegroundColor Yellow
                $availableDisks | Format-Table Name, State, OwnerGroup -AutoSize

                $witnessResource = $availableDisks[0].Name
                Write-Info "Using disk: $witnessResource"
            } else {
                Write-Host "[WARNING] No available disk for witness. Please specify -WitnessPath" -ForegroundColor Yellow
                Write-Host "Available disks:" -ForegroundColor Yellow
                Get-ClusterResource | Where-Object { $_.ResourceType -eq 'Physical Disk' } |
                    Format-Table Name, State, OwnerGroup -AutoSize
                $witnessResource = $null
            }
        } else {
            $witnessResource = $WitnessPath
        }

        if ($witnessResource) {
            Write-Info "Configuring disk witness..."
            Set-ClusterQuorum -NodeAndDiskMajority $witnessResource

            Write-Success "Disk witness configured"

            # Verify
            $newQuorum = Get-ClusterQuorum
            Write-Host "`nNew Quorum Configuration:" -ForegroundColor Yellow
            $newQuorum | Format-List QuorumType, QuorumResource
        }
    }
    #endregion

    #region Step 6: Configure File Share Witness
    if ($QuorumType -eq 'NodeAndFileShareMajority') {
        Write-Step "Configuring Node and File Share Majority Quorum"

        if (-not $WitnessPath) {
            Write-Host "[INFO] File share path not provided" -ForegroundColor Cyan
            Write-Host "To configure file share witness, provide -WitnessPath parameter" -ForegroundColor Yellow
            Write-Host "Example: -WitnessPath '\\FileServer\WitnessShare'" -ForegroundColor Gray

            Write-Host "`nFile Share Witness Requirements:" -ForegroundColor Yellow
            Write-Host "  1. SMB file share accessible by all cluster nodes" -ForegroundColor White
            Write-Host "  2. Cluster Name Object (CNO) needs Full Control on share and NTFS" -ForegroundColor White
            Write-Host "  3. Share should be on different failure domain than cluster nodes" -ForegroundColor White
            Write-Host "  4. Minimum space required: ~1 MB" -ForegroundColor White

            Write-Host "`nTo create file share witness:" -ForegroundColor Gray
            Write-Host "  # On file server:" -ForegroundColor Gray
            Write-Host "  New-Item -Path 'C:\Shares\ClusterWitness' -ItemType Directory" -ForegroundColor Gray
            Write-Host "  New-SmbShare -Name 'ClusterWitness' -Path 'C:\Shares\ClusterWitness' -FullAccess 'Everyone'" -ForegroundColor Gray
            Write-Host "  # Grant cluster name object full control on NTFS permissions" -ForegroundColor Gray
        } else {
            Write-Info "Configuring file share witness at: $WitnessPath"

            try {
                Set-ClusterQuorum -NodeAndFileShareMajority $WitnessPath
                Write-Success "File share witness configured"

                # Verify
                $newQuorum = Get-ClusterQuorum
                Write-Host "`nNew Quorum Configuration:" -ForegroundColor Yellow
                $newQuorum | Format-List QuorumType, QuorumResource
            } catch {
                Write-Host "[ERROR] Failed to configure file share witness: $_" -ForegroundColor Red
                Write-Host "Please verify:" -ForegroundColor Yellow
                Write-Host "  - Share path is accessible: $WitnessPath" -ForegroundColor White
                Write-Host "  - Cluster name object has Full Control permissions" -ForegroundColor White
                Write-Host "  - Share exists and is online" -ForegroundColor White
            }
        }
    }
    #endregion

    #region Step 7: Configure Cloud Witness
    if ($QuorumType -eq 'CloudWitness') {
        Write-Step "Configuring Cloud Witness (Azure Storage Account)"

        Write-Info "Cloud Witness Benefits:"
        Write-Host "  - Highly available (Azure SLA)" -ForegroundColor White
        Write-Host "  - Geographic redundancy" -ForegroundColor White
        Write-Host "  - No on-premises infrastructure required" -ForegroundColor White
        Write-Host "  - Ideal for stretch/multi-site clusters" -ForegroundColor White
        Write-Host "  - Very low cost" -ForegroundColor White

        if (-not $AzureStorageAccountName -or -not $AzureStorageAccountKey) {
            Write-Host "`n[INFO] Azure Storage Account credentials not provided" -ForegroundColor Cyan

            Write-Host "`nTo configure Cloud Witness:" -ForegroundColor Yellow
            Write-Host "`n1. Create Azure Storage Account:" -ForegroundColor Cyan
            Write-Host "  - Sign in to Azure Portal" -ForegroundColor White
            Write-Host "  - Create new Storage Account (any region)" -ForegroundColor White
            Write-Host "  - Standard performance tier is sufficient" -ForegroundColor White
            Write-Host "  - LRS or GRS replication" -ForegroundColor White

            Write-Host "`n2. Get Access Key:" -ForegroundColor Cyan
            Write-Host "  - Navigate to Storage Account > Access Keys" -ForegroundColor White
            Write-Host "  - Copy 'Storage account name' and 'key1'" -ForegroundColor White

            Write-Host "`n3. Configure Cloud Witness:" -ForegroundColor Cyan
            Write-Host "  Set-ClusterQuorum -CloudWitness ``" -ForegroundColor Gray
            Write-Host "    -AccountName '<StorageAccountName>' ``" -ForegroundColor Gray
            Write-Host "    -AccessKey '<StorageAccountKey>'" -ForegroundColor Gray

            Write-Host "`nOr using PowerShell to create Azure resources:" -ForegroundColor Cyan
            Write-Host "  # Install Azure PowerShell if needed" -ForegroundColor Gray
            Write-Host "  Install-Module -Name Az -AllowClobber -Scope CurrentUser" -ForegroundColor Gray
            Write-Host "  Connect-AzAccount" -ForegroundColor Gray
            Write-Host "  New-AzStorageAccount -ResourceGroupName 'ClusterRG' ``" -ForegroundColor Gray
            Write-Host "    -Name 'clusterwitness' -Location 'EastUS' ``" -ForegroundColor Gray
            Write-Host "    -SkuName Standard_LRS -Kind StorageV2" -ForegroundColor Gray
            Write-Host "  \$key = (Get-AzStorageAccountKey -ResourceGroupName 'ClusterRG' ``" -ForegroundColor Gray
            Write-Host "    -Name 'clusterwitness')[0].Value" -ForegroundColor Gray
        } else {
            Write-Info "Configuring Cloud Witness with provided credentials..."

            try {
                Set-ClusterQuorum -CloudWitness `
                    -AccountName $AzureStorageAccountName `
                    -AccessKey $AzureStorageAccountKey

                Write-Success "Cloud Witness configured successfully!"

                # Verify
                $newQuorum = Get-ClusterQuorum
                Write-Host "`nNew Quorum Configuration:" -ForegroundColor Yellow
                $newQuorum | Format-List QuorumType, QuorumResource

                Write-Info "Cloud Witness endpoint: $AzureStorageAccountName.blob.core.windows.net"
            } catch {
                Write-Host "[ERROR] Failed to configure Cloud Witness: $_" -ForegroundColor Red
                Write-Host "Please verify:" -ForegroundColor Yellow
                Write-Host "  - Storage account name is correct" -ForegroundColor White
                Write-Host "  - Access key is valid" -ForegroundColor White
                Write-Host "  - Cluster nodes can reach Azure (*.blob.core.windows.net)" -ForegroundColor White
                Write-Host "  - Firewall allows HTTPS (443) outbound" -ForegroundColor White
            }
        }
    }
    #endregion

    #region Step 8: Advanced Quorum Configuration
    Write-Step "Advanced Quorum Configuration"

    Write-Host "`nDynamic Quorum:" -ForegroundColor Yellow
    $dynamicQuorum = (Get-Cluster).DynamicQuorum
    Write-Host "  Status: $dynamicQuorum" -ForegroundColor White
    Write-Host "  - Automatically adjusts node votes based on membership" -ForegroundColor White
    Write-Host "  - Enabled by default in Windows Server 2012 R2+" -ForegroundColor White

    Write-Host "`nDynamic Witness:" -ForegroundColor Yellow
    try {
        $dynamicWitness = (Get-ClusterQuorum).DynamicWeight
        Write-Host "  Status: Enabled" -ForegroundColor White
    } catch {
        Write-Host "  Status: Not configured" -ForegroundColor White
    }
    Write-Host "  - Automatically adjusts witness vote based on node count" -ForegroundColor White

    Write-Host "`nNode Vote Management:" -ForegroundColor Yellow
    Write-Host "  To manually set node vote weight:" -ForegroundColor Gray
    Write-Host "  (Get-ClusterNode '<NodeName>').NodeWeight = 1  # 1 = has vote, 0 = no vote" -ForegroundColor Gray

    Write-Host "`nQuorum Management Commands:" -ForegroundColor Yellow
    Write-Host "  View: Get-ClusterQuorum" -ForegroundColor Gray
    Write-Host "  Node Majority: Set-ClusterQuorum -NodeMajority" -ForegroundColor Gray
    Write-Host "  Disk Witness: Set-ClusterQuorum -NodeAndDiskMajority '<DiskResource>'" -ForegroundColor Gray
    Write-Host "  File Share: Set-ClusterQuorum -NodeAndFileShareMajority '\\\\server\\share'" -ForegroundColor Gray
    Write-Host "  Cloud Witness: Set-ClusterQuorum -CloudWitness -AccountName '<name>' -AccessKey '<key>'" -ForegroundColor Gray
    #endregion

    #region Step 9: Testing Quorum Configuration
    Write-Step "Testing Quorum Configuration"

    Write-Info "Quorum test scenarios..."

    Write-Host "`nCurrent Configuration:" -ForegroundColor Yellow
    $testQuorum = Get-ClusterQuorum
    Write-Host "  Quorum Type: $($testQuorum.QuorumType)" -ForegroundColor White
    Write-Host "  Witness: $($testQuorum.QuorumResource)" -ForegroundColor White

    # Calculate failure tolerance
    $upNodes = ($nodes | Where-Object { $_.State -eq 'Up' }).Count
    $hasWitness = if ($testQuorum.QuorumResource) { 1 } else { 0 }
    $totalVotes = $upNodes + $hasWitness
    $votesNeeded = [Math]::Floor($totalVotes / 2) + 1
    $maxFailures = $upNodes - $votesNeeded

    Write-Host "`nFailure Tolerance:" -ForegroundColor Yellow
    Write-Host "  Current Online Nodes: $upNodes" -ForegroundColor White
    Write-Host "  Witness Vote: $hasWitness" -ForegroundColor White
    Write-Host "  Total Votes: $totalVotes" -ForegroundColor White
    Write-Host "  Votes Needed: $votesNeeded" -ForegroundColor White
    Write-Host "  Maximum Node Failures Tolerated: $maxFailures" -ForegroundColor $(if ($maxFailures -gt 0) { 'Green' } else { 'Yellow' })

    Write-Host "`nTo test quorum manually:" -ForegroundColor Cyan
    Write-Host "  1. Stop a node: Stop-Computer -ComputerName '<NodeName>'" -ForegroundColor Gray
    Write-Host "  2. Check cluster health: Get-ClusterNode" -ForegroundColor Gray
    Write-Host "  3. Verify resources still running: Get-ClusterGroup" -ForegroundColor Gray
    Write-Host "  4. Start node: Start-Computer -ComputerName '<NodeName>'" -ForegroundColor Gray
    #endregion

    #region Step 10: Best Practices
    Write-Step "Quorum Configuration Best Practices"

    Write-Host "`nBest Practices:" -ForegroundColor Yellow
    Write-Host "  1. ODD nodes (3,5,7): Use Node Majority" -ForegroundColor White
    Write-Host "  2. EVEN nodes (2,4,6): Use witness (Disk, File Share, or Cloud)" -ForegroundColor White
    Write-Host "  3. Multi-site clusters: Use Cloud Witness or File Share in 3rd site" -ForegroundColor White
    Write-Host "  4. Azure/Hybrid: Use Cloud Witness" -ForegroundColor White
    Write-Host "  5. Keep Dynamic Quorum enabled (default)" -ForegroundColor White
    Write-Host "  6. Test failover scenarios before production" -ForegroundColor White
    Write-Host "  7. Monitor quorum health regularly" -ForegroundColor White
    Write-Host "  8. Document quorum configuration" -ForegroundColor White
    Write-Host "  9. Review after adding/removing nodes" -ForegroundColor White
    Write-Host "  10. Never use Disk Only quorum" -ForegroundColor White

    Write-Host "`nQuorum Configuration by Scenario:" -ForegroundColor Yellow
    Write-Host "  Single site, 3 nodes: Node Majority" -ForegroundColor White
    Write-Host "  Single site, 2 nodes: Node + Disk/FileShare/Cloud Witness" -ForegroundColor White
    Write-Host "  Multi-site, even nodes: Cloud Witness or FileShare in 3rd location" -ForegroundColor White
    Write-Host "  Multi-site, odd nodes: Node Majority or Cloud Witness" -ForegroundColor White
    Write-Host "  Disaster Recovery: Cloud Witness (survives site failure)" -ForegroundColor White
    #endregion

    #region Summary
    Write-Host "`n" + "="*80 -ForegroundColor Cyan
    Write-Success "Quorum Configuration Completed"
    Write-Host "="*80 -ForegroundColor Cyan

    $finalQuorum = Get-ClusterQuorum
    Write-Host "`nFinal Quorum Configuration:" -ForegroundColor Yellow
    Write-Host "  Cluster: $($finalQuorum.Cluster)" -ForegroundColor White
    Write-Host "  Quorum Type: $($finalQuorum.QuorumType)" -ForegroundColor White
    Write-Host "  Quorum Resource: $(if ($finalQuorum.QuorumResource) { $finalQuorum.QuorumResource } else { 'None' })" -ForegroundColor White
    Write-Host "  Node Count: $nodeCount" -ForegroundColor White
    Write-Host "  Dynamic Quorum: $((Get-Cluster).DynamicQuorum)" -ForegroundColor White
    #endregion

} catch {
    Write-Host "`n[ERROR] Failed to configure quorum: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red

    Write-Host "`nTroubleshooting:" -ForegroundColor Yellow
    Write-Host "  1. Verify cluster is online and healthy" -ForegroundColor White
    Write-Host "  2. Check witness resource is accessible" -ForegroundColor White
    Write-Host "  3. Verify permissions on witness (disk/share/Azure)" -ForegroundColor White
    Write-Host "  4. Review cluster logs: Get-ClusterLog" -ForegroundColor White
    Write-Host "  5. Check Event Viewer: FailoverClustering/Operational" -ForegroundColor White

    exit 1
}

Write-Host "`nScript completed successfully!" -ForegroundColor Green
