<#
.SYNOPSIS
    Task 7.5 - Configure FSRM and Storage QoS
.DESCRIPTION
    Comprehensive demonstration of File Server Resource Manager and Storage QoS.
    Covers quotas, file screening, storage reports, and performance management.
.EXAMPLE
    .\task-7.5-fsrm-storage-qos.ps1
.NOTES
    Module: Module 7 - Secure Storage with Encryption
    Task: 7.5 - Configure FSRM and Storage QoS
    Prerequisites:
    - Windows Server with File Server role
    - FSRM feature installed
    - Administrative privileges
    PowerShell Version: 5.1+
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

Write-Host "=== AZ-801 Module 7: Task 7.5 - Configure FSRM and Storage QoS ===" -ForegroundColor Cyan
Write-Host ""

try {
    # Step 1: FSRM Overview
    Write-Host "[Step 1] File Server Resource Manager Overview" -ForegroundColor Yellow
    Write-Host "FSRM features:" -ForegroundColor Cyan
    Write-Host "  - Quota management" -ForegroundColor White
    Write-Host "  - File screening (block file types)" -ForegroundColor White
    Write-Host "  - Storage reports" -ForegroundColor White
    Write-Host "  - Classification management" -ForegroundColor White
    Write-Host ""

    # Step 2: Create FSRM quotas
    Write-Host "[Step 2] Creating FSRM quotas" -ForegroundColor Yellow
    Write-Host @'
  # Create a hard quota (blocks writes when exceeded)
  New-FsrmQuota `
      -Path "D:\UserData" `
      -Size 10GB `
      -Description "10 GB hard quota for user data" `
      -Threshold @(
          (New-FsrmQuotaThreshold -Percentage 85 -Action Email,Event),
          (New-FsrmQuotaThreshold -Percentage 95 -Action Email,Event)
      )

  # Create a soft quota (warning only)
  New-FsrmQuota `
      -Path "D:\Shared" `
      -Size 50GB `
      -SoftLimit `
      -Description "50 GB soft quota for shared data"

  # View all quotas
  Get-FsrmQuota | Format-Table Path, Size, Usage, SoftLimit
'@ -ForegroundColor Gray
    Write-Host ""

    # Step 3: Create file screening
    Write-Host "[Step 3] Configuring file screening" -ForegroundColor Yellow
    Write-Host @'
  # Create file group for executable files
  New-FsrmFileGroup `
      -Name "Executable Files" `
      -IncludePattern @("*.exe", "*.com", "*.bat", "*.cmd")

  # Create file group for media files
  New-FsrmFileGroup `
      -Name "Audio and Video Files" `
      -IncludePattern @("*.mp3", "*.mp4", "*.avi", "*.mkv", "*.flv")

  # Create file screen to block executable files
  New-FsrmFileScreen `
      -Path "D:\UserData" `
      -Description "Block executable files in user data" `
      -IncludeGroup "Executable Files" `
      -Notification (
          New-FsrmAction -Type Email -MailTo "admin@contoso.com" -Subject "Blocked File Attempt"
      )

  # View file screens
  Get-FsrmFileScreen | Format-Table Path, IncludeGroup, Active
'@ -ForegroundColor Gray
    Write-Host ""

    # Step 4: Generate storage reports
    Write-Host "[Step 4] Generating storage reports" -ForegroundColor Yellow
    Write-Host @'
  # Create storage report job
  New-FsrmStorageReport `
      -Name "Monthly Storage Report" `
      -Namespace @("D:\") `
      -ReportType @("DuplicateFiles", "LargeFiles", "FilesByOwner", "QuotaUsage") `
      -Schedule (New-FsrmScheduledTask -Weekly -Day Monday -Time "02:00") `
      -MailTo "admin@contoso.com"

  # Run report immediately
  Start-FsrmStorageReport -Name "Monthly Storage Report" -RunDuration 0

  # View reports
  Get-FsrmStorageReport | Format-Table Name, ReportType, Status
'@ -ForegroundColor Gray
    Write-Host ""

    # Step 5: Storage QoS Overview
    Write-Host "[Step 5] Storage Quality of Service Overview" -ForegroundColor Yellow
    Write-Host "Storage QoS features:" -ForegroundColor Cyan
    Write-Host "  - Limit IOPS for VMs or volumes" -ForegroundColor White
    Write-Host "  - Guarantee minimum IOPS" -ForegroundColor White
    Write-Host "  - Monitor storage performance" -ForegroundColor White
    Write-Host "  - Prevent noisy neighbor issues" -ForegroundColor White
    Write-Host ""

    # Step 6: Create Storage QoS policies
    Write-Host "[Step 6] Creating Storage QoS policies" -ForegroundColor Yellow
    Write-Host @'
  # Create QoS policy with maximum IOPS
  New-StorageQosPolicy `
      -Name "Limited IOPS Policy" `
      -MaximumIops 1000 `
      -PolicyType Dedicated

  # Create QoS policy with minimum IOPS guarantee
  New-StorageQosPolicy `
      -Name "Guaranteed IOPS Policy" `
      -MinimumIops 500 `
      -MaximumIops 2000 `
      -PolicyType Aggregated

  # View all QoS policies
  Get-StorageQosPolicy | Format-Table Name, MinimumIops, MaximumIops, PolicyType
'@ -ForegroundColor Gray
    Write-Host ""

    # Step 7: Apply Storage QoS
    Write-Host "[Step 7] Applying Storage QoS policies" -ForegroundColor Yellow
    Write-Host @'
  # Get the QoS policy
  $policy = Get-StorageQosPolicy -Name "Limited IOPS Policy"

  # Apply to a VHD/VHDX file
  Set-VMHardDiskDrive `
      -VMName "TestVM" `
      -Path "C:\VMs\TestVM\disk.vhdx" `
      -QoSPolicyId $policy.PolicyId

  # Verify QoS assignment
  Get-VMHardDiskDrive -VMName "TestVM" |
      Select-Object VMName, Path, QoSPolicyId
'@ -ForegroundColor Gray
    Write-Host ""

    # Step 8: Monitor Storage QoS
    Write-Host "[Step 8] Monitoring Storage QoS performance" -ForegroundColor Yellow
    Write-Host @'
  # Get Storage QoS flows
  Get-StorageQosFlow |
      Select-Object FilePath, MinimumIOPS, MaximumIOPS, Status |
      Format-Table -AutoSize

  # Get volume statistics
  Get-StorageQosVolume |
      Select-Object MountPoint, Capacity, AvailableCapacity, IOPS |
      Format-Table -AutoSize

  # Monitor real-time IOPS
  while ($true) {
      $flows = Get-StorageQosFlow
      foreach ($flow in $flows) {
          Write-Host "Flow: $($flow.FilePath)"
          Write-Host "  Current IOPS: $($flow.CurrentIOPS)"
          Write-Host "  Bandwidth: $($flow.CurrentBandwidth)"
      }
      Start-Sleep -Seconds 5
  }
'@ -ForegroundColor Gray
    Write-Host ""

    # Step 9: Update policies
    Write-Host "[Step 9] Updating Storage QoS policies" -ForegroundColor Yellow
    Write-Host @'
  # Update existing policy
  Set-StorageQosPolicy `
      -Name "Limited IOPS Policy" `
      -MaximumIops 1500

  # Remove QoS policy from VHD
  Set-VMHardDiskDrive `
      -VMName "TestVM" `
      -Path "C:\VMs\TestVM\disk.vhdx" `
      -QoSPolicyId $null

  # Delete QoS policy
  Remove-StorageQosPolicy -Name "Limited IOPS Policy" -Confirm:$false
'@ -ForegroundColor Gray
    Write-Host ""

    # Step 10: Best practices
    Write-Host "[Step 10] FSRM and Storage QoS best practices" -ForegroundColor Yellow
    Write-Host "FSRM Best Practices:" -ForegroundColor Cyan
    Write-Host "  1. Use soft quotas for user awareness" -ForegroundColor White
    Write-Host "  2. Block risky file types (executables, scripts)" -ForegroundColor White
    Write-Host "  3. Generate regular storage reports" -ForegroundColor White
    Write-Host "  4. Configure email notifications for quota/screening events" -ForegroundColor White
    Write-Host "  5. Review file screen exceptions regularly" -ForegroundColor White
    Write-Host ""

    Write-Host "Storage QoS Best Practices:" -ForegroundColor Cyan
    Write-Host "  1. Start with conservative IOPS limits" -ForegroundColor White
    Write-Host "  2. Monitor actual usage before setting policies" -ForegroundColor White
    Write-Host "  3. Use aggregated policies for flexibility" -ForegroundColor White
    Write-Host "  4. Reserve minimum IOPS for critical VMs" -ForegroundColor White
    Write-Host "  5. Regular review and adjustment of policies" -ForegroundColor White
    Write-Host ""

    Write-Host "Useful commands:" -ForegroundColor Cyan
    Write-Host '  Get-FsrmQuota | Format-Table' -ForegroundColor Gray
    Write-Host '  Get-FsrmFileScreen | Format-Table' -ForegroundColor Gray
    Write-Host '  Get-StorageQosPolicy | Format-Table' -ForegroundColor Gray
    Write-Host '  Get-StorageQosFlow | Format-Table' -ForegroundColor Gray
    Write-Host ""

} catch {
    Write-Host "[ERROR] $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

Write-Host "Demo completed successfully!" -ForegroundColor Green
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Implement quota policies for all file shares" -ForegroundColor White
Write-Host "  2. Configure file screening to block risky file types" -ForegroundColor White
Write-Host "  3. Schedule regular storage reports" -ForegroundColor White
Write-Host "  4. Create Storage QoS policies for VM workloads" -ForegroundColor White
Write-Host "  5. Monitor storage performance and adjust policies" -ForegroundColor White
