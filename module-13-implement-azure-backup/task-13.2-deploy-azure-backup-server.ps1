<#
.SYNOPSIS
    Task 13.2 - Deploy Azure Backup Server (MABS)

.DESCRIPTION
    Demo script for AZ-801 Module 13: Implement Azure Backup
    Demonstrates Azure Backup Server (MABS) deployment, installation prerequisites,
    and configuration steps. Covers Modern Backup Storage setup.

.NOTES
    Module: Module 13 - Implement Azure Backup
    Task: 13.2 - Deploy Azure Backup Server
    Prerequisites: Windows Server 2019/2022, SQL Server, Administrative privileges
    PowerShell Version: 5.1+
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$MABSInstallPath = "C:\Program Files\Microsoft Azure Backup Server",

    [Parameter(Mandatory = $false)]
    [string]$StoragePoolName = "MABS-Storage-Pool",

    [Parameter(Mandatory = $false)]
    [ValidateSet("StandardHDD", "StandardSSD", "PremiumSSD")]
    [string]$StorageType = "StandardSSD"
)

$ErrorActionPreference = 'Stop'
Write-Host "=== AZ-801 Module 13: Task 13.2 - Deploy Azure Backup Server (MABS) ===" -ForegroundColor Cyan
Write-Host ""

try {
    # Step 1: Prerequisites Check
    Write-Host "[Step 1] Checking Prerequisites" -ForegroundColor Yellow

    # Check OS version
    $os = Get-CimInstance Win32_OperatingSystem
    Write-Host "Operating System:" -ForegroundColor Cyan
    Write-Host "  OS: $($os.Caption)" -ForegroundColor White
    Write-Host "  Version: $($os.Version)" -ForegroundColor White
    Write-Host "  Build: $($os.BuildNumber)" -ForegroundColor White

    # Check memory
    $memory = [Math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
    Write-Host "  RAM: $memory GB" -ForegroundColor White

    if ($memory -lt 8) {
        Write-Host "  [WARNING] MABS requires minimum 8GB RAM. Current: $memory GB" -ForegroundColor Yellow
    } else {
        Write-Host "  [OK] Memory requirement met" -ForegroundColor Green
    }
    Write-Host ""

    # Step 2: Check Required Features
    Write-Host "[Step 2] Verifying Required Windows Features" -ForegroundColor Yellow

    $requiredFeatures = @(
        'NET-Framework-45-Core',
        'NET-Framework-45-Features',
        'NET-WCF-Services45',
        'NET-WCF-TCP-PortSharing45'
    )

    Write-Host "Checking Windows Features:" -ForegroundColor Cyan
    foreach ($feature in $requiredFeatures) {
        $installed = Get-WindowsFeature -Name $feature -ErrorAction SilentlyContinue
        if ($installed -and $installed.Installed) {
            Write-Host "  [OK] $feature" -ForegroundColor Green
        } else {
            Write-Host "  [MISSING] $feature - Would install in production" -ForegroundColor Yellow
            # Install-WindowsFeature -Name $feature -IncludeManagementTools
        }
    }
    Write-Host ""

    # Step 3: SQL Server Check
    Write-Host "[Step 3] Checking SQL Server Requirements" -ForegroundColor Yellow

    Write-Host "MABS SQL Server Requirements:" -ForegroundColor Cyan
    Write-Host "  - SQL Server 2016/2017/2019/2022 with SP2 or later" -ForegroundColor White
    Write-Host "  - SQL Server Reporting Services (SSRS)" -ForegroundColor White
    Write-Host "  - Dedicated SQL instance or shared SQL Server" -ForegroundColor White

    # Check for SQL Server installation
    $sqlService = Get-Service -Name 'MSSQLSERVER' -ErrorAction SilentlyContinue
    if ($sqlService) {
        Write-Host "  [OK] SQL Server detected" -ForegroundColor Green
        Write-Host "  Status: $($sqlService.Status)" -ForegroundColor White
    } else {
        Write-Host "  [INFO] SQL Server not detected on this machine" -ForegroundColor Yellow
        Write-Host "  MABS can use remote SQL Server or install SQL Server Express" -ForegroundColor White
    }
    Write-Host ""

    # Step 4: Storage Configuration
    Write-Host "[Step 4] Storage Configuration for MABS" -ForegroundColor Yellow

    # Get disk information
    $disks = Get-PhysicalDisk | Where-Object { $_.CanPool -eq $true }

    Write-Host "Available storage for MABS:" -ForegroundColor Cyan
    Get-Volume | Where-Object { $_.DriveLetter -and $_.SizeRemaining -gt 10GB } |
        Format-Table DriveLetter, FileSystemLabel,
        @{L='Size(GB)';E={[Math]::Round($_.Size/1GB,2)}},
        @{L='Free(GB)';E={[Math]::Round($_.SizeRemaining/1GB,2)}} -AutoSize

    Write-Host "Storage Requirements:" -ForegroundColor Cyan
    Write-Host "  - Minimum 500 GB for MABS storage pool" -ForegroundColor White
    Write-Host "  - Recommended: 1.5x protected data size" -ForegroundColor White
    Write-Host "  - Modern Backup Storage (MBS) with ReFS" -ForegroundColor White
    Write-Host ""

    # Step 5: MABS Installation Steps (Educational)
    Write-Host "[Step 5] MABS Installation Process" -ForegroundColor Yellow

    Write-Host "To install Azure Backup Server (MABS v4):" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. Download MABS from Microsoft Download Center" -ForegroundColor White
    Write-Host "   URL: https://aka.ms/downloadmabs" -ForegroundColor Gray
    Write-Host ""

    Write-Host "2. Extract installation files" -ForegroundColor White
    Write-Host "   Example: D:\MABSSetup\Setup.exe" -ForegroundColor Gray
    Write-Host ""

    Write-Host "3. Run setup with prerequisites check" -ForegroundColor White
    Write-Host '   .\Setup.exe /s /v"/qn' -ForegroundColor Gray
    Write-Host ""

    Write-Host "4. Configure SQL Server connection" -ForegroundColor White
    Write-Host "   - Local SQL Server instance or" -ForegroundColor Gray
    Write-Host "   - Remote SQL Server (instance name required)" -ForegroundColor Gray
    Write-Host ""

    Write-Host "5. Configure Modern Backup Storage" -ForegroundColor White
    Write-Host "   - Select dedicated volumes for storage pool" -ForegroundColor Gray
    Write-Host "   - Format as ReFS for deduplication support" -ForegroundColor Gray
    Write-Host ""

    # Step 6: Modern Backup Storage Configuration
    Write-Host "[Step 6] Modern Backup Storage (MBS) Configuration" -ForegroundColor Yellow

    Write-Host "Configuring storage pool with PowerShell:" -ForegroundColor Cyan
    Write-Host ""

    # Check for available disks
    $availableDisks = Get-PhysicalDisk -CanPool $true -ErrorAction SilentlyContinue

    if ($availableDisks) {
        Write-Host "Available physical disks for storage pool:" -ForegroundColor Cyan
        $availableDisks | Format-Table FriendlyName, MediaType,
            @{L='Size(GB)';E={[Math]::Round($_.Size/1GB,2)}},
            OperationalStatus -AutoSize

        Write-Host "Example: Creating storage pool" -ForegroundColor White
        Write-Host '# $disks = Get-PhysicalDisk -CanPool $true' -ForegroundColor Gray
        Write-Host '# New-StoragePool -FriendlyName "MABS-Storage-Pool" `' -ForegroundColor Gray
        Write-Host '#     -StorageSubsystemFriendlyName "Windows Storage*" -PhysicalDisks $disks' -ForegroundColor Gray
        Write-Host '# New-VirtualDisk -StoragePoolFriendlyName "MABS-Storage-Pool" `' -ForegroundColor Gray
        Write-Host '#     -FriendlyName "MABS-Disk" -ResiliencySettingName Simple -UseMaximumSize' -ForegroundColor Gray
        Write-Host '# Initialize-Disk -VirtualDisk (Get-VirtualDisk -FriendlyName "MABS-Disk")' -ForegroundColor Gray
        Write-Host '# New-Volume -DiskNumber X -FriendlyName "MABS-Volume" -FileSystem ReFS -DriveLetter M' -ForegroundColor Gray
    } else {
        Write-Host "  [INFO] No additional disks available for pooling" -ForegroundColor Yellow
        Write-Host "  In production: Add dedicated disks for MABS storage pool" -ForegroundColor White
    }
    Write-Host ""

    # Step 7: MABS Registration with Recovery Services Vault
    Write-Host "[Step 7] Registering MABS with Azure" -ForegroundColor Yellow

    Write-Host "After MABS installation, register with Azure:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. Download vault credentials from Azure Portal" -ForegroundColor White
    Write-Host "   - Navigate to Recovery Services Vault" -ForegroundColor Gray
    Write-Host "   - Select 'Properties' > 'Backup Infrastructure'" -ForegroundColor Gray
    Write-Host "   - Download vault credentials file" -ForegroundColor Gray
    Write-Host ""

    Write-Host "2. Register MABS using PowerShell or GUI" -ForegroundColor White
    Write-Host '   Start-OBRegistration -VaultCredentials "<path-to-vault-creds>"' -ForegroundColor Gray
    Write-Host ""

    Write-Host "3. Set encryption passphrase" -ForegroundColor White
    Write-Host "   - Create strong passphrase (minimum 16 characters)" -ForegroundColor Gray
    Write-Host "   - Store securely (required for recovery)" -ForegroundColor Gray
    Write-Host ""

    # Step 8: MABS Configuration and Protection Groups
    Write-Host "[Step 8] MABS Configuration" -ForegroundColor Yellow

    Write-Host "Post-installation configuration:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. Launch MABS Administrator Console" -ForegroundColor White
    Write-Host "   - Located at: $MABSInstallPath\bin\Microsoft.Mabs.UI.exe" -ForegroundColor Gray
    Write-Host ""

    Write-Host "2. Add MABS storage pool" -ForegroundColor White
    Write-Host "   - Management > Disks > Add" -ForegroundColor Gray
    Write-Host "   - Select volumes formatted with ReFS" -ForegroundColor Gray
    Write-Host ""

    Write-Host "3. Create Protection Groups" -ForegroundColor White
    Write-Host "   - Protection > Create Protection Group" -ForegroundColor Gray
    Write-Host "   - Select workload type: SQL, SharePoint, File, Hyper-V, etc." -ForegroundColor Gray
    Write-Host "   - Configure protection schedule and retention" -ForegroundColor Gray
    Write-Host ""

    Write-Host "4. Configure online protection to Azure" -ForegroundColor White
    Write-Host "   - Select 'Online Protection' for long-term retention" -ForegroundColor Gray
    Write-Host "   - Configure Azure backup schedule and policy" -ForegroundColor Gray
    Write-Host ""

    # Step 9: MABS PowerShell Module
    Write-Host "[Step 9] MABS PowerShell Management" -ForegroundColor Yellow

    Write-Host "MABS PowerShell cmdlets (after installation):" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Import MABS module:" -ForegroundColor White
    Write-Host '  Import-Module "$env:ProgramFiles\Microsoft Azure Backup Server\DPM\bin\DataProtectionManager"' -ForegroundColor Gray
    Write-Host ""

    Write-Host "Common MABS cmdlets:" -ForegroundColor White
    Write-Host "  Get-DPMProductionServer        # List protected servers" -ForegroundColor Gray
    Write-Host "  Get-DPMProtectionGroup         # List protection groups" -ForegroundColor Gray
    Write-Host "  Get-DPMDatasource              # List protected datasources" -ForegroundColor Gray
    Write-Host "  Get-DPMRecoveryPoint           # List recovery points" -ForegroundColor Gray
    Write-Host "  Start-DPMBackupJob             # Start backup job" -ForegroundColor Gray
    Write-Host "  Get-DPMJob                     # Monitor backup jobs" -ForegroundColor Gray
    Write-Host ""

    # Step 10: Best Practices
    Write-Host "[Step 10] MABS Best Practices" -ForegroundColor Yellow

    Write-Host "[INFO] Best Practices:" -ForegroundColor Cyan
    Write-Host "  - Install MABS on dedicated server (not domain controller)" -ForegroundColor White
    Write-Host "  - Use ReFS for storage pools (enables block cloning)" -ForegroundColor White
    Write-Host "  - Configure SQL Server with appropriate memory limits" -ForegroundColor White
    Write-Host "  - Size storage pool at 1.5x-2x of protected data" -ForegroundColor White
    Write-Host "  - Enable online protection for critical workloads" -ForegroundColor White
    Write-Host "  - Regular MABS agent updates and patches" -ForegroundColor White
    Write-Host "  - Monitor backup jobs and set up email alerts" -ForegroundColor White
    Write-Host "  - Test recovery procedures regularly" -ForegroundColor White
    Write-Host "  - Keep encryption passphrase in secure location" -ForegroundColor White
    Write-Host ""

    Write-Host "[INFO] Supported Workloads:" -ForegroundColor Cyan
    Write-Host "  - Hyper-V Virtual Machines" -ForegroundColor White
    Write-Host "  - SQL Server databases" -ForegroundColor White
    Write-Host "  - SharePoint farms" -ForegroundColor White
    Write-Host "  - Exchange Server" -ForegroundColor White
    Write-Host "  - File servers and client computers" -ForegroundColor White
    Write-Host "  - System state and bare metal recovery" -ForegroundColor White
    Write-Host ""

} catch {
    Write-Host "[ERROR] An error occurred: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Script completed successfully!" -ForegroundColor Green
Write-Host "MABS deployment prerequisites and steps documented" -ForegroundColor Yellow
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Download MABS from: https://aka.ms/downloadmabs" -ForegroundColor White
Write-Host "  2. Run setup and configure SQL Server" -ForegroundColor White
Write-Host "  3. Configure Modern Backup Storage pool" -ForegroundColor White
Write-Host "  4. Register with Recovery Services Vault" -ForegroundColor White
Write-Host "  5. Create protection groups for workloads" -ForegroundColor White
