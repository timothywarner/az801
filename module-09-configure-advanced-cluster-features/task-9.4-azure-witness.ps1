<#
.SYNOPSIS
    Task 9.4 - Configure Azure Cloud Witness

.DESCRIPTION
    Comprehensive script for configuring Azure Storage as a cluster quorum witness.
    Cloud Witness provides a more reliable quorum option than file share witness,
    especially for multi-site and stretch clusters.

.NOTES
    Module: Module 9 - Configure Advanced Cluster Features
    Task: 9.4 - Configure Azure Cloud Witness
    Prerequisites:
        - Failover Clustering configured
        - Azure subscription and storage account
        - Internet connectivity from cluster nodes
        - Windows Server 2016 or later
    PowerShell Version: 5.1+

.EXAMPLE
    .\task-9.4-azure-witness.ps1
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [string]$StorageAccountName = "clustwitness",
    [string]$ResourceGroupName = "RG-Cluster",
    [string]$Location = "EastUS",
    [string]$StorageAccountKey = ""
)

$ErrorActionPreference = 'Stop'
Write-Host "=== AZ-801 Module 9: Task 9.4 - Configure Azure Cloud Witness ===" -ForegroundColor Cyan
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
    #region Step 1: Understanding Cloud Witness
    Write-Step "Understanding Azure Cloud Witness"

    Write-Info "Cloud Witness provides:"
    Write-Host "  - Azure Blob storage as quorum witness" -ForegroundColor White
    Write-Host "  - No need for additional file server infrastructure" -ForegroundColor White
    Write-Host "  - Ideal for multi-site and stretch clusters" -ForegroundColor White
    Write-Host "  - Automatic failover between Azure regions" -ForegroundColor White
    Write-Host "  - Cost-effective (minimal storage usage)" -ForegroundColor White

    Write-Host "`nCloud Witness vs File Share Witness:" -ForegroundColor Yellow
    Write-Host "  File Share: Requires file server, single point of failure" -ForegroundColor White
    Write-Host "  Cloud Witness: Uses Azure, globally redundant, highly available" -ForegroundColor White

    Write-Host "`nSupported OS Versions:" -ForegroundColor Yellow
    Write-Host "  - Windows Server 2016 and later" -ForegroundColor White
    Write-Host "  - Azure Stack HCI" -ForegroundColor White
    #endregion

    #region Step 2: Prerequisites Check
    Write-Step "Checking Prerequisites"

    # Check cluster
    if (Get-Command Get-Cluster -ErrorAction SilentlyContinue) {
        $cluster = Get-Cluster -ErrorAction SilentlyContinue
        if ($cluster) {
            Write-Success "Cluster found: $($cluster.Name)"

            Write-Host "`nCurrent Quorum Configuration:" -ForegroundColor Yellow
            $quorum = Get-ClusterQuorum
            $quorum | Format-List Cluster, QuorumResource, QuorumType

            Write-Info "Current Quorum Type: $($quorum.QuorumType)"
        } else {
            Write-Info "No cluster found - Cloud Witness requires failover cluster"
        }
    } else {
        Write-Info "Failover Clustering cmdlets not available"
    }

    # Check Azure PowerShell
    if (Get-Module -ListAvailable -Name Az.Storage) {
        Write-Success "Azure PowerShell module available"
        Write-Info "Use Connect-AzAccount to authenticate to Azure"
    } else {
        Write-Info "Azure PowerShell not installed"
        Write-Host "  Install-Module -Name Az -AllowClobber -Scope CurrentUser" -ForegroundColor Gray
    }
    #endregion

    #region Step 3: Create Azure Storage Account
    Write-Step "Creating Azure Storage Account for Cloud Witness"

    Write-Info "Cloud Witness requires a general-purpose Azure Storage account"

    Write-Host "`nAzure Storage Account Setup:" -ForegroundColor Yellow
    Write-Host @"
  # Connect to Azure
  Connect-AzAccount

  # Create resource group
  New-AzResourceGroup -Name '$ResourceGroupName' -Location '$Location'

  # Create storage account (General Purpose v2)
  New-AzStorageAccount ``
      -ResourceGroupName '$ResourceGroupName' ``
      -Name '$StorageAccountName' ``
      -Location '$Location' ``
      -SkuName Standard_LRS ``
      -Kind StorageV2 ``
      -AccessTier Hot ``
      -EnableHttpsTrafficOnly `$true

  # Get storage account key
  `$storageKey = (Get-AzStorageAccountKey ``
      -ResourceGroupName '$ResourceGroupName' ``
      -Name '$StorageAccountName')[0].Value

  # Display the key
  Write-Host "Storage Account Name: $StorageAccountName"
  Write-Host "Storage Account Key: `$storageKey"
