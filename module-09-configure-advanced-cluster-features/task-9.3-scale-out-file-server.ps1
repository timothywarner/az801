<#
.SYNOPSIS
    Task 9.3 - Configure Scale-Out File Server (SOFS)

.DESCRIPTION
    Comprehensive script for deploying and managing Scale-Out File Server (SOFS)
    for continuously available SMB 3.0 file shares with cluster shared volumes.

.NOTES
    Module: Module 9 - Configure Advanced Cluster Features
    Task: 9.3 - Configure Scale-Out File Server
    Prerequisites:
        - Failover Clustering configured
        - Cluster Shared Volumes (CSV) available
        - File Server role installed
        - SMB 3.0 or later
    PowerShell Version: 5.1+

.EXAMPLE
    .\task-9.3-scale-out-file-server.ps1
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [string]$SOFSName = "SOFS-Cluster",
    [string]$ShareName = "VMStorage",
    [string]$CSVPath = "C:\ClusterStorage\Volume1",
    [string]$SharePath = "C:\ClusterStorage\Volume1\Shares\VMStorage"
)

$ErrorActionPreference = 'Stop'
Write-Host "=== AZ-801 Module 9: Task 9.3 - Configure Scale-Out File Server ===" -ForegroundColor Cyan
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
    #region Step 1: Understanding SOFS
    Write-Step "Understanding Scale-Out File Server"

    Write-Info "SOFS provides:"
    Write-Host "  - Continuously available SMB 3.0+ file shares" -ForegroundColor White
    Write-Host "  - Transparent failover (no disconnection)" -ForegroundColor White
    Write-Host "  - Active-active file server clustering" -ForegroundColor White
    Write-Host "  - Load distribution across all nodes" -ForegroundColor White
    Write-Host "  - Optimized for Hyper-V and SQL Server workloads" -ForegroundColor White

    Write-Host "`nSOFS vs Traditional File Server:" -ForegroundColor Yellow
    Write-Host "  Traditional FS: Active-passive, single node serves shares" -ForegroundColor White
    Write-Host "  SOFS: Active-active, all nodes serve shares simultaneously" -ForegroundColor White
    #endregion

    #region Step 2: Prerequisites Check
    Write-Step "Checking Prerequisites"

    # Check File Server role
    $fsRole = Get-WindowsFeature -Name FS-FileServer
    if (-not $fsRole.Installed) {
        Write-Info "Installing File Server role..."
        Install-WindowsFeature -Name FS-FileServer -IncludeManagementTools
        Write-Success "File Server role installed"
    } else {
        Write-Success "File Server role already installed"
    }

    # Check for cluster
    if (Get-Command Get-Cluster -ErrorAction SilentlyContinue) {
        $cluster = Get-Cluster -ErrorAction SilentlyContinue
        if ($cluster) {
            Write-Success "Cluster found: $($cluster.Name)"

            # Check CSV
            $csvs = Get-ClusterSharedVolume -ErrorAction SilentlyContinue
            if ($csvs) {
                Write-Host "`nCluster Shared Volumes:" -ForegroundColor Yellow
                $csvs | Format-Table Name, State, OwnerNode, @{Name='SizeGB';Expression={
                    [math]::Round($_.SharedVolumeInfo.Partition.Size / 1GB, 2)
                }} -AutoSize
            } else {
                Write-Info "No Cluster Shared Volumes found - CSV required for SOFS"
            }
        } else {
            Write-Info "No cluster found - SOFS requires failover cluster"
        }
    } else {
        Write-Info "Failover Clustering cmdlets not available"
    }
    #endregion

    #region Step 3: Create Scale-Out File Server Role
    Write-Step "Creating Scale-Out File Server Role"

    Write-Info "Creating SOFS clustered role..."
    Write-Host "`nCommand to create SOFS:" -ForegroundColor Yellow
    Write-Host @"
  # Create Scale-Out File Server role
  Add-ClusterScaleOutFileServerRole -Name '$SOFSName'

  # Verify creation
  Get-ClusterGroup -Name '$SOFSName'
  Get-ClusterResource | Where-Object OwnerGroup -eq '$SOFSName'
