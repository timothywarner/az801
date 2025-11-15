# Module 8: Implement Failover Clusters

**Duration:** ~20 minutes

## Learning Objectives

After completing this module, you will be able to:

- Implement a failover cluster on-premises, hybrid, or cloud-only
- Create a Windows failover cluster, including workgroup clusters
- Implement a stretch cluster across datacenters or Azure regions, including Storage Spaces Direct (S2D) campus clusters
- Configure storage for failover clustering
- Modify quorum options
- Configure network adapters for failover clustering

## Topics Covered

### 8.1. Implement a Failover Cluster On-premises, Hybrid, or Cloud-only
Plan and deploy failover clusters in various scenarios including on-premises, hybrid, and Azure-only deployments.

### 8.2. Create a Windows Failover Cluster, Including Workgroup Clusters
Create and configure a failover cluster, including non-domain scenarios.

### 8.3. Implement a Stretch Cluster Across Datacenters or Azure Regions
Deploy stretch clusters for disaster recovery scenarios.

### 8.4. Configure Storage for Failover Clustering
Set up shared storage using iSCSI, Fibre Channel, SMB 3.0, or Storage Spaces Direct.

### 8.5. Modify Quorum Options
Configure quorum settings including disk witness, file share witness, and cloud witness.

### 8.6. Configure Network Adapters for Failover Clustering
Configure network interfaces for cluster communication and live migration.

## Supplemental Resources

- [Failover Clustering in Windows Server](https://learn.microsoft.com/en-us/windows-server/failover-clustering/failover-clustering-overview)
- [Deploy a Failover Cluster](https://learn.microsoft.com/en-us/windows-server/failover-clustering/create-failover-cluster)
- [Stretch Clusters](https://learn.microsoft.com/en-us/windows-server/storage/storage-spaces/stretch-cluster-overview)
- [Configure Cluster Quorum](https://learn.microsoft.com/en-us/windows-server/failover-clustering/manage-cluster-quorum)
- [Cloud Witness](https://learn.microsoft.com/en-us/windows-server/failover-clustering/deploy-cloud-witness)

## Hands-on Labs

Check the `/labs` subdirectory for hands-on exercises related to this module.

## Scripts

- `create-cluster-vms.bicep` - Bicep template for creating cluster VMs
- `create-cluster-storage.ps1` - PowerShell script for configuring cluster storage

## Notes

- Failover clustering requires identical hardware across nodes
- Cloud Witness is the recommended quorum witness for Azure-based clusters
- Network ATC simplifies network configuration for clusters
- Workgroup clusters are useful for Azure-only deployments without AD DS
