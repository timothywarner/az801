<#
.SYNOPSIS
    Task 5.4 - Configure Microsoft Defender for Cloud
.DESCRIPTION
    Comprehensive demonstration of Microsoft Defender for Cloud configuration and features.
    Covers enabling defender plans, security posture management, and compliance monitoring.
.EXAMPLE
    .\task-5.4-defender-for-cloud.ps1
.NOTES
    Module: Module 5 - Monitor and Defend with Microsoft Security Tools
    Task: 5.4 - Configure Microsoft Defender for Cloud
    Prerequisites:
    - Azure subscription with appropriate permissions
    - Az PowerShell modules (Az.Accounts, Az.Security, Az.Resources)
    - Contributor or Security Admin role
    PowerShell Version: 5.1+
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

Write-Host "=== AZ-801 Module 5: Task 5.4 - Configure Microsoft Defender for Cloud ===" -ForegroundColor Cyan
Write-Host ""

try {
    # Step 1: Defender for Cloud Overview
    Write-Host "[Step 1] Microsoft Defender for Cloud Overview" -ForegroundColor Yellow

    Write-Host "Defender for Cloud capabilities:" -ForegroundColor Cyan
    Write-Host "  - Continuous security posture assessment" -ForegroundColor White
    Write-Host "  - Threat protection across Azure, hybrid, and multi-cloud workloads" -ForegroundColor White
    Write-Host "  - Regulatory compliance dashboards" -ForegroundColor White
    Write-Host "  - Just-in-Time VM access" -ForegroundColor White
    Write-Host "  - Adaptive application controls" -ForegroundColor White
    Write-Host "  - File integrity monitoring" -ForegroundColor White
    Write-Host ""

    Write-Host "Available Defender plans:" -ForegroundColor Cyan
    Write-Host "  - Defender for Servers (Plan 1 & Plan 2)" -ForegroundColor White
    Write-Host "  - Defender for App Service" -ForegroundColor White
    Write-Host "  - Defender for Storage" -ForegroundColor White
    Write-Host "  - Defender for SQL" -ForegroundColor White
    Write-Host "  - Defender for Containers" -ForegroundColor White
    Write-Host "  - Defender for Key Vault" -ForegroundColor White
    Write-Host "  - Defender for Resource Manager" -ForegroundColor White
    Write-Host "  - Defender for DNS" -ForegroundColor White
    Write-Host ""

    # Step 2: Check Azure PowerShell modules
    Write-Host "[Step 2] Checking Azure PowerShell modules" -ForegroundColor Yellow

    $requiredModules = @('Az.Accounts', 'Az.Security', 'Az.Resources', 'Az.Compute')

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
            Write-Host "  Tenant: $($context.Tenant.Id)" -ForegroundColor White
        } else {
            Write-Host "Not connected to Azure" -ForegroundColor Yellow
            Write-Host "Run: Connect-AzAccount" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "Example:" -ForegroundColor Cyan
            Write-Host '  Connect-AzAccount' -ForegroundColor Gray
            Write-Host '  Set-AzContext -Subscription "Your Subscription Name"' -ForegroundColor Gray
        }
    } catch {
        Write-Host "Azure PowerShell not authenticated" -ForegroundColor Yellow
        Write-Host "Run: Connect-AzAccount" -ForegroundColor Cyan
    }
    Write-Host ""

    # Step 4: Check current Defender for Cloud pricing tiers
    Write-Host "[Step 4] Checking current Defender for Cloud pricing" -ForegroundColor Yellow

    Write-Host "Querying current Defender for Cloud pricing tiers..." -ForegroundColor Cyan
    Write-Host ""

    Write-Host "Example: Get current pricing tiers" -ForegroundColor Cyan
    Write-Host @'
  # Get all pricing tiers
  $pricingTiers = Get-AzSecurityPricing

  # Display pricing information
  foreach ($tier in $pricingTiers) {
      Write-Host "  Resource: $($tier.Name)"
      Write-Host "  Tier: $($tier.PricingTier)"
      Write-Host ""
  }
