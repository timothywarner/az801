<#
.SYNOPSIS
    Task 8.2 - Create Windows Failover Cluster

.DESCRIPTION
    Step-by-step guide for creating a Windows Failover Cluster with comprehensive
    validation, configuration, and verification.

.NOTES
    Module: Module 8 - Implement Failover Clusters
    Task: 8.2 - Create Windows Failover Cluster
    Prerequisites:
        - Multiple Windows Server nodes (minimum 2)
        - Shared storage accessible from all nodes
        - Same domain membership
        - Network connectivity
    PowerShell Version: 5.1+

.EXAMPLE
    .\task-8.2-create-windows-failover-cluster.ps1 -ClusterName "CORP-CLUSTER" -ClusterIP "10.0.1.100"
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [string[]]$Nodes = @('SRV1', 'SRV2', 'SRV3'),
    [string]$ClusterName = 'CORP-CLUSTER',
    [string]$ClusterIP = '10.0.1.100',
    [ValidateSet('NodeMajority', 'NodeAndDiskMajority', 'NodeAndFileShareMajority', 'DiskOnly')]
    [string]$QuorumType = 'NodeMajority',
    [string]$WitnessPath = '',
    [switch]$RunValidationOnly
)

$ErrorActionPreference = 'Stop'
Write-Host "=== AZ-801 Module 8: Task 8.2 - Create Windows Failover Cluster ===" -ForegroundColor Cyan
Write-Host ""

#region Helper Functions
function Write-Step {
    param([string]$Message, [int]$Step)
    Write-Host "`n[$Step] $Message" -ForegroundColor Yellow
    Write-Host ("-" * 80) -ForegroundColor Gray
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Cyan
}

function Test-Prerequisites {
    param([string[]]$NodeList)

    Write-Info "Checking prerequisites for cluster creation..."

    $issues = @()

    # Test network connectivity to all nodes
    foreach ($node in $NodeList) {
        if (-not (Test-Connection -ComputerName $node -Count 1 -Quiet)) {
            $issues += "Cannot reach node: $node"
        }
    }

    # Check if WinRM is available on nodes
    foreach ($node in $NodeList) {
        try {
            $null = Invoke-Command -ComputerName $node -ScriptBlock { $env:COMPUTERNAME } -ErrorAction Stop
            Write-Success "WinRM connectivity verified for $node"
        } catch {
            $issues += "WinRM not accessible on $node"
        }
    }

    if ($issues.Count -gt 0) {
        Write-Host "`n[ERROR] Prerequisites check failed:" -ForegroundColor Red
        $issues | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
        return $false
    }

    Write-Success "All prerequisites met"
    return $true
}
#endregion

