# Storage Spaces Direct

# Ref: https://timw.info/6ve

# Install roles and features
Install-WindowsFeature -Name "Hyper-V", "Failover-Clustering", "Data-Center-Bridging", "RSAT-Clustering-PowerShell", "Hyper-V-PowerShell", "FS-FileServer"

$ServerList = "node1.timw.info", "node2.timw.info"
$FeatureList = "Hyper-V", "Failover-Clustering", "Data-Center-Bridging", "RSAT-Clustering-PowerShell", "Hyper-V-PowerShell", "FS-FileServer"
Invoke-Command ($ServerList) {
    Install-WindowsFeature -Name $Using:Featurelist
}

# Validate the cluster
Test-Cluster -Node node1.timw.info, node2.timw.info  -Include "Storage Spaces Direct", "Inventory", "Network", "System Configuration"

# Create the cluster
New-Cluster -Name az801 -Node node1.timw.info, node2.timw.info -NoStorage

<# Configure a cloud witness
https://docs.microsoft.com/en-us/windows-server/failover-clustering/deploy-cloud-witness
#>

# Enable S2D
Enable-ClusterStorageSpacesDirect -CimSession az801

<# Create volumes
https://docs.microsoft.com/en-us/windows-server/storage/storage-spaces/create-volumes
#>

# Enable the CSV cache
$ClusterName = "az801"
$CSVCacheSize = 2048 #Size in MB

Write-Output "Setting the CSV cache..."
(Get-Cluster $ClusterName).BlockCacheSize = $CSVCacheSize

$CSVCurrentCacheSize = (Get-Cluster $ClusterName).BlockCacheSize
Write-Output "$ClusterName CSV cache size: $CSVCurrentCacheSize MB"

# Add SoFS role to cluster
Add-ClusterScaleOutFileServerRole -Name SOFS -Cluster az801

# Create file shares
# Replace the values of these variables
$HyperVClusterName = "Compute01"
$HyperVObjectADGroupSamName = "Hyper-VServerComputerAccounts" <#No spaces#>
$ScriptFolder = "C:\Scripts\SetupSMBSharesWithHyperV"

# Start of script itself
CD $ScriptFolder
.\ADGroupSetup.ps1 -HyperVObjectADGroupSamName $HyperVObjectADGroupSamName -HyperVClusterName $HyperVClusterName

# Replace the values of these variables
$StorageClusterName = "StorageSpacesDirect1"
$HyperVObjectADGroupSamName = "Hyper-VServerComputerAccounts" <#No spaces#>
$SOFSName = "SOFS"
$SharePrefix = "Share"
$ScriptFolder = "C:\Scripts\SetupSMBSharesWithHyperV"

# Start of the script itself
CD $ScriptFolder
Get-ClusterSharedVolume -Cluster $StorageClusterName | ForEach-Object {
    $ShareName = $SharePrefix + $_.SharedVolumeInfo.friendlyvolumename.trimstart("C:\ClusterStorage\Volume")
    Write-host "Creating share $ShareName on "$_.name "on Volume: " $_.SharedVolumeInfo.friendlyvolumename
    .\FileShareSetup.ps1 -HyperVClusterName $StorageClusterName -CSVVolumeNumber $_.SharedVolumeInfo.friendlyvolumename.trimstart("C:\ClusterStorage\Volume") -ScaleOutFSName $SOFSName -ShareName $ShareName -HyperVObjectADGroupSamName $HyperVObjectADGroupSamName
}

# Enable Kerberos constrained delegation
$HyperVClusterName = "Compute01"
$ScaleOutFSName = "SOFS"
$ScriptFolder = "C:\Scripts\SetupSMBSharesWithHyperV"

CD $ScriptFolder
.\KCDSetup.ps1 -HyperVClusterName $HyperVClusterName -ScaleOutFSName $ScaleOutFSName -EnableLM







Enable-ClusterStorageSpacesDirect -PoolFriendlyName 'S2D'

New-Volume -FriendlyName “vDisk01” -FileSystem CSVFS_ReFS -StoragePoolFriendlyName S2D* -Size 10TB -ResiliencySettingName Mirror