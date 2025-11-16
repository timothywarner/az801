<#
.SYNOPSIS
    Task 13.5 - Configure Backup Policies

.DESCRIPTION
    Demo script for AZ-801 Module 13: Implement Azure Backup
    Demonstrates backup policy configuration including schedules, retention,
    and policy assignment to backup items.

.NOTES
    Module: Module 13 - Implement Azure Backup
    Task: 13.5 - Configure Backup Policies
    Prerequisites: Az.RecoveryServices module
    PowerShell Version: 5.1+
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ResourceGroupName = "rg-backup-demo",

    [Parameter(Mandatory = $false)]
    [string]$VaultName = "rsv-backup-vault-demo",

    [Parameter(Mandatory = $false)]
    [string]$PolicyName = "EnhancedBackupPolicy"
)

$ErrorActionPreference = 'Stop'
Write-Host "=== AZ-801 Module 13: Task 13.5 - Configure Backup Policies ===" -ForegroundColor Cyan
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

    # Step 2: Get Recovery Services Vault
    Write-Host "[Step 2] Setting Vault Context" -ForegroundColor Yellow

    $vault = Get-AzRecoveryServicesVault -ResourceGroupName $ResourceGroupName -Name $VaultName -ErrorAction SilentlyContinue

    if ($vault) {
        Set-AzRecoveryServicesVaultContext -Vault $vault
        Write-Host "  Vault context set: $($vault.Name)" -ForegroundColor Green
    } else {
        Write-Host "  [INFO] Creating demo vault..." -ForegroundColor Yellow
        $vault = New-AzRecoveryServicesVault -ResourceGroupName $ResourceGroupName -Name $VaultName -Location "eastus"
        Set-AzRecoveryServicesVaultContext -Vault $vault
    }
    Write-Host ""

    # Step 3: List Existing Policies
    Write-Host "[Step 3] Listing Existing Backup Policies" -ForegroundColor Yellow

    $policies = Get-AzRecoveryServicesBackupProtectionPolicy

    Write-Host "Existing Policies: $($policies.Count)" -ForegroundColor Cyan
    $policies | Format-Table Name, WorkloadType, ScheduleRunFrequency, 
        @{L='DailyRetention';E={$_.RetentionPolicy.DailySchedule.DurationCountInDays}} -AutoSize
    Write-Host ""

    # Step 4: Create Custom Backup Policy for Azure VM
    Write-Host "[Step 4] Creating Custom Azure VM Backup Policy" -ForegroundColor Yellow

    # Get default schedule and retention policy objects
    $schedulePolicy = Get-AzRecoveryServicesBackupSchedulePolicyObject -WorkloadType AzureVM
    $retentionPolicy = Get-AzRecoveryServicesBackupRetentionPolicyObject -WorkloadType AzureVM

    # Configure schedule - Daily backup at 2:00 AM
    $schedulePolicy.ScheduleRunFrequency = "Daily"
    $schedulePolicy.ScheduleRunTimes.Clear()
    $schedulePolicy.ScheduleRunTimes.Add((Get-Date -Hour 2 -Minute 0 -Second 0))

    Write-Host "Schedule Configuration:" -ForegroundColor Cyan
    Write-Host "  Frequency: Daily" -ForegroundColor White
    Write-Host "  Time: 2:00 AM UTC" -ForegroundColor White
    Write-Host ""

    # Configure retention
    # Daily: 30 days
    $retentionPolicy.DailySchedule.DurationCountInDays = 30
    
    # Weekly: 12 weeks (every Sunday)
    $retentionPolicy.IsWeeklyScheduleEnabled = $true
    $retentionPolicy.WeeklySchedule.DurationCountInWeeks = 12
    $retentionPolicy.WeeklySchedule.DaysOfTheWeek.Clear()
    $retentionPolicy.WeeklySchedule.DaysOfTheWeek.Add("Sunday")
    
    # Monthly: 12 months (first Sunday of each month)
    $retentionPolicy.IsMonthlyScheduleEnabled = $true
    $retentionPolicy.MonthlySchedule.DurationCountInMonths = 12
    
    # Yearly: 5 years (first Sunday of January)
    $retentionPolicy.IsYearlyScheduleEnabled = $true
    $retentionPolicy.YearlySchedule.DurationCountInYears = 5

    Write-Host "Retention Configuration:" -ForegroundColor Cyan
    Write-Host "  Daily: 30 days" -ForegroundColor White
    Write-Host "  Weekly: 12 weeks (every Sunday)" -ForegroundColor White
    Write-Host "  Monthly: 12 months" -ForegroundColor White
    Write-Host "  Yearly: 5 years" -ForegroundColor White
    Write-Host ""

    # Create the policy
    $existingPolicy = Get-AzRecoveryServicesBackupProtectionPolicy -Name $PolicyName -ErrorAction SilentlyContinue

    if (-not $existingPolicy) {
        Write-Host "Creating backup policy '$PolicyName'..." -ForegroundColor Cyan
        
        $newPolicy = New-AzRecoveryServicesBackupProtectionPolicy `
            -Name $PolicyName `
            -WorkloadType AzureVM `
            -RetentionPolicy $retentionPolicy `
            -SchedulePolicy $schedulePolicy

        Write-Host "  Policy created successfully" -ForegroundColor Green
    } else {
        Write-Host "  Policy '$PolicyName' already exists" -ForegroundColor White
        $newPolicy = $existingPolicy
    }
    Write-Host ""

    # Step 5: Create File Backup Policy (MARS)
    Write-Host "[Step 5] Creating File Backup Policy (MARS)" -ForegroundColor Yellow

    $fileSchedulePolicy = Get-AzRecoveryServicesBackupSchedulePolicyObject -WorkloadType Windows
    $fileRetentionPolicy = Get-AzRecoveryServicesBackupRetentionPolicyObject -WorkloadType Windows

    # Three times daily backup
    $fileSchedulePolicy.ScheduleRunFrequency = "Daily"
    $fileSchedulePolicy.ScheduleRunTimes.Clear()
    $fileSchedulePolicy.ScheduleRunTimes.Add((Get-Date -Hour 9 -Minute 0 -Second 0))
    $fileSchedulePolicy.ScheduleRunTimes.Add((Get-Date -Hour 14 -Minute 0 -Second 0))
    $fileSchedulePolicy.ScheduleRunTimes.Add((Get-Date -Hour 21 -Minute 0 -Second 0))

    # Configure file retention
    $fileRetentionPolicy.DailySchedule.DurationCountInDays = 60

    Write-Host "File Backup Policy Configuration:" -ForegroundColor Cyan
    Write-Host "  Frequency: Three times daily (9 AM, 2 PM, 9 PM)" -ForegroundColor White
    Write-Host "  Retention: 60 days" -ForegroundColor White
    Write-Host ""

    $filePolicyName = "FileBackupPolicy"
    $existingFilePolicy = Get-AzRecoveryServicesBackupProtectionPolicy -Name $filePolicyName -ErrorAction SilentlyContinue

    if (-not $existingFilePolicy) {
        Write-Host "Creating file backup policy..." -ForegroundColor Cyan
        
        $filePolicy = New-AzRecoveryServicesBackupProtectionPolicy `
            -Name $filePolicyName `
            -WorkloadType Windows `
            -RetentionPolicy $fileRetentionPolicy `
            -SchedulePolicy $fileSchedulePolicy

        Write-Host "  File policy created successfully" -ForegroundColor Green
    } else {
        Write-Host "  File policy already exists" -ForegroundColor White
    }
    Write-Host ""

    # Step 6: Modify Existing Policy
    Write-Host "[Step 6] Modifying Backup Policy" -ForegroundColor Yellow

    Write-Host "Example: Updating retention settings" -ForegroundColor Cyan
    Write-Host '  $policy = Get-AzRecoveryServicesBackupProtectionPolicy -Name "PolicyName"' -ForegroundColor Gray
    Write-Host '  $policy.RetentionPolicy.DailySchedule.DurationCountInDays = 45' -ForegroundColor Gray
    Write-Host '  Set-AzRecoveryServicesBackupProtectionPolicy -Policy $policy' -ForegroundColor Gray
    Write-Host ""

    # Step 7: Assign Policy to Backup Item
    Write-Host "[Step 7] Assigning Policy to Backup Items" -ForegroundColor Yellow

    Write-Host "Enable protection with policy:" -ForegroundColor Cyan
    Write-Host '  $vm = Get-AzVM -Name "MyVM"' -ForegroundColor Gray
    Write-Host '  $policy = Get-AzRecoveryServicesBackupProtectionPolicy -Name "EnhancedBackupPolicy"' -ForegroundColor Gray
    Write-Host '  Enable-AzRecoveryServicesBackupProtection `' -ForegroundColor Gray
    Write-Host '      -ResourceGroupName "rg-prod" -Name "MyVM" `' -ForegroundColor Gray
    Write-Host '      -Policy $policy' -ForegroundColor Gray
    Write-Host ""

    Write-Host "Change policy for existing item:" -ForegroundColor Cyan
    Write-Host '  $item = Get-AzRecoveryServicesBackupItem -WorkloadType AzureVM -Name "MyVM"' -ForegroundColor Gray
    Write-Host '  $newPolicy = Get-AzRecoveryServicesBackupProtectionPolicy -Name "NewPolicy"' -ForegroundColor Gray
    Write-Host '  Enable-AzRecoveryServicesBackupProtection -Item $item -Policy $newPolicy' -ForegroundColor Gray
    Write-Host ""

    # Step 8: Policy Summary
    Write-Host "[Step 8] Policy Summary" -ForegroundColor Yellow

    $allPolicies = Get-AzRecoveryServicesBackupProtectionPolicy

    Write-Host "All Configured Policies:" -ForegroundColor Cyan
    foreach ($policy in $allPolicies) {
        Write-Host "`nPolicy: $($policy.Name)" -ForegroundColor White
        Write-Host "  Workload Type: $($policy.WorkloadType)" -ForegroundColor Gray
        Write-Host "  Schedule: $($policy.ScheduleRunFrequency)" -ForegroundColor Gray
        
        if ($policy.RetentionPolicy.DailySchedule) {
            Write-Host "  Daily Retention: $($policy.RetentionPolicy.DailySchedule.DurationCountInDays) days" -ForegroundColor Gray
        }
        
        if ($policy.RetentionPolicy.WeeklySchedule -and $policy.RetentionPolicy.IsWeeklyScheduleEnabled) {
            Write-Host "  Weekly Retention: $($policy.RetentionPolicy.WeeklySchedule.DurationCountInWeeks) weeks" -ForegroundColor Gray
        }
    }
    Write-Host ""

    # Step 9: Best Practices
    Write-Host "[Step 9] Backup Policy Best Practices" -ForegroundColor Yellow

    Write-Host "[INFO] Best Practices:" -ForegroundColor Cyan
    Write-Host "  - Align backup schedules with business requirements (RPO/RTO)" -ForegroundColor White
    Write-Host "  - Schedule backups during off-peak hours" -ForegroundColor White
    Write-Host "  - Implement GFS retention (Grandfather-Father-Son)" -ForegroundColor White
    Write-Host "  - Different policies for production vs non-production" -ForegroundColor White
    Write-Host "  - Regular review of retention requirements" -ForegroundColor White
    Write-Host "  - Document policy assignments and changes" -ForegroundColor White
    Write-Host "  - Test restore from each retention tier" -ForegroundColor White
    Write-Host "  - Consider compliance and legal hold requirements" -ForegroundColor White
    Write-Host ""

    Write-Host "[INFO] Retention Strategy Recommendations:" -ForegroundColor Cyan
    Write-Host "  Production:" -ForegroundColor White
    Write-Host "    - Daily: 30 days" -ForegroundColor Gray
    Write-Host "    - Weekly: 12 weeks" -ForegroundColor Gray
    Write-Host "    - Monthly: 12 months" -ForegroundColor Gray
    Write-Host "    - Yearly: 7 years" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Development:" -ForegroundColor White
    Write-Host "    - Daily: 7 days" -ForegroundColor Gray
    Write-Host "    - Weekly: 4 weeks" -ForegroundColor Gray
    Write-Host ""

} catch {
    Write-Host "[ERROR] An error occurred: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Script completed successfully!" -ForegroundColor Green
Write-Host "Backup policies configured" -ForegroundColor Yellow
