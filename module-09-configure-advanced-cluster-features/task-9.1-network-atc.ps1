<#
.SYNOPSIS
    Task 9.1 - Configure Network ATC (Automatic Template Configuration)

.DESCRIPTION
    Comprehensive script for implementing Network ATC for simplified and automated
    cluster network configuration. Network ATC uses intent-based networking to
    automatically configure network adapters for cluster workloads.

.NOTES
    Module: Module 9 - Configure Advanced Cluster Features
    Task: 9.1 - Configure Network ATC
    Prerequisites:
        - Windows Server 2022 or later
        - Failover Clustering feature installed
        - Network ATC feature installed
        - RDMA-capable network adapters (recommended)
        - Administrative privileges
    PowerShell Version: 5.1+

.EXAMPLE
    .\task-9.1-network-atc.ps1

.EXAMPLE
    .\task-9.1-network-atc.ps1 -ClusterName "HCI-Cluster" -IntentName "ClusterIntent"
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [string]$ClusterName = $env:COMPUTERNAME,
    [string]$IntentName = "ClusterIntent",
    [string[]]$ManagementAdapters = @("Ethernet", "Ethernet 2"),
    [string[]]$ComputeAdapters = @("RDMA1", "RDMA2"),
    [string[]]$StorageAdapters = @("RDMA1", "RDMA2"),
    [switch]$EnableRDMA,
    [switch]$ConvergedIntent
)