'@ -ForegroundColor Gray
    Write-Host ""

    # Step 5: Enable Defender plans
    Write-Host "[Step 5] Enabling Defender for Cloud plans" -ForegroundColor Yellow

    Write-Host "Enable Defender plans for subscription protection..." -ForegroundColor Cyan
    Write-Host ""

    Write-Host "Example: Enable Defender for Servers Plan 2" -ForegroundColor Cyan
    Write-Host @'
  # Enable Defender for Servers (Plan 2 - full features)
  Set-AzSecurityPricing `
      -Name "VirtualMachines" `
      -PricingTier "Standard" `
      -SubPlan "P2"

  # Enable Defender for App Service
  Set-AzSecurityPricing `
      -Name "AppServices" `
      -PricingTier "Standard"

  # Enable Defender for Storage
  Set-AzSecurityPricing `
      -Name "StorageAccounts" `
      -PricingTier "Standard"

  # Enable Defender for SQL
  Set-AzSecurityPricing `
      -Name "SqlServers" `
      -PricingTier "Standard"

  # Enable Defender for Containers
  Set-AzSecurityPricing `
      -Name "Containers" `
      -PricingTier "Standard"

  # Enable Defender for Key Vault
  Set-AzSecurityPricing `
      -Name "KeyVaults" `
      -PricingTier "Standard"

  # Enable Defender for Resource Manager
  Set-AzSecurityPricing `
      -Name "Arm" `
      -PricingTier "Standard"

  # Enable Defender for DNS
  Set-AzSecurityPricing `
      -Name "Dns" `
      -PricingTier "Standard"
'@ -ForegroundColor Gray
    Write-Host ""

    Write-Host "Defender for Servers Plan comparison:" -ForegroundColor Cyan
    Write-Host "  Plan 1: Basic threat detection, Just-in-Time access" -ForegroundColor White
    Write-Host "  Plan 2: All Plan 1 + File Integrity Monitoring, Adaptive Application Controls" -ForegroundColor White
    Write-Host ""

    # Step 6: Configure security contacts
    Write-Host "[Step 6] Configuring security contacts" -ForegroundColor Yellow

    Write-Host "Set up security contact information for alerts..." -ForegroundColor Cyan
    Write-Host ""

    Write-Host "Example: Configure security contacts" -ForegroundColor Cyan
    Write-Host @'
  # Set security contact
  Set-AzSecurityContact `
      -Name "default1" `
      -Email "security@contoso.com" `
      -Phone "+1-555-0123" `
      -AlertAdmin `
      -NotifyOnAlert

  # Verify security contact
  Get-AzSecurityContact -Name "default1"
'@ -ForegroundColor Gray
    Write-Host ""

    Write-Host "Email notification options:" -ForegroundColor Cyan
    Write-Host "  -AlertAdmin: Email subscription administrators" -ForegroundColor White
    Write-Host "  -NotifyOnAlert: Send emails for high severity alerts" -ForegroundColor White
    Write-Host ""

    # Step 7: Review security recommendations
    Write-Host "[Step 7] Reviewing security recommendations" -ForegroundColor Yellow

    Write-Host "Defender for Cloud provides continuous security assessment..." -ForegroundColor Cyan
    Write-Host ""

    Write-Host "Example: Get security recommendations" -ForegroundColor Cyan
    Write-Host @'
  # Get all security tasks/recommendations
  $recommendations = Get-AzSecurityTask

  # Display high priority recommendations
  $recommendations |
      Where-Object {$_.State -eq "Active"} |
      Select-Object Name, State, SecurityTaskParameters |
      Format-Table -AutoSize

  # Get recommendations for specific resource
  Get-AzSecurityTask |
      Where-Object {$_.ResourceId -like "*server01*"}
'@ -ForegroundColor Gray
    Write-Host ""

    Write-Host "Common security recommendations:" -ForegroundColor Cyan
    Write-Host "  - Install endpoint protection" -ForegroundColor White
    Write-Host "  - Apply system updates" -ForegroundColor White
    Write-Host "  - Enable disk encryption" -ForegroundColor White
    Write-Host "  - Restrict network access" -ForegroundColor White
    Write-Host "  - Enable MFA for privileged accounts" -ForegroundColor White
    Write-Host "  - Remediate vulnerabilities" -ForegroundColor White
    Write-Host ""

    # Step 8: Monitor security alerts
    Write-Host "[Step 8] Monitoring security alerts" -ForegroundColor Yellow

    Write-Host "View and manage security alerts from Defender for Cloud..." -ForegroundColor Cyan
    Write-Host ""

    Write-Host "Example: Get security alerts" -ForegroundColor Cyan
    Write-Host @'
  # Get all security alerts
  $alerts = Get-AzSecurityAlert

  # Display recent high severity alerts
  $alerts |
      Where-Object {$_.Severity -eq "High"} |
      Select-Object AlertDisplayName, Severity, Status, TimeGeneratedUtc |
      Sort-Object TimeGeneratedUtc -Descending |
      Format-Table -AutoSize

  # Get alerts for specific VM
  Get-AzSecurityAlert |
      Where-Object {$_.ExtendedProperties.resourceName -eq "server01"}

  # Update alert status
  Set-AzSecurityAlert `
      -Name "<alert-id>" `
      -Status "Dismissed" `
      -ActionReason "False positive"
'@ -ForegroundColor Gray
    Write-Host ""

    Write-Host "Alert severity levels:" -ForegroundColor Cyan
    Write-Host "  - High: Immediate attention required" -ForegroundColor Red
    Write-Host "  - Medium: Should be investigated" -ForegroundColor Yellow
    Write-Host "  - Low: Informational" -ForegroundColor White
    Write-Host "  - Informational: Awareness only" -ForegroundColor Gray
    Write-Host ""

    # Step 9: Configure auto-provisioning
    Write-Host "[Step 9] Configuring auto-provisioning" -ForegroundColor Yellow

    Write-Host "Enable automatic agent deployment for new VMs..." -ForegroundColor Cyan
    Write-Host ""

    Write-Host "Example: Enable auto-provisioning" -ForegroundColor Cyan
    Write-Host @'
  # Enable auto-provisioning of Log Analytics agent
  Set-AzSecurityAutoProvisioningSetting `
      -Name "default" `
      -EnableAutoProvision

  # Check auto-provisioning status
  Get-AzSecurityAutoProvisioningSetting

  # Configure workspace for auto-provisioning
  Set-AzSecurityWorkspaceSetting `
      -Name "default" `
      -Scope "/subscriptions/<subscription-id>" `
      -WorkspaceId "/subscriptions/<sub-id>/resourceGroups/<rg>/providers/Microsoft.OperationalInsights/workspaces/<workspace>"