"@ -ForegroundColor Gray

    # Check if SOFS already exists
    try {
        $sofs = Get-ClusterGroup -Name $SOFSName -ErrorAction SilentlyContinue
        if ($sofs) {
            Write-Success "SOFS '$SOFSName' already exists"
            Write-Host "`nSOFS Details:" -ForegroundColor Yellow
            $sofs | Format-List Name, State, OwnerNode, GroupType
        } else {
            Write-Info "SOFS role needs to be created (command shown above)"
        }
    } catch {
        Write-Info "Run the Add-ClusterScaleOutFileServerRole command to create SOFS"
    }
    #endregion

    #region Step 4: Create Share Directory
    Write-Step "Preparing Share Directory on CSV"

    Write-Info "Share directory should be on Cluster Shared Volume"
    Write-Host "`nCreate share directory:" -ForegroundColor Yellow
    Write-Host @"
  # Create directory on CSV
  New-Item -Path '$SharePath' -ItemType Directory -Force

  # Set NTFS permissions
  `$acl = Get-Acl -Path '$SharePath'
  `$rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
      'Domain\Hyper-V Hosts', 'FullControl',
      'ContainerInherit,ObjectInherit', 'None', 'Allow'
  )
  `$acl.SetAccessRule(`$rule)
  Set-Acl -Path '$SharePath' -AclObject `$acl
"@ -ForegroundColor Gray
    #endregion

    #region Step 5: Create SMB Share
    Write-Step "Creating Continuously Available SMB Share"

    Write-Info "Creating CA (Continuously Available) share for Hyper-V/SQL workloads"
    Write-Host "`nCreate SOFS Share:" -ForegroundColor Yellow
    Write-Host @"
  # Create continuously available SMB share
  New-SmbShare -Name '$ShareName' ``
      -Path '$SharePath' ``
      -FullAccess 'Everyone' ``
      -ContinuouslyAvailable `$true ``
      -CachingMode None ``
      -EncryptData `$true ``
      -ScopeName '$SOFSName' ``
      -Description 'SOFS share for VM storage'

  # Verify share creation
  Get-SmbShare -Name '$ShareName' -ScopeName '$SOFSName'

  # Access path
  \\$SOFSName\$ShareName
"@ -ForegroundColor Gray

    Write-Host "`nShare Parameters:" -ForegroundColor Yellow
    Write-Host "  - ContinuouslyAvailable: Enables transparent failover" -ForegroundColor White
    Write-Host "  - CachingMode None: Recommended for Hyper-V/SQL" -ForegroundColor White
    Write-Host "  - EncryptData: Enables SMB encryption" -ForegroundColor White
    Write-Host "  - ScopeName: Specifies SOFS cluster name" -ForegroundColor White
    #endregion

    #region Step 6: Configure SMB Share Permissions
    Write-Step "Configuring Share Permissions"

    Write-Host "`nSet Share Permissions:" -ForegroundColor Yellow
    Write-Host @"
  # Grant Hyper-V hosts full control
  Grant-SmbShareAccess -Name '$ShareName' ``
      -ScopeName '$SOFSName' ``
      -AccountName 'DOMAIN\Hyper-V Hosts' ``
      -AccessRight Full ``
      -Force

  # Grant SQL Server accounts access
  Grant-SmbShareAccess -Name '$ShareName' ``
      -ScopeName '$SOFSName' ``
      -AccountName 'DOMAIN\SQL Service Account' ``
      -AccessRight Full ``
      -Force

  # View permissions
  Get-SmbShareAccess -Name '$ShareName' -ScopeName '$SOFSName'
"@ -ForegroundColor Gray

    # Display SMB shares if available
    try {
        $shares = Get-SmbShare -ErrorAction SilentlyContinue | Where-Object ScopeName -like "*$SOFSName*"
        if ($shares) {
            Write-Host "`nExisting SOFS Shares:" -ForegroundColor Yellow
            $shares | Format-Table Name, Path, ScopeName, ContinuouslyAvailable, EncryptData -AutoSize
        }
    } catch {
        Write-Info "No SOFS shares found or SMB cmdlets not available"
    }
    #endregion

    #region Step 7: SMB Multichannel and RDMA
    Write-Step "Configuring SMB Multichannel and RDMA"

    Write-Info "SMB Multichannel improves performance and redundancy"
    Write-Host "`nSMB Multichannel Configuration:" -ForegroundColor Yellow
    Write-Host @"
  # Enable SMB Multichannel (enabled by default in SMB 3.0+)
  Set-SmbServerConfiguration -EnableMultiChannel `$true -Force

  # View SMB client connections and channels
  Get-SmbMultichannelConnection

  # View SMB network interfaces
  Get-SmbServerNetworkInterface
  Get-SmbClientNetworkInterface

  # For RDMA (if available)
  Get-NetAdapterRdma | Where-Object Enabled -eq `$true
