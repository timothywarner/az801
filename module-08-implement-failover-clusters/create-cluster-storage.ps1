# ***** Variables - Customize these for your environment *****
$clusterName = "az801cluster"
$vmNames = "MEM1", "MEM2", "MEM3"
$storagePoolName = "S2DPool"
$virtualDiskName = "S2DDisk"

# ***** Install Failover Clustering feature if not already present *****
foreach ($vm in $vmNames) {
  Install-WindowsFeature -Name Failover-Clustering -ComputerName $vm -IncludeManagementTools
}

# ***** Enable Storage Spaces Direct *****
Enable-ClusterS2D

# ***** Create the storage pool *****
New-StoragePool -FriendlyName $storagePoolName -StorageSubSystemFriendlyName (Get-Cluster).StorageSubsystemFriendlyName

# ***** Create the virtual disk - Using simplest resiliency (equivalent to mirror without parity) *****
New-VirtualDisk -StoragePoolFriendlyName $storagePoolName -FriendlyName $virtualDiskName -NumberOfColumns 2 -UseMaximumSize

# ***** Initialize, partition, and format the virtual disk *****
$s2dDisk = Get-Disk | Where-Object { $_.Number -eq (Get-VirtualDisk $virtualDiskName | Get-PhysicalDisk).Number }
Initialize-Disk -Number $s2dDisk.Number -PartitionStyle GPT
New-Partition -DiskNumber $s2dDisk.Number -UseMaximumSize -DriveLetter F  # Adjust drive letter if needed
Format-Volume -FileSystem NTFS -DriveLetter F -NewFileSystemLabel "ClusterDisk" -Confirm:$false

# ***** Add the disk to the cluster as shared storage. *****
Add-ClusterSharedVolume -Name "ClusterDisk" -Cluster $clusterName
