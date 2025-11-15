# Module 12: Protect VMs with Hyper-V Replication

**Duration:** ~15 minutes

## Learning Objectives

After completing this module, you will be able to:

- Configure Hyper-V hosts for replication
- Manage Hyper-V replica servers
- Configure VM replication
- Perform a failover

## Topics Covered

### 12.1. Configure Hyper-V Hosts for Replication
Set up Hyper-V hosts to support VM replication.

### 12.2. Manage Hyper-V Replica Servers
Configure and manage replica servers for disaster recovery.

### 12.3. Configure VM Replication
Enable and configure replication for virtual machines.

### 12.4. Perform a Failover
Execute planned and unplanned failovers of replicated VMs.

## Supplemental Resources

- [Hyper-V Replica Overview](https://learn.microsoft.com/en-us/windows-server/virtualization/hyper-v/manage/set-up-hyper-v-replica)
- [Configure Hyper-V Replica](https://learn.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2012-R2-and-2012/jj134207(v=ws.11))
- [Failover and Failback](https://learn.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2012-R2-and-2012/jj134216(v=ws.11))

## Hands-on Labs

Check the `/labs` subdirectory for hands-on exercises related to this module.

## Notes

- Hyper-V Replica provides asynchronous replication
- Replication can use HTTP or HTTPS
- Certificate-based authentication is recommended for production
- Extended replication allows a third site for DR
- Test failover can be performed without impacting production
