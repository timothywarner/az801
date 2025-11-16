<#
.SYNOPSIS
    Task 23.5 - Use Azure Update Manager

.DESCRIPTION
    Demo script for AZ-801 Module 23: Monitor with Azure Services
    Demonstrates Azure Update Manager for patch assessment, deployment, and
    compliance monitoring on Azure and Arc-enabled servers.

.NOTES
    Module: Module 23 - Monitor with Azure Services
    Task: 23.5 - Use Azure Update Manager
    Prerequisites: Azure subscription, Az PowerShell module
    PowerShell Version: 5.1+
#>

#Requires -RunAsAdministrator
#Requires -Modules Az.Accounts, Az.Compute, Az.Maintenance

$ErrorActionPreference = 'Stop'
Write-Host "=== AZ-801 Module 23: Task 23.5 - Use Azure Update Manager ===" -ForegroundColor Cyan
Write-Host ""

try {
    # Check Azure connection
    Write-Host "[Step 1] Verify Azure Connection" -ForegroundColor Yellow
    $context = Get-AzContext -ErrorAction SilentlyContinue
    if (-not $context) {
        Write-Host "Not connected. Use: Connect-AzAccount" -ForegroundColor Yellow
    } else {
        Write-Host "Connected: $($context.Subscription.Name)" -ForegroundColor Green
    }
    Write-Host ""

    # Variables
    $resourceGroup = "rg-production-servers"
    $vmName = "vm-webserver-01"
    $location = "eastus"

    # Assess updates
    Write-Host "[Step 2] Assess Available Updates" -ForegroundColor Yellow
    Write-Host "Trigger update assessment:" -ForegroundColor Cyan
    Write-Host @"
  # Assessment for Azure VM
  Invoke-AzRestMethod ``
    -Method POST ``
    -ResourceGroupName '$resourceGroup' ``
    -ResourceProviderName 'Microsoft.Compute' ``
    -ResourceType 'virtualMachines' ``
    -Name '$vmName' ``
    -ApiVersion '2023-03-01' ``
    -Payload '{"assessmentMode": "ImageDefault"}'

  # View assessment results
  Get-AzVMPatchAssessment ``
    -ResourceGroupName '$resourceGroup' ``
    -VMName '$vmName'
"@ -ForegroundColor White
    Write-Host ""

    # Create maintenance configuration
    Write-Host "[Step 3] Create Maintenance Configuration for Patching" -ForegroundColor Yellow
    Write-Host @"
  `$config = New-AzMaintenanceConfiguration ``
    -ResourceGroupName '$resourceGroup' ``
    -Name 'monthly-patching' ``
    -Location '$location' ``
    -MaintenanceScope 'InGuestPatch' ``
    -ExtensionProperty @{
      InGuestPatchMode = 'User'
    } ``
    -RecurEvery '1Month Third Sunday' ``
    -Duration '03:00' ``
    -StartDateTime '2025-01-15 02:00' ``
    -TimeZone 'Eastern Standard Time'

  # Apply to reboot settings
  `$config.InstallPatches.WindowsParameters.RebootSetting = 'IfRequired'
  `$config.InstallPatches.WindowsParameters.ClassificationsToInclude = @('Critical', 'Security', 'UpdateRollup')
"@ -ForegroundColor White
    Write-Host ""

    # Assign maintenance configuration
    Write-Host "[Step 4] Assign Maintenance Configuration to Servers" -ForegroundColor Yellow
    Write-Host @"
  # Get VM resource ID
  `$vmId = (Get-AzVM -ResourceGroupName '$resourceGroup' -Name '$vmName').Id

  # Create configuration assignment
  New-AzConfigurationAssignment ``
    -ResourceGroupName '$resourceGroup' ``
    -Location '$location' ``
    -ResourceName '$vmName' ``
    -ResourceType 'virtualMachines' ``
    -ProviderName 'Microsoft.Compute' ``
    -ConfigurationAssignmentName 'monthly-patching-assignment' ``
    -MaintenanceConfigurationId `$config.Id
"@ -ForegroundColor White
    Write-Host ""

    # One-time patch deployment
    Write-Host "[Step 5] Perform One-Time Patch Deployment" -ForegroundColor Yellow
    Write-Host @"
  # Install updates immediately
  Invoke-AzVMPatchInstallation ``
    -ResourceGroupName '$resourceGroup' ``
    -VMName '$vmName' ``
    -MaximumDuration '02:00:00' ``
    -RebootSetting 'IfRequired' ``
    -WindowsParameterClassificationToInclude 'Critical','Security'
"@ -ForegroundColor White
    Write-Host ""

    # View patch status
    Write-Host "[Step 6] Query Patch Status and History" -ForegroundColor Yellow
    Write-Host @"
  # Get patch installation status
  Get-AzVMPatchStatus ``
    -ResourceGroupName '$resourceGroup' ``
    -VMName '$vmName'

  # List patch installation history
  Get-AzVMPatchInstallationHistory ``
    -ResourceGroupName '$resourceGroup' ``
    -VMName '$vmName'
"@ -ForegroundColor White
    Write-Host ""

    # Update compliance reporting
    Write-Host "[Step 7] Monitor Update Compliance" -ForegroundColor Yellow
    $kqlQuery = @"
// Update compliance summary
PatchAssessmentResources
| where type == 'microsoft.compute/virtualmachines/patchassessmentresults'
| extend
    OS = tostring(properties.osType),
    AssessmentTime = todatetime(properties.lastModifiedDateTime),
    CriticalUpdates = toint(properties.criticalAndSecurityPatchCount),
    OtherUpdates = toint(properties.otherPatchCount)
| project Computer = name, OS, AssessmentTime, CriticalUpdates, OtherUpdates
| order by CriticalUpdates desc

// Servers needing updates
PatchAssessmentResources
| where type == 'microsoft.compute/virtualmachines/patchassessmentresults'
| where toint(properties.criticalAndSecurityPatchCount) > 0
| project
    Computer = name,
    CriticalUpdates = toint(properties.criticalAndSecurityPatchCount),
    LastAssessed = todatetime(properties.lastModifiedDateTime)
"@
    Write-Host "Azure Resource Graph queries:" -ForegroundColor Cyan
    Write-Host $kqlQuery -ForegroundColor Gray
    Write-Host ""

    # Arc-enabled servers
    Write-Host "[Step 8] Manage Updates on Arc-Enabled Servers" -ForegroundColor Yellow
    Write-Host @"
  # Assessment for Arc machine
  Invoke-AzRestMethod ``
    -Method POST ``
    -ResourceGroupName '$resourceGroup' ``
    -ResourceProviderName 'Microsoft.HybridCompute' ``
    -ResourceType 'machines' ``
    -Name 'onprem-server-01' ``
    -ApiVersion '2023-03-01' ``
    -Payload '{"assessmentMode": "AutomaticByPlatform"}'

  # Apply maintenance configuration to Arc machine
  New-AzConfigurationAssignment ``
    -ResourceGroupName '$resourceGroup' ``
    -Location '$location' ``
    -ResourceName 'onprem-server-01' ``
    -ResourceType 'machines' ``
    -ProviderName 'Microsoft.HybridCompute' ``
    -ConfigurationAssignmentName 'monthly-patching-assignment' ``
    -MaintenanceConfigurationId `$config.Id
"@ -ForegroundColor White
    Write-Host ""

    # Dynamic scoping
    Write-Host "[Step 9] Use Dynamic Scoping for Multiple Servers" -ForegroundColor Yellow
    Write-Host @"
  # Create maintenance configuration with dynamic scope
  `$config = New-AzMaintenanceConfiguration ``
    -ResourceGroupName '$resourceGroup' ``
    -Name 'prod-servers-patching' ``
    -Location '$location' ``
    -MaintenanceScope 'InGuestPatch' ``
    -RecurEvery '1Month Second Tuesday' ``
    -Duration '04:00'

  # Define dynamic scope (all VMs with specific tag)
  `$filter = @{
    ResourceType = 'Microsoft.Compute/virtualMachines'
    ResourceGroup = '$resourceGroup'
    TagFilter = @{
      Environment = 'Production'
      PatchGroup = 'Group1'
    }
  }

  New-AzMaintenanceConfigurationDynamicScope ``
    -ResourceGroupName '$resourceGroup' ``
    -MaintenanceConfigurationName 'prod-servers-patching' ``
    -Name 'prod-scope' ``
    -FilterProperty `$filter
"@ -ForegroundColor White
    Write-Host ""

    # Pre/Post scripts
    Write-Host "[Step 10] Configure Pre and Post Update Scripts" -ForegroundColor Yellow
    Write-Host @"
  # Create pre-update script
  `$preScript = @{
    source = 'https://mystorageaccount.blob.core.windows.net/scripts/pre-update.ps1'
    scriptParameters = '-Action Backup'
  }

  # Create post-update script
  `$postScript = @{
    source = 'https://mystorageaccount.blob.core.windows.net/scripts/post-update.ps1'
    scriptParameters = '-Action Verify'
  }

  # Apply scripts to maintenance configuration
  Update-AzMaintenanceConfiguration ``
    -ResourceGroupName '$resourceGroup' ``
    -Name 'monthly-patching' ``
    -PreTask `$preScript ``
    -PostTask `$postScript
"@ -ForegroundColor White
    Write-Host ""

    # Update management best practices
    Write-Host "[Step 11] Update Management Best Practices" -ForegroundColor Yellow
    $bestPractices = @"
Patching Strategy:
1. Assessment: Run weekly assessments to track available updates
2. Classification: Prioritize Critical and Security updates
3. Scheduling: Use maintenance windows during off-peak hours
4. Testing: Patch dev/test servers before production
5. Phasing: Roll out patches in groups (waves)
6. Reboots: Configure appropriate reboot settings

Maintenance Configurations:
- Critical servers: Weekly security updates with 2-hour window
- Production servers: Monthly updates on Patch Tuesday +7 days
- Dev/Test servers: Monthly updates on Patch Tuesday
- Use dynamic scoping with tags for flexible targeting

Monitoring:
- Review patch compliance weekly
- Alert on missing critical security updates
- Track patch deployment success rates
- Monitor reboot requirements

Integration:
- Use with Azure Policy for compliance reporting
- Integrate with Azure Monitor for alerting
- Leverage Azure Resource Graph for reporting
- Combine with change tracking for audit trail
"@
    Write-Host $bestPractices -ForegroundColor White
    Write-Host ""

    Write-Host "[INFO] Update Manager Benefits:" -ForegroundColor Cyan
    Write-Host "  - Unified update management for Azure and Arc servers" -ForegroundColor White
    Write-Host "  - No additional infrastructure required" -ForegroundColor White
    Write-Host "  - Support for Windows and Linux" -ForegroundColor White
    Write-Host "  - Flexible scheduling with maintenance configurations" -ForegroundColor White
    Write-Host "  - Compliance reporting and audit trail" -ForegroundColor White
    Write-Host "  - Integration with Azure Policy and Monitor" -ForegroundColor White
    Write-Host ""

} catch {
    Write-Host "[ERROR] $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

Write-Host "Demo completed successfully!" -ForegroundColor Green
Write-Host "Next Steps: Configure maintenance schedules and enable automatic assessments" -ForegroundColor Yellow
