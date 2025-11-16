<#
.SYNOPSIS
    Task 8.4 - Configure Cluster Storage

.DESCRIPTION
    Comprehensive script for configuring shared storage, cluster disks, and
    Cluster Shared Volumes (CSV) in Windows Failover Clusters.

.NOTES
    Module: Module 8 - Implement Failover Clusters
    Task: 8.4 - Configure Cluster Storage
    Prerequisites:
        - Existing failover cluster
        - Shared storage accessible from all nodes (SAN, iSCSI, or S2D)
        - Administrative privileges
    PowerShell Version: 5.1+

.EXAMPLE
    .\task-8.4-cluster-storage.ps1
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [string]$ClusterName = '',
    [switch]$AutoAddDisks,
    [switch]$ConvertToCSV
)

$ErrorActionPreference = 'Stop'
Write-Host "=== AZ-801 Module 8: Task 8.4 - Configure Cluster Storage ===" -ForegroundColor Cyan
Write-Host ""

#region Helper Functions
function Write-Step {
    param([string]$Message)
    Write-Host "`n[STEP] $Message" -ForegroundColor Yellow
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
#endregion

try {
    #region Step 1: Verify Cluster and Prerequisites
    Write-Step "Verifying Cluster and Storage Prerequisites"

    # Get cluster
    if ($ClusterName) {
        $cluster = Get-Cluster -Name $ClusterName
    } else {
        $cluster = Get-Cluster
    }

    Write-Success "Connected to cluster: $($cluster.Name)"
    Write-Info "Cluster nodes: $(($cluster | Get-ClusterNode | Select-Object -ExpandProperty Name) -join ', ')"

    # Verify cluster is healthy
    $nodes = Get-ClusterNode
    $upNodes = $nodes | Where-Object { $_.State -eq 'Up' }
    Write-Host "`nCluster Health: $($upNodes.Count) of $($nodes.Count) nodes online" -ForegroundColor $(if ($upNodes.Count -eq $nodes.Count) { 'Green' } else { 'Yellow' })
    #endregion

    #region Step 2: Discover Available Storage
    Write-Step "Discovering Available Storage"

    Write-Info "Scanning for shared disks visible to all cluster nodes..."

    # Get disks available to cluster
    $availableDisks = Get-Disk | Where-Object {
        $_.BusType -in @('iSCSI', 'SAS', 'Fibre Channel', 'RAID') -and
        $_.PartitionStyle -eq 'RAW' -or
        ($_.PartitionStyle -eq 'GPT' -and $_.NumberOfPartitions -eq 0)
    }

    if ($availableDisks) {
        Write-Host "`nAvailable Disks for Clustering:" -ForegroundColor Yellow
        $availableDisks | Format-Table Number, FriendlyName, SerialNumber, @{
            Name='Size(GB)'
            Expression={[Math]::Round($_.Size/1GB, 2)}
        }, OperationalStatus, PartitionStyle -AutoSize
    } else {
        Write-Host "[INFO] No new disks available. Showing all disks:" -ForegroundColor Cyan
        Get-Disk | Format-Table Number, FriendlyName, @{
            Name='Size(GB)'
            Expression={[Math]::Round($_.Size/1GB, 2)}
        }, PartitionStyle, OperationalStatus -AutoSize
    }

    # Get disks already in cluster
    $clusterDisks = Get-ClusterResource | Where-Object { $_.ResourceType -eq 'Physical Disk' }

    if ($clusterDisks) {
        Write-Host "`nDisks Already in Cluster:" -ForegroundColor Yellow
        $clusterDisks | Format-Table Name, State, OwnerNode, OwnerGroup -AutoSize
    } else {
        Write-Info "No disks currently added to cluster"
    }
    #endregion

    #region Step 3: Initialize and Prepare Disks
    Write-Step "Initializing and Preparing Disks for Clustering"

    # Example: Prepare a raw disk for clustering
    $rawDisks = Get-Disk | Where-Object { $_.PartitionStyle -eq 'RAW' }

    if ($rawDisks) {
        Write-Host "`nRaw Disks Found:" -ForegroundColor Yellow
        $rawDisks | Format-Table Number, FriendlyName, @{
            Name='Size(GB)'
            Expression={[Math]::Round($_.Size/1GB, 2)}
        } -AutoSize

        if ($AutoAddDisks) {
            foreach ($disk in $rawDisks) {
                Write-Info "Initializing disk $($disk.Number)..."

                # Initialize disk as GPT
                Initialize-Disk -Number $disk.Number -PartitionStyle GPT -PassThru | Out-Null

                # Create partition
                $partition = New-Partition -DiskNumber $disk.Number -UseMaximumSize -AssignDriveLetter

                # Format with NTFS or ReFS
                $volume = Format-Volume -DriveLetter $partition.DriveLetter `
                    -FileSystem NTFS `
                    -NewFileSystemLabel "ClusterDisk$($disk.Number)" `
                    -Confirm:$false

                Write-Success "Disk $($disk.Number) initialized and formatted (Drive $($partition.DriveLetter):)"
            }
        } else {
            Write-Host "`nTo initialize disks manually:" -ForegroundColor Gray
            Write-Host "  Initialize-Disk -Number <DiskNumber> -PartitionStyle GPT" -ForegroundColor Gray
            Write-Host "  New-Partition -DiskNumber <DiskNumber> -UseMaximumSize -AssignDriveLetter" -ForegroundColor Gray
            Write-Host "  Format-Volume -DriveLetter <Letter> -FileSystem NTFS -NewFileSystemLabel 'ClusterDisk'" -ForegroundColor Gray
        }
    } else {
        Write-Info "No raw disks found"
    }
    #endregion

    #region Step 4: Add Disks to Cluster
    Write-Step "Adding Eligible Disks to Cluster"

    # Get eligible disks (formatted, not in cluster)
    $eligibleDisks = Get-Disk | Where-Object {
        $_.PartitionStyle -eq 'GPT' -and
        $_.NumberOfPartitions -gt 0 -and
        $_.OperationalStatus -eq 'Online'
    }

    if ($eligibleDisks) {
        Write-Host "`nEligible Disks:" -ForegroundColor Yellow
        $eligibleDisks | Format-Table Number, FriendlyName, @{
            Name='Size(GB)'
            Expression={[Math]::Round($_.Size/1GB, 2)}
        }, PartitionStyle -AutoSize

        if ($AutoAddDisks) {
            foreach ($disk in $eligibleDisks) {
                # Check if disk is already in cluster
                $existingResource = Get-ClusterResource | Where-Object {
                    $_.ResourceType -eq 'Physical Disk' -and
                    ($_ | Get-ClusterParameter -Name DiskSignature).Value -eq $disk.Signature
                }

                if (-not $existingResource) {
                    Write-Info "Adding disk $($disk.Number) to cluster..."
                    try {
                        $clusterDisk = Add-ClusterDisk -InputObject $disk
                        Write-Success "Disk $($disk.Number) added as cluster resource: $($clusterDisk.Name)"
                    } catch {
                        Write-Host "[WARNING] Could not add disk $($disk.Number): $_" -ForegroundColor Yellow
                    }
                } else {
                    Write-Info "Disk $($disk.Number) already in cluster as $($existingResource.Name)"
                }
            }
        } else {
            Write-Host "`nTo add disks to cluster:" -ForegroundColor Gray
            Write-Host "  Get-Disk -Number <DiskNumber> | Add-ClusterDisk" -ForegroundColor Gray
        }
    }

    # Display current cluster disks
    Write-Host "`nCurrent Cluster Disks:" -ForegroundColor Yellow
    Get-ClusterResource | Where-Object { $_.ResourceType -eq 'Physical Disk' } |
        ForEach-Object {
            $diskInfo = $_ | Get-ClusterParameter
            [PSCustomObject]@{
                Name = $_.Name
                State = $_.State
                OwnerNode = $_.OwnerNode
                OwnerGroup = $_.OwnerGroup
                Size = ($diskInfo | Where-Object { $_.Name -eq 'Size' }).Value
            }
        } | Format-Table -AutoSize
    #endregion

    #region Step 5: Configure Cluster Shared Volumes (CSV)
    Write-Step "Configuring Cluster Shared Volumes (CSV)"

    Write-Info "CSV Benefits:"
    Write-Host "  - Multiple nodes can access the same storage simultaneously" -ForegroundColor White
    Write-Host "  - Required for Hyper-V clusters with live migration" -ForegroundColor White
    Write-Host "  - Simplified storage management" -ForegroundColor White
    Write-Host "  - Automatic failover and redirection" -ForegroundColor White

    # Get cluster disks not yet in CSV
    $nonCSVDisks = Get-ClusterResource | Where-Object {
        $_.ResourceType -eq 'Physical Disk' -and
        $_.OwnerGroup -ne 'Cluster Group' -and
        -not (Get-ClusterSharedVolume | Where-Object { $_.Name -eq $_.Name })
    }

    if ($nonCSVDisks) {
        Write-Host "`nDisks Available for CSV Conversion:" -ForegroundColor Yellow
        $nonCSVDisks | Format-Table Name, State, OwnerNode -AutoSize

        if ($ConvertToCSV) {
            foreach ($disk in $nonCSVDisks) {
                Write-Info "Converting $($disk.Name) to CSV..."
                try {
                    $csv = Add-ClusterSharedVolume -Name $disk.Name
                    Write-Success "$($disk.Name) converted to CSV: $($csv.Name)"
                } catch {
                    Write-Host "[WARNING] Could not convert $($disk.Name) to CSV: $_" -ForegroundColor Yellow
                }
            }
        } else {
            Write-Host "`nTo convert to CSV:" -ForegroundColor Gray
            Write-Host "  Add-ClusterSharedVolume -Name '<DiskResourceName>'" -ForegroundColor Gray
        }
    } else {
        Write-Info "No non-CSV disks available for conversion"
    }

    # Display CSV configuration
    $csvs = Get-ClusterSharedVolume

    if ($csvs) {
        Write-Host "`nCluster Shared Volumes:" -ForegroundColor Yellow
        $csvs | ForEach-Object {
            $csvInfo = $_.SharedVolumeInfo[0]
            [PSCustomObject]@{
                Name = $_.Name
                OwnerNode = $_.OwnerNode
                State = $_.State
                Path = $csvInfo.FriendlyVolumeName
                PartitionNumber = $csvInfo.PartitionNumber
                'Size(GB)' = [Math]::Round($csvInfo.Partition.Size/1GB, 2)
                'FreeSpace(GB)' = [Math]::Round($csvInfo.Partition.FreeSpace/1GB, 2)
            }
        } | Format-Table -AutoSize

        Write-Success "CSV is accessible at: C:\ClusterStorage\Volume*"
    } else {
        Write-Info "No Cluster Shared Volumes configured"
    }
    #endregion

    #region Step 6: Configure Cluster Storage Parameters
    Write-Step "Configuring Cluster Storage Parameters"

    Write-Info "Optimizing cluster storage settings..."

    # Get cluster resource types
    $physicalDiskType = Get-ClusterResourceType -Name "Physical Disk"

    # Display storage-related cluster parameters
    Write-Host "`nCluster Storage Parameters:" -ForegroundColor Yellow
    Get-Cluster | Get-ClusterParameter | Where-Object {
        $_.Name -match 'Storage|Disk|Volume'
    } | Format-Table Name, Value, Description -AutoSize

    # CSV Cache configuration (for Hyper-V workloads)
    Write-Host "`nCSV Cache Configuration:" -ForegroundColor Yellow
    $csvCache = (Get-Cluster).BlockCacheSize
    Write-Host "  Current CSV Cache Size: $csvCache MB" -ForegroundColor White

    Write-Host "`nTo configure CSV cache (recommended for Hyper-V):" -ForegroundColor Gray
    Write-Host "  (Get-Cluster).BlockCacheSize = 512  # Set to 512 MB or higher" -ForegroundColor Gray

    # CSV network settings
    Write-Host "`nCSV Network Configuration:" -ForegroundColor Yellow
    Write-Host "  To configure CSV preferred networks:" -ForegroundColor Gray
    Write-Host "  (Get-ClusterNetwork 'Storage Network').Metric = 1000" -ForegroundColor Gray
    #endregion

    #region Step 7: Storage Performance and Monitoring
    Write-Step "Storage Performance and Monitoring"

    Write-Info "Checking storage health..."

    # Get physical disk resources and their status
    $diskResources = Get-ClusterResource | Where-Object { $_.ResourceType -eq 'Physical Disk' }

    foreach ($diskResource in $diskResources) {
        $diskParams = $diskResource | Get-ClusterParameter
        $signature = ($diskParams | Where-Object { $_.Name -eq 'DiskSignature' }).Value

        Write-Host "`nDisk Resource: $($diskResource.Name)" -ForegroundColor Yellow
        Write-Host "  State: $($diskResource.State)" -ForegroundColor White
        Write-Host "  Owner Node: $($diskResource.OwnerNode)" -ForegroundColor White
        Write-Host "  Signature: $signature" -ForegroundColor White
    }

    # CSV status
    if ($csvs) {
        Write-Host "`nCSV Detailed Status:" -ForegroundColor Yellow
        $csvs | ForEach-Object {
            $csvInfo = $_.SharedVolumeInfo[0]
            Write-Host "`n  Volume: $($_.Name)" -ForegroundColor Cyan
            Write-Host "    Owner: $($_.OwnerNode)" -ForegroundColor White
            Write-Host "    Path: $($csvInfo.FriendlyVolumeName)" -ForegroundColor White
            Write-Host "    State: $($_.State)" -ForegroundColor White
            Write-Host "    Redirected Access: $($csvInfo.RedirectedAccess)" -ForegroundColor White
        }
    }
    #endregion

    #region Step 8: Storage Maintenance Operations
    Write-Step "Storage Maintenance Operations"

    Write-Host "`nCommon Storage Maintenance Commands:" -ForegroundColor Yellow

    Write-Host "`n1. Move storage to another node:" -ForegroundColor Cyan
    Write-Host "  Move-ClusterSharedVolume -Name '<CSVName>' -Node '<NodeName>'" -ForegroundColor Gray

    Write-Host "`n2. Take disk offline for maintenance:" -ForegroundColor Cyan
    Write-Host "  Stop-ClusterResource -Name '<DiskName>'" -ForegroundColor Gray

    Write-Host "`n3. Bring disk back online:" -ForegroundColor Cyan
    Write-Host "  Start-ClusterResource -Name '<DiskName>'" -ForegroundColor Gray

    Write-Host "`n4. Remove disk from cluster:" -ForegroundColor Cyan
    Write-Host "  Remove-ClusterSharedVolume -Name '<CSVName>'" -ForegroundColor Gray
    Write-Host "  Remove-ClusterResource -Name '<DiskName>'" -ForegroundColor Gray

    Write-Host "`n5. Enable CSV cache:" -ForegroundColor Cyan
    Write-Host "  (Get-Cluster).BlockCacheSize = 512" -ForegroundColor Gray

    Write-Host "`n6. Repair CSV volume:" -ForegroundColor Cyan
    Write-Host "  Repair-ClusterSharedVolume -Name '<CSVName>'" -ForegroundColor Gray
    #endregion

    #region Step 9: Storage Best Practices
    Write-Step "Cluster Storage Best Practices"

    Write-Host "`nBest Practices:" -ForegroundColor Yellow
    Write-Host "  1. Use CSV for Hyper-V and Scale-Out File Server workloads" -ForegroundColor White
    Write-Host "  2. Format volumes with ReFS for better resiliency (Windows Server 2016+)" -ForegroundColor White
    Write-Host "  3. Configure CSV cache for improved performance" -ForegroundColor White
    Write-Host "  4. Use dedicated storage networks (separate from cluster heartbeat)" -ForegroundColor White
    Write-Host "  5. Implement multipath I/O (MPIO) for storage redundancy" -ForegroundColor White
    Write-Host "  6. Monitor storage performance and capacity regularly" -ForegroundColor White
    Write-Host "  7. Test storage failover before production use" -ForegroundColor White
    Write-Host "  8. Keep firmware and drivers updated" -ForegroundColor White
    Write-Host "  9. Use appropriate block sizes for your workload" -ForegroundColor White
    Write-Host "  10. Document storage configuration and LUN mappings" -ForegroundColor White

    Write-Host "`nStorage Configuration for Different Scenarios:" -ForegroundColor Yellow
    Write-Host "  - Hyper-V: Use CSV with ReFS, enable CSV cache" -ForegroundColor White
    Write-Host "  - SQL Server: Use dedicated disks, NTFS, separate log/data" -ForegroundColor White
    Write-Host "  - File Server: Use CSV or standard cluster disks with NTFS" -ForegroundColor White
    Write-Host "  - Storage Spaces Direct: Use CSV with ReFS mirror or parity" -ForegroundColor White
    #endregion

    #region Summary
    Write-Host "`n" + "="*80 -ForegroundColor Cyan
    Write-Success "Cluster Storage Configuration Completed"
    Write-Host "="*80 -ForegroundColor Cyan

    Write-Host "`nStorage Summary:" -ForegroundColor Yellow
    $diskCount = (Get-ClusterResource | Where-Object { $_.ResourceType -eq 'Physical Disk' }).Count
    $csvCount = (Get-ClusterSharedVolume).Count

    Write-Host "  Cluster: $($cluster.Name)" -ForegroundColor White
    Write-Host "  Cluster Disks: $diskCount" -ForegroundColor White
    Write-Host "  Cluster Shared Volumes: $csvCount" -ForegroundColor White
    Write-Host "  CSV Cache Size: $((Get-Cluster).BlockCacheSize) MB" -ForegroundColor White
    #endregion

} catch {
    Write-Host "`n[ERROR] Failed to configure cluster storage: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red

    Write-Host "`nTroubleshooting:" -ForegroundColor Yellow
    Write-Host "  1. Verify shared storage is accessible from all cluster nodes" -ForegroundColor White
    Write-Host "  2. Check disk signatures and ensure they're unique" -ForegroundColor White
    Write-Host "  3. Verify MPIO is configured correctly" -ForegroundColor White
    Write-Host "  4. Check storage network connectivity" -ForegroundColor White
    Write-Host "  5. Review disk management and ensure disks are online" -ForegroundColor White

    exit 1
}

Write-Host "`nScript completed successfully!" -ForegroundColor Green