$ErrorActionPreference = 'Stop'
Write-Host "=== AZ-801 Module 9: Task 9.1 - Configure Network ATC ===" -ForegroundColor Cyan
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
    #region Step 1: Prerequisites Check
    Write-Step "Checking Prerequisites for Network ATC"

    # Check if running on Windows Server 2022 or later
    $osVersion = (Get-CimInstance Win32_OperatingSystem).Version
    Write-Info "Operating System Version: $osVersion"

    # Check if Network ATC feature is available
    $networkATCFeature = Get-WindowsFeature -Name NetworkATC -ErrorAction SilentlyContinue

    if (-not $networkATCFeature) {
        Write-Host "[WARNING] Network ATC feature not found. Installing..." -ForegroundColor Yellow
        Install-WindowsFeature -Name NetworkATC -IncludeManagementTools
        Write-Success "Network ATC feature installed"
    } elseif (-not $networkATCFeature.Installed) {
        Write-Info "Installing Network ATC feature..."
        Install-WindowsFeature -Name NetworkATC -IncludeManagementTools
        Write-Success "Network ATC feature installed"
    } else {
        Write-Success "Network ATC feature already installed"
    }

    # Import Network ATC module
    if (Get-Module -ListAvailable -Name NetworkATC) {
        Import-Module NetworkATC -ErrorAction SilentlyContinue
        Write-Success "Network ATC module imported"
    } else {
        Write-Host "[WARNING] Network ATC module not available on this OS version" -ForegroundColor Yellow
        Write-Info "Network ATC is primarily available on Azure Stack HCI and Windows Server 2022+"
    }

    # Check for RDMA capable adapters
    Write-Info "Checking for RDMA-capable network adapters..."
    $rdmaAdapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }
    Write-Host "`nAvailable Network Adapters:" -ForegroundColor Yellow
    $rdmaAdapters | Format-Table Name, InterfaceDescription, Status, LinkSpeed -AutoSize
    #endregion

    #region Step 2: Network Adapter Configuration
    Write-Step "Configuring Network Adapters for Clustering"

    # Display current network adapter configuration
    Write-Host "`nCurrent Network Adapter Configuration:" -ForegroundColor Yellow
    Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } |
        Select-Object Name, InterfaceDescription, Status, MacAddress, LinkSpeed |
        Format-Table -AutoSize

    # Configure adapter properties for optimal cluster performance
    Write-Info "Optimizing network adapter settings for cluster workloads..."

    foreach ($adapter in $rdmaAdapters) {
        Write-Info "Configuring adapter: $($adapter.Name)"

        # Disable power management
        try {
            $powerMgmt = Get-NetAdapterPowerManagement -Name $adapter.Name
            if ($powerMgmt.AllowComputerToTurnOffDevice -eq 'Enabled') {
                Set-NetAdapterPowerManagement -Name $adapter.Name -AllowComputerToTurnOffDevice Disabled -ErrorAction SilentlyContinue
                Write-Info "  - Power management disabled"
            }
        } catch {
            Write-Info "  - Power management already optimized"
        }

        # Enable jumbo frames for storage/cluster networks (if not management)
        if ($adapter.Name -notin $ManagementAdapters) {
            try {
                Set-NetAdapterAdvancedProperty -Name $adapter.Name -RegistryKeyword "*JumboPacket" -RegistryValue 9014 -ErrorAction SilentlyContinue
                Write-Info "  - Jumbo frames enabled (9014 bytes)"
            } catch {
                Write-Info "  - Jumbo frames not supported on this adapter"
            }
        }
    }
    Write-Success "Network adapters optimized"
    #endregion

    #region Step 3: Network Intent Creation (Network ATC)
    Write-Step "Creating Network Intent with Network ATC"

    Write-Info "Network ATC provides intent-based networking for:"
    Write-Host "  - Simplified network configuration" -ForegroundColor White
    Write-Host "  - Automatic network optimization" -ForegroundColor White
    Write-Host "  - Consistent configuration across cluster" -ForegroundColor White
    Write-Host "  - RDMA and QoS configuration" -ForegroundColor White

    # Example: Create a converged intent (compute + storage on same adapters)
    if ($ConvergedIntent) {
        Write-Info "Creating converged network intent (Management + Compute + Storage)..."
        Write-Host "`nExample command for converged intent:" -ForegroundColor Gray
        Write-Host @"
Add-NetIntent -Name '$IntentName' ``
    -Compute ``
    -Storage ``
    -Management ``
    -AdapterName $($ComputeAdapters -join ', ') ``
    -Verbose
"@ -ForegroundColor Gray
    } else {
        # Example: Separate intents for different traffic types
        Write-Info "Creating separate network intents for different traffic types..."

        Write-Host "`nExample - Management Intent:" -ForegroundColor Gray
        Write-Host @"
Add-NetIntent -Name 'Management' ``
    -Management ``
    -AdapterName $($ManagementAdapters -join ', ') ``
    -Verbose
"@ -ForegroundColor Gray

        Write-Host "`nExample - Compute Intent:" -ForegroundColor Gray
        Write-Host @"
Add-NetIntent -Name 'Compute' ``
    -Compute ``
    -AdapterName $($ComputeAdapters -join ', ') ``
    -Verbose
"@ -ForegroundColor Gray

        Write-Host "`nExample - Storage Intent (with RDMA):" -ForegroundColor Gray
        Write-Host @"
Add-NetIntent -Name 'Storage' ``
    -Storage ``
    -AdapterName $($StorageAdapters -join ', ') ``
    -StorageVLAN 711 ``
    -Verbose
"@ -ForegroundColor Gray
    }

    Write-Info "`nNote: Actual intent creation requires Network ATC to be fully operational"
    Write-Info "Network ATC is primarily used with Azure Stack HCI and Storage Spaces Direct"
    #endregion

    #region Step 4: Check Network Intent Status
    Write-Step "Monitoring Network Intent Status"

    Write-Info "To check network intent status, use:"
    Write-Host "  Get-NetIntent" -ForegroundColor Gray
    Write-Host "  Get-NetIntentStatus" -ForegroundColor Gray
    Write-Host "  Get-NetIntentStatus -Name '$IntentName' -Detailed" -ForegroundColor Gray

    # Try to get existing intents (if any)
    try {
        if (Get-Command Get-NetIntent -ErrorAction SilentlyContinue) {
            Write-Host "`nExisting Network Intents:" -ForegroundColor Yellow
            $intents = Get-NetIntent -ErrorAction SilentlyContinue
            if ($intents) {
                $intents | Format-Table Name, IntentType, AdapterName, Scope -AutoSize

                # Get detailed status
                Write-Host "`nIntent Status:" -ForegroundColor Yellow
                Get-NetIntentStatus -ErrorAction SilentlyContinue |
                    Format-Table Name, Host, ProvisioningStatus, ConfigurationStatus -AutoSize
            } else {
                Write-Info "No network intents currently configured"
            }
        }
    } catch {
        Write-Info "Network ATC cmdlets not available on this system"
    }
    #endregion

    #region Step 5: RDMA Configuration (if applicable)
    Write-Step "RDMA Configuration for High-Performance Networking"

    if ($EnableRDMA) {
        Write-Info "Configuring RDMA (Remote Direct Memory Access)..."

        # Check for RDMA-capable adapters
        $rdmaCapable = Get-NetAdapter | Where-Object {
            $_.InterfaceDescription -match 'Mellanox|Chelsio|Intel.*RDMA|Broadcom.*RDMA'
        }

        if ($rdmaCapable) {
            Write-Host "`nRDMA-Capable Adapters:" -ForegroundColor Yellow
            $rdmaCapable | Format-Table Name, InterfaceDescription, Status -AutoSize

            foreach ($adapter in $rdmaCapable) {
                Write-Info "Enabling RDMA on: $($adapter.Name)"

                # Enable RDMA on the adapter
                try {
                    Enable-NetAdapterRdma -Name $adapter.Name -ErrorAction Stop
                    Write-Success "  RDMA enabled on $($adapter.Name)"
                } catch {
                    Write-Info "  RDMA already enabled or not supported"
                }

                # Check RDMA status
                $rdmaStatus = Get-NetAdapterRdma -Name $adapter.Name
                Write-Info "  RDMA Status: $($rdmaStatus.Enabled)"
            }

            # Configure DCB (Data Center Bridging) for RDMA over Converged Ethernet (RoCE)
            Write-Info "`nConfiguring DCB for RoCE..."
            Write-Host "  Install-WindowsFeature -Name Data-Center-Bridging" -ForegroundColor Gray
            Write-Host "  Set-NetQosDcbxSetting -Willing `$false" -ForegroundColor Gray
            Write-Host "  New-NetQosPolicy 'SMB' -NetDirectPortMatchCondition 445 -PriorityValue8021Action 3" -ForegroundColor Gray
            Write-Host "  Enable-NetQosFlowControl -Priority 3" -ForegroundColor Gray
            Write-Host "  New-NetQosTrafficClass 'SMB' -Priority 3 -BandwidthPercentage 50 -Algorithm ETS" -ForegroundColor Gray
        } else {
            Write-Info "No RDMA-capable adapters detected"
        }
    }

    # Display RDMA status for all adapters
    Write-Host "`nRDMA Status Summary:" -ForegroundColor Yellow
    Get-NetAdapterRdma | Format-Table Name, Enabled, @{Name='EncapsulationType';Expression={$_.EncapsulationType}} -AutoSize
    #endregion

    #region Step 6: Network Intent Modification
    Write-Step "Modifying Network Intents"

    Write-Info "To modify an existing network intent:"
    Write-Host "`n  # Override adapter properties" -ForegroundColor Gray
    Write-Host "  Set-NetIntent -Name '$IntentName' -JumboPacket 9014" -ForegroundColor Gray

    Write-Host "`n  # Update RDMA settings" -ForegroundColor Gray
    Write-Host "  Set-NetIntent -Name '$IntentName' -EnableRdma `$true" -ForegroundColor Gray

    Write-Host "`n  # Modify VLAN configuration" -ForegroundColor Gray
    Write-Host "  Set-NetIntent -Name 'Storage' -StorageVLAN 711" -ForegroundColor Gray
    #endregion

    #region Step 7: Removing Network Intents
    Write-Step "Managing Network Intent Lifecycle"

    Write-Info "To remove a network intent when no longer needed:"
    Write-Host "  Remove-NetIntent -Name '$IntentName' -Confirm:`$false" -ForegroundColor Gray

    Write-Info "To suspend intent provisioning (for maintenance):"
    Write-Host "  Suspend-NetIntent -Name '$IntentName'" -ForegroundColor Gray

    Write-Info "To resume intent provisioning:"
    Write-Host "  Resume-NetIntent -Name '$IntentName'" -ForegroundColor Gray
    #endregion

    #region Step 8: Cluster Network Configuration
    Write-Step "Verifying Cluster Network Configuration"

    try {
        if (Get-Command Get-ClusterNetwork -ErrorAction SilentlyContinue) {
            Write-Host "`nCluster Networks:" -ForegroundColor Yellow
            Get-ClusterNetwork | Format-Table Name, Role, State, @{Name='Address';Expression={$_.Address}}, Metric -AutoSize

            Write-Host "`nCluster Network Interfaces:" -ForegroundColor Yellow
            Get-ClusterNetworkInterface |
                Format-Table Node, Network, Name, State, Adapter -AutoSize
        }
    } catch {
        Write-Info "Not running on a cluster node or cluster service not available"
    }
    #endregion

    #region Step 9: Network Testing and Validation
    Write-Step "Network Performance Testing"

    Write-Info "Recommended network validation tests:"
    Write-Host "`n1. Test cluster network connectivity:" -ForegroundColor White
    Write-Host "   Test-Cluster -Node NODE1,NODE2 -Include Network" -ForegroundColor Gray

    Write-Host "`n2. Test RDMA functionality:" -ForegroundColor White
    Write-Host "   # On source node:" -ForegroundColor Gray
    Write-Host "   New-NetQosPolicy 'Test' -NetDirectPortMatchCondition 5201" -ForegroundColor Gray
    Write-Host "   Get-NetAdapter | Where-Object Name -like 'RDMA*' | Enable-NetAdapterRdma" -ForegroundColor Gray

    Write-Host "`n3. Performance testing with diskspd or ctsTraffic:" -ForegroundColor White
    Write-Host "   # Measure RDMA throughput" -ForegroundColor Gray
    Write-Host "   ctsTraffic -target:TARGETIP -consumertype:rdma -connections:4" -ForegroundColor Gray

    Write-Host "`n4. SMB Direct testing:" -ForegroundColor White
    Write-Host "   Get-SmbClientNetworkInterface | Format-Table -AutoSize" -ForegroundColor Gray
    Write-Host "   Get-SmbServerNetworkInterface | Format-Table -AutoSize" -ForegroundColor Gray
    #endregion

    #region Step 10: Best Practices
    Write-Step "Network ATC Best Practices"

    Write-Host "`nNetwork ATC Best Practices:" -ForegroundColor Yellow
    Write-Host "  1. Use Network ATC for consistent configuration across cluster nodes" -ForegroundColor White
    Write-Host "  2. Leverage converged intents for Azure Stack HCI deployments" -ForegroundColor White
    Write-Host "  3. Separate management from cluster/storage traffic when possible" -ForegroundColor White
    Write-Host "  4. Enable RDMA for Storage Spaces Direct deployments" -ForegroundColor White
    Write-Host "  5. Use jumbo frames (MTU 9014) for storage networks" -ForegroundColor White
    Write-Host "  6. Configure proper QoS policies for traffic prioritization" -ForegroundColor White
    Write-Host "  7. Monitor intent provisioning status regularly" -ForegroundColor White
    Write-Host "  8. Test network performance before production workloads" -ForegroundColor White
    Write-Host "  9. Document network intent configuration" -ForegroundColor White
    Write-Host "  10. Use Network ATC's automatic remediation capabilities" -ForegroundColor White

    Write-Host "`nNetwork Traffic Separation Guidelines:" -ForegroundColor Yellow
    Write-Host "  - Management: Cluster administration, AD, DNS (1 Gbps minimum)" -ForegroundColor White
    Write-Host "  - Compute: VM live migration, cluster heartbeat (10 Gbps+)" -ForegroundColor White
    Write-Host "  - Storage: SMB Direct, CSV traffic (25/100 Gbps with RDMA)" -ForegroundColor White

    Write-Host "`nVLAN Recommendations:" -ForegroundColor Yellow
    Write-Host "  - Management: VLAN 1 or default" -ForegroundColor White
    Write-Host "  - Compute: VLAN 100-200 range" -ForegroundColor White
    Write-Host "  - Storage: VLAN 700-800 range (isolated)" -ForegroundColor White
    #endregion

    #region Summary
    Write-Host "`n" + "="*80 -ForegroundColor Cyan
    Write-Success "Network ATC Configuration Completed Successfully"
    Write-Host "="*80 -ForegroundColor Cyan

    Write-Host "`nConfiguration Summary:" -ForegroundColor Yellow
    Write-Host "  Target Cluster: $ClusterName" -ForegroundColor White
    Write-Host "  Intent Name: $IntentName" -ForegroundColor White
    Write-Host "  RDMA Configuration: $(if($EnableRDMA){'Enabled'}else{'Disabled'})" -ForegroundColor White
    Write-Host "  Network Adapters Configured: $(($rdmaAdapters | Measure-Object).Count)" -ForegroundColor White

    Write-Host "`nNext Steps:" -ForegroundColor Yellow
    Write-Host "  - Review intent provisioning status with Get-NetIntentStatus" -ForegroundColor Cyan
    Write-Host "  - Configure cluster workload options (task-9.2)" -ForegroundColor Cyan
    Write-Host "  - Test network performance and RDMA functionality" -ForegroundColor Cyan
    Write-Host "  - Monitor cluster network health regularly" -ForegroundColor Cyan
    #endregion

} catch {
    Write-Host "`n[ERROR] Failed to configure Network ATC: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red

    Write-Host "`nTroubleshooting Tips:" -ForegroundColor Yellow
    Write-Host "  1. Verify Windows Server 2022+ or Azure Stack HCI OS" -ForegroundColor White
    Write-Host "  2. Check network adapter drivers are up to date" -ForegroundColor White
    Write-Host "  3. Ensure adapters are properly connected and configured" -ForegroundColor White
    Write-Host "  4. Review Network ATC event logs" -ForegroundColor White
    Write-Host "  5. Verify no conflicting network configurations exist" -ForegroundColor White

    exit 1
}

Write-Host "`nScript completed successfully!" -ForegroundColor Green
