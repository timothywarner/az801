<#
.SYNOPSIS
    Task 13.6 - Configure Ransomware Protection

.DESCRIPTION
    Demo script for AZ-801 Module 13: Implement Azure Backup
    Shows ransomware protection features in Azure Backup including soft delete,
    multi-user authorization, and immutable vault settings.

.NOTES
    Module: Module 13 - Implement Azure Backup
    Task: 13.6 - Configure Ransomware Protection
    Prerequisites: Az.RecoveryServices module, Az.Security module
    PowerShell Version: 5.1+
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ResourceGroupName = "rg-backup-demo",

    [Parameter(Mandatory = $false)]
    [string]$VaultName = "rsv-backup-vault-demo"
)

$ErrorActionPreference = 'Stop'
Write-Host "=== AZ-801 Module 13: Task 13.6 - Configure Ransomware Protection ===" -ForegroundColor Cyan
Write-Host ""

try {
    # Step 1: Azure Authentication
    Write-Host "[Step 1] Authenticating to Azure" -ForegroundColor Yellow

    $context = Get-AzContext -ErrorAction SilentlyContinue
    if (-not $context) {
        Connect-AzAccount
        $context = Get-AzContext
    }

    Write-Host "  Connected to subscription: $($context.Subscription.Name)" -ForegroundColor Green
    Write-Host ""

    # Step 2: Enable Soft Delete
    Write-Host "[Step 2] Configuring Soft Delete" -ForegroundColor Yellow

    $vault = Get-AzRecoveryServicesVault -ResourceGroupName $ResourceGroupName -Name $VaultName -ErrorAction SilentlyContinue

    if ($vault) {
        Set-AzRecoveryServicesVaultContext -Vault $vault

        Write-Host "Enabling soft delete..." -ForegroundColor Cyan
        
        # Enable soft delete with extended retention
        Set-AzRecoveryServicesVaultProperty `
            -VaultId $vault.ID `
            -SoftDeleteFeatureState Enable

        Write-Host "  Soft delete enabled" -ForegroundColor Green
        Write-Host "  Retention period: 14 days (default)" -ForegroundColor White
        Write-Host ""

        Write-Host "Soft Delete Benefits:" -ForegroundColor Cyan
        Write-Host "  - Protection against accidental deletion" -ForegroundColor White
        Write-Host "  - 14-day recovery window" -ForegroundColor White
        Write-Host "  - Protects backup data and configuration" -ForegroundColor White
        Write-Host "  - No additional cost" -ForegroundColor White
    } else {
        Write-Host "  [INFO] Vault not found - demonstrating configuration..." -ForegroundColor Yellow
    }
    Write-Host ""

    # Step 3: Enhanced Soft Delete
    Write-Host "[Step 3] Configuring Enhanced Soft Delete (Always-On)" -ForegroundColor Yellow

    Write-Host "Enable enhanced soft delete (cannot be disabled):" -ForegroundColor Cyan
    Write-Host '  Set-AzRecoveryServicesVaultProperty `' -ForegroundColor Gray
    Write-Host '      -VaultId $vault.ID `' -ForegroundColor Gray
    Write-Host '      -SoftDeleteFeatureState AlwaysON' -ForegroundColor Gray
    Write-Host ""

    Write-Host "Enhanced Soft Delete Features:" -ForegroundColor Cyan
    Write-Host "  - Always enabled, cannot be disabled" -ForegroundColor White
    Write-Host "  - Protects against malicious deletion" -ForegroundColor White
    Write-Host "  - Recommended for production environments" -ForegroundColor White
    Write-Host "  - Additional security layer" -ForegroundColor White
    Write-Host ""

    # Step 4: Multi-User Authorization (MUA)
    Write-Host "[Step 4] Configuring Multi-User Authorization" -ForegroundColor Yellow

    Write-Host "Multi-User Authorization (MUA) protects critical operations:" -ForegroundColor Cyan
    Write-Host "  - Stop backup protection" -ForegroundColor White
    Write-Host "  - Disable soft delete" -ForegroundColor White
    Write-Host "  - Modify backup policy retention" -ForegroundColor White
    Write-Host "  - Delete recovery points" -ForegroundColor White
    Write-Host ""

    Write-Host "Enable MUA:" -ForegroundColor Cyan
    Write-Host '  # Create Resource Guard' -ForegroundColor Gray
    Write-Host '  $rg = New-AzResourceGuard -ResourceGroupName "rg-security" `' -ForegroundColor Gray
    Write-Host '      -Name "backup-resource-guard" -Location "eastus"' -ForegroundColor Gray
    Write-Host ""
    Write-Host '  # Associate Resource Guard with Vault' -ForegroundColor Gray
    Write-Host '  $vault = Get-AzRecoveryServicesVault -Name "VaultName"' -ForegroundColor Gray
    Write-Host '  Set-AzRecoveryServicesVaultProperty `' -ForegroundColor Gray
    Write-Host '      -VaultId $vault.ID `' -ForegroundColor Gray
    Write-Host '      -ResourceGuardOperationRequest $rg.Id' -ForegroundColor Gray
    Write-Host ""

    # Step 5: Immutable Vault Settings
    Write-Host "[Step 5] Configuring Immutable Vault" -ForegroundColor Yellow

    Write-Host "Immutable vault prevents:" -ForegroundColor Cyan
    Write-Host "  - Deletion of backup data before retention period" -ForegroundColor White
    Write-Host "  - Disabling of security features" -ForegroundColor White
    Write-Host "  - Modification of backup policies to reduce retention" -ForegroundColor White
    Write-Host ""

    Write-Host "Enable immutability:" -ForegroundColor Cyan
    Write-Host '  Set-AzRecoveryServicesVaultProperty `' -ForegroundColor Gray
    Write-Host '      -VaultId $vault.ID `' -ForegroundColor Gray
    Write-Host '      -ImmutabilityState Locked' -ForegroundColor Gray
    Write-Host ""

    Write-Host "Immutability States:" -ForegroundColor Cyan
    Write-Host "  Unlocked: Default state, can be changed" -ForegroundColor White
    Write-Host "  Locked: Immutability enforced, cannot be disabled" -ForegroundColor White
    Write-Host ""

    # Step 6: Security PIN for Critical Operations
    Write-Host "[Step 6] Security PIN Configuration" -ForegroundColor Yellow

    Write-Host "Set security PIN for on-premises backup (MARS agent):" -ForegroundColor Cyan
    Write-Host '  # On MARS agent' -ForegroundColor Gray
    Write-Host '  Set-OBMachineSetting -SecurityPIN "1234"' -ForegroundColor Gray
    Write-Host '  # Now critical operations require PIN' -ForegroundColor Gray
    Write-Host ""

    # Step 7: Azure Defender for Cloud Integration
    Write-Host "[Step 7] Azure Defender Integration" -ForegroundColor Yellow

    Write-Host "Enable Azure Defender for enhanced threat protection:" -ForegroundColor Cyan
    Write-Host "  - Ransomware detection" -ForegroundColor White
    Write-Host "  - Unusual backup activity alerts" -ForegroundColor White
    Write-Host "  - Security recommendations" -ForegroundColor White
    Write-Host ""

    Write-Host "Example: Enable Defender for Storage" -ForegroundColor White
    Write-Host '  Set-AzSecurityPricing -Name "StorageAccounts" -PricingTier "Standard"' -ForegroundColor Gray
    Write-Host ""

    # Step 8: Monitoring and Alerts
    Write-Host "[Step 8] Security Monitoring and Alerts" -ForegroundColor Yellow

    Write-Host "Configure security alerts:" -ForegroundColor Cyan
    Write-Host '  # Create action group for security alerts' -ForegroundColor Gray
    Write-Host '  $actionGroup = New-AzActionGroup -ResourceGroupName "rg-monitoring" `' -ForegroundColor Gray
    Write-Host '      -Name "backup-security-alerts" -ShortName "BkpSec"' -ForegroundColor Gray
    Write-Host ""
    Write-Host '  # Create alert rule for soft delete disablement' -ForegroundColor Gray
    Write-Host '  $condition = New-AzActivityLogAlertCondition `' -ForegroundColor Gray
    Write-Host '      -Field "operationName" -Equals "Microsoft.RecoveryServices/vaults/write"' -ForegroundColor Gray
    Write-Host ""

    # Step 9: Backup Data Security Best Practices
    Write-Host "[Step 9] Data Security Best Practices" -ForegroundColor Yellow

    Write-Host "[INFO] Ransomware Protection Best Practices:" -ForegroundColor Cyan
    Write-Host "  - Enable enhanced soft delete (Always-On)" -ForegroundColor White
    Write-Host "  - Configure multi-user authorization (MUA)" -ForegroundColor White
    Write-Host "  - Enable immutable vault for critical workloads" -ForegroundColor White
    Write-Host "  - Use separate Azure AD account for Resource Guard" -ForegroundColor White
    Write-Host "  - Implement RBAC with least privilege" -ForegroundColor White
    Write-Host "  - Monitor for unusual backup activity" -ForegroundColor White
    Write-Host "  - Regular security audits and reviews" -ForegroundColor White
    Write-Host "  - Test recovery procedures from isolated environment" -ForegroundColor White
    Write-Host "  - Maintain offline/air-gapped backup copies" -ForegroundColor White
    Write-Host ""

    # Step 10: Recovery from Ransomware Attack
    Write-Host "[Step 10] Ransomware Recovery Procedures" -ForegroundColor Yellow

    Write-Host "Recovery steps after ransomware attack:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. Isolate affected systems" -ForegroundColor White
    Write-Host "   - Disconnect from network" -ForegroundColor Gray
    Write-Host "   - Stop further encryption" -ForegroundColor Gray
    Write-Host ""

    Write-Host "2. Assess backup integrity" -ForegroundColor White
    Write-Host '   Get-AzRecoveryServicesBackupRecoveryPoint -Item $item' -ForegroundColor Gray
    Write-Host "   - Verify pre-infection recovery points" -ForegroundColor Gray
    Write-Host ""

    Write-Host "3. Restore from clean recovery point" -ForegroundColor White
    Write-Host '   $rp = Get-AzRecoveryServicesBackupRecoveryPoint -Item $item | Where-Object {' -ForegroundColor Gray
    Write-Host '       $_.RecoveryPointTime -lt (Get-Date "2024-01-15")  # Before attack' -ForegroundColor Gray
    Write-Host '   } | Select-Object -First 1' -ForegroundColor Gray
    Write-Host '   Restore-AzRecoveryServicesBackupItem -RecoveryPoint $rp' -ForegroundColor Gray
    Write-Host ""

    Write-Host "4. Verify restored data" -ForegroundColor White
    Write-Host "   - Scan for malware" -ForegroundColor Gray
    Write-Host "   - Validate data integrity" -ForegroundColor Gray
    Write-Host ""

    Write-Host "5. Document incident" -ForegroundColor White
    Write-Host "   - Timeline of events" -ForegroundColor Gray
    Write-Host "   - Recovery actions taken" -ForegroundColor Gray
    Write-Host "   - Lessons learned" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[INFO] Security Layers:" -ForegroundColor Cyan
    Write-Host "  Layer 1: Soft Delete (14-day retention)" -ForegroundColor White
    Write-Host "  Layer 2: Multi-User Authorization (MUA)" -ForegroundColor White
    Write-Host "  Layer 3: Immutable Vault" -ForegroundColor White
    Write-Host "  Layer 4: RBAC and least privilege" -ForegroundColor White
    Write-Host "  Layer 5: Azure Defender monitoring" -ForegroundColor White
    Write-Host ""

} catch {
    Write-Host "[ERROR] An error occurred: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Script completed successfully!" -ForegroundColor Green
Write-Host "Ransomware protection features configured" -ForegroundColor Yellow
