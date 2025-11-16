<#
.SYNOPSIS
    Task 15.3 - ASR Recovery Plan

.DESCRIPTION
    Demo script for AZ-801 Module 15: Implement Azure Site Recovery
    Demonstrates creation and management of Azure Site Recovery recovery plans
    for orchestrated failover and disaster recovery.

.NOTES
    Module: Module 15 - Implement Azure Site Recovery
    Task: 15.3 - ASR Recovery Plan
    Prerequisites: Az.RecoveryServices module
    PowerShell Version: 5.1+
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ResourceGroupName = "rg-asr",

    [Parameter(Mandatory = $false)]
    [string]$VaultName = "rsv-asr-vault",

    [Parameter(Mandatory = $false)]
    [string]$RecoveryPlanName = "RecoveryPlan-Production"
)

$ErrorActionPreference = 'Stop'
Write-Host "=== AZ-801 Module 15: Task 15.3 - ASR Recovery Plan ===" -ForegroundColor Cyan
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

    # Step 2: Set ASR Vault Context
    Write-Host "[Step 2] Setting ASR Vault Context" -ForegroundColor Yellow

    $vault = Get-AzRecoveryServicesVault -ResourceGroupName $ResourceGroupName -Name $VaultName -ErrorAction SilentlyContinue

    if ($vault) {
        Set-AzRecoveryServicesAsrVaultContext -Vault $vault
        Write-Host "  Vault context set: $($vault.Name)" -ForegroundColor Green
    } else {
        Write-Host "  [INFO] Vault not found - demonstrating recovery plan concepts" -ForegroundColor Yellow
    }
    Write-Host ""

    # Step 3: Recovery Plan Overview
    Write-Host "[Step 3] Recovery Plan Components" -ForegroundColor Yellow

    Write-Host "Recovery Plan elements:" -ForegroundColor Cyan
    Write-Host "  1. Protected Items - VMs to failover" -ForegroundColor White
    Write-Host "  2. Failover Groups - Orchestrated boot sequence" -ForegroundColor White
    Write-Host "  3. Pre/Post Actions - Scripts and manual steps" -ForegroundColor White
    Write-Host "  4. Recovery Points - Point-in-time for recovery" -ForegroundColor White
    Write-Host ""

    # Step 4: Create Recovery Plan
    Write-Host "[Step 4] Creating Recovery Plan" -ForegroundColor Yellow

    Write-Host "Example: Create recovery plan" -ForegroundColor Cyan
    Write-Host '  # Get protected items (replicated VMs)' -ForegroundColor Gray
    Write-Host '  $protectionContainer = Get-AzRecoveryServicesAsrProtectionContainer' -ForegroundColor Gray
    Write-Host '  $protectedItems = Get-AzRecoveryServicesAsrReplicationProtectedItem `' -ForegroundColor Gray
    Write-Host '      -ProtectionContainer $protectionContainer[0]' -ForegroundColor Gray
    Write-Host ""
    Write-Host '  # Create recovery plan with VMs' -ForegroundColor Gray
    Write-Host '  $recoveryPlan = New-AzRecoveryServicesAsrRecoveryPlan `' -ForegroundColor Gray
    Write-Host '      -Name "RecoveryPlan-Production" `' -ForegroundColor Gray
    Write-Host '      -PrimaryFabric $primaryFabric `' -ForegroundColor Gray
    Write-Host '      -PrimaryProtectionContainer $protectionContainer[0] `' -ForegroundColor Gray
    Write-Host '      -RecoveryFabric $recoveryFabric `' -ForegroundColor Gray
    Write-Host '      -RecoveryProtectionContainer $recoveryContainer `' -ForegroundColor Gray
    Write-Host '      -ReplicationProtectedItem $protectedItems' -ForegroundColor Gray
    Write-Host ""

    # Step 5: Configure Failover Groups
    Write-Host "[Step 5] Configuring Failover Groups" -ForegroundColor Yellow

    Write-Host "Failover group strategy:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Group 1 - Infrastructure Tier:" -ForegroundColor White
    Write-Host "  - Domain Controllers" -ForegroundColor Gray
    Write-Host "  - DNS Servers" -ForegroundColor Gray
    Write-Host "  - DHCP Servers" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Group 2 - Data Tier:" -ForegroundColor White
    Write-Host "  - Database Servers (SQL, MySQL)" -ForegroundColor Gray
    Write-Host "  - File Servers" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Group 3 - Application Tier:" -ForegroundColor White
    Write-Host "  - Web Servers" -ForegroundColor Gray
    Write-Host "  - Application Servers" -ForegroundColor Gray
    Write-Host ""

    Write-Host "Edit recovery plan to create groups:" -ForegroundColor Cyan
    Write-Host '  $rp = Get-AzRecoveryServicesAsrRecoveryPlan -Name "RecoveryPlan-Production"' -ForegroundColor Gray
    Write-Host '  Edit-AzRecoveryServicesAsrRecoveryPlan -RecoveryPlan $rp `' -ForegroundColor Gray
    Write-Host '      -AppendGroup' -ForegroundColor Gray
    Write-Host ""

    # Step 6: Add Scripts to Recovery Plan
    Write-Host "[Step 6] Adding Automation Scripts" -ForegroundColor Yellow

    Write-Host "Pre/Post failover scripts:" -ForegroundColor Cyan
    Write-Host '  # Create Azure Automation runbook' -ForegroundColor Gray
    Write-Host '  $automationAccount = Get-AzAutomationAccount -Name "ASRAutomation"' -ForegroundColor Gray
    Write-Host '  $runbook = Get-AzAutomationRunbook -Name "Post-Failover-Script"' -ForegroundColor Gray
    Write-Host ""
    Write-Host '  # Add script to recovery plan' -ForegroundColor Gray
    Write-Host '  $rp = Get-AzRecoveryServicesAsrRecoveryPlan -Name "RecoveryPlan-Production"' -ForegroundColor Gray
    Write-Host '  Edit-AzRecoveryServicesAsrRecoveryPlan -RecoveryPlan $rp `' -ForegroundColor Gray
    Write-Host '      -AddPostActionRunbook -AutomationAccountName "ASRAutomation" `' -ForegroundColor Gray
    Write-Host '      -RunbookName "Post-Failover-Script" -GroupId "Group 2"' -ForegroundColor Gray
    Write-Host ""

    Write-Host "Common automation tasks:" -ForegroundColor Cyan
    Write-Host "  - Update DNS records" -ForegroundColor White
    Write-Host "  - Reconfigure load balancers" -ForegroundColor White
    Write-Host "  - Send notifications" -ForegroundColor White
    Write-Host "  - Update application config files" -ForegroundColor White
    Write-Host "  - Start/stop services" -ForegroundColor White
    Write-Host ""

    # Step 7: Test Failover
    Write-Host "[Step 7] Executing Test Failover" -ForegroundColor Yellow

    Write-Host "Test failover process:" -ForegroundColor Cyan
    Write-Host '  # Select test network (isolated)' -ForegroundColor Gray
    Write-Host '  $testNetwork = Get-AzVirtualNetwork -Name "vnet-test-dr"' -ForegroundColor Gray
    Write-Host ""
    Write-Host '  # Start test failover' -ForegroundColor Gray
    Write-Host '  $rp = Get-AzRecoveryServicesAsrRecoveryPlan -Name "RecoveryPlan-Production"' -ForegroundColor Gray
    Write-Host '  $job = Start-AzRecoveryServicesAsrTestFailoverJob `' -ForegroundColor Gray
    Write-Host '      -RecoveryPlan $rp `' -ForegroundColor Gray
    Write-Host '      -Direction PrimaryToRecovery `' -ForegroundColor Gray
    Write-Host '      -AzureVMNetworkId $testNetwork.Id' -ForegroundColor Gray
    Write-Host ""
    Write-Host '  # Monitor test failover' -ForegroundColor Gray
    Write-Host '  Get-AzRecoveryServicesAsrJob -Job $job' -ForegroundColor Gray
    Write-Host ""
    Write-Host '  # Cleanup test failover' -ForegroundColor Gray
    Write-Host '  Start-AzRecoveryServicesAsrTestFailoverCleanupJob -RecoveryPlan $rp' -ForegroundColor Gray
    Write-Host ""

    # Step 8: Planned Failover
    Write-Host "[Step 8] Planned Failover" -ForegroundColor Yellow

    Write-Host "Planned failover (for maintenance):" -ForegroundColor Cyan
    Write-Host '  $job = Start-AzRecoveryServicesAsrPlannedFailoverJob `' -ForegroundColor Gray
    Write-Host '      -RecoveryPlan $rp `' -ForegroundColor Gray
    Write-Host '      -Direction PrimaryToRecovery' -ForegroundColor Gray
    Write-Host ""
    Write-Host "Planned failover characteristics:" -ForegroundColor Cyan
    Write-Host "  - Synchronizes data before failover" -ForegroundColor White
    Write-Host "  - Zero data loss" -ForegroundColor White
    Write-Host "  - Requires primary site to be accessible" -ForegroundColor White
    Write-Host "  - Used for planned maintenance" -ForegroundColor White
    Write-Host ""

    # Step 9: Unplanned Failover
    Write-Host "[Step 9] Unplanned Failover" -ForegroundColor Yellow

    Write-Host "Unplanned failover (disaster scenario):" -ForegroundColor Cyan
    Write-Host '  $rp = Get-AzRecoveryServicesAsrRecoveryPlan -Name "RecoveryPlan-Production"' -ForegroundColor Gray
    Write-Host '  $job = Start-AzRecoveryServicesAsrUnplannedFailoverJob `' -ForegroundColor Gray
    Write-Host '      -RecoveryPlan $rp `' -ForegroundColor Gray
    Write-Host '      -Direction PrimaryToRecovery' -ForegroundColor Gray
    Write-Host ""

    # Step 10: Failback and Reprotect
    Write-Host "[Step 10] Failback and Reprotection" -ForegroundColor Yellow

    Write-Host "Failback to primary site:" -ForegroundColor Cyan
    Write-Host '  # After primary site is restored' -ForegroundColor Gray
    Write-Host '  # Reverse replication direction' -ForegroundColor Gray
    Write-Host '  Update-AzRecoveryServicesAsrProtectionDirection `' -ForegroundColor Gray
    Write-Host '      -RecoveryPlan $rp `' -ForegroundColor Gray
    Write-Host '      -Direction RecoveryToPrimary' -ForegroundColor Gray
    Write-Host ""
    Write-Host '  # Execute failback' -ForegroundColor Gray
    Write-Host '  Start-AzRecoveryServicesAsrPlannedFailoverJob `' -ForegroundColor Gray
    Write-Host '      -RecoveryPlan $rp `' -ForegroundColor Gray
    Write-Host '      -Direction RecoveryToPrimary' -ForegroundColor Gray
    Write-Host ""

    # Step 11: Monitoring
    Write-Host "[Step 11] Monitoring Recovery Plans" -ForegroundColor Yellow

    Write-Host "Monitor recovery plan status:" -ForegroundColor Cyan
    Write-Host '  # Get all recovery plans' -ForegroundColor Gray
    Write-Host '  $plans = Get-AzRecoveryServicesAsrRecoveryPlan' -ForegroundColor Gray
    Write-Host '  $plans | Format-Table Name, ReplicationProvider, PrimaryFabricId' -ForegroundColor Gray
    Write-Host ""
    Write-Host '  # Get recent jobs' -ForegroundColor Gray
    Write-Host '  $jobs = Get-AzRecoveryServicesAsrJob -Name "RecoveryPlan*"' -ForegroundColor Gray
    Write-Host '  $jobs | Format-Table StartTime, State, TargetObjectName' -ForegroundColor Gray
    Write-Host ""

    # Step 12: Best Practices
    Write-Host "[Step 12] Recovery Plan Best Practices" -ForegroundColor Yellow

    Write-Host "[INFO] Best Practices:" -ForegroundColor Cyan
    Write-Host "  - Test recovery plans quarterly" -ForegroundColor White
    Write-Host "  - Document boot sequence and dependencies" -ForegroundColor White
    Write-Host "  - Use automation for post-failover tasks" -ForegroundColor White
    Write-Host "  - Organize VMs into logical failover groups" -ForegroundColor White
    Write-Host "  - Include manual steps in recovery plan" -ForegroundColor White
    Write-Host "  - Set RTO/RPO targets for each tier" -ForegroundColor White
    Write-Host "  - Validate network connectivity after failover" -ForegroundColor White
    Write-Host "  - Train staff on failover procedures" -ForegroundColor White
    Write-Host ""

    Write-Host "[INFO] Recovery Plan Testing Schedule:" -ForegroundColor Cyan
    Write-Host "  Monthly: Individual VM test failovers" -ForegroundColor White
    Write-Host "  Quarterly: Full recovery plan test" -ForegroundColor White
    Write-Host "  Annually: Complete DR drill with all teams" -ForegroundColor White
    Write-Host ""

} catch {
    Write-Host "[ERROR] An error occurred: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Script completed successfully!" -ForegroundColor Green
Write-Host "ASR Recovery Plan configuration demonstrated" -ForegroundColor Yellow
