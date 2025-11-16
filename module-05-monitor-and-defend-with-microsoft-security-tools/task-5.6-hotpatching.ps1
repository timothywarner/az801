<#
.SYNOPSIS
    Task 5.6 - Configure Hotpatching for Windows Server Azure Edition
.DESCRIPTION
    Comprehensive demonstration of hotpatching configuration for Windows Server Azure Edition.
    Covers VM creation with hotpatch support, assessment, and monitoring without reboots.
.EXAMPLE
    .\task-5.6-hotpatching.ps1
.NOTES
    Module: Module 5 - Monitor and Defend with Microsoft Security Tools
    Task: 5.6 - Configure Hotpatching
    Prerequisites:
    - Azure subscription with appropriate permissions
    - Az PowerShell modules (Az.Accounts, Az.Compute)
    - Windows Server Azure Edition 2022 Datacenter (required for hotpatch)
    PowerShell Version: 5.1+
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

Write-Host "=== AZ-801 Module 5: Task 5.6 - Configure Hotpatching ===" -ForegroundColor Cyan
Write-Host ""

try {
    # Step 1: Hotpatching Overview
    Write-Host "[Step 1] Hotpatching Overview" -ForegroundColor Yellow

    Write-Host "Hotpatching benefits:" -ForegroundColor Cyan
    Write-Host "  - Apply security updates without rebooting" -ForegroundColor White
    Write-Host "  - Reduce downtime and maintenance windows" -ForegroundColor White
    Write-Host "  - Faster patch deployment (no reboot time)" -ForegroundColor White
    Write-Host "  - Improved availability for critical workloads" -ForegroundColor White
    Write-Host "  - Automatic patch orchestration by Azure" -ForegroundColor White
    Write-Host ""

    Write-Host "Requirements for hotpatching:" -ForegroundColor Cyan
    Write-Host "  - Windows Server 2022 Datacenter: Azure Edition" -ForegroundColor White
    Write-Host "  - Azure VM (not supported on-premises)" -ForegroundColor White
    Write-Host "  - VM must be created with PatchMode set to 'AutomaticByPlatform'" -ForegroundColor White
    Write-Host "  - EnableHotpatching must be set to true at creation" -ForegroundColor White
    Write-Host ""

    Write-Host "Hotpatch update cycle:" -ForegroundColor Cyan
    Write-Host "  - Monthly hotpatch releases (no reboot required)" -ForegroundColor White
    Write-Host "  - Quarterly baseline updates (reboot required)" -ForegroundColor White
    Write-Host "  - Out-of-band security updates as needed" -ForegroundColor White
    Write-Host ""

    # Step 2: Check Azure PowerShell modules
    Write-Host "[Step 2] Checking Azure PowerShell modules" -ForegroundColor Yellow

    $requiredModules = @('Az.Accounts', 'Az.Compute', 'Az.Resources')

    foreach ($module in $requiredModules) {
        $installedModule = Get-Module -ListAvailable -Name $module | Select-Object -First 1
        if ($installedModule) {
            Write-Host "  $module : Version $($installedModule.Version) [OK]" -ForegroundColor Green
        } else {
            Write-Host "  $module : Not installed [MISSING]" -ForegroundColor Yellow
            Write-Host "    Install with: Install-Module -Name $module -Force -AllowClobber" -ForegroundColor Gray
        }
    }
    Write-Host ""

    # Step 3: Connect to Azure
    Write-Host "[Step 3] Connecting to Azure" -ForegroundColor Yellow

    Write-Host "Checking Azure connection..." -ForegroundColor Cyan
    try {
        $context = Get-AzContext
        if ($context) {
            Write-Host "Already connected to Azure" -ForegroundColor Green
            Write-Host "  Subscription: $($context.Subscription.Name)" -ForegroundColor White
            Write-Host "  Account: $($context.Account.Id)" -ForegroundColor White
        } else {
            Write-Host "Not connected to Azure" -ForegroundColor Yellow
            Write-Host "Run: Connect-AzAccount" -ForegroundColor Cyan
        }
    } catch {
        Write-Host "Azure PowerShell not authenticated" -ForegroundColor Yellow
        Write-Host "Run: Connect-AzAccount" -ForegroundColor Cyan
    }
    Write-Host ""

    # Step 4: Create VM with hotpatching enabled
    Write-Host "[Step 4] Creating VM with hotpatching enabled" -ForegroundColor Yellow

    Write-Host "Create new Windows Server Azure Edition VM with hotpatching..." -ForegroundColor Cyan
    Write-Host ""

    Write-Host "Example: Create VM with hotpatch support" -ForegroundColor Cyan
    Write-Host @'
  # Define parameters
  $resourceGroupName = "rg-servers-prod"
  $location = "East US"
  $vmName = "server-hotpatch01"
  $vmSize = "Standard_D2s_v3"

  # Create resource group
  New-AzResourceGroup -Name $resourceGroupName -Location $location

  # Create network resources
  $subnet = New-AzVirtualNetworkSubnetConfig `
      -Name "default" `
      -AddressPrefix "10.0.1.0/24"

  $vnet = New-AzVirtualNetwork `
      -ResourceGroupName $resourceGroupName `
      -Location $location `
      -Name "$vmName-vnet" `
      -AddressPrefix "10.0.0.0/16" `
      -Subnet $subnet

  $pip = New-AzPublicIpAddress `
      -ResourceGroupName $resourceGroupName `
      -Location $location `
      -Name "$vmName-pip" `
      -AllocationMethod Static

  $nic = New-AzNetworkInterface `
      -ResourceGroupName $resourceGroupName `
      -Location $location `
      -Name "$vmName-nic" `
      -SubnetId $vnet.Subnets[0].Id `
      -PublicIpAddressId $pip.Id

  # Create VM configuration with hotpatching
  $vmConfig = New-AzVMConfig `
      -VMName $vmName `
      -VMSize $vmSize |
      Set-AzVMOperatingSystem `
          -Windows `
          -ComputerName $vmName `
          -Credential (Get-Credential) `
          -PatchMode "AutomaticByPlatform" `
          -EnableHotpatching |
      Set-AzVMSourceImage `
          -PublisherName "MicrosoftWindowsServer" `
          -Offer "WindowsServer" `
          -Skus "2022-datacenter-azure-edition-hotpatch" `
          -Version "latest" |
      Add-AzVMNetworkInterface -Id $nic.Id |
      Set-AzVMBootDiagnostic -Enable -ResourceGroupName $resourceGroupName

  # Create the VM
  New-AzVM `
      -ResourceGroupName $resourceGroupName `
      -Location $location `
      -VM $vmConfig
'@ -ForegroundColor Gray
    Write-Host ""

    Write-Host "IMPORTANT: Hotpatching must be enabled at VM creation" -ForegroundColor Yellow
    Write-Host "  Cannot be enabled on existing VMs" -ForegroundColor Gray
    Write-Host "  Requires specific SKU: 2022-datacenter-azure-edition-hotpatch" -ForegroundColor Gray
    Write-Host ""

    # Step 5: Verify hotpatch configuration
    Write-Host "[Step 5] Verifying hotpatch configuration" -ForegroundColor Yellow

    Write-Host "Check VM patch settings..." -ForegroundColor Cyan
    Write-Host ""

    Write-Host "Example: Verify hotpatch settings on VM" -ForegroundColor Cyan
    Write-Host @'
  # Get VM details
  $vm = Get-AzVM -ResourceGroupName $resourceGroupName -Name $vmName

  # Check patch mode
  Write-Host "Patch Mode: $($vm.OSProfile.WindowsConfiguration.PatchSettings.PatchMode)"
  Write-Host "Hotpatching Enabled: $($vm.OSProfile.WindowsConfiguration.PatchSettings.EnableHotpatching)"
  Write-Host "Assessment Mode: $($vm.OSProfile.WindowsConfiguration.PatchSettings.AssessmentMode)"

  # Verify image SKU
  Write-Host "Image Reference:"
  $vm.StorageProfile.ImageReference | Format-List Publisher, Offer, Sku, Version
'@ -ForegroundColor Gray
    Write-Host ""

    Write-Host "Valid PatchMode values:" -ForegroundColor Cyan
    Write-Host "  - AutomaticByPlatform: Azure manages patching (required for hotpatch)" -ForegroundColor White
    Write-Host "  - AutomaticByOS: Windows Update manages patching" -ForegroundColor White
    Write-Host "  - Manual: Administrator manages patching" -ForegroundColor White
    Write-Host ""

    # Step 6: Update existing VM patch settings
    Write-Host "[Step 6] Updating VM patch settings" -ForegroundColor Yellow

    Write-Host "Update patch mode on existing VM (without hotpatch)..." -ForegroundColor Cyan
    Write-Host ""

    Write-Host "Example: Update VM to AutomaticByPlatform mode" -ForegroundColor Cyan
    Write-Host @'
  # Get VM
  $vm = Get-AzVM -ResourceGroupName $resourceGroupName -Name $vmName

  # Update patch settings (cannot enable hotpatching on existing VMs)
  $vm.OSProfile.WindowsConfiguration.PatchSettings.PatchMode = "AutomaticByPlatform"
  $vm.OSProfile.WindowsConfiguration.PatchSettings.AssessmentMode = "AutomaticByPlatform"

  # Apply changes
  Update-AzVM -ResourceGroupName $resourceGroupName -VM $vm

  Write-Host "VM patch mode updated successfully"
'@ -ForegroundColor Gray
    Write-Host ""

    Write-Host "Note: EnableHotpatching cannot be changed after VM creation" -ForegroundColor Yellow
    Write-Host ""

    # Step 7: Assess patch compliance
    Write-Host "[Step 7] Assessing patch compliance" -ForegroundColor Yellow

    Write-Host "Check available updates and patch status..." -ForegroundColor Cyan
    Write-Host ""

    Write-Host "Example: Get VM patch assessment" -ForegroundColor Cyan
    Write-Host @'
  # Trigger patch assessment
  $assessment = Invoke-AzVMPatchAssessment `
      -ResourceGroupName $resourceGroupName `
      -VMName $vmName

  Write-Host "Assessment Status: $($assessment.Status)"

  # Get patch assessment results
  $patchStatus = Get-AzVMPatchAssessment `
      -ResourceGroupName $resourceGroupName `
      -VMName $vmName

  # Display assessment details
  Write-Host "Available Patches:"
  Write-Host "  Critical: $($patchStatus.CriticalAndSecurityPatchCount)"
  Write-Host "  Other: $($patchStatus.OtherPatchCount)"
  Write-Host "  Assessment Time: $($patchStatus.LastPatchInstallationSummary.LastModifiedTime)"
  Write-Host "  Reboot Status: $($patchStatus.RebootPending)"
'@ -ForegroundColor Gray
    Write-Host ""

    # Step 8: Install patches
    Write-Host "[Step 8] Installing patches" -ForegroundColor Yellow

    Write-Host "Install available updates on VM..." -ForegroundColor Cyan
    Write-Host ""

    Write-Host "Example: Install patches on VM" -ForegroundColor Cyan
    Write-Host @'
  # Install patches with specific classifications
  $install = Invoke-AzVMInstallPatch `
      -ResourceGroupName $resourceGroupName `
      -VMName $vmName `
      -MaximumDuration "PT2H" `
      -RebootSetting "IfRequired" `
      -ClassificationToInclude "Critical", "Security"

  Write-Host "Patch installation initiated"
  Write-Host "  Status: $($install.Status)"
  Write-Host "  Operation ID: $($install.Name)"

  # Monitor installation progress
  do {
      Start-Sleep -Seconds 30
      $status = Get-AzVMInstallPatch `
          -ResourceGroupName $resourceGroupName `
          -VMName $vmName `
          -InstallPatchOperationId $install.Name

      Write-Host "Status: $($status.Status) - Installed: $($status.PatchesInstalled)"
  } while ($status.Status -eq "InProgress")

  Write-Host "Patch installation completed"
  Write-Host "  Installed: $($status.PatchesInstalled)"
  Write-Host "  Failed: $($status.PatchesFailed)"
  Write-Host "  Reboot Status: $($status.RebootStatus)"