'@ -ForegroundColor Gray
    Write-Host ""

    Write-Host "Auto-provisioning benefits:" -ForegroundColor Cyan
    Write-Host "  - Automatic agent installation on new VMs" -ForegroundColor White
    Write-Host "  - Consistent security monitoring" -ForegroundColor White
    Write-Host "  - Centralized log collection" -ForegroundColor White
    Write-Host "  - Simplified management" -ForegroundColor White
    Write-Host ""

    # Step 10: Secure Score and Compliance
    Write-Host "[Step 10] Monitoring Secure Score and Compliance" -ForegroundColor Yellow

    Write-Host "Track security posture and regulatory compliance..." -ForegroundColor Cyan
    Write-Host ""

    Write-Host "Example: Get Secure Score" -ForegroundColor Cyan
    Write-Host @'
  # Get current secure score
  $secureScore = Get-AzSecuritySecureScore -Name "ascScore"

  Write-Host "Secure Score: $($secureScore.Score.Current) / $($secureScore.Score.Max)"
  Write-Host "Percentage: $($secureScore.Score.Percentage)%"

  # Get secure score controls
  $controls = Get-AzSecuritySecureScoreControl

  # Display controls with potential for improvement
  $controls |
      Where-Object {$_.Score.Current -lt $_.Score.Max} |
      Select-Object DisplayName,
          @{N='Current';E={$_.Score.Current}},
          @{N='Max';E={$_.Score.Max}},
          @{N='Unhealthy';E={$_.Definition.Properties.UnhealthyResourceCount}} |
      Sort-Object Unhealthy -Descending
'@ -ForegroundColor Gray
    Write-Host ""

    Write-Host "Compliance standards available:" -ForegroundColor Cyan
    Write-Host "  - Azure Security Benchmark" -ForegroundColor White
    Write-Host "  - PCI DSS 3.2.1" -ForegroundColor White
    Write-Host "  - ISO 27001:2013" -ForegroundColor White
    Write-Host "  - SOC 2 Type 2" -ForegroundColor White
    Write-Host "  - NIST SP 800-53 R4" -ForegroundColor White
    Write-Host "  - HIPAA/HITRUST" -ForegroundColor White
    Write-Host ""

    Write-Host "View compliance in Azure Portal:" -ForegroundColor Cyan
    Write-Host "  Defender for Cloud > Regulatory compliance" -ForegroundColor White
    Write-Host ""

    # Best Practices
    Write-Host "Best Practices:" -ForegroundColor Cyan
    Write-Host "  1. Enable all relevant Defender plans for comprehensive protection" -ForegroundColor White
    Write-Host "  2. Configure security contacts with valid email addresses" -ForegroundColor White
    Write-Host "  3. Enable auto-provisioning for consistent agent deployment" -ForegroundColor White
    Write-Host "  4. Review security recommendations weekly" -ForegroundColor White
    Write-Host "  5. Investigate high severity alerts immediately" -ForegroundColor White
    Write-Host "  6. Monitor Secure Score trends over time" -ForegroundColor White
    Write-Host "  7. Map compliance standards to business requirements" -ForegroundColor White
    Write-Host "  8. Use workflow automation for alert response" -ForegroundColor White
    Write-Host "  9. Regularly review and update security policies" -ForegroundColor White
    Write-Host "  10. Integrate with Microsoft Sentinel for advanced SIEM" -ForegroundColor White
    Write-Host ""

    Write-Host "[INFO] Additional Resources:" -ForegroundColor Cyan
    Write-Host "  Portal: https://portal.azure.com/#view/Microsoft_Azure_Security/SecurityMenuBlade" -ForegroundColor White
    Write-Host "  Docs: https://docs.microsoft.com/azure/defender-for-cloud/" -ForegroundColor White
    Write-Host "  Pricing: https://azure.microsoft.com/pricing/details/defender-for-cloud/" -ForegroundColor White
    Write-Host ""

} catch {
    Write-Host "[ERROR] $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

Write-Host "Demo completed successfully!" -ForegroundColor Green
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Enable Defender for Cloud plans on your subscription" -ForegroundColor White
Write-Host "  2. Configure security contact information" -ForegroundColor White
Write-Host "  3. Enable auto-provisioning for agents" -ForegroundColor White
Write-Host "  4. Review and remediate security recommendations" -ForegroundColor White
Write-Host "  5. Configure alert email notifications" -ForegroundColor White
Write-Host "  6. Monitor Secure Score and improve security posture" -ForegroundColor White
Write-Host "  7. Map compliance standards to your requirements" -ForegroundColor White
Write-Host "  8. Set up workflow automation for incident response" -ForegroundColor White
