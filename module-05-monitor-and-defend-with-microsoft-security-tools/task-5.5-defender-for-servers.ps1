<#
.SYNOPSIS
    Task 5.5 - Configure Defender for Servers
.DESCRIPTION
    Comprehensive demonstration of Microsoft Defender for Servers deployment and configuration.
    Covers Plan 1 vs Plan 2, agent deployment, threat protection, and vulnerability assessment.
.EXAMPLE
    .\task-5.5-defender-for-servers.ps1
.NOTES
    Module: Module 5 - Monitor and Defend with Microsoft Security Tools
    Task: 5.5 - Configure Defender for Servers
    Prerequisites:
    - Azure subscription with appropriate permissions
    - Az PowerShell modules (Az.Accounts, Az.Security, Az.Compute)
    - Windows Server Azure VMs or Azure Arc-enabled servers
    PowerShell Version: 5.1+
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

Write-Host "=== AZ-801 Module 5: Task 5.5 - Configure Defender for Servers ===" -ForegroundColor Cyan
Write-Host ""

try {
    # Step 1: Defender for Servers Overview
    Write-Host "[Step 1] Microsoft Defender for Servers Overview" -ForegroundColor Yellow

    Write-Host "Defender for Servers provides:" -ForegroundColor Cyan
    Write-Host "  - Advanced threat protection for Windows and Linux servers" -ForegroundColor White
    Write-Host "  - Integration with Microsoft Defender for Endpoint" -ForegroundColor White
    Write-Host "  - Vulnerability assessment scanning" -ForegroundColor White
    Write-Host "  - Just-in-Time VM access" -ForegroundColor White
    Write-Host "  - File Integrity Monitoring (Plan 2)" -ForegroundColor White
    Write-Host "  - Adaptive Application Controls (Plan 2)" -ForegroundColor White
    Write-Host "  - Adaptive Network Hardening (Plan 2)" -ForegroundColor White
    Write-Host ""

    Write-Host "Plan Comparison:" -ForegroundColor Cyan
    Write-Host "  Plan 1:" -ForegroundColor White
    Write-Host "    - Microsoft Defender for Endpoint integration" -ForegroundColor Gray
    Write-Host "    - Just-in-Time VM access" -ForegroundColor Gray
    Write-Host "    - Vulnerability assessment with Qualys" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Plan 2 (includes all Plan 1 features plus):" -ForegroundColor White
    Write-Host "    - File Integrity Monitoring" -ForegroundColor Gray
    Write-Host "    - Adaptive Application Controls" -ForegroundColor Gray
    Write-Host "    - Adaptive Network Hardening" -ForegroundColor Gray
    Write-Host "    - Regulatory compliance dashboard" -ForegroundColor Gray
    Write-Host ""

    # Step 2: Register Microsoft.Security resource provider
    Write-Host "[Step 2] Registering Microsoft.Security resource provider" -ForegroundColor Yellow

    Write-Host "Example: Register the Security resource provider" -ForegroundColor Cyan
    Write-Host @'
  # Register Microsoft.Security provider
  Register-AzResourceProvider -ProviderNamespace "Microsoft.Security"

  # Check registration status
  Get-AzResourceProvider -ProviderNamespace "Microsoft.Security" |
      Select-Object ProviderNamespace, RegistrationState
'@ -ForegroundColor Gray
    Write-Host ""

    # Step 3: Enable Defender for Servers
    Write-Host "[Step 3] Enabling Defender for Servers" -ForegroundColor Yellow

    Write-Host "Enable Defender for Servers Plan 2 on subscription..." -ForegroundColor Cyan
    Write-Host ""

    Write-Host "Example: Enable Defender for Servers Plan 2" -ForegroundColor Cyan
    Write-Host @'
  # Connect to Azure
  Connect-AzAccount
  Set-AzContext -Subscription "Your Subscription Name"

  # Enable Defender for Servers Plan 2
  Set-AzSecurityPricing `
      -Name "VirtualMachines" `
      -PricingTier "Standard" `
      -SubPlan "P2"

  # Verify pricing tier
  $pricing = Get-AzSecurityPricing -Name "VirtualMachines"
  Write-Host "Defender for Servers: $($pricing.PricingTier)"
  Write-Host "Sub Plan: $($pricing.SubPlan)"
'@ -ForegroundColor Gray
    Write-Host ""

    Write-Host "Enable Defender for Servers Plan 1 (cost-effective option):" -ForegroundColor Cyan
    Write-Host '  Set-AzSecurityPricing -Name "VirtualMachines" -PricingTier "Standard" -SubPlan "P1"' -ForegroundColor Gray
    Write-Host ""

    # Step 4: Deploy monitoring agents
    Write-Host "[Step 4] Deploying monitoring agents" -ForegroundColor Yellow

    Write-Host "Install Log Analytics agent (MMA) or Azure Monitor Agent (AMA)..." -ForegroundColor Cyan
    Write-Host ""

    Write-Host "Example: Install Azure Monitor Agent on Azure VM" -ForegroundColor Cyan
    Write-Host @'
  # Install AMA extension on Azure VM
  Set-AzVMExtension `
      -Publisher "Microsoft.Azure.Monitor" `
      -ExtensionType "AzureMonitorWindowsAgent" `
      -Name "AzureMonitorWindowsAgent" `
      -ResourceGroupName "rg-servers" `
      -VMName "server01" `
      -Location "East US" `
      -TypeHandlerVersion "1.0" `
      -EnableAutomaticUpgrade $true

  # Verify extension installation
  Get-AzVMExtension `
      -ResourceGroupName "rg-servers" `
      -VMName "server01" |
      Where-Object {$_.ExtensionType -like "*Monitor*"}
'@ -ForegroundColor Gray
    Write-Host ""

    Write-Host "For Azure Arc-enabled servers (on-premises/hybrid):" -ForegroundColor Cyan
    Write-Host @'
  New-AzConnectedMachineExtension `
      -Name "AzureMonitorWindowsAgent" `
      -ResourceGroupName "rg-servers" `
      -MachineName "onprem-server01" `
      -Location "East US" `
      -Publisher "Microsoft.Azure.Monitor" `
      -ExtensionType "AzureMonitorWindowsAgent"
'@ -ForegroundColor Gray
    Write-Host ""

    # Step 5: Enable Microsoft Defender for Endpoint integration
    Write-Host "[Step 5] Microsoft Defender for Endpoint integration" -ForegroundColor Yellow

    Write-Host "Defender for Servers integrates with Microsoft Defender for Endpoint..." -ForegroundColor Cyan
    Write-Host ""

    Write-Host "MDE deployment is automatic when Defender for Servers is enabled" -ForegroundColor White
    Write-Host "  - Auto-provisioning installs MDE on servers" -ForegroundColor Gray
    Write-Host "  - Provides endpoint detection and response (EDR)" -ForegroundColor Gray
    Write-Host "  - Unified portal experience in Microsoft 365 Defender" -ForegroundColor Gray
    Write-Host ""

    Write-Host "Verify MDE deployment:" -ForegroundColor Cyan
    Write-Host '  Get-Service -Name "Sense" | Select-Object Name, Status, StartType' -ForegroundColor Gray
    Write-Host ""

    # Step 6: Configure vulnerability assessment
    Write-Host "[Step 6] Configuring vulnerability assessment" -ForegroundColor Yellow

    Write-Host "Defender for Servers includes integrated vulnerability scanning..." -ForegroundColor Cyan
    Write-Host ""

    Write-Host "Two options available:" -ForegroundColor White
    Write-Host "  1. Microsoft Defender Vulnerability Management (included)" -ForegroundColor Gray
    Write-Host "  2. Qualys scanner (legacy)" -ForegroundColor Gray
    Write-Host ""

    Write-Host "Enable vulnerability assessment with Defender VM:" -ForegroundColor Cyan
    Write-Host @'
  # Enable vulnerability assessment (auto-deployed with MDE)
  # No additional configuration required

  # View vulnerability assessment findings
  $assessments = Get-AzSecurityAssessment |
      Where-Object {$_.DisplayName -like "*vulnerabilit*"}

  foreach ($assessment in $assessments) {
      Write-Host "Assessment: $($assessment.DisplayName)"
      Write-Host "Status: $($assessment.Status.Code)"
      Write-Host "Severity: $($assessment.Status.Severity)"
  }
'@ -ForegroundColor Gray
    Write-Host ""

    # Step 7: Review security alerts
    Write-Host "[Step 7] Reviewing security alerts and assessments" -ForegroundColor Yellow

    Write-Host "Monitor alerts generated by Defender for Servers..." -ForegroundColor Cyan
    Write-Host ""

    Write-Host "Example: Get security alerts for servers" -ForegroundColor Cyan
    Write-Host @'
  # Get all security alerts
  $alerts = Get-AzSecurityAlert

  # Filter alerts for virtual machines
  $vmAlerts = $alerts | Where-Object {
      $_.ResourceType -eq "Microsoft.Compute/virtualMachines"
  }

  # Display high severity VM alerts
  $vmAlerts |
      Where-Object {$_.Severity -eq "High"} |
      Select-Object AlertDisplayName, Severity, Status, @{
          N='VM'; E={$_.ExtendedProperties.resourceName}
      } |
      Format-Table -AutoSize
'@ -ForegroundColor Gray
    Write-Host ""

    Write-Host "Common Defender for Servers alerts:" -ForegroundColor Cyan
    Write-Host "  - Suspicious PowerShell activity detected" -ForegroundColor White
    Write-Host "  - Unusual process execution detected" -ForegroundColor White
    Write-Host "  - Antimalware Action Failed" -ForegroundColor White
    Write-Host "  - Fileless attack behavior detected" -ForegroundColor White
    Write-Host "  - High risk login detected" -ForegroundColor White
    Write-Host "  - Potential crypto mining activity" -ForegroundColor White
    Write-Host ""

    # Step 8: Get security assessments
    Write-Host "[Step 8] Getting security assessments" -ForegroundColor Yellow

    Write-Host "View security posture and compliance status..." -ForegroundColor Cyan
    Write-Host ""

    Write-Host "Example: Get security assessments for servers" -ForegroundColor Cyan
    Write-Host @'
  # Get security assessments for virtual machines
  $vmAssessments = Get-AzSecurityAssessment |
      Where-Object {
          $_.ResourceDetails.Id -like "*/virtualMachines/*"
      }

  # Show unhealthy assessments
  $vmAssessments |
      Where-Object {$_.Status.Code -ne "Healthy"} |
      Select-Object DisplayName,
          @{N='Status';E={$_.Status.Code}},
          @{N='Severity';E={$_.Status.Severity}},
          @{N='VM';E={($_.ResourceDetails.Id -split '/')[-1]}} |
      Format-Table -AutoSize

  # Get specific assessment (e.g., system updates)
  Get-AzSecurityAssessment |
      Where-Object {$_.DisplayName -like "*System updates*"}
'@ -ForegroundColor Gray
    Write-Host ""

    # Step 9: Configure Just-in-Time VM access
    Write-Host "[Step 9] Configuring Just-in-Time VM access" -ForegroundColor Yellow

    Write-Host "JIT VM access reduces attack surface by controlling RDP/SSH access..." -ForegroundColor Cyan
    Write-Host ""

    Write-Host "JIT access must be enabled through Azure Portal:" -ForegroundColor White
    Write-Host "  1. Navigate to Defender for Cloud" -ForegroundColor Gray
    Write-Host "  2. Workload protections > Just-in-time VM access" -ForegroundColor Gray
    Write-Host "  3. Select VMs and configure JIT policies" -ForegroundColor Gray
    Write-Host "  4. Set allowed ports (RDP 3389, SSH 22, etc.)" -ForegroundColor Gray
    Write-Host "  5. Configure maximum request time (default 3 hours)" -ForegroundColor Gray
    Write-Host ""

    Write-Host "Request JIT access via PowerShell:" -ForegroundColor Cyan
    Write-Host @'
  # Request JIT access (example structure)
  $justInTimeAccessRequests = @{
      virtualMachines = @(
          @{
              id = "/subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.Compute/virtualMachines/server01"
              ports = @(
                  @{
                      number = 3389
                      duration = "PT3H"
                      allowedSourceAddressPrefix = @("192.168.1.0/24")
                  }
              )
          }
      )
  }

  # Apply via Azure Portal or REST API
'@ -ForegroundColor Gray
    Write-Host ""

    # Step 10: Best practices and monitoring
    Write-Host "[Step 10] Best practices and monitoring" -ForegroundColor Yellow

    Write-Host "Best practices for Defender for Servers:" -ForegroundColor Cyan
    Write-Host "  1. Enable Plan 2 for maximum protection" -ForegroundColor White
    Write-Host "  2. Use auto-provisioning for consistent agent deployment" -ForegroundColor White
    Write-Host "  3. Configure JIT VM access for all internet-facing VMs" -ForegroundColor White
    Write-Host "  4. Review security alerts daily" -ForegroundColor White
    Write-Host "  5. Remediate vulnerability findings promptly" -ForegroundColor White
    Write-Host "  6. Enable File Integrity Monitoring for critical servers" -ForegroundColor White
    Write-Host "  7. Use Adaptive Application Controls in audit mode first" -ForegroundColor White
    Write-Host "  8. Integrate with Microsoft Sentinel for SIEM" -ForegroundColor White
    Write-Host "  9. Configure security contacts for alert notifications" -ForegroundColor White
    Write-Host "  10. Monitor Secure Score for continuous improvement" -ForegroundColor White
    Write-Host ""

    Write-Host "Monitoring commands:" -ForegroundColor Cyan
    Write-Host '  Get-AzSecurityAlert | Where-Object {$_.ResourceType -like "*VirtualMachine*"}' -ForegroundColor Gray
    Write-Host '  Get-AzSecurityAssessment | Where-Object {$_.ResourceDetails.Id -like "*/virtualMachines/*"}' -ForegroundColor Gray
    Write-Host '  Get-AzSecurityPricing -Name "VirtualMachines"' -ForegroundColor Gray
    Write-Host ""

    Write-Host "[INFO] Additional Resources:" -ForegroundColor Cyan
    Write-Host "  Docs: https://docs.microsoft.com/azure/defender-for-cloud/defender-for-servers-introduction" -ForegroundColor White
    Write-Host "  MDE Portal: https://security.microsoft.com" -ForegroundColor White
    Write-Host "  Pricing: https://azure.microsoft.com/pricing/details/defender-for-cloud/" -ForegroundColor White
    Write-Host ""

} catch {
    Write-Host "[ERROR] $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

Write-Host "Demo completed successfully!" -ForegroundColor Green
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Enable Defender for Servers Plan 2 on subscription" -ForegroundColor White
Write-Host "  2. Configure auto-provisioning for agents" -ForegroundColor White
Write-Host "  3. Verify MDE deployment on all servers" -ForegroundColor White
Write-Host "  4. Review and remediate vulnerability findings" -ForegroundColor White
Write-Host "  5. Configure Just-in-Time VM access policies" -ForegroundColor White
Write-Host "  6. Enable File Integrity Monitoring on critical servers" -ForegroundColor White
Write-Host "  7. Review and respond to security alerts" -ForegroundColor White
Write-Host "  8. Monitor security assessments and Secure Score" -ForegroundColor White
