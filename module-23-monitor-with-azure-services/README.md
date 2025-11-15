# Module 23: Monitor with Azure Services

**Duration:** ~15 minutes

## Learning Objectives

After completing this module, you will be able to:

- Configure data collection rules for Azure Monitor
- Create alerts
- Monitor Azure VM performance by using VM Insights
- Manage Windows Server resources with Azure Arc extensions and policies
- Configure Azure Update Manager for hybrid patch orchestration

## Topics Covered

### 23.1. Configure Data Collection Rules for Azure Monitor
Set up data collection rules to gather metrics and logs from servers.

### 23.2. Create Alerts
Configure metric and log alerts in Azure Monitor.

### 23.3. Monitor Azure VM Performance by Using VM Insights
Enable VM Insights for detailed performance monitoring.

### 23.4. Manage Windows Server Resources with Azure Arc Extensions and Policies
Use Azure Arc to manage on-premises servers with Azure tools.

### 23.5. Configure Azure Update Manager for Hybrid Patch Orchestration
Centrally manage Windows updates across hybrid environments.

## Supplemental Resources

- [Azure Monitor Overview](https://learn.microsoft.com/en-us/azure/azure-monitor/overview)
- [Data Collection Rules](https://learn.microsoft.com/en-us/azure/azure-monitor/essentials/data-collection-rule-overview)
- [VM Insights](https://learn.microsoft.com/en-us/azure/azure-monitor/vm/vminsights-overview)
- [Azure Arc](https://learn.microsoft.com/en-us/azure/azure-arc/servers/overview)
- [Azure Update Manager](https://learn.microsoft.com/en-us/azure/update-manager/overview)

## Hands-on Labs

Check the `/labs` subdirectory for hands-on exercises related to this module.

## Files

- `kql-queries.kql` - Sample KQL queries for log analysis

## Notes

- Azure Monitor provides unified monitoring for Azure and on-premises resources
- VM Insights requires the Azure Monitor Agent
- Azure Arc brings Azure management to on-premises and multi-cloud servers
- Update Manager replaces the legacy Update Management solution
- KQL (Kusto Query Language) is used for log queries