'@ -ForegroundColor Gray
    Write-Host ""

    Write-Host "Reboot settings:" -ForegroundColor Cyan
    Write-Host "  - IfRequired: Reboot if patches require it" -ForegroundColor White
    Write-Host "  - Never: Never reboot (use for hotpatch VMs)" -ForegroundColor White
    Write-Host "  - Always: Always reboot after patching" -ForegroundColor White
    Write-Host ""

    # Step 9: Monitor hotpatch status
    Write-Host "[Step 9] Monitoring hotpatch status" -ForegroundColor Yellow

    Write-Host "Monitor patch installation history and status..." -ForegroundColor Cyan
    Write-Host ""

    Write-Host "Example: Get patch installation history" -ForegroundColor Cyan
    Write-Host @'
  # Get last patch installation summary
  $vm = Get-AzVM -ResourceGroupName $resourceGroupName -Name $vmName -Status

  # Check VM guest agent status
  $vm.VMAgent | Format-List

  # Get recent patch installations
  $patchStatus = Get-AzVMPatchAssessment `
      -ResourceGroupName $resourceGroupName `
      -VMName $vmName

  Write-Host "Last Patch Installation:"
  Write-Host "  Status: $($patchStatus.LastPatchInstallationSummary.Status)"
  Write-Host "  Time: $($patchStatus.LastPatchInstallationSummary.LastModifiedTime)"
  Write-Host "  Installed: $($patchStatus.LastPatchInstallationSummary.InstalledPatchCount)"
  Write-Host "  Failed: $($patchStatus.LastPatchInstallationSummary.FailedPatchCount)"
  Write-Host "  Reboot: $($patchStatus.LastPatchInstallationSummary.RebootStatus)"
