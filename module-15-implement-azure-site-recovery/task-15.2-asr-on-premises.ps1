<#
.SYNOPSIS
    Task 15.2 - Configure ASR for On-Premises

.DESCRIPTION
    Demonstrates on-premises to Azure Site Recovery configuration.

.NOTES
    Module: Module 15 - Implement Azure Site Recovery
    Task: 15.2 - Configure ASR for On-Premises
    PowerShell Version: 5.1+
#>

#Requires -RunAsAdministrator

$ErrorActionPreference = 'Stop'
Write-Host "=== AZ-801 Module 15: Task 15.2 - Configure ASR for On-Premises ===" -ForegroundColor Cyan
Write-Host ""

try {
    Write-Host "[Step 1] On-Premises ASR Components" -ForegroundColor Yellow
    Write-Host "Required components:" -ForegroundColor Cyan
    Write-Host "  - Configuration Server (VMware/Physical)" -ForegroundColor White
    Write-Host "  - Process Server (handles replication traffic)" -ForegroundColor White
    Write-Host "  - Master Target Server (Linux failback)" -ForegroundColor White
    Write-Host "  - Hyper-V Host/SCVMM (for Hyper-V)" -ForegroundColor White
    Write-Host ""

    Write-Host "[Step 2] Hyper-V Site Setup" -ForegroundColor Yellow
    Write-Host "Configure Hyper-V replication:" -ForegroundColor Cyan
    Write-Host '  # Download Site Recovery Provider' -ForegroundColor Gray
    Write-Host '  # Install on Hyper-V host' -ForegroundColor Gray
    Write-Host '  # Register with vault using registration key' -ForegroundColor Gray
    Write-Host ""

    Write-Host "[Step 3] VMware/Physical Setup" -ForegroundColor Yellow
    Write-Host "Configuration Server deployment:" -ForegroundColor Cyan
    Write-Host "  1. Download OVA template or unified setup" -ForegroundColor White
    Write-Host "  2. Deploy configuration server VM" -ForegroundColor White
    Write-Host "  3. Register with Recovery Services Vault" -ForegroundColor White
    Write-Host "  4. Install Mobility Service on source VMs" -ForegroundColor White
    Write-Host ""

    Write-Host "[Step 4] Best Practices" -ForegroundColor Yellow
    Write-Host "[INFO] On-Premises ASR Best Practices:" -ForegroundColor Cyan
    Write-Host "  - Size configuration server appropriately" -ForegroundColor White
    Write-Host "  - Ensure network connectivity to Azure" -ForegroundColor White
    Write-Host "  - Monitor replication health" -ForegroundColor White
    Write-Host "  - Test failover regularly" -ForegroundColor White
    Write-Host ""

} catch {
    Write-Host "[ERROR] $_" -ForegroundColor Red
    exit 1
}

Write-Host "Script completed successfully!" -ForegroundColor Green
