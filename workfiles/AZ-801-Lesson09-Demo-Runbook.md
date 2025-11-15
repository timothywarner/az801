# AZ-801 Lesson 9 Demo Runbook
## Configure Advanced Cluster Features

**Target Runtime:** 10-15 minutes
**Environment:** 2-node Windows Server 2025 failover cluster
**Prerequisites:** Existing cluster named "AZ801-CLUSTER" with nodes NODE1, NODE2
**Demo Flow:** Network ATC → Workload Policies → Cloud Witness → DNN Configuration

---

## 🎯 Demo Objectives

1. Deploy Network ATC intent for cluster networking
2. Configure anti-affinity rules for VM placement
3. Set up Azure cloud witness for quorum
4. Demonstrate floating IP with Distributed Network Name (DNN)

---

## Demo 1: Deploy Network ATC Intent (3-4 minutes)

### Teaching Moment
"Network ATC eliminates manual network configuration errors by using declarative intents. Watch how we define WHAT we want - management and storage separation - and Network ATC figures out HOW to configure it across both nodes."

### Prerequisites Check

```powershell
# Verify Network ATC feature is installed
Get-WindowsFeature -Name NetworkATC

# Check adapter status on both nodes
Invoke-Command -ComputerName NODE1,NODE2 -ScriptBlock {
    Get-NetAdapter | Where-Object Status -eq 'Up' |
    Select-Object PSComputerName, Name, InterfaceDescription, LinkSpeed
}

# Verify adapter symmetry (names must match)
$node1Adapters = Invoke-Command -ComputerName NODE1 {Get-NetAdapter | Select Name,InterfaceDescription}
$node2Adapters = Invoke-Command -ComputerName NODE2 {Get-NetAdapter | Select Name,InterfaceDescription}

Compare-Object $node1Adapters $node2Adapters -Property Name,InterfaceDescription
# Should return NO differences
```

### Deploy Management Intent

```powershell
# Create management intent on Ethernet adapter
Add-NetIntent -Name 'ManagementIntent' `
              -Management `
              -AdapterName 'Ethernet' `
              -Cluster 'AZ801-CLUSTER'

# Verify intent status
Get-NetIntentStatus -Name 'ManagementIntent' -Cluster 'AZ801-CLUSTER'
```

**Expected Output:**
```
Name              : ManagementIntent
Host              : NODE1
ProvisioningState : Provisioned
ConfigurationState: Success
```

### Deploy Converged Storage+Compute Intent

```powershell
# Create converged intent on Ethernet 2 and Ethernet 3 (2x adapters for redundancy)
Add-NetIntent -Name 'ConvergedIntent' `
              -Compute `
              -Storage `
              -AdapterName 'Ethernet 2','Ethernet 3' `
              -Cluster 'AZ801-CLUSTER'

# Monitor deployment progress
Get-NetIntentStatus -Name 'ConvergedIntent' -Cluster 'AZ801-CLUSTER' |
Select-Object Name, Host, ProvisioningState, ConfigurationState, LastConfigurationError
```

### Validate Network ATC Configuration

```powershell
# View all intents
Get-NetIntent -Cluster 'AZ801-CLUSTER' | Format-Table Name, AdapterName, Compute, Storage, Management

# Check storage VLANs (should be 711-712 by default)
Invoke-Command -ComputerName NODE1,NODE2 -ScriptBlock {
    Get-NetAdapter -Name 'vEthernet*' | Get-NetAdapterAdvancedProperty -RegistryKeyword VlanID
}

# Verify automatic storage IP addressing (10.71.1.x and 10.71.2.x)
Invoke-Command -ComputerName NODE1,NODE2 -ScriptBlock {
    Get-NetIPAddress -AddressFamily IPv4 | Where-Object IPAddress -like '10.71.*' |
    Select-Object PSComputerName, IPAddress, InterfaceAlias
}
```

**Demo Talking Points:**
- "Notice Network ATC automatically assigned VLAN 711 and 712 to storage adapters"
- "Storage IPs are in 10.71.1.x and 10.71.2.x subnets - no manual config needed"
- "If we check Event Viewer → Microsoft-Windows-Networking-NetworkATC, we'd see validation events"

---

## Demo 2: Configure Cluster Workload Policies (2-3 minutes)

### Teaching Moment
"Anti-affinity rules prevent related VMs from competing for resources on the same node. We'll configure SOFT anti-affinity so two SQL VMs spread across nodes but can temporarily coexist during maintenance."

### Create Test Cluster Groups (Simulating VMs)

```powershell
# Create two cluster groups representing SQL Server VMs
Add-ClusterGroup -Name 'SQL-VM1' -GroupType GenericApplication -Cluster AZ801-CLUSTER
Add-ClusterGroup -Name 'SQL-VM2' -GroupType GenericApplication -Cluster AZ801-CLUSTER

