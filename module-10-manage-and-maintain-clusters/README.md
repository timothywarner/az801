# Module 10: Manage and Maintain Clusters

**Duration:** ~20 minutes

## Learning Objectives

After completing this module, you will be able to:

- Implement cluster-aware updating
- Recover a failed cluster node
- Upgrade failover cluster nodes
- Failover workloads between nodes
- Install Windows updates on cluster nodes
- Use Windows Admin Center as the primary management tool for hybrid and cluster operations

## Topics Covered

### 10.1. Implement Cluster-Aware Updating
Configure and use Cluster-Aware Updating (CAU) to automate Windows updates on cluster nodes.

### 10.2. Recover a Failed Cluster Node
Restore a failed cluster node to operational status.

### 10.3. Upgrade Failover Cluster Nodes
Perform rolling upgrades of cluster nodes with minimal downtime.

### 10.4. Failover Workloads Between Nodes
Manually move clustered resources between nodes for maintenance or testing.

### 10.5. Install Windows Updates on Cluster Nodes
Apply Windows updates to cluster nodes while maintaining service availability.

### 10.6. Use Windows Admin Center as the Primary Management Tool
Manage clusters using Windows Admin Center for simplified administration.

## Supplemental Resources

- [Cluster-Aware Updating](https://learn.microsoft.com/en-us/windows-server/failover-clustering/cluster-aware-updating)
- [Cluster Operating System Rolling Upgrade](https://learn.microsoft.com/en-us/windows-server/failover-clustering/cluster-operating-system-rolling-upgrade)
- [Windows Admin Center](https://learn.microsoft.com/en-us/windows-server/manage/windows-admin-center/overview)
- [Manage Failover Clusters](https://learn.microsoft.com/en-us/windows-server/failover-clustering/manage-cluster-quorum)

## Hands-on Labs

Check the `/labs` subdirectory for hands-on exercises related to this module.

## Notes

- CAU can run in self-updating mode or coordinated by a remote computer
- Cluster rolling upgrades allow mixed OS versions temporarily
- Windows Admin Center provides a modern web-based management interface
- Always validate cluster health before and after maintenance operations