"@ -ForegroundColor Gray

    Write-Host "`nStorage Account Requirements:" -ForegroundColor Yellow
    Write-Host "  - General Purpose v1 or v2 (not Blob storage)" -ForegroundColor White
    Write-Host "  - LRS (Locally Redundant) or GRS (Geo-Redundant) recommended" -ForegroundColor White
    Write-Host "  - HTTPS traffic only (secure transfer)" -ForegroundColor White
    Write-Host "  - Standard performance tier sufficient" -ForegroundColor White
    #endregion

    #region Step 4: Configure Cloud Witness
    Write-Step "Configuring Cloud Witness on Failover Cluster"

    Write-Info "Setting up Cloud Witness quorum configuration"

    Write-Host "`nConfigure Cloud Witness:" -ForegroundColor Yellow
    Write-Host @"
  # Set Cloud Witness (requires storage account name and key)
  Set-ClusterQuorum ``
      -CloudWitness ``
      -AccountName '$StorageAccountName' ``
      -AccessKey 'YOUR_STORAGE_ACCOUNT_KEY'

  # Alternative: Use Azure endpoint (for specific Azure regions)
  Set-ClusterQuorum ``
      -CloudWitness ``
      -AccountName '$StorageAccountName' ``
      -AccessKey 'YOUR_STORAGE_ACCOUNT_KEY' ``
      -Endpoint 'core.windows.net'

  # For Azure Government or Azure China
  # -Endpoint 'core.usgovcloudapi.net'  # Azure Government
  # -Endpoint 'core.chinacloudapi.cn'    # Azure China
"@ -ForegroundColor Gray

    Write-Host "`nQuorum Configuration Command:" -ForegroundColor Yellow
    if ($StorageAccountKey) {
        Write-Host "Set-ClusterQuorum -CloudWitness -AccountName '$StorageAccountName' -AccessKey '$StorageAccountKey'" -ForegroundColor Cyan
    } else {
        Write-Host "Set-ClusterQuorum -CloudWitness -AccountName '$StorageAccountName' -AccessKey '<KEY>'" -ForegroundColor Cyan
        Write-Info "Replace <KEY> with your actual storage account key"
    }
    #endregion

    #region Step 5: Verify Cloud Witness Configuration
    Write-Step "Verifying Cloud Witness Configuration"

    Write-Host "`nVerification Commands:" -ForegroundColor Yellow
    Write-Host @"
  # Get quorum configuration
  Get-ClusterQuorum

  # View detailed quorum information
  Get-ClusterQuorum | Format-List *

  # Check quorum resource
  Get-ClusterResource | Where-Object ResourceType -eq 'Cloud Witness'

  # View cluster resource parameters
  Get-ClusterResource 'Cloud Witness' | Get-ClusterParameter

  # Test quorum vote
  Test-Cluster -Node (Get-ClusterNode).Name -Include 'System Configuration'