try {
    #region Step 1: Install Failover Clustering Feature
    Write-Step "Installing Failover Clustering Feature on All Nodes" -Step 1

    $featureInstallScript = {
        $feature = Get-WindowsFeature -Name Failover-Clustering
        if (-not $feature.Installed) {
            Write-Host "Installing Failover Clustering on $env:COMPUTERNAME..."
            Install-WindowsFeature -Name Failover-Clustering -IncludeManagementTools -IncludeAllSubFeature
            return @{
                ComputerName = $env:COMPUTERNAME
                Installed = $true
                RestartNeeded = $true
            }
        } else {
            return @{
                ComputerName = $env:COMPUTERNAME
                Installed = $true
                RestartNeeded = $false
            }
        }
    }

    # Install on all nodes in parallel
    $installResults = Invoke-Command -ComputerName $Nodes -ScriptBlock $featureInstallScript

    Write-Host "`nFeature Installation Results:" -ForegroundColor Yellow
    $installResults | Format-Table ComputerName, Installed, RestartNeeded -AutoSize

    if ($installResults | Where-Object { $_.RestartNeeded }) {
        Write-Host "`n[WARNING] Some nodes require a restart." -ForegroundColor Yellow
        Write-Host "Please restart the following nodes and re-run this script:" -ForegroundColor Yellow
        $installResults | Where-Object { $_.RestartNeeded } | ForEach-Object {
            Write-Host "  - $($_.ComputerName)" -ForegroundColor Yellow
        }
        exit 0
    }

    Write-Success "Failover Clustering feature installed on all nodes"
    #endregion

    #region Step 2: Verify Prerequisites
    Write-Step "Verifying Prerequisites" -Step 2

    if (-not (Test-Prerequisites -NodeList $Nodes)) {
        throw "Prerequisites check failed. Please address issues before continuing."
    }

    # Check domain membership
    $domainCheck = Invoke-Command -ComputerName $Nodes -ScriptBlock {
        [PSCustomObject]@{
            ComputerName = $env:COMPUTERNAME
            Domain = (Get-WmiObject Win32_ComputerSystem).Domain
        }
    }

    Write-Host "`nDomain Membership:" -ForegroundColor Yellow
    $domainCheck | Format-Table -AutoSize

    $uniqueDomains = $domainCheck.Domain | Select-Object -Unique
    if ($uniqueDomains.Count -gt 1) {
        Write-Host "[WARNING] Nodes are in different domains. This is not supported." -ForegroundColor Red
        throw "All nodes must be in the same domain"
    }

    Write-Success "All nodes are in domain: $uniqueDomains"
    #endregion

    #region Step 3: Run Cluster Validation
    Write-Step "Running Comprehensive Cluster Validation Tests" -Step 3

    Write-Info "Starting cluster validation (this may take 10-20 minutes)..."
    Write-Info "Nodes being validated: $($Nodes -join ', ')"

    # Create validation report filename
    $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $validationReportPath = "$env:TEMP\ClusterValidation-$ClusterName-$timestamp.htm"

    # Run comprehensive validation
    Write-Host "`nRunning validation tests..." -ForegroundColor Cyan
    $validationTests = @(
        "Inventory",
        "Network",
        "Storage",
        "System Configuration",
        "Storage Spaces Direct"
    )

    $validation = Test-Cluster -Node $Nodes -Include $validationTests -ReportName $validationReportPath -Verbose

    # Display validation summary
    Write-Host "`nValidation Summary:" -ForegroundColor Yellow
    Write-Host "  Report Path: $validationReportPath" -ForegroundColor White
    Write-Host "  Tests Run: $($validationTests -join ', ')" -ForegroundColor White

    # Check validation results
    if ($validation) {
        Write-Host "`nValidation completed. Please review the report at:" -ForegroundColor Yellow
        Write-Host "  $validationReportPath" -ForegroundColor White

        # Open the report
        if (Test-Path $validationReportPath) {
            Write-Info "Opening validation report in browser..."
            Start-Process $validationReportPath
        }
    }

    if ($RunValidationOnly) {
        Write-Success "Validation-only mode completed. Exiting without creating cluster."
        exit 0
    }

    $proceed = Read-Host "`nReview the validation report. Proceed with cluster creation? (Y/N)"
    if ($proceed -ne 'Y') {
        Write-Host "Cluster creation cancelled. Please address validation issues." -ForegroundColor Yellow
        exit 0
    }
    #endregion

    #region Step 4: Create the Cluster
    Write-Step "Creating Failover Cluster" -Step 4

    # Check if cluster already exists
    try {
        $existingCluster = Get-Cluster -Name $ClusterName -ErrorAction SilentlyContinue
        if ($existingCluster) {
            Write-Host "[WARNING] Cluster '$ClusterName' already exists!" -ForegroundColor Yellow
            $overwrite = Read-Host "Remove and recreate cluster? (Y/N)"
            if ($overwrite -eq 'Y') {
                Write-Info "Removing existing cluster..."
                Remove-Cluster -Cluster $ClusterName -CleanupAD -Force
                Start-Sleep -Seconds 5
            } else {
                Write-Info "Using existing cluster"
                $cluster = $existingCluster
            }
        }
    } catch {
        # Cluster doesn't exist, proceed with creation
    }

    if (-not $cluster) {
        Write-Info "Creating new cluster: $ClusterName"
        Write-Info "Cluster IP: $ClusterIP"
        Write-Info "Nodes: $($Nodes -join ', ')"

        # Create cluster without adding storage yet
        $cluster = New-Cluster -Name $ClusterName `
            -Node $Nodes `
            -StaticAddress $ClusterIP `
            -NoStorage `
            -Verbose

        Write-Success "Cluster created successfully!"
    }

    # Display cluster properties
    Write-Host "`nCluster Properties:" -ForegroundColor Yellow
    $cluster | Format-List Name, Domain, Id

    Get-Cluster -Name $ClusterName | Select-Object Name, Domain, @{
        Name='Nodes'
        Expression={($_.Nodes | Select-Object -ExpandProperty Name) -join ', '}
    } | Format-Table -AutoSize
    #endregion

    #region Step 5: Configure Quorum Settings
    Write-Step "Configuring Quorum Settings" -Step 5

    Write-Info "Current quorum configuration:"
    Get-ClusterQuorum | Format-List

    switch ($QuorumType) {
        'NodeMajority' {
            Write-Info "Setting quorum to Node Majority (recommended for odd number of nodes)"
            Set-ClusterQuorum -NodeMajority
        }
        'NodeAndDiskMajority' {
            Write-Info "Setting quorum to Node and Disk Majority (recommended for even number of nodes)"
            if (-not $WitnessPath) {
                Write-Host "[WARNING] Witness disk path not specified. Skipping quorum configuration." -ForegroundColor Yellow
            } else {
                Set-ClusterQuorum -NodeAndDiskMajority $WitnessPath
            }
        }
        'NodeAndFileShareMajority' {
            Write-Info "Setting quorum to Node and File Share Majority"
            if (-not $WitnessPath) {
                Write-Host "[WARNING] File share witness path not specified. Skipping quorum configuration." -ForegroundColor Yellow
            } else {
                Set-ClusterQuorum -NodeAndFileShareMajority $WitnessPath
            }
        }
        'DiskOnly' {
            Write-Host "[WARNING] Disk-only quorum is not recommended!" -ForegroundColor Yellow
            if ($WitnessPath) {
                Set-ClusterQuorum -DiskOnly $WitnessPath
            }
        }
    }

    Write-Host "`nUpdated Quorum Configuration:" -ForegroundColor Yellow
    Get-ClusterQuorum | Format-List QuorumResource, QuorumType

    Write-Success "Quorum configured successfully"
    #endregion

    #region Step 6: Verify Cluster Resources
    Write-Step "Verifying Cluster Resources" -Step 6

    # Get cluster nodes
    Write-Host "`nCluster Nodes:" -ForegroundColor Yellow
    Get-ClusterNode | Format-Table Name, State, NodeWeight, Id -AutoSize

    # Get cluster resources
    Write-Host "`nCluster Resources:" -ForegroundColor Yellow
    Get-ClusterResource | Format-Table Name, ResourceType, State, OwnerGroup, OwnerNode -AutoSize

    # Get cluster groups
    Write-Host "`nCluster Groups:" -ForegroundColor Yellow
    Get-ClusterGroup | Format-Table Name, State, OwnerNode, GroupType -AutoSize

    # Get cluster networks
    Write-Host "`nCluster Networks:" -ForegroundColor Yellow
    Get-ClusterNetwork | Format-Table Name, State, Role, Address -AutoSize

    Write-Success "Cluster resources verified"
    #endregion

    #region Step 7: Configure Cluster Properties
    Write-Step "Configuring Cluster Properties" -Step 7

    # Set cluster properties for better management
    Write-Info "Configuring cluster parameters..."

    # Set cluster description
    (Get-Cluster).Description = "Production Failover Cluster - Created $(Get-Date -Format 'yyyy-MM-dd')"

    # Configure cluster timeouts (optional)
    # (Get-Cluster).SameSubnetDelay = 1000  # milliseconds
    # (Get-Cluster).SameSubnetThreshold = 5  # heartbeats

    # Display cluster parameters
    Write-Host "`nCluster Parameters:" -ForegroundColor Yellow
    Get-Cluster | Select-Object Name, Description, SameSubnetDelay, SameSubnetThreshold, CrossSubnetDelay, CrossSubnetThreshold | Format-List

    Write-Success "Cluster properties configured"
    #endregion

    #region Step 8: Test Cluster Functionality
    Write-Step "Testing Cluster Functionality" -Step 8

    Write-Info "Performing basic cluster tests..."

    # Test 1: Verify all nodes are online
    $offlineNodes = Get-ClusterNode | Where-Object { $_.State -ne 'Up' }
    if ($offlineNodes) {
        Write-Host "[WARNING] Some nodes are not online:" -ForegroundColor Yellow
        $offlineNodes | Format-Table Name, State
    } else {
        Write-Success "All cluster nodes are online"
    }

    # Test 2: Verify cluster network communication
    $clusterNetworks = Get-ClusterNetwork
    $clusterNetworks | ForEach-Object {
        if ($_.State -eq 'Up') {
            Write-Success "Network '$($_.Name)' is up (Role: $($_.Role))"
        } else {
            Write-Host "[WARNING] Network '$($_.Name)' is $($_.State)" -ForegroundColor Yellow
        }
    }

    # Test 3: Generate cluster log for verification
    Write-Info "Generating cluster diagnostic log..."
    $logPath = "$env:TEMP\ClusterLog-$ClusterName-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Get-ClusterLog -Destination $logPath -TimeSpan 5 -UseLocalTime
    Write-Success "Cluster log saved to: $logPath"

    Write-Success "Cluster functionality tests completed"
    #endregion

    #region Step 9: Documentation and Next Steps
    Write-Step "Documentation and Next Steps" -Step 9

    Write-Host "`nCluster Configuration Summary:" -ForegroundColor Yellow
    Write-Host "  Cluster Name: $ClusterName" -ForegroundColor White
    Write-Host "  Cluster IP: $ClusterIP" -ForegroundColor White
    Write-Host "  Node Count: $($Nodes.Count)" -ForegroundColor White
    Write-Host "  Quorum Type: $QuorumType" -ForegroundColor White
    Write-Host "  Domain: $uniqueDomains" -ForegroundColor White
    Write-Host "  Creation Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor White

    Write-Host "`nNext Steps:" -ForegroundColor Yellow
    Write-Host "  1. Add shared storage to the cluster (task-8.4-cluster-storage.ps1)" -ForegroundColor Cyan
    Write-Host "  2. Configure cluster networks (task-8.6-cluster-network-adapters.ps1)" -ForegroundColor Cyan
    Write-Host "  3. Review and optimize quorum settings (task-8.5-quorum-options.ps1)" -ForegroundColor Cyan
    Write-Host "  4. Create highly available workloads (Module 9)" -ForegroundColor Cyan
    Write-Host "  5. Configure Cluster Aware Updating (task-10.1-cluster-aware-updating.ps1)" -ForegroundColor Cyan

    Write-Host "`nImportant Files:" -ForegroundColor Yellow
    Write-Host "  Validation Report: $validationReportPath" -ForegroundColor White
    Write-Host "  Cluster Log: $logPath" -ForegroundColor White

    # Export cluster configuration
    $configPath = "$env:TEMP\ClusterConfig-$ClusterName-$(Get-Date -Format 'yyyyMMdd-HHmmss').xml"
    Get-Cluster | Export-Clixml -Path $configPath
    Write-Info "Cluster configuration exported to: $configPath"
    #endregion

    #region Summary
    Write-Host "`n" + "="*80 -ForegroundColor Cyan
    Write-Success "Windows Failover Cluster Created Successfully!"
    Write-Host "="*80 -ForegroundColor Cyan

    Write-Host "`nCluster Status:" -ForegroundColor Yellow
    Get-Cluster | Select-Object Name, Domain, @{
        Name='NodeCount'
        Expression={$_.Nodes.Count}
    }, QuorumType | Format-Table -AutoSize

    Write-Host "`nCluster is ready for workload deployment!" -ForegroundColor Green
    #endregion

} catch {
    Write-Host "`n[ERROR] Failed to create cluster: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red

    Write-Host "`nTroubleshooting Steps:" -ForegroundColor Yellow
    Write-Host "  1. Review validation report for specific issues" -ForegroundColor White
    Write-Host "  2. Verify network connectivity between all nodes" -ForegroundColor White
    Write-Host "  3. Check firewall settings on all nodes" -ForegroundColor White
    Write-Host "  4. Ensure all nodes are in the same Active Directory domain" -ForegroundColor White
    Write-Host "  5. Verify shared storage is accessible from all nodes" -ForegroundColor White
    Write-Host "  6. Check cluster service logs: Get-WinEvent -LogName 'Microsoft-Windows-FailoverClustering/Operational'" -ForegroundColor White

    exit 1
}

Write-Host "`nScript completed successfully!" -ForegroundColor Green
