<#
.SYNOPSIS
    Task 10.6 - Windows Admin Center for Cluster Management

.DESCRIPTION
    Configure and use Windows Admin Center for failover cluster management.

.NOTES
    Module: Module 10 - Manage and Maintain Clusters
    Task: 10.6 - Windows Admin Center
    Prerequisites: Windows Server, Internet connectivity
    PowerShell Version: 5.1+
#>

#Requires -RunAsAdministrator

$ErrorActionPreference = 'Stop'
Write-Host "=== AZ-801 Module 10: Task 10.6 - Windows Admin Center ===" -ForegroundColor Cyan

function Write-Step { param([string]$Message); Write-Host "`n[STEP] $Message" -ForegroundColor Yellow }
function Write-Info { param([string]$Message); Write-Host "[INFO] $Message" -ForegroundColor Cyan }

try {
    Write-Step "Install Windows Admin Center"
    Write-Host @"
  # Download WAC from Microsoft
  # https://aka.ms/WACDownload
  
  # Install on Windows Server (Gateway mode)
  msiexec /i WindowsAdminCenter.msi /qn /L*v log.txt ``
      SME_PORT=443 ``
      SSL_CERTIFICATE_OPTION=generate
  
  # Or install on Windows 10/11 (Desktop mode)
  msiexec /i WindowsAdminCenter.msi /qn /L*v log.txt ``
      SME_PORT=6516 ``
      SME_THUMBPRINT=auto
"@ -ForegroundColor Gray

    Write-Step "Access Windows Admin Center"
    Write-Info "Browse to: https://SERVER:443 or https://localhost:6516"
    Write-Host "  - Use domain credentials to log in" -ForegroundColor White
    Write-Host "  - Add cluster connections" -ForegroundColor White

    Write-Step "Cluster Management with WAC"
    Write-Host "Features available:" -ForegroundColor Yellow
    Write-Host "  - Dashboard: Cluster health overview" -ForegroundColor White
    Write-Host "  - Nodes: View/manage cluster nodes" -ForegroundColor White
    Write-Host "  - Roles: Manage cluster roles and groups" -ForegroundColor White
    Write-Host "  - Virtual Machines: VM management" -ForegroundColor White
    Write-Host "  - Storage: Storage Spaces Direct, CSV management" -ForegroundColor White
    Write-Host "  - Networks: Network configuration" -ForegroundColor White
    Write-Host "  - Updates: Cluster-Aware Updating integration" -ForegroundColor White
    Write-Host "  - Performance Monitor: Real-time metrics" -ForegroundColor White

    Write-Step "PowerShell Management of WAC"
    Write-Host @"
  # Check WAC service
  Get-Service ServerManagementGateway
  
  # View WAC configuration
  Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\ServerManagementGateway'
  
  # Update WAC
  # Download new MSI and run:
  msiexec /i WindowsAdminCenter.msi /qn /L*v update.txt
  
  # Uninstall WAC
  wmic product where "name like '%Windows Admin Center%'" call uninstall
"@ -ForegroundColor Gray

    Write-Step "Best Practices"
    Write-Host "  1. Install WAC on dedicated management server" -ForegroundColor White
    Write-Host "  2. Use HTTPS with valid SSL certificate" -ForegroundColor White
    Write-Host "  3. Configure Windows Defender Firewall" -ForegroundColor White
    Write-Host "  4. Keep WAC updated" -ForegroundColor White
    Write-Host "  5. Use RBAC for access control" -ForegroundColor White
    Write-Host "  6. Monitor WAC gateway performance" -ForegroundColor White

    Write-Host "`n" + "="*80 -ForegroundColor Cyan
    Write-Host "[SUCCESS] Windows Admin Center Overview Completed" -ForegroundColor Green

} catch {
    Write-Host "`n[ERROR] $_" -ForegroundColor Red
    exit 1
}
