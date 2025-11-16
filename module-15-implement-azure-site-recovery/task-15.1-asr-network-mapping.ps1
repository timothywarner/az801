<#
.SYNOPSIS
    Task 15.1 - Configure ASR Network Mapping

.DESCRIPTION
    Demonstrates network mapping configuration for Azure Site Recovery.

.NOTES
    Module: Module 15 - Implement Azure Site Recovery
    Task: 15.1 - Configure ASR Network Mapping
    Prerequisites: Az.RecoveryServices module
    PowerShell Version: 5.1+
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$VaultName = "rsv-asr-vault",
    
    [Parameter(Mandatory = $false)]
    [string]$PrimaryLocation = "eastus",
    
    [Parameter(Mandatory = $false)]
    [string]$SecondaryLocation = "westus"
)

$ErrorActionPreference = 'Stop'
Write-Host "=== AZ-801 Module 15: Task 15.1 - Configure ASR Network Mapping ===" -ForegroundColor Cyan
Write-Host ""

try {
    Write-Host "[Step 1] Authenticating to Azure" -ForegroundColor Yellow
    
    $context = Get-AzContext -ErrorAction SilentlyContinue
    if (-not $context) {
        Connect-AzAccount
    }
    Write-Host "  Connected" -ForegroundColor Green
    Write-Host ""

    Write-Host "[Step 2] ASR Network Mapping Overview" -ForegroundColor Yellow
    Write-Host "Network mapping ensures:" -ForegroundColor Cyan
    Write-Host "  - VMs connect to appropriate networks after failover" -ForegroundColor White
    Write-Host "  - IP addressing is maintained or reassigned" -ForegroundColor White
    Write-Host "  - Network isolation and security maintained" -ForegroundColor White
    Write-Host ""

    Write-Host "[Step 3] Configure Network Mapping" -ForegroundColor Yellow
    Write-Host "Create network mapping:" -ForegroundColor Cyan
    Write-Host '  # Get primary and recovery fabrics' -ForegroundColor Gray
    Write-Host '  $vault = Get-AzRecoveryServicesVault -Name "rsv-asr-vault"' -ForegroundColor Gray
    Write-Host '  Set-AzRecoveryServicesAsrVaultContext -Vault $vault' -ForegroundColor Gray
    Write-Host '  ' -ForegroundColor Gray
    Write-Host '  $primaryFabric = Get-AzRecoveryServicesAsrFabric -Name "PrimaryFabric"' -ForegroundColor Gray
    Write-Host '  $recoveryFabric = Get-AzRecoveryServicesAsrFabric -Name "RecoveryFabric"' -ForegroundColor Gray
    Write-Host '  ' -ForegroundColor Gray
    Write-Host '  # Get networks' -ForegroundColor Gray
    Write-Host '  $primaryNetwork = Get-AzRecoveryServicesAsrNetwork -Fabric $primaryFabric' -ForegroundColor Gray
    Write-Host '  $recoveryNetwork = Get-AzRecoveryServicesAsrNetwork -Fabric $recoveryFabric' -ForegroundColor Gray
    Write-Host '  ' -ForegroundColor Gray
    Write-Host '  # Create network mapping' -ForegroundColor Gray
    Write-Host '  New-AzRecoveryServicesAsrNetworkMapping `' -ForegroundColor Gray
    Write-Host '      -Name "PrimaryToRecovery" `' -ForegroundColor Gray
    Write-Host '      -PrimaryNetwork $primaryNetwork[0] `' -ForegroundColor Gray
    Write-Host '      -RecoveryNetwork $recoveryNetwork[0]' -ForegroundColor Gray
    Write-Host ""

    Write-Host "[Step 4] Best Practices" -ForegroundColor Yellow
    Write-Host "[INFO] Network Mapping Best Practices:" -ForegroundColor Cyan
    Write-Host "  - Map all production networks to DR networks" -ForegroundColor White
    Write-Host "  - Document IP addressing schemes" -ForegroundColor White
    Write-Host "  - Test network connectivity after failover" -ForegroundColor White
    Write-Host "  - Configure NSGs in recovery region" -ForegroundColor White
    Write-Host ""

} catch {
    Write-Host "[ERROR] $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

Write-Host "Script completed successfully!" -ForegroundColor Green