'@ -ForegroundColor Gray
    Write-Host ""

    # Step 10: Best practices
    Write-Host "[Step 10] Hotpatching best practices" -ForegroundColor Yellow

    Write-Host "Best practices:" -ForegroundColor Cyan
    Write-Host "  1. Use Windows Server 2022 Azure Edition for new deployments" -ForegroundColor White
    Write-Host "  2. Enable hotpatching at VM creation time" -ForegroundColor White
    Write-Host "  3. Set PatchMode to AutomaticByPlatform" -ForegroundColor White
    Write-Host "  4. Schedule quarterly maintenance windows for baseline updates" -ForegroundColor White
    Write-Host "  5. Monitor patch compliance with Azure Update Manager" -ForegroundColor White
    Write-Host "  6. Test patches in non-production first" -ForegroundColor White
    Write-Host "  7. Use maintenance configurations for patch scheduling" -ForegroundColor White
    Write-Host "  8. Enable boot diagnostics for troubleshooting" -ForegroundColor White
    Write-Host "  9. Document hotpatch-enabled VMs in your inventory" -ForegroundColor White
    Write-Host "  10. Plan for quarterly reboots (baseline updates)" -ForegroundColor White
    Write-Host ""

    Write-Host "Hotpatch update schedule:" -ForegroundColor Cyan
    Write-Host "  - Monthly: Security hotpatches (no reboot)" -ForegroundColor White
    Write-Host "  - Quarterly: Baseline update (reboot required)" -ForegroundColor White
    Write-Host "  - Ad-hoc: Critical out-of-band updates" -ForegroundColor White
    Write-Host ""

    Write-Host "Monitoring and reporting:" -ForegroundColor Cyan
    Write-Host "  - Use Azure Update Manager for centralized view" -ForegroundColor White
    Write-Host "  - Configure Azure Monitor alerts for patch failures" -ForegroundColor White
    Write-Host "  - Review compliance in Azure Policy" -ForegroundColor White
    Write-Host "  - Export patch data to Log Analytics" -ForegroundColor White
    Write-Host ""

    Write-Host "[INFO] Additional Resources:" -ForegroundColor Cyan
    Write-Host "  Docs: https://docs.microsoft.com/azure/virtual-machines/automatic-vm-guest-patching" -ForegroundColor White
    Write-Host "  Hotpatch: https://docs.microsoft.com/azure/automanage/automanage-hotpatch" -ForegroundColor White
    Write-Host "  Update Manager: https://docs.microsoft.com/azure/update-manager/" -ForegroundColor White
    Write-Host ""

} catch {
    Write-Host "[ERROR] $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

Write-Host "Demo completed successfully!" -ForegroundColor Green
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Deploy new VMs with Windows Server 2022 Azure Edition" -ForegroundColor White
Write-Host "  2. Enable hotpatching at VM creation (EnableHotpatching = true)" -ForegroundColor White
Write-Host "  3. Set PatchMode to AutomaticByPlatform" -ForegroundColor White
Write-Host "  4. Verify hotpatch configuration on new VMs" -ForegroundColor White
Write-Host "  5. Run patch assessment to check compliance" -ForegroundColor White
Write-Host "  6. Schedule quarterly maintenance for baseline updates" -ForegroundColor White
Write-Host "  7. Monitor patch status with Azure Update Manager" -ForegroundColor White
Write-Host "  8. Configure alerts for patch failures" -ForegroundColor White
