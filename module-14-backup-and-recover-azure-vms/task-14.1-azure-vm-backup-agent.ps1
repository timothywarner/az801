<#
.SYNOPSIS
    Task 14.1 - Configure Azure VM Backup Agent

.DESCRIPTION
    Demo script for AZ-801 Module 14: Backup and Recover Azure VMs
    Demonstrates VM backup agent installation, configuration, and enabling Azure VM backup protection.

.NOTES
    Module: Module 14 - Backup and Recover Azure VMs
    Task: 14.1 - Configure Azure VM Backup Agent
    Prerequisites: Az.Compute, Az.RecoveryServices modules
    PowerShell Version: 5.1+
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ResourceGroupName = "rg-vm-backup",

    [Parameter(Mandatory = $false)]
    [string]$VMName = "vm-webserver-01",

    [Parameter(Mandatory = $false)]
    [string]$VaultName = "rsv-vm-backup",

    [Parameter(Mandatory = $false)]
    [string]$Location = "eastus"
)

$ErrorActionPreference = 'Stop'
Write-Host "=== AZ-801 Module 14: Task 14.1 - Configure Azure VM Backup Agent ===" -ForegroundColor Cyan
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

    # Step 2: Create or Get Recovery Services Vault
    Write-Host "[Step 2] Setting Up Recovery Services Vault" -ForegroundColor Yellow

    $vault = Get-AzRecoveryServicesVault -ResourceGroupName $ResourceGroupName -Name $VaultName -ErrorAction SilentlyContinue

    if (-not $vault) {
        Write-Host "Creating Recovery Services Vault..." -ForegroundColor Cyan
        $rg = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
        if (-not $rg) {
            $rg = New-AzResourceGroup -Name $ResourceGroupName -Location $Location
        }

        $vault = New-AzRecoveryServicesVault -ResourceGroupName $ResourceGroupName -Name $VaultName -Location $Location
        Write-Host "  Vault created: $($vault.Name)" -ForegroundColor Green
    } else {
        Write-Host "  Using existing vault: $($vault.Name)" -ForegroundColor White
    }

    Set-AzRecoveryServicesVaultContext -Vault $vault
    Write-Host ""

    # Step 3: Configure Vault Properties
    Write-Host "[Step 3] Configuring Vault Properties" -ForegroundColor Yellow

    Set-AzRecoveryServicesBackupProperty -Vault $vault -BackupStorageRedundancy GeoRedundant
    Write-Host "  Storage redundancy: GeoRedundant" -ForegroundColor Green
    Write-Host ""

    # Step 4: Create or Get Backup Policy
    Write-Host "[Step 4] Configuring Backup Policy" -ForegroundColor Yellow

    $policyName = "DefaultVMPolicy"
    $policy = Get-AzRecoveryServicesBackupProtectionPolicy -Name $policyName -ErrorAction SilentlyContinue

    if (-not $policy) {
        Write-Host "Creating backup policy..." -ForegroundColor Cyan
        
        $schPol = Get-AzRecoveryServicesBackupSchedulePolicyObject -WorkloadType AzureVM
        $retPol = Get-AzRecoveryServicesBackupRetentionPolicyObject -WorkloadType AzureVM
        
        $schPol.ScheduleRunTimes.Clear()
        $schPol.ScheduleRunTimes.Add((Get-Date -Hour 23 -Minute 0 -Second 0))
        
        $retPol.DailySchedule.DurationCountInDays = 30
        
        $policy = New-AzRecoveryServicesBackupProtectionPolicy -Name $policyName -WorkloadType AzureVM -RetentionPolicy $retPol -SchedulePolicy $schPol
        Write-Host "  Policy created: $policyName" -ForegroundColor Green
    } else {
        Write-Host "  Using existing policy: $policyName" -ForegroundColor White
    }
    Write-Host ""

    # Step 5: Get Azure VM
    Write-Host "[Step 5] Locating Azure VM" -ForegroundColor Yellow

    $vm = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VMName -ErrorAction SilentlyContinue

    if ($vm) {
        Write-Host "  VM found: $($vm.Name)" -ForegroundColor Green
        Write-Host "  Location: $($vm.Location)" -ForegroundColor White
        Write-Host "  OS Type: $($vm.StorageProfile.OsDisk.OsType)" -ForegroundColor White
    } else {
        Write-Host "  [INFO] VM '$VMName' not found - demonstrating cmdlets..." -ForegroundColor Yellow
    }
    Write-Host ""

    # Step 6: Enable Backup Protection
    Write-Host "[Step 6] Enabling Backup Protection for VM" -ForegroundColor Yellow

    if ($vm) {
        Write-Host "Enabling backup protection..." -ForegroundColor Cyan
        
        $result = Enable-AzRecoveryServicesBackupProtection -ResourceGroupName $ResourceGroupName -Name $VMName -Policy $policy
        
        Write-Host "  Backup protection enabled" -ForegroundColor Green
        Write-Host "  Policy: $($policy.Name)" -ForegroundColor White
        Write-Host "  Schedule: Daily at 11:00 PM" -ForegroundColor White
    } else {
        Write-Host "Example: Enable backup protection" -ForegroundColor Cyan
        Write-Host '  Enable-AzRecoveryServicesBackupProtection `' -ForegroundColor Gray
        Write-Host '      -ResourceGroupName "rg-vm-backup" `' -ForegroundColor Gray
        Write-Host '      -Name "vm-webserver-01" `' -ForegroundColor Gray
        Write-Host '      -Policy $policy' -ForegroundColor Gray
    }
    Write-Host ""

    # Step 7: Verify Backup Configuration
    Write-Host "[Step 7] Verifying Backup Configuration" -ForegroundColor Yellow

    Write-Host "Check backup item status:" -ForegroundColor Cyan
    Write-Host '  $container = Get-AzRecoveryServicesBackupContainer -ContainerType AzureVM' -ForegroundColor Gray
    Write-Host '  $backupItem = Get-AzRecoveryServicesBackupItem -Container $container[0] -WorkloadType AzureVM' -ForegroundColor Gray
    Write-Host '  $backupItem | Select-Object Name, ProtectionStatus, LastBackupTime' -ForegroundColor Gray
    Write-Host ""

    # Step 8: Trigger Initial Backup
    Write-Host "[Step 8] Triggering Initial Backup" -ForegroundColor Yellow

    Write-Host "Run on-demand backup:" -ForegroundColor Cyan
    Write-Host '  $backupJob = Backup-AzRecoveryServicesBackupItem `' -ForegroundColor Gray
    Write-Host '      -Item $backupItem `' -ForegroundColor Gray
    Write-Host '      -ExpiryDateTimeUTC (Get-Date).AddDays(30)' -ForegroundColor Gray
    Write-Host '  Wait-AzRecoveryServicesBackupJob -Job $backupJob' -ForegroundColor Gray
    Write-Host ""

    # Step 9: VM Backup Agent Information
    Write-Host "[Step 9] VM Backup Agent Information" -ForegroundColor Yellow

    Write-Host "Azure VM Backup Agent:" -ForegroundColor Cyan
    Write-Host "  - Azure VM Extension automatically installed" -ForegroundColor White
    Write-Host "  - No manual agent installation required" -ForegroundColor White
    Write-Host "  - Supports Windows and Linux VMs" -ForegroundColor White
    Write-Host "  - Application-consistent snapshots (Windows with VSS)" -ForegroundColor White
    Write-Host "  - File-system consistent snapshots (Linux)" -ForegroundColor White
    Write-Host ""

    Write-Host "VM Extension Details:" -ForegroundColor Cyan
    Write-Host "  Windows: VMSnapshotWindows extension" -ForegroundColor White
    Write-Host "  Linux: VMSnapshotLinux extension" -ForegroundColor White
    Write-Host "  Automatic updates managed by Azure" -ForegroundColor White
    Write-Host ""

    # Step 10: Best Practices
    Write-Host "[Step 10] Azure VM Backup Best Practices" -ForegroundColor Yellow

    Write-Host "[INFO] Best Practices:" -ForegroundColor Cyan
    Write-Host "  - Enable backup protection immediately after VM creation" -ForegroundColor White
    Write-Host "  - Use appropriate backup policy based on RPO requirements" -ForegroundColor White
    Write-Host "  - Enable Azure Disk Encryption before backup if needed" -ForegroundColor White
    Write-Host "  - Test restore procedures regularly" -ForegroundColor White
    Write-Host "  - Monitor backup job status daily" -ForegroundColor White
    Write-Host "  - Use geo-redundant storage for production VMs" -ForegroundColor White
    Write-Host "  - Tag VMs with backup policy assignments" -ForegroundColor White
    Write-Host "  - Configure backup alerts and notifications" -ForegroundColor White
    Write-Host ""

    Write-Host "[INFO] Backup Types:" -ForegroundColor Cyan
    Write-Host "  Crash-consistent: All VMs (basic protection)" -ForegroundColor White
    Write-Host "  File-system consistent: Linux VMs with pre/post scripts" -ForegroundColor White
    Write-Host "  Application-consistent: Windows VMs with VSS" -ForegroundColor White
    Write-Host ""

} catch {
    Write-Host "[ERROR] An error occurred: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Script completed successfully!" -ForegroundColor Green
Write-Host "Azure VM backup configuration demonstrated" -ForegroundColor Yellow
