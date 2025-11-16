<#
.SYNOPSIS
    Task 14.2 - Instant Recovery Snapshots

.DESCRIPTION
    Demonstrates snapshot-based recovery and instant restore capabilities for Azure VMs.

.NOTES
    Module: Module 14 - Backup and Recover Azure VMs
    Task: 14.2 - Instant Recovery Snapshots
    Prerequisites: Az.RecoveryServices, Az.Compute modules
    PowerShell Version: 5.1+
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ResourceGroupName = "rg-vm-backup",
    
    [Parameter(Mandatory = $false)]
    [string]$VaultName = "rsv-vm-backup"
)

$ErrorActionPreference = 'Stop'
Write-Host "=== AZ-801 Module 14: Task 14.2 - Instant Recovery Snapshots ===" -ForegroundColor Cyan
Write-Host ""

try {
    Write-Host "[Step 1] Authenticating to Azure" -ForegroundColor Yellow
    
    $context = Get-AzContext -ErrorAction SilentlyContinue
    if (-not $context) {
        Connect-AzAccount
    }
    Write-Host "  Connected to: $($context.Subscription.Name)" -ForegroundColor Green
    Write-Host ""

    Write-Host "[Step 2] Understanding Instant Restore" -ForegroundColor Yellow
    Write-Host "Instant Restore Features:" -ForegroundColor Cyan
    Write-Host "  - Recovery from snapshots (1-5 days retention)" -ForegroundColor White
    Write-Host "  - Faster restore times (minutes vs hours)" -ForegroundColor White
    Write-Host "  - Snapshots stored in same region as VM" -ForegroundColor White
    Write-Host "  - No data transfer from vault required" -ForegroundColor White
    Write-Host "  - Ideal for recent recovery point scenarios" -ForegroundColor White
    Write-Host ""

    Write-Host "[Step 3] Configuring Instant Restore Snapshot Retention" -ForegroundColor Yellow
    Write-Host "Configure snapshot retention in policy:" -ForegroundColor Cyan
    Write-Host '  $policy = Get-AzRecoveryServicesBackupProtectionPolicy -Name "VMPolicy"' -ForegroundColor Gray
    Write-Host '  $policy.SnapshotRetentionInDays = 5  # 1-5 days' -ForegroundColor Gray
    Write-Host '  Set-AzRecoveryServicesBackupProtectionPolicy -Policy $policy' -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "Snapshot retention considerations:" -ForegroundColor Cyan
    Write-Host "  - Default: 2 days" -ForegroundColor White
    Write-Host "  - Maximum: 5 days" -ForegroundColor White
    Write-Host "  - Additional cost for longer retention" -ForegroundColor White
    Write-Host "  - Balance between cost and recovery speed" -ForegroundColor White
    Write-Host ""

    Write-Host "[Step 4] Instant Restore Process" -ForegroundColor Yellow
    Write-Host "Restore VM from instant recovery snapshot:" -ForegroundColor Cyan
    Write-Host '  # Get backup item' -ForegroundColor Gray
    Write-Host '  $container = Get-AzRecoveryServicesBackupContainer -ContainerType AzureVM' -ForegroundColor Gray
    Write-Host '  $item = Get-AzRecoveryServicesBackupItem -Container $container[0] -WorkloadType AzureVM' -ForegroundColor Gray
    Write-Host ""
    Write-Host '  # Get snapshot recovery points' -ForegroundColor Gray
    Write-Host '  $rp = Get-AzRecoveryServicesBackupRecoveryPoint -Item $item' -ForegroundColor Gray
    Write-Host '  $snapshotRP = $rp | Where-Object {$_.RecoveryPointTier -eq "Snapshot"}' -ForegroundColor Gray
    Write-Host ""
    Write-Host '  # Restore from snapshot' -ForegroundColor Gray
    Write-Host '  $restoreJob = Restore-AzRecoveryServicesBackupItem `' -ForegroundColor Gray
    Write-Host '      -RecoveryPoint $snapshotRP[0] `' -ForegroundColor Gray
    Write-Host '      -StorageAccountName "storageaccount" `' -ForegroundColor Gray
    Write-Host '      -StorageAccountResourceGroupName "rg-storage"' -ForegroundColor Gray
    Write-Host ""

    Write-Host "[Step 5] Recovery Point Tiers" -ForegroundColor Yellow
    Write-Host "Understanding recovery point tiers:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Tier 1 - Snapshot (Instant Restore):" -ForegroundColor White
    Write-Host "  - 1-5 days retention" -ForegroundColor Gray
    Write-Host "  - Fastest restore (5-10 minutes)" -ForegroundColor Gray
    Write-Host "  - Higher cost" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Tier 2 - Vault-Standard:" -ForegroundColor White
    Write-Host "  - Long-term retention" -ForegroundColor Gray
    Write-Host "  - Slower restore (hours)" -ForegroundColor Gray
    Write-Host "  - Lower cost" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[Step 6] Monitoring Snapshot Usage" -ForegroundColor Yellow
    Write-Host "Check snapshot storage usage:" -ForegroundColor Cyan
    Write-Host '  # View recovery points with tier information' -ForegroundColor Gray
    Write-Host '  $rp | Format-Table RecoveryPointTime, RecoveryPointTier, RecoveryPointType' -ForegroundColor Gray
    Write-Host ""
    Write-Host '  # Calculate snapshot storage cost' -ForegroundColor Gray
    Write-Host '  $snapshots = Get-AzSnapshot -ResourceGroupName $ResourceGroupName' -ForegroundColor Gray
    Write-Host '  $totalSize = ($snapshots | Measure-Object -Property DiskSizeGB -Sum).Sum' -ForegroundColor Gray
    Write-Host ""

    Write-Host "[Step 7] Best Practices" -ForegroundColor Yellow
    Write-Host "[INFO] Instant Restore Best Practices:" -ForegroundColor Cyan
    Write-Host "  - Use 2-day retention for most scenarios (cost-effective)" -ForegroundColor White
    Write-Host "  - Extend to 5 days for critical VMs" -ForegroundColor White
    Write-Host "  - Monitor snapshot storage costs" -ForegroundColor White
    Write-Host "  - Prefer instant restore for recent recovery needs" -ForegroundColor White
    Write-Host "  - Use vault-tier for older recovery points" -ForegroundColor White
    Write-Host "  - Test instant restore procedures" -ForegroundColor White
    Write-Host ""

} catch {
    Write-Host "[ERROR] $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

Write-Host "Script completed successfully!" -ForegroundColor Green