"@ -ForegroundColor Gray

    # Try to display current configuration
    try {
        if ($cluster) {
            $quorumAfter = Get-ClusterQuorum -ErrorAction SilentlyContinue
            Write-Host "`nCurrent Quorum Status:" -ForegroundColor Yellow
            Write-Host "  Quorum Type: $($quorumAfter.QuorumType)" -ForegroundColor White
            Write-Host "  Quorum Resource: $($quorumAfter.QuorumResource.Name)" -ForegroundColor White

            # Check for Cloud Witness resource
            $cloudWitness = Get-ClusterResource -ErrorAction SilentlyContinue |
                Where-Object ResourceType -eq 'Cloud Witness'
            if ($cloudWitness) {
                Write-Success "Cloud Witness resource found: $($cloudWitness.Name)"
                $cloudWitness | Format-List Name, State, ResourceType
            }
        }
    } catch {
        Write-Info "Run Set-ClusterQuorum to configure Cloud Witness"
    }
    #endregion

    #region Step 6: Quorum Types and Voting
    Write-Step "Understanding Cluster Quorum and Voting"

    Write-Host "`nQuorum Types:" -ForegroundColor Yellow
    Write-Host "  - NodeMajority: Odd number of nodes, no witness" -ForegroundColor White
    Write-Host "  - NodeAndDiskMajority: Even nodes + disk witness" -ForegroundColor White
    Write-Host "  - NodeAndFileShareMajority: Even nodes + file share witness" -ForegroundColor White
    Write-Host "  - NodeAndCloudMajority: Even nodes + cloud witness" -ForegroundColor White

    Write-Host "`nRecommended Quorum Configuration:" -ForegroundColor Yellow
    Write-Host "  2 nodes: Cloud Witness (provides 3rd vote)" -ForegroundColor White
    Write-Host "  3 nodes: Node Majority (no witness needed)" -ForegroundColor White
    Write-Host "  4 nodes: Cloud Witness (prevents split-brain)" -ForegroundColor White
    Write-Host "  Multi-site: Cloud Witness (neutral 3rd datacenter)" -ForegroundColor White

    Write-Host "`nViewing Node Votes:" -ForegroundColor Yellow
    Write-Host @"
  # View node vote configuration
  Get-ClusterNode | Select-Object Name, State, NodeWeight

  # Modify node vote weight (0 or 1)
  (Get-ClusterNode -Name 'NODE1').NodeWeight = 1

  # Dynamic quorum (automatic vote adjustment)
  (Get-Cluster).DynamicQuorum = 1
"@ -ForegroundColor Gray
    #endregion

    #region Step 7: Multi-Site Clusters
    Write-Step "Cloud Witness for Multi-Site Clusters"

    Write-Info "Cloud Witness is ideal for stretch/multi-site clusters"

    Write-Host "`nMulti-Site Cluster Benefits:" -ForegroundColor Yellow
    Write-Host "  - Neutral witness location (not in either site)" -ForegroundColor White
    Write-Host "  - Survives site failures" -ForegroundColor White
    Write-Host "  - No third datacenter required" -ForegroundColor White
    Write-Host "  - Automatic Azure region failover" -ForegroundColor White

    Write-Host "`nStretch Cluster Configuration:" -ForegroundColor Yellow
    Write-Host @"
  # Configure site-aware quorum for stretch cluster
  # Example: 2 nodes in Site A, 2 nodes in Site B, Cloud Witness

  # Set site assignment
  (Get-ClusterNode -Name 'NODE1').Site = 'SiteA'
  (Get-ClusterNode -Name 'NODE2').Site = 'SiteA'
  (Get-ClusterNode -Name 'NODE3').Site = 'SiteB'
  (Get-ClusterNode -Name 'NODE4').Site = 'SiteB'

  # Configure preferred site
  (Get-Cluster).PreferredSite = 'SiteA'

  # Use Cloud Witness
  Set-ClusterQuorum -CloudWitness -AccountName '$StorageAccountName' -AccessKey '<KEY>'

  # View site configuration
  Get-ClusterNode | Select-Object Name, Site
"@ -ForegroundColor Gray
    #endregion

    #region Step 8: Troubleshooting Cloud Witness
    Write-Step "Troubleshooting Cloud Witness"

    Write-Host "`nCommon Issues and Solutions:" -ForegroundColor Yellow

    Write-Host "`n1. Connectivity Issues:" -ForegroundColor Cyan
    Write-Host @"
  # Test connectivity to Azure Storage
  Test-NetConnection -ComputerName $StorageAccountName.blob.core.windows.net -Port 443

  # Check firewall rules (allow outbound HTTPS)
  # Ensure proxy settings configured if applicable

  # Test DNS resolution
  Resolve-DnsName $StorageAccountName.blob.core.windows.net
"@ -ForegroundColor Gray

    Write-Host "`n2. Authentication Issues:" -ForegroundColor Cyan
    Write-Host @"
  # Verify storage account key is correct
  Get-ClusterResource 'Cloud Witness' | Get-ClusterParameter

  # Update storage account key if rotated
  Set-ClusterQuorum ``
      -CloudWitness ``
      -AccountName '$StorageAccountName' ``
      -AccessKey 'NEW_STORAGE_ACCOUNT_KEY'
"@ -ForegroundColor Gray

    Write-Host "`n3. Check Cloud Witness Resource:" -ForegroundColor Cyan
    Write-Host @"
  # View resource state
  Get-ClusterResource 'Cloud Witness'

  # View resource events
  Get-ClusterLog -TimeSpan 15 -Destination C:\Temp

  # Check event logs
  Get-WinEvent -LogName 'Microsoft-Windows-FailoverClustering/Operational' ``
      -MaxEvents 50 | Where-Object Message -like '*Cloud Witness*'
