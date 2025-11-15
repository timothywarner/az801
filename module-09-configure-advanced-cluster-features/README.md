# Module 9: Configure Advanced Cluster Features

**Duration:** ~15 minutes

## Learning Objectives

After completing this module, you will be able to:

- Deploy and troubleshoot deployment, validation and cluster networking with Network ATC
- Configure cluster workload options
- Configure Scale-Out File Servers
- Configure an Azure witness
- Configure a floating IP address for the cluster

## Topics Covered

### 9.1. Deploy and Troubleshoot Deployment, Validation and Cluster Networking with Network ATC
Use Network ATC (Adaptive Traffic Control) to simplify and automate cluster network configuration.

### 9.2. Configure Cluster Workload Options
Configure various cluster workload types including virtual machines, file servers, and other services.

### 9.3. Configure Scale-Out File Servers
Implement Scale-Out File Server (SOFS) for continuously available file shares.

### 9.4. Configure an Azure Witness
Set up Azure Blob Storage as a quorum witness for failover clusters.

### 9.5. Configure a Floating IP Address for the Cluster
Configure virtual IP addresses for cluster resources.

## Supplemental Resources

- [Network ATC Overview](https://learn.microsoft.com/en-us/azure-stack/hci/deploy/network-atc-overview)
- [Scale-Out File Server](https://learn.microsoft.com/en-us/windows-server/failover-clustering/sofs-overview)
- [Cloud Witness for Failover Cluster](https://learn.microsoft.com/en-us/windows-server/failover-clustering/deploy-cloud-witness)
- [Cluster Resource Properties](https://learn.microsoft.com/en-us/windows-server/failover-clustering/prestage-cluster-adds)

## Hands-on Labs

Check the `/labs` subdirectory for hands-on exercises related to this module.

## Notes

- Network ATC is particularly useful for Azure Stack HCI and Storage Spaces Direct clusters
- Scale-Out File Servers are optimized for Hyper-V and SQL Server workloads
- Azure witness provides a third vote for cluster quorum without additional hardware
- Floating IPs enable seamless failover for cluster services