# Check current placement
Get-ClusterGroup -Name 'SQL-VM*' | Select-Object Name, OwnerNode, State
```

### Configure Soft Anti-Affinity

```powershell
# Set matching AntiAffinityClassNames on both groups
(Get-ClusterGroup -Name 'SQL-VM1').AntiAffinityClassNames = 'SQLServers'
(Get-ClusterGroup -Name 'SQL-VM2').AntiAffinityClassNames = 'SQLServers'

# Verify anti-affinity configuration
Get-ClusterGroup -Name 'SQL-VM*' | Select-Object Name, OwnerNode, AntiAffinityClassNames
```

### Test Anti-Affinity Behavior

```powershell
# Bring groups online - should land on different nodes
Start-ClusterGroup -Name 'SQL-VM1'
Start-ClusterGroup -Name 'SQL-VM2'

# Verify they're on different nodes
Get-ClusterGroup -Name 'SQL-VM*' | Select-Object Name, OwnerNode, State | Format-Table

# Demonstrate preferred owners
(Get-ClusterGroup -Name 'SQL-VM1').PreferredOwners = 'NODE1'
(Get-ClusterGroup -Name 'SQL-VM2').PreferredOwners = 'NODE2'

# View preferred owner configuration
Get-ClusterGroup -Name 'SQL-VM*' | Select-Object Name, OwnerNode, @{N='PreferredOwners';E={$_.PreferredOwners -join ','}}
```

### Demonstrate Drain Operation

```powershell
# Suspend NODE1 and drain workloads
Suspend-ClusterNode -Name 'NODE1' -Drain

# Watch SQL-VM1 live migrate to NODE2
Get-ClusterGroup -Name 'SQL-VM*' | Select-Object Name, OwnerNode, State

# Resume NODE1
Resume-ClusterNode -Name 'NODE1'
```

**Demo Talking Points:**
- "Soft anti-affinity (AntiAffinityClassNames) PREFERS separation but allows co-location during drain"
- "Hard anti-affinity (ClusterEnforcedAntiAffinity=1) would BLOCK startup if conflict exists"
- "Drain operations are how Cluster-Aware Updating patches nodes with zero downtime"

---

## Demo 3: Configure Azure Cloud Witness (3-4 minutes)

### Teaching Moment
"Cloud witness eliminates the need for a third datacenter or file share witness. We're using Azure Storage as our tie-breaker vote - perfect for 2-node clusters and stretched cluster scenarios."

### Prerequisites: Azure Storage Account

**Note:** This would be pre-created in Azure Portal. For demo, show these values:
- Storage Account Name: `az801clusterwitness`
- Resource Group: `AZ801-RG`
- Region: `East US 2`
- Performance: `Standard`
- Replication: `LRS (Locally Redundant Storage)`

### Retrieve Storage Account Key

```powershell
# FROM AZURE CLOUD SHELL or with Az PowerShell module installed:
$resourceGroup = 'AZ801-RG'
$storageAccountName = 'az801clusterwitness'

