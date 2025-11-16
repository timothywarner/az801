<#
.SYNOPSIS
    Task 13.1 - Backup to Recovery Services Vault

.DESCRIPTION
    Demo script for AZ-801 Module 13: Implement Azure Backup
    Demonstrates Azure Backup deployment for on-premises servers using Recovery Services Vault.
    Covers vault creation, resource registration, and backup configuration.

.NOTES
    Module: Module 13 - Implement Azure Backup
    Task: 13.1 - Backup to Recovery Services Vault
    Prerequisites: Az.RecoveryServices module, Azure subscription
    PowerShell Version: 5.1+
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ResourceGroupName = "rg-backup-demo",

    [Parameter(Mandatory = $false)]
    [string]$Location = "eastus",

    [Parameter(Mandatory = $false)]
    [string]$VaultName = "rsv-backup-vault-demo",

    [Parameter(Mandatory = $false)]
    [switch]$SkipCleanup
)

$ErrorActionPreference = 'Stop'
Write-Host "=== AZ-801 Module 13: Task 13.1 - Backup to Recovery Services Vault ===" -ForegroundColor Cyan
Write-Host ""

try {
    # Step 1: Azure Authentication
    Write-Host "[Step 1] Authenticating to Azure" -ForegroundColor Yellow

    # Check if already connected
    $context = Get-AzContext -ErrorAction SilentlyContinue
    if (-not $context) {
        Write-Host "Connecting to Azure..." -ForegroundColor Cyan
        Connect-AzAccount
        $context = Get-AzContext
    }

    Write-Host "  Connected to subscription: $($context.Subscription.Name)" -ForegroundColor Green
    Write-Host "  Subscription ID: $($context.Subscription.Id)" -ForegroundColor White
    Write-Host ""

    # Step 2: Create Resource Group
    Write-Host "[Step 2] Creating Resource Group" -ForegroundColor Yellow

    $rg = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
    if (-not $rg) {
        Write-Host "Creating resource group '$ResourceGroupName' in $Location..." -ForegroundColor Cyan
        $rg = New-AzResourceGroup -Name $ResourceGroupName -Location $Location
        Write-Host "  Resource group created successfully" -ForegroundColor Green
    } else {
        Write-Host "  Resource group '$ResourceGroupName' already exists" -ForegroundColor White
    }
    Write-Host ""

    # Step 3: Create Recovery Services Vault
    Write-Host "[Step 3] Creating Recovery Services Vault" -ForegroundColor Yellow

    # Check if vault already exists
    $vault = Get-AzRecoveryServicesVault -ResourceGroupName $ResourceGroupName -Name $VaultName -ErrorAction SilentlyContinue

    if (-not $vault) {
        Write-Host "Creating Recovery Services Vault '$VaultName'..." -ForegroundColor Cyan

        # Create the vault
        $vault = New-AzRecoveryServicesVault `
            -ResourceGroupName $ResourceGroupName `
            -Name $VaultName `
            -Location $Location

        Write-Host "  Vault created successfully" -ForegroundColor Green
        Write-Host "  Vault ID: $($vault.ID)" -ForegroundColor White
    } else {
        Write-Host "  Vault '$VaultName' already exists" -ForegroundColor White
    }

    # Set vault context for subsequent operations
    Set-AzRecoveryServicesVaultContext -Vault $vault
    Write-Host ""

    # Step 4: Configure Vault Properties
    Write-Host "[Step 4] Configuring Vault Properties" -ForegroundColor Yellow

    # Get current vault properties
    $vaultProperty = Get-AzRecoveryServicesVaultProperty -VaultId $vault.ID

    Write-Host "Configuring storage redundancy..." -ForegroundColor Cyan
    # Set storage redundancy to Geo-Redundant (GRS)
    Set-AzRecoveryServicesBackupProperty `
        -Vault $vault `
        -BackupStorageRedundancy GeoRedundant

    Write-Host "  Storage redundancy set to: GeoRedundant" -ForegroundColor Green
    Write-Host ""

    # Step 5: Register Backup Container (simulated for on-premises)
    Write-Host "[Step 5] Backup Container Registration" -ForegroundColor Yellow
    Write-Host "For on-premises backup, you would:" -ForegroundColor Cyan
    Write-Host "  1. Download the vault credentials file" -ForegroundColor White
    Write-Host "  2. Install the Azure Backup Agent (MARS)" -ForegroundColor White
    Write-Host "  3. Register the server with the vault" -ForegroundColor White
    Write-Host ""

    # Download vault credentials (for reference)
    $vaultCredsPath = "$env:TEMP\$VaultName.VaultCredentials"
    Write-Host "Vault credentials would be downloaded to: $vaultCredsPath" -ForegroundColor White

    # In production, use:
    # Get-AzRecoveryServicesVaultSettingsFile -Vault $vault -Path $env:TEMP

    Write-Host ""

    # Step 6: Configure Backup Policy
    Write-Host "[Step 6] Creating Backup Policy" -ForegroundColor Yellow

    # Get default policy as template
    $schPolicy = Get-AzRecoveryServicesBackupSchedulePolicyObject -WorkloadType "Windows"
    $retPolicy = Get-AzRecoveryServicesBackupRetentionPolicyObject -WorkloadType "Windows"

    # Modify schedule - Daily at 10:00 PM
    $schPolicy.ScheduleRunTimes.Clear()
    $schPolicy.ScheduleRunTimes.Add((Get-Date -Hour 22 -Minute 0 -Second 0))

    Write-Host "Creating backup policy with daily schedule..." -ForegroundColor Cyan

    # Check if policy exists
    $policyName = "DailyBackupPolicy"
    $existingPolicy = Get-AzRecoveryServicesBackupProtectionPolicy `
        -Name $policyName `
        -ErrorAction SilentlyContinue

    if (-not $existingPolicy) {
        $policy = New-AzRecoveryServicesBackupProtectionPolicy `
            -Name $policyName `
            -WorkloadType "Windows" `
            -RetentionPolicy $retPolicy `
            -SchedulePolicy $schPolicy

        Write-Host "  Policy '$policyName' created successfully" -ForegroundColor Green
    } else {
        Write-Host "  Policy '$policyName' already exists" -ForegroundColor White
        $policy = $existingPolicy
    }

    Write-Host "  Schedule: Daily at 10:00 PM" -ForegroundColor White
    Write-Host "  Retention: $($retPolicy.DailySchedule.DurationCountInDays) days" -ForegroundColor White
    Write-Host ""

    # Step 7: Vault Information Summary
    Write-Host "[Step 7] Recovery Services Vault Summary" -ForegroundColor Yellow

    $vaultInfo = Get-AzRecoveryServicesVault -ResourceGroupName $ResourceGroupName -Name $VaultName

    Write-Host "Vault Details:" -ForegroundColor Cyan
    Write-Host "  Name: $($vaultInfo.Name)" -ForegroundColor White
    Write-Host "  Location: $($vaultInfo.Location)" -ForegroundColor White
    Write-Host "  Resource Group: $($vaultInfo.ResourceGroupName)" -ForegroundColor White
    Write-Host "  Vault ID: $($vaultInfo.ID)" -ForegroundColor White
    Write-Host ""

    # Get backup policies
    $policies = Get-AzRecoveryServicesBackupProtectionPolicy
    Write-Host "Configured Backup Policies: $($policies.Count)" -ForegroundColor Cyan
    foreach ($pol in $policies) {
        Write-Host "  - $($pol.Name) [$($pol.WorkloadType)]" -ForegroundColor White
    }
    Write-Host ""

    # Step 8: Next Steps and Best Practices
    Write-Host "[Step 8] Next Steps" -ForegroundColor Yellow
    Write-Host "To complete on-premises backup setup:" -ForegroundColor Cyan
    Write-Host "  1. Download vault credentials from Azure Portal" -ForegroundColor White
    Write-Host "  2. Install Microsoft Azure Recovery Services (MARS) Agent" -ForegroundColor White
    Write-Host "  3. Register the server using vault credentials" -ForegroundColor White
    Write-Host "  4. Configure backup items (files, folders, system state)" -ForegroundColor White
    Write-Host "  5. Run initial backup and verify completion" -ForegroundColor White
    Write-Host ""

    Write-Host "[INFO] Best Practices:" -ForegroundColor Cyan
    Write-Host "  - Use GeoRedundant storage for production workloads" -ForegroundColor White
    Write-Host "  - Configure backup policies based on RPO/RTO requirements" -ForegroundColor White
    Write-Host "  - Enable soft delete for ransomware protection" -ForegroundColor White
    Write-Host "  - Regularly test restore procedures" -ForegroundColor White
    Write-Host "  - Monitor backup jobs and set up alerts" -ForegroundColor White
    Write-Host "  - Document vault credentials location securely" -ForegroundColor White
    Write-Host ""

    # Cleanup option
    if (-not $SkipCleanup) {
        Write-Host "[Cleanup] Resource Cleanup" -ForegroundColor Yellow
        $cleanup = Read-Host "Do you want to delete the created resources? (yes/no)"

        if ($cleanup -eq 'yes') {
            Write-Host "Deleting Recovery Services Vault..." -ForegroundColor Cyan

            # Remove policies first
            $policies = Get-AzRecoveryServicesBackupProtectionPolicy
            foreach ($pol in $policies) {
                if ($pol.Name -ne "DefaultPolicy") {
                    Remove-AzRecoveryServicesBackupProtectionPolicy -Policy $pol -Force
                }
            }

            # Remove vault
            Remove-AzRecoveryServicesVault -ResourceGroupName $ResourceGroupName -Name $VaultName -Force
            Write-Host "  Vault deleted" -ForegroundColor Green

            Write-Host "Deleting resource group..." -ForegroundColor Cyan
            Remove-AzResourceGroup -Name $ResourceGroupName -Force
            Write-Host "  Resource group deleted" -ForegroundColor Green
        }
    }

} catch {
    Write-Host "[ERROR] An error occurred: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Script completed successfully!" -ForegroundColor Green
Write-Host "Recovery Services Vault is ready for backup operations" -ForegroundColor Yellow