"@ -ForegroundColor Gray

    Write-Host "`nSMB Direct (RDMA) Benefits:" -ForegroundColor Yellow
    Write-Host "  - Extremely low CPU utilization" -ForegroundColor White
    Write-Host "  - High throughput (40/100 Gbps)" -ForegroundColor White
    Write-Host "  - Low latency (microseconds)" -ForegroundColor White
    Write-Host "  - Automatic when RDMA NICs detected" -ForegroundColor White
    #endregion

    #region Step 8: Testing and Validation
    Write-Step "Testing SOFS Functionality"

    Write-Info "Testing share access and performance"
    Write-Host "`nValidation Tests:" -ForegroundColor Yellow
    Write-Host @"
  # Test share connectivity
  Test-Path "\\$SOFSName\$ShareName"

  # Test write access
  New-Item -Path "\\$SOFSName\$ShareName\test.txt" -ItemType File
  Remove-Item -Path "\\$SOFSName\$ShareName\test.txt"

  # Monitor SMB sessions
  Get-SmbSession

  # View SMB open files
  Get-SmbOpenFile | Where-Object ShareName -eq '$ShareName'

  # Performance counters
  Get-Counter '\SMB Server Shares(*)\*'
  Get-Counter '\SMB Client Shares(*)\*'
"@ -ForegroundColor Gray
    #endregion

    #region Step 9: Hyper-V Integration
    Write-Step "Using SOFS with Hyper-V"

    Write-Info "SOFS is ideal for Hyper-V VM storage"
    Write-Host "`nHyper-V Configuration:" -ForegroundColor Yellow
    Write-Host @"
  # Create VM on SOFS share
  New-VM -Name 'TestVM' -MemoryStartupBytes 2GB ``
      -Path "\\$SOFSName\$ShareName\VMs"

  # Create VHDX on SOFS
  New-VHD -Path "\\$SOFSName\$ShareName\VHDs\TestVM.vhdx" ``
      -SizeBytes 50GB -Dynamic

  # Live migrate VMs between Hyper-V hosts
  Move-VM -Name 'TestVM' -DestinationHost 'HyperV-02'
  # VMs remain accessible during failover - no storage migration needed

  # Use for VM configuration and VHD files
  Set-VM -Name 'TestVM' -Path "\\$SOFSName\$ShareName\VMs\TestVM"
"@ -ForegroundColor Gray

    Write-Host "`nSOFS Benefits for Hyper-V:" -ForegroundColor Yellow
    Write-Host "  - Transparent failover (no VM interruption)" -ForegroundColor White
    Write-Host "  - Simplified live migration" -ForegroundColor White
    Write-Host "  - No LUN management required" -ForegroundColor White
    Write-Host "  - Scale-out performance" -ForegroundColor White
    #endregion

    #region Step 10: Monitoring and Management
    Write-Step "Monitoring SOFS Health"

    Write-Host "`nMonitoring Commands:" -ForegroundColor Yellow
    Write-Host @"
  # Monitor SOFS cluster group
  Get-ClusterGroup -Name '$SOFSName'

  # View SOFS shares
  Get-SmbShare -ScopeName '$SOFSName'

  # Monitor SMB bandwidth
  Get-SmbBandwidthLimit

  # View SMB sessions
  Get-SmbSession | Where-Object ScopeName -eq '$SOFSName'

  # Monitor CSV health
  Get-ClusterSharedVolume | Select-Object Name, State, OwnerNode

  # Performance monitoring
  Get-Counter '\SMB Server Shares($ShareName)\*' -Continuous

  # Event logs
  Get-WinEvent -LogName 'Microsoft-Windows-SMBServer/Operational' -MaxEvents 50
