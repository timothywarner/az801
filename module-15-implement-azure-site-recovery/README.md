# Module 15: Implement Azure Site Recovery

**Duration:** ~20 minutes

## Learning Objectives

After completing this module, you will be able to:

- Configure Azure Site Recovery network mapping
- Configure Site Recovery for on-premises servers
- Configure a recovery plan in Azure Site Recovery
- Configure Site Recovery for Azure VMs
- Implement VM replication to secondary datacenter or Azure region
- Configure Azure Site Recovery replication policies

## Topics Covered

### 15.1. Configure Azure Site Recovery Network Mapping
Map source and target networks for failover scenarios.

### 15.2. Configure Site Recovery for On-premises Servers
Set up ASR to replicate on-premises servers to Azure.

### 15.3. Configure a Recovery Plan in Azure Site Recovery
Create recovery plans to orchestrate failover of multiple VMs.

### 15.4. Configure Site Recovery for Azure VMs
Enable replication between Azure regions.

### 15.5. Implement VM Replication to Secondary Datacenter or Azure Region
Replicate virtual machines for disaster recovery.

### 15.6. Configure Azure Site Recovery Replication Policies
Define replication frequency, retention, and crash-consistent snapshot settings.

## Supplemental Resources

- [Azure Site Recovery Overview](https://learn.microsoft.com/en-us/azure/site-recovery/site-recovery-overview)
- [Replicate Azure VMs](https://learn.microsoft.com/en-us/azure/site-recovery/azure-to-azure-tutorial-enable-replication)
- [Replicate On-premises to Azure](https://learn.microsoft.com/en-us/azure/site-recovery/physical-azure-disaster-recovery)
- [Recovery Plans](https://learn.microsoft.com/en-us/azure/site-recovery/recovery-plan-overview)
- [Network Mapping](https://learn.microsoft.com/en-us/azure/site-recovery/azure-to-azure-network-mapping)

## Hands-on Labs

Check the `/labs` subdirectory for hands-on exercises related to this module.

## Notes

- ASR provides continuous replication with RPO as low as 30 seconds for Azure VMs
- Recovery plans can include manual actions and automation scripts
- Network mapping ensures correct network configuration after failover
- Test failover can be performed without impacting production
- ASR supports replication of both physical and virtual servers