# Get primary access key
$storageKey = (Get-AzStorageAccountKey -ResourceGroupName $resourceGroup `
               -Name $storageAccountName)[0].Value

# Show key (first 20 characters for demo security)
Write-Host "Storage Key: $($storageKey.Substring(0,20))..." -ForegroundColor Cyan
```

### Configure Cloud Witness on Cluster

```powershell
# Check current quorum configuration
Get-ClusterQuorum -Cluster AZ801-CLUSTER

# Set cloud witness
Set-ClusterQuorum -Cluster AZ801-CLUSTER `
                  -CloudWitness `
                  -AccountName 'az801clusterwitness' `
                  -AccessKey $storageKey

# Verify cloud witness configuration
Get-ClusterQuorum -Cluster AZ801-CLUSTER | Select-Object Cluster, QuorumResource, QuorumType
```

**Expected Output:**
```
Cluster         : AZ801-CLUSTER
QuorumResource  : Cloud Witness
QuorumType      : NodeAndCloudMajority
```

### Validate Cloud Witness Operation

```powershell
# Check cluster witness resource
Get-ClusterResource -Cluster AZ801-CLUSTER | Where-Object ResourceType -eq 'Cloud Witness' |
Select-Object Name, State, OwnerGroup, ResourceType

# View cloud witness properties
Get-ClusterResource -Name 'Cloud Witness' -Cluster AZ801-CLUSTER |
Get-ClusterParameter | Format-Table Name, Value

# Test quorum vote calculation
Get-ClusterNode -Cluster AZ801-CLUSTER | Select-Object Name, State, NodeWeight
```

### Demonstrate Quorum Resiliency

```powershell
# Show quorum votes
(Get-Cluster -Name AZ801-CLUSTER).DynamicQuorum
# DynamicQuorum = True (Windows Server 2012 R2+ feature)

# Calculate vote count
Write-Host "Quorum Vote Count:" -ForegroundColor Yellow
Write-Host "NODE1: 1 vote"
Write-Host "NODE2: 1 vote"
Write-Host "Cloud Witness: 1 vote"
Write-Host "Total: 3 votes | Majority Needed: 2 votes"
Write-Host ""
Write-Host "If NODE1 fails: NODE2 (1) + Cloud Witness (1) = 2 votes = Cluster ONLINE" -ForegroundColor Green
```

**Demo Talking Points:**
- "Cloud witness blob is stored in msft-cloud-witness container"
- "Blob name is cluster's unique GUID - one storage account serves multiple clusters"
- "All nodes need HTTPS (443) outbound to *.core.windows.net"
- "Cost is typically $0.01-0.02/month per cluster - dirt cheap disaster avoidance"

---

## Demo 4: Configure Distributed Network Name (DNN) (3-4 minutes)

### Teaching Moment
"DNN replaces the Azure Load Balancer approach with DNS-based client connection. Clients try all node IPs in parallel and connect to whichever node owns the clustered resource - instant failover with zero probe delay."

### Create Generic Application Cluster Role (Simulates Clustered App)

```powershell
# Add cluster role with IP resource (simulating SQL FCI or generic app)
Add-ClusterGenericApplicationRole -Name 'LineOfBusinessApp' `
                                  -Cluster AZ801-CLUSTER `
                                  -StaticAddress '10.0.1.100' `
                                  -CheckpointKey 'SOFTWARE\MyApp'

# Verify role creation
Get-ClusterGroup -Name 'LineOfBusinessApp' | Format-List Name, OwnerNode, State
Get-ClusterResource -Group 'LineOfBusinessApp' | Format-Table Name, ResourceType, State
```

### Create DNN Resource

```powershell
# Add Distributed Network Name resource to the role
Add-ClusterResource -Name 'LOB-DNN' `
                    -ResourceType 'Distributed Network Name' `
                    -Group 'LineOfBusinessApp'

# Set DNS name for DNN
Get-ClusterResource -Name 'LOB-DNN' |
Set-ClusterParameter -Name DnsName -Value 'lobapp-dnn.contoso.com'

# Set possible owners (only nodes in this cluster role)
$clusterNodes = Get-ClusterNode -Cluster AZ801-CLUSTER
Set-ClusterResourceDependency -Resource 'LOB-DNN' -Dependency "" # Remove default deps
Get-ClusterResource -Name 'LOB-DNN' | Set-ClusterParameter -Name PossibleOwners -Value ($clusterNodes.Name -join ',')

# Bring DNN online
Start-ClusterResource -Name 'LOB-DNN'
```

### Verify DNN Configuration

```powershell
# Check DNN resource status
Get-ClusterResource -Name 'LOB-DNN' | Select-Object Name, ResourceType, State, OwnerNode

# View DNN DNS name and IP mappings
Get-ClusterResource -Name 'LOB-DNN' | Get-ClusterParameter

# Resolve DNN via DNS (should return both node IPs)
Resolve-DnsName -Name 'lobapp-dnn.contoso.com' -Type A |
Select-Object Name, IPAddress
```

**Expected Output:**
```
Name                    IPAddress
----                    ---------
lobapp-dnn.contoso.com  10.0.1.10  (NODE1)
lobapp-dnn.contoso.com  10.0.1.11  (NODE2)
```

### Demonstrate DNN Failover

```powershell
# Show current owner
$currentOwner = (Get-ClusterGroup -Name 'LineOfBusinessApp').OwnerNode
Write-Host "Current Owner: $currentOwner" -ForegroundColor Cyan

# Move to other node
Move-ClusterGroup -Name 'LineOfBusinessApp' -Node 'NODE2'

# Verify move completed
Start-Sleep -Seconds 3
$newOwner = (Get-ClusterGroup -Name 'LineOfBusinessApp').OwnerNode
Write-Host "New Owner: $newOwner" -ForegroundColor Green

# DNS still resolves to BOTH node IPs - clients connect to active node
Resolve-DnsName -Name 'lobapp-dnn.contoso.com' -Type A | Select-Object Name, IPAddress
```

### Client Connection String Example

```powershell
Write-Host "`n=== Client Connection String Requirements ===" -ForegroundColor Yellow
Write-Host "For SQL Server FCI with DNN:"
Write-Host "Server=lobapp-dnn.contoso.com,1433;Database=MyDB;MultiSubnetFailover=True;" -ForegroundColor Cyan
Write-Host ""
Write-Host "MultiSubnetFailover=True is REQUIRED even in single subnet!"
Write-Host "This tells client driver to try all IPs in parallel for instant connection."
```

**Demo Talking Points:**
- "DNN binds DNS name to ALL node IPs in cluster"
- "No load balancer needed = lower cost, simpler architecture"
- "Failover is instant - no health probe delay like Azure Load Balancer (5-15 sec)"
- "Requires SQL 2019 CU8+ or SQL 2016 SP3+ for SQL Server workloads"
- "For multi-subnet clusters, neither DNN nor VNN needed - use multiple static IPs"

---

## Demo Validation & Cleanup

### Validate All Configurations

```powershell
# Comprehensive cluster health check
Test-Cluster -Node NODE1,NODE2 -Include 'Inventory','Network','System Configuration'

# Network ATC validation
Get-NetIntentStatus -Cluster AZ801-CLUSTER |
Format-Table Name, ProvisioningState, ConfigurationState

# Quorum configuration
Get-ClusterQuorum | Format-List

# DNN resource status
Get-ClusterResource -Name 'LOB-DNN' | Format-Table Name, State, OwnerNode
```

### Optional: Cleanup Demo Resources

```powershell
# Remove DNN and test application
Stop-ClusterGroup -Name 'LineOfBusinessApp'
Remove-ClusterGroup -Name 'LineOfBusinessApp' -Force

# Remove test SQL groups
Remove-ClusterGroup -Name 'SQL-VM1','SQL-VM2' -Force

# Remove Network ATC intents (optional - probably keep for cluster operation)
# Remove-NetIntent -Name 'ManagementIntent','ConvergedIntent' -Cluster AZ801-CLUSTER
```

---

## 📚 Additional Resources

### Microsoft Learn Documentation
- **Network ATC:** https://learn.microsoft.com/en-us/windows-server/networking/network-atc/network-atc
- **Scale-Out File Server:** https://learn.microsoft.com/en-us/windows-server/failover-clustering/sofs-overview
- **Cloud Witness:** https://learn.microsoft.com/en-us/windows-server/failover-clustering/deploy-cloud-witness
- **DNN Configuration:** https://learn.microsoft.com/en-us/azure/azure-sql/virtual-machines/windows/failover-cluster-instance-distributed-network-name-dnn-configure

### PowerShell Module References
```powershell
# Network ATC cmdlets
Get-Command -Module NetworkATC

# Failover Clustering cmdlets
Get-Command -Module FailoverClusters | Where-Object Name -like '*Cluster*'

# Quick reference
Get-Help Add-NetIntent -Full
Get-Help Set-ClusterQuorum -Examples
Get-Help Add-ClusterResource -Online
```

---

## 🎓 Exam Tips Summary

### Network ATC (9.1)
- **Adapter Requirements:** Symmetric (same make/model/speed/firmware), same name on all nodes, "Up" status
- **Required Features:** NetworkATC, Hyper-V, Failover-Clustering, Data-Center-Bridging
- **Default Storage VLANs:** 711-718 for storage adapters 1-8
- **Automatic IP Addressing:** 10.71.1.x, 10.71.2.x, etc. for storage adapters
- **Key Cmdlets:** `Add-NetIntent`, `Get-NetIntentStatus`, `Remove-NetIntent`

### Cluster Workload Options (9.2)
- **Soft Anti-Affinity:** `AntiAffinityClassNames` - prefers separation, allows temporary co-location
- **Hard Anti-Affinity:** `ClusterEnforcedAntiAffinity=1` - blocks startup on conflicts
- **Drain Operations:** `Suspend-ClusterNode -Drain` moves workloads, `Resume-ClusterNode` restores
- **Preferred Owners:** List evaluated in order - first available node gets role
- **VM Monitoring:** Configure per-VM restart actions for application health failures

### Scale-Out File Server (9.3)
- **Active-Active:** All nodes simultaneously serve SMB clients
- **Requires:** CSV volumes, SMB 3.0+ clients, Continuously Available shares
- **CSV Cache:** Configure with `(Get-Cluster).BlockCacheSize` in MB
- **Use Cases:** Hyper-V VM storage, SQL Server file shares, scale-out app data
- **NOT for:** User home directories, roaming profiles (use traditional File Server role)

### Azure Cloud Witness (9.4)
- **Storage Requirements:** Standard General Purpose v2, LRS replication
- **Connectivity:** HTTPS (443) outbound to *.core.windows.net from all nodes
- **Container:** Auto-created `msft-cloud-witness` container
- **Cost:** ~$0.01-0.02/month per cluster
- **Quorum:** Provides tie-breaker vote for even-node clusters (2, 4, 6, 8 nodes)
- **Key Cmdlet:** `Set-ClusterQuorum -CloudWitness -AccountName -AccessKey`

### Floating IP / DNN (9.5)
- **DNN Advantages:** No load balancer, instant failover, lower cost, simpler
- **DNN Requirements:** SQL 2019 CU8+ or 2016 SP3+, Windows Server 2016+, connection string `MultiSubnetFailover=True`
- **VNN+Load Balancer:** Works with all SQL versions, adds 5-15 sec probe delay, requires Azure Load Balancer
- **Multi-Subnet:** Fastest option (instant failover), no VNN or DNN needed, requires multiple Azure subnets/VNets
- **Exam Scenario:** "What's fastest failover?" Multi-subnet > DNN > VNN+Load Balancer

---

## Demo Recording Tips

### Recommended Flow
1. **START:** Show cluster status and validation (30 sec)
2. **Demo 1:** Network ATC deployment with pre-validated adapters (3 min)
3. **Demo 2:** Anti-affinity configuration and drain operation (2.5 min)
4. **Demo 3:** Cloud witness setup with Azure Portal quick tour (3 min)
5. **Demo 4:** DNN creation and failover demonstration (3 min)
6. **WRAP:** Quick validation commands, exam tips recap (1 min)

### Split-Screen Layout
- **LEFT:** PowerShell console with commands
- **RIGHT:**
  - Failover Cluster Manager showing resource moves
  - Event Viewer for Network ATC validation logs
  - Azure Portal for cloud witness storage account

### Key Moments to Pause & Explain
- Network ATC automatic VLAN/IP assignment
- Soft vs hard anti-affinity behavior difference
- Cloud witness quorum vote calculation
- DNN DNS resolution returning multiple IPs

---

**Total Demo Time:** 12-13 minutes with talking points, 8-9 minutes raw PowerShell execution

**Target Audience:** AZ-801 candidates building hands-on cluster configuration skills

**Demo Author:** Tim Warner | techtrainertim.com | Microsoft MVP