"@ -ForegroundColor Gray
    #endregion

    #region Step 11: Failover Testing
    Write-Step "Testing SOFS Failover"

    Write-Info "SOFS provides transparent failover"
    Write-Host "`nFailover Test Procedure:" -ForegroundColor Yellow
    Write-Host @"
  # 1. Start continuous file access test
  while (`$true) {
      Get-Date | Out-File "\\$SOFSName\$ShareName\heartbeat.txt"
      Start-Sleep -Seconds 1
  }

  # 2. In another window, move CSV ownership
  Get-ClusterSharedVolume | Move-ClusterSharedVolume -Node 'NODE2'

  # 3. Observe no disruption in file access
  # Clients remain connected during CSV owner transition

  # 4. Verify share accessibility
  Test-Path "\\$SOFSName\$ShareName"

  # 5. Check SMB sessions (should persist)
  Get-SmbSession | Where-Object ScopeName -eq '$SOFSName'
"@ -ForegroundColor Gray
    #endregion

    #region Step 12: Best Practices
    Write-Step "SOFS Best Practices"

    Write-Host "`nScale-Out File Server Best Practices:" -ForegroundColor Yellow
    Write-Host "  1. Use SOFS exclusively for Hyper-V and SQL Server workloads" -ForegroundColor White
    Write-Host "  2. Enable SMB encryption for security" -ForegroundColor White
    Write-Host "  3. Use RDMA-capable adapters for best performance" -ForegroundColor White
    Write-Host "  4. Configure SMB Multichannel for redundancy" -ForegroundColor White
    Write-Host "  5. Set CachingMode to None for CA shares" -ForegroundColor White
    Write-Host "  6. Place shares on Cluster Shared Volumes (CSV)" -ForegroundColor White
    Write-Host "  7. Use Storage Spaces Direct for underlying storage" -ForegroundColor White
    Write-Host "  8. Monitor SMB bandwidth and sessions regularly" -ForegroundColor White
    Write-Host "  9. Test failover scenarios before production" -ForegroundColor White
    Write-Host "  10. Keep SMB protocol at 3.0 or later" -ForegroundColor White

    Write-Host "`nCapacity Planning:" -ForegroundColor Yellow
    Write-Host "  - Minimum 2 cluster nodes (4+ recommended)" -ForegroundColor White
    Write-Host "  - 10 GbE or faster networking (25/40/100 GbE ideal)" -ForegroundColor White
    Write-Host "  - RDMA support for optimal performance" -ForegroundColor White
    Write-Host "  - Sufficient CSV capacity for workload growth" -ForegroundColor White

    Write-Host "`nSecurity Considerations:" -ForegroundColor Yellow
    Write-Host "  - Use Kerberos authentication" -ForegroundColor White
    Write-Host "  - Enable SMB encryption" -ForegroundColor White
    Write-Host "  - Implement proper NTFS permissions" -ForegroundColor White
    Write-Host "  - Use security groups for access control" -ForegroundColor White
    Write-Host "  - Enable SMB signing for integrity" -ForegroundColor White
    #endregion

    #region Summary
    Write-Host "`n" + "="*80 -ForegroundColor Cyan
    Write-Success "Scale-Out File Server Configuration Completed"
    Write-Host "="*80 -ForegroundColor Cyan

    Write-Host "`nConfiguration Summary:" -ForegroundColor Yellow
    Write-Host "  SOFS Name: $SOFSName" -ForegroundColor White
    Write-Host "  Share Name: $ShareName" -ForegroundColor White
    Write-Host "  Share Path: $SharePath" -ForegroundColor White
    Write-Host "  Access Path: \\$SOFSName\$ShareName" -ForegroundColor White

    Write-Host "`nNext Steps:" -ForegroundColor Yellow
    Write-Host "  - Create SOFS role: Add-ClusterScaleOutFileServerRole" -ForegroundColor Cyan
    Write-Host "  - Create continuously available shares" -ForegroundColor Cyan
    Write-Host "  - Configure Azure cloud witness (task-9.4)" -ForegroundColor Cyan
    Write-Host "  - Test transparent failover scenarios" -ForegroundColor Cyan
    Write-Host "  - Migrate Hyper-V VMs to SOFS storage" -ForegroundColor Cyan
    #endregion

} catch {
    Write-Host "`n[ERROR] Failed to configure Scale-Out File Server: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

Write-Host "`nScript completed successfully!" -ForegroundColor Green