"@ -ForegroundColor Gray
    #endregion

    #region Step 9: Managing Cloud Witness
    Write-Step "Managing Cloud Witness"

    Write-Host "`nManagement Tasks:" -ForegroundColor Yellow
    Write-Host @"
  # Change Cloud Witness storage account
  Set-ClusterQuorum ``
      -CloudWitness ``
      -AccountName 'newstorage' ``
      -AccessKey 'NEW_KEY'

  # Switch to different quorum type
  # To Disk Witness
  Set-ClusterQuorum -DiskWitness (Get-ClusterResource 'Cluster Disk 1')

  # To File Share Witness
  Set-ClusterQuorum -FileShareWitness '\\FileServer\WitnessShare'

  # To Node Majority (no witness)
  Set-ClusterQuorum -NodeMajority

  # View what's stored in Azure
  # Cloud Witness creates container 'msft-cloud-witness' in storage account
  # Contains a small blob for witness data
"@ -ForegroundColor Gray
    #endregion

    #region Step 10: Best Practices
    Write-Step "Cloud Witness Best Practices"

    Write-Host "`nCloud Witness Best Practices:" -ForegroundColor Yellow
    Write-Host "  1. Use Cloud Witness for 2-node or even-node clusters" -ForegroundColor White
    Write-Host "  2. Choose storage account in different Azure region than VMs" -ForegroundColor White
    Write-Host "  3. Use LRS or GRS replication for storage account" -ForegroundColor White
    Write-Host "  4. Enable secure transfer (HTTPS only) on storage account" -ForegroundColor White
    Write-Host "  5. Document storage account details securely" -ForegroundColor White
    Write-Host "  6. Rotate storage account keys periodically" -ForegroundColor White
    Write-Host "  7. Monitor storage account availability" -ForegroundColor White
    Write-Host "  8. Use resource locks to prevent accidental deletion" -ForegroundColor White
    Write-Host "  9. Configure network connectivity from all cluster nodes" -ForegroundColor White
    Write-Host "  10. Test failover scenarios regularly" -ForegroundColor White

    Write-Host "`nSecurity Considerations:" -ForegroundColor Yellow
    Write-Host "  - Store storage account keys securely" -ForegroundColor White
    Write-Host "  - Use Azure Key Vault for key management" -ForegroundColor White
    Write-Host "  - Enable Azure Storage firewall if needed" -ForegroundColor White
    Write-Host "  - Monitor storage account access logs" -ForegroundColor White
    Write-Host "  - Use managed identities when possible" -ForegroundColor White

    Write-Host "`nCost Optimization:" -ForegroundColor Yellow
    Write-Host "  - Cloud Witness uses minimal storage (~1 KB)" -ForegroundColor White
    Write-Host "  - Approximately $0.05/month for storage" -ForegroundColor White
    Write-Host "  - Transaction costs are negligible" -ForegroundColor White
    Write-Host "  - Much cheaper than dedicated file server" -ForegroundColor White
    #endregion

    #region Summary
    Write-Host "`n" + "="*80 -ForegroundColor Cyan
    Write-Success "Azure Cloud Witness Configuration Completed"
    Write-Host "="*80 -ForegroundColor Cyan

    Write-Host "`nConfiguration Summary:" -ForegroundColor Yellow
    Write-Host "  Storage Account Name: $StorageAccountName" -ForegroundColor White
    Write-Host "  Resource Group: $ResourceGroupName" -ForegroundColor White
    Write-Host "  Azure Region: $Location" -ForegroundColor White

    Write-Host "`nNext Steps:" -ForegroundColor Yellow
    Write-Host "  1. Create Azure Storage account if not exists" -ForegroundColor Cyan
    Write-Host "  2. Run: Set-ClusterQuorum -CloudWitness -AccountName '$StorageAccountName' -AccessKey '<KEY>'" -ForegroundColor Cyan
    Write-Host "  3. Verify quorum: Get-ClusterQuorum" -ForegroundColor Cyan
    Write-Host "  4. Test cluster failover scenarios" -ForegroundColor Cyan
    Write-Host "  5. Configure floating IP resources (task-9.5)" -ForegroundColor Cyan
    #endregion

} catch {
    Write-Host "`n[ERROR] Failed to configure Cloud Witness: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

Write-Host "`nScript completed successfully!" -ForegroundColor Green
