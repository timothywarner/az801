# Module 11: Implement Storage Spaces Direct

**Duration:** ~15 minutes

## Learning Objectives

After completing this module, you will be able to:

- Upgrade an S2D node
- Implement networking for S2D
- Configure S2D

## Topics Covered

### 11.1. Upgrade an S2D Node
Perform rolling upgrades of Storage Spaces Direct nodes.

### 11.2. Implement Networking for S2D
Configure network infrastructure for Storage Spaces Direct including RDMA.

### 11.3. Configure S2D
Deploy and configure Storage Spaces Direct for hyper-converged infrastructure.

## Supplemental Resources

- [Storage Spaces Direct Overview](https://learn.microsoft.com/en-us/windows-server/storage/storage-spaces/storage-spaces-direct-overview)
- [Deploy Storage Spaces Direct](https://learn.microsoft.com/en-us/windows-server/storage/storage-spaces/deploy-storage-spaces-direct)
- [RDMA and SET](https://learn.microsoft.com/en-us/windows-server/virtualization/hyper-v-virtual-switch/rdma-and-switch-embedded-teaming)
- [Plan Storage Spaces Direct](https://learn.microsoft.com/en-us/windows-server/storage/storage-spaces/plan-volumes)

## Hands-on Labs

Check the `/labs` subdirectory for hands-on exercises related to this module.

## Scripts

- `S2D-cluster.ps1` - PowerShell script for S2D cluster configuration

## Notes

- S2D requires Windows Server 2016 or later
- RDMA significantly improves S2D performance
- S2D supports 2-16 nodes in a cluster
- Network ATC simplifies S2D network configuration
- S2D provides software-defined storage for hyper-converged infrastructure
