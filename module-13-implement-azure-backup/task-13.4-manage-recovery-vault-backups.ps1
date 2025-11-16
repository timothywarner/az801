<#
.SYNOPSIS
    Task 13.4 - Manage Recovery Vault Backups

.DESCRIPTION
    Demo script for AZ-801 Module 13: Implement Azure Backup
    Shows backup management in Azure Recovery Services including monitoring,
    job management, and backup item administration.

.NOTES
    Module: Module 13 - Implement Azure Backup
    Task: 13.4 - Manage Recovery Vault Backups
    Prerequisites: Az.RecoveryServices module, existing vault with backups
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
Write-Host "=== AZ-801 Module 13: Task 13.4 - Manage Recovery Vault Backups ===" -ForegroundColor Cyan
Write-Host ""

try {
    # Step 1: Azure Authentication
    Write-Host "[Step 1] Authenticating to Azure" -ForegroundColor Yellow

    $context = Get-AzContext -ErrorAction SilentlyContinue
    if (-not $context) {
        Write-Host "Connecting to Azure..." -ForegroundColor Cyan
        Connect-AzAccount
        $context = Get-AzContext
    }

    Write-Host "  Connected to subscription: $($context.Subscription.Name)" -ForegroundColor Green
    Write-Host ""

    # Step 2: Get Recovery Services Vault
    Write-Host "[Step 2] Retrieving Recovery Services Vault" -ForegroundColor Yellow

    $vault = Get-AzRecoveryServicesVault `
        -ResourceGroupName $ResourceGroupName `
        -Name $VaultName `
        -ErrorAction SilentlyContinue

    if ($vault) {
        Write-Host "  Vault found: $($vault.Name)" -ForegroundColor Green
        Write-Host "  Location: $($vault.Location)" -ForegroundColor White
        
        # Set vault context
        Set-AzRecoveryServicesVaultContext -Vault $vault
    } else {
        Write-Host "  [WARNING] Vault '$VaultName' not found" -ForegroundColor Yellow
        Write-Host "  Demonstrating backup management cmdlets..." -ForegroundColor Cyan
    }
    Write-Host ""

    # Step 3: List Backup Items
    Write-Host "[Step 3] Managing Backup Items" -ForegroundColor Yellow

    Write-Host "Get all backup items:" -ForegroundColor Cyan
    Write-Host '  $containers = Get-AzRecoveryServicesBackupContainer -ContainerType AzureVM' -ForegroundColor Gray
    Write-Host '  $backupItems = Get-AzRecoveryServicesBackupItem -Container $containers[0] -WorkloadType AzureVM' -ForegroundColor Gray
    Write-Host ""

    if ($vault) {
        # Get backup containers
        $containers = Get-AzRecoveryServicesBackupContainer `
            -ContainerType AzureVM `
            -Status Registered `
            -ErrorAction SilentlyContinue

        if ($containers) {
            Write-Host "Registered Backup Containers: $($containers.Count)" -ForegroundColor Cyan
            $containers | Format-Table FriendlyName, Status, ContainerType -AutoSize

            # Get backup items
            foreach ($container in $containers | Select-Object -First 1) {
                $items = Get-AzRecoveryServicesBackupItem `
                    -Container $container `
                    -WorkloadType AzureVM

                if ($items) {
                    Write-Host "Backup Items in $($container.FriendlyName):" -ForegroundColor Cyan
                    $items | Format-Table Name, ProtectionStatus, HealthStatus, LastBackupTime -AutoSize
                }
            }
        } else {
            Write-Host "  [INFO] No backup containers found" -ForegroundColor Yellow
        }
    }
    Write-Host ""

    # Step 4: Monitor Backup Jobs
    Write-Host "[Step 4] Monitoring Backup Jobs" -ForegroundColor Yellow

    Write-Host "Get recent backup jobs:" -ForegroundColor Cyan
    Write-Host '  $jobs = Get-AzRecoveryServicesBackupJob -From (Get-Date).AddDays(-7)' -ForegroundColor Gray
    Write-Host '  $jobs | Format-Table JobId, Operation, Status, StartTime, EndTime' -ForegroundColor Gray
    Write-Host ""

    if ($vault) {
        # Get jobs from last 7 days
        $jobs = Get-AzRecoveryServicesBackupJob `
            -From (Get-Date).AddDays(-7) `
            -ErrorAction SilentlyContinue

        if ($jobs) {
            Write-Host "Recent Backup Jobs: $($jobs.Count)" -ForegroundColor Cyan
            $jobs | Select-Object -First 10 | 
                Format-Table @{L='Operation';E={$_.Operation}}, 
                            @{L='Status';E={$_.Status}},
                            @{L='Duration';E={if($_.EndTime){($_.EndTime - $_.StartTime).ToString()}}},
                            StartTime -AutoSize

            # Job statistics
            Write-Host "Job Statistics:" -ForegroundColor Cyan
            $jobStats = $jobs | Group-Object Status
            foreach ($stat in $jobStats) {
                Write-Host "  $($stat.Name): $($stat.Count)" -ForegroundColor White
            }
        } else {
            Write-Host "  [INFO] No backup jobs found" -ForegroundColor Yellow
        }
    }
    Write-Host ""

    # Step 5: Recovery Points Management
    Write-Host "[Step 5] Managing Recovery Points" -ForegroundColor Yellow

    Write-Host "List recovery points:" -ForegroundColor Cyan
    Write-Host '  $item = Get-AzRecoveryServicesBackupItem -WorkloadType AzureVM' -ForegroundColor Gray
    Write-Host '  $rp = Get-AzRecoveryServicesBackupRecoveryPoint -Item $item[0]' -ForegroundColor Gray
    Write-Host '  $rp | Format-Table RecoveryPointId, RecoveryPointTime, RecoveryPointType' -ForegroundColor Gray
    Write-Host ""

    Write-Host "Example: Getting recovery points for a specific item" -ForegroundColor White
    Write-Host '  $startDate = (Get-Date).AddDays(-30)' -ForegroundColor Gray
    Write-Host '  $endDate = Get-Date' -ForegroundColor Gray
    Write-Host '  $rp = Get-AzRecoveryServicesBackupRecoveryPoint -Item $item[0] `' -ForegroundColor Gray
    Write-Host '      -StartDate $startDate -EndDate $endDate' -ForegroundColor Gray
    Write-Host ""

    # Step 6: Backup Policy Management
    Write-Host "[Step 6] Managing Backup Policies" -ForegroundColor Yellow

    if ($vault) {
        # Get backup policies
        $policies = Get-AzRecoveryServicesBackupProtectionPolicy

        Write-Host "Backup Policies: $($policies.Count)" -ForegroundColor Cyan
        $policies | Format-Table Name, WorkloadType, ScheduleRunFrequency -AutoSize

        # Show policy details
        if ($policies) {
            $policy = $policies[0]
            Write-Host "`nPolicy Details: $($policy.Name)" -ForegroundColor Cyan
            Write-Host "  Workload Type: $($policy.WorkloadType)" -ForegroundColor White
            Write-Host "  Schedule Frequency: $($policy.ScheduleRunFrequency)" -ForegroundColor White
            
            if ($policy.RetentionPolicy) {
                Write-Host "  Daily Retention: $($policy.RetentionPolicy.DailySchedule.DurationCountInDays) days" -ForegroundColor White
                Write-Host "  Weekly Retention: $($policy.RetentionPolicy.WeeklySchedule.DurationCountInWeeks) weeks" -ForegroundColor White
            }
        }
    }
    Write-Host ""

    # Step 7: Trigger On-Demand Backup
    Write-Host "[Step 7] Triggering On-Demand Backup" -ForegroundColor Yellow

    Write-Host "Run on-demand backup:" -ForegroundColor Cyan
    Write-Host '  $item = Get-AzRecoveryServicesBackupItem -WorkloadType AzureVM -Name "VM01"' -ForegroundColor Gray
    Write-Host '  $policy = Get-AzRecoveryServicesBackupProtectionPolicy -Name "DefaultPolicy"' -ForegroundColor Gray
    Write-Host '  $job = Backup-AzRecoveryServicesBackupItem -Item $item -ExpiryDateTimeUTC (Get-Date).AddDays(30)' -ForegroundColor Gray
    Write-Host '  Wait-AzRecoveryServicesBackupJob -Job $job' -ForegroundColor Gray
    Write-Host ""

    # Step 8: Modify Backup Protection
    Write-Host "[Step 8] Modifying Backup Protection" -ForegroundColor Yellow

    Write-Host "Enable protection for item:" -ForegroundColor Cyan
    Write-Host '  Enable-AzRecoveryServicesBackupProtection -Item $item -Policy $policy' -ForegroundColor Gray
    Write-Host ""

    Write-Host "Disable protection (retain data):" -ForegroundColor Cyan
    Write-Host '  Disable-AzRecoveryServicesBackupProtection -Item $item -RemoveRecoveryPoints:$false' -ForegroundColor Gray
    Write-Host ""

    Write-Host "Stop protection (delete data):" -ForegroundColor Cyan
    Write-Host '  Disable-AzRecoveryServicesBackupProtection -Item $item -RemoveRecoveryPoints -Force' -ForegroundColor Gray
    Write-Host ""

    # Step 9: Backup Reports and Monitoring
    Write-Host "[Step 9] Backup Reporting" -ForegroundColor Yellow

    Write-Host "Generate backup summary:" -ForegroundColor Cyan
    Write-Host '  $items = Get-AzRecoveryServicesBackupItem -WorkloadType AzureVM' -ForegroundColor Gray
    Write-Host '  $summary = $items | Group-Object ProtectionStatus' -ForegroundColor Gray
    Write-Host '  $summary | Format-Table Name, Count' -ForegroundColor Gray
    Write-Host ""

    Write-Host "Check backup health:" -ForegroundColor Cyan
    Write-Host '  $items | Where-Object {$_.HealthStatus -ne "Passed"} | Format-Table Name, HealthStatus, HealthDetails' -ForegroundColor Gray
    Write-Host ""

    # Step 10: Alerts and Notifications
    Write-Host "[Step 10] Configuring Alerts" -ForegroundColor Yellow

    Write-Host "Azure Monitor integration:" -ForegroundColor Cyan
    Write-Host "  - Configure action groups for backup alerts" -ForegroundColor White
    Write-Host "  - Set up email notifications for failed backups" -ForegroundColor White
    Write-Host "  - Create alert rules for backup job failures" -ForegroundColor White
    Write-Host ""

    Write-Host "Example: Query backup alerts using Azure Monitor" -ForegroundColor White
    Write-Host '  $query = "AzureBackupReport | where OperationName == \"Backup\" and Status == \"Failed\""' -ForegroundColor Gray
    Write-Host '  $result = Invoke-AzOperationalInsightsQuery -WorkspaceId $workspaceId -Query $query' -ForegroundColor Gray
    Write-Host ""

    # Best Practices
    Write-Host "[INFO] Backup Management Best Practices:" -ForegroundColor Cyan
    Write-Host "  - Monitor backup jobs daily for failures" -ForegroundColor White
    Write-Host "  - Test recovery procedures regularly (monthly)" -ForegroundColor White
    Write-Host "  - Review and optimize backup policies quarterly" -ForegroundColor White
    Write-Host "  - Maintain audit logs for compliance" -ForegroundColor White
    Write-Host "  - Set up automated alerting for backup failures" -ForegroundColor White
    Write-Host "  - Document retention requirements and policies" -ForegroundColor White
    Write-Host "  - Verify backup item health status weekly" -ForegroundColor White
    Write-Host "  - Keep recovery points within defined SLA" -ForegroundColor White
    Write-Host ""

} catch {
    Write-Host "[ERROR] An error occurred: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Script completed successfully!" -ForegroundColor Green
Write-Host "Recovery vault backup management demonstrated" -ForegroundColor Yellow
