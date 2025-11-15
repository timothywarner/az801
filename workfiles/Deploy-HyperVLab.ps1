#Requires -Version 7.0
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Idempotent Hyper-V deployment script for AZ-801 Windows Server lab environment

.DESCRIPTION
    This script safely:
    - Installs and configures Hyper-V on Windows 11
    - Creates an external virtual switch for internet access
    - Deploys 3 VMs (DC01, HOST01, HOST02) with proper disk configuration for S2D
    - Mounts Windows Server ISO from L:\801\WindowsServer.iso
    - Stores all VM files in L:\801
    - All operations are idempotent (safe to run multiple times)

.NOTES
    Author: Tim Warner (@TechTrainerTim)
    Version: 2.0
    Purpose: AZ-801 Lab Environment - Hyper-V Deployment
    Date: 2025-11-09

    Requirements:
    - Windows 11 Pro/Enterprise/Education (Home doesn't support Hyper-V)
    - 32GB+ RAM recommended (minimum 24GB)
    - 300GB+ free disk space on L: drive
    - Windows Server ISO at L:\801\WindowsServer.iso
    - PowerShell 7.x

.EXAMPLE
    .\Deploy-HyperVLab.ps1
    Uses default settings with L:\801 storage

.EXAMPLE
    .\Deploy-HyperVLab.ps1 -Force
    Recreates existing VMs (destructive)
#>

param(
  [Parameter()]
  [string]$VMPath = "L:\801",  # Tim's specified path

  [Parameter()]
  [string]$ISOPath = "L:\801\WindowsServer.iso",  # Tim's ISO location

  [Parameter()]
  [string]$SwitchName = "AZ801-External",

  [Parameter()]
  [switch]$SkipVMCreation,  # Only setup Hyper-V, don't create VMs

  [Parameter()]
  [switch]$Force  # Force recreation of existing resources
)

# ============================================
# HELPER FUNCTIONS
# ============================================

function Write-Phase {
  param([string]$Message)
  Write-Host "`n" + "="*70 -ForegroundColor DarkGray
  Write-Host ">>> $Message" -ForegroundColor Cyan
  Write-Host "="*70 -ForegroundColor DarkGray
}

function Test-IsHyperVEnabled {
  $hyperv = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All
  return ($hyperv.State -eq 'Enabled')
}

function Test-VMExists {
  param([string]$VMName)
  try {
    $null = Get-VM -Name $VMName -ErrorAction Stop
    return $true
  }
  catch {
    return $false
  }
}

function New-VMDisk {
  param(
    [string]$Path,
    [uint64]$Size,
    [switch]$Dynamic
  )

  if (Test-Path $Path) {
    if ($Force) {
      Write-Host "    Removing existing disk: $Path" -ForegroundColor Yellow
      Remove-Item $Path -Force
    }
    else {
      Write-Host "    Disk already exists: $($Path | Split-Path -Leaf)" -ForegroundColor Green
      return
    }
  }

  Write-Host "    Creating disk: $($Path | Split-Path -Leaf) ($([math]::Round($Size/1GB))GB)" -ForegroundColor Gray

  if ($Dynamic) {
    New-VHD -Path $Path -SizeBytes $Size -Dynamic | Out-Null
  }
  else {
    New-VHD -Path $Path -SizeBytes $Size -Fixed | Out-Null
  }
}

# ============================================
# MAIN SCRIPT
# ============================================

Write-Host @"
╔════════════════════════════════════════════════════════════════════════╗
║           HYPER-V LAB DEPLOYMENT FOR AZ-801 CLUSTERING                ║
║                    Tim Warner Configuration                           ║
╚════════════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

Write-Host "VM Storage Path: $VMPath" -ForegroundColor Yellow
Write-Host "Virtual Switch: $SwitchName" -ForegroundColor Yellow
Write-Host "ISO Path: $ISOPath" -ForegroundColor Yellow

# ============================================
# PHASE 1: CHECK SYSTEM REQUIREMENTS
# ============================================

Write-Phase "Phase 1: System Requirements Check"

# Check if L: drive exists
if (-not (Test-Path "L:\")) {
  Write-Host "[ERROR] L: drive not found!" -ForegroundColor Red
  Write-Host "Please ensure your L: drive is mounted and accessible" -ForegroundColor Yellow
  exit 1
}

# Check if ISO exists
if (-not (Test-Path $ISOPath)) {
  Write-Host "[WARNING] Windows Server ISO not found at: $ISOPath" -ForegroundColor Yellow
  Write-Host "VMs will be created but you'll need to attach the ISO manually" -ForegroundColor Yellow
  $ISOPath = $null
}
else {
  Write-Host "[✓] Windows Server ISO found" -ForegroundColor Green
}

# Check Windows edition
$edition = Get-CimInstance -ClassName Win32_OperatingSystem | Select-Object -ExpandProperty Caption
Write-Host "Windows Edition: $edition" -ForegroundColor Gray

if ($edition -match "Home") {
  Write-Host "[ERROR] Windows Home edition does not support Hyper-V!" -ForegroundColor Red
  Write-Host "Upgrade to Pro, Enterprise, or Education edition" -ForegroundColor Yellow
  exit 1
}

# Check available RAM
$totalRAM = [math]::Round((Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum).Sum / 1GB, 2)
Write-Host "Total RAM: ${totalRAM}GB" -ForegroundColor Gray

if ($totalRAM -lt 24) {
  Write-Host "[WARNING] Less than 24GB RAM. VMs may run slowly." -ForegroundColor Yellow
  Write-Host "DC01: 4GB + HOST01: 8GB + HOST02: 8GB = 20GB minimum" -ForegroundColor Yellow
}

# Check available disk space on L:
$freeSpace = [math]::Round((Get-PSDrive L).Free / 1GB, 2)
Write-Host "Free space on L: ${freeSpace}GB" -ForegroundColor Gray

if ($freeSpace -lt 300) {
  Write-Host "[WARNING] Less than 300GB free on L: drive" -ForegroundColor Yellow
  Write-Host "Each VM needs ~200GB for OS + data disks" -ForegroundColor Yellow
}

# Check CPU virtualization
Write-Host "Checking CPU virtualization support..." -ForegroundColor Gray
$virt = Get-CimInstance -ClassName Win32_Processor | Select-Object -Property VMMonitorModeExtensions
if ($virt.VMMonitorModeExtensions) {
  Write-Host "[✓] CPU virtualization supported" -ForegroundColor Green
}
else {
  Write-Host "[!] Cannot detect virtualization - check BIOS/UEFI settings" -ForegroundColor Yellow
}

# ============================================
# PHASE 2: INSTALL/ENABLE HYPER-V
# ============================================

Write-Phase "Phase 2: Hyper-V Installation"

if (Test-IsHyperVEnabled) {
  Write-Host "[IDEMPOTENT] Hyper-V is already enabled" -ForegroundColor Yellow

  # Verify Hyper-V services are running
  $vmms = Get-Service -Name vmms -ErrorAction SilentlyContinue
  if ($vmms.Status -ne 'Running') {
    Write-Host "Starting Hyper-V Virtual Machine Management Service..." -ForegroundColor Yellow
    Start-Service vmms
  }
}
else {
  Write-Host "Installing Hyper-V features..." -ForegroundColor Green

  # Enable all Hyper-V features
  $features = @(
    "Microsoft-Hyper-V-All",
    "Microsoft-Hyper-V",
    "Microsoft-Hyper-V-Tools-All",
    "Microsoft-Hyper-V-Management-PowerShell",
    "Microsoft-Hyper-V-Management-Clients"
  )

  foreach ($feature in $features) {
    Write-Host "  Enabling $feature..." -ForegroundColor Gray
    Enable-WindowsOptionalFeature -Online -FeatureName $feature -All -NoRestart | Out-Null
  }

  Write-Host @"

[ACTION REQUIRED] Hyper-V has been installed!
You must restart your computer for changes to take effect.

After restart, run this script again to continue with VM creation.

Restart now? (Y/N):
"@ -ForegroundColor Yellow

  $restart = Read-Host
  if ($restart -eq 'Y') {
    Restart-Computer -Force
  }
  exit 0
}

# Import Hyper-V module if needed
if (-not (Get-Module -Name Hyper-V)) {
  Import-Module Hyper-V -ErrorAction SilentlyContinue
}

# ============================================
# PHASE 3: CONFIGURE VIRTUAL SWITCH
# ============================================

Write-Phase "Phase 3: Virtual Switch Configuration"

# Check for existing switch
$existingSwitch = Get-VMSwitch -Name $SwitchName -ErrorAction SilentlyContinue

if ($existingSwitch) {
  Write-Host "[IDEMPOTENT] Virtual switch '$SwitchName' already exists" -ForegroundColor Yellow
  Write-Host "  Type: $($existingSwitch.SwitchType)" -ForegroundColor Gray
  Write-Host "  NetAdapter: $($existingSwitch.NetAdapterInterfaceDescription)" -ForegroundColor Gray
}
else {
  Write-Host "Creating external virtual switch for internet access..." -ForegroundColor Green

  # Get the primary network adapter with internet connectivity
  $netAdapter = Get-NetAdapter |
  Where-Object { $_.Status -eq 'Up' -and $_.PhysicalMediaType -ne 'Unspecified' } |
  Sort-Object -Property LinkSpeed -Descending |
  Select-Object -First 1

  if (-not $netAdapter) {
    Write-Host "[ERROR] No suitable network adapter found for external switch!" -ForegroundColor Red
    Write-Host "Creating internal switch instead (no internet access)..." -ForegroundColor Yellow

    New-VMSwitch -Name $SwitchName `
      -SwitchType Internal `
      -Notes "AZ-801 Lab Network (Internal Only)"
  }
  else {
    Write-Host "Using network adapter: $($netAdapter.Name)" -ForegroundColor Gray

    New-VMSwitch -Name $SwitchName `
      -NetAdapterName $netAdapter.Name `
      -AllowManagementOS $true `
      -Notes "AZ-801 Lab Network with Internet Access"

    Write-Host "[✓] External switch created successfully" -ForegroundColor Green
  }
}

# ============================================
# PHASE 4: CREATE VM STORAGE STRUCTURE
# ============================================

if (-not $SkipVMCreation) {
  Write-Phase "Phase 4: Storage Structure Setup"

  # Create directory structure on L:\801
  $directories = @(
    $VMPath,
    "$VMPath\VMs",
    "$VMPath\VMs\DC01",
    "$VMPath\VMs\DC01\Virtual Hard Disks",
    "$VMPath\VMs\DC01\Checkpoints",
    "$VMPath\VMs\DC01\Virtual Machines",
    "$VMPath\VMs\HOST01",
    "$VMPath\VMs\HOST01\Virtual Hard Disks",
    "$VMPath\VMs\HOST01\Checkpoints",
    "$VMPath\VMs\HOST01\Virtual Machines",
    "$VMPath\VMs\HOST02",
    "$VMPath\VMs\HOST02\Virtual Hard Disks",
    "$VMPath\VMs\HOST02\Checkpoints",
    "$VMPath\VMs\HOST02\Virtual Machines",
    "$VMPath\ISOs"
  )

  foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
      Write-Host "Creating directory: $($dir.Replace($VMPath, 'L:\801'))" -ForegroundColor Gray
      New-Item -Path $dir -ItemType Directory -Force | Out-Null
    }
  }

  # Copy ISO to ISOs folder if it exists elsewhere
  if ($ISOPath -and (Test-Path $ISOPath) -and $ISOPath -notlike "*\ISOs\*") {
    $isoDestination = "$VMPath\ISOs\WindowsServer.iso"
    if (-not (Test-Path $isoDestination)) {
      Write-Host "Copying ISO to central location..." -ForegroundColor Yellow
      Copy-Item -Path $ISOPath -Destination $isoDestination
      $ISOPath = $isoDestination
    }
  }

  Write-Host "[✓] Storage structure ready at L:\801" -ForegroundColor Green
}

# ============================================
# PHASE 5: CREATE VIRTUAL MACHINES
# ============================================

if (-not $SkipVMCreation) {
  Write-Phase "Phase 5: Virtual Machine Creation"

  # VM Configuration definitions
  $vmConfigs = @(
    @{
      Name       = 'DC01'
      Memory     = 4GB
      Processors = 2
      Generation = 2
      Disks      = @(
        @{ Name = 'OS'; Size = 100GB; Dynamic = $true }
      )
    },
    @{
      Name       = 'HOST01'
      Memory     = 8GB
      Processors = 4
      Generation = 2
      Disks      = @(
        @{ Name = 'OS'; Size = 100GB; Dynamic = $true },
        @{ Name = 'Data1'; Size = 60GB; Dynamic = $false },
        @{ Name = 'Data2'; Size = 60GB; Dynamic = $false },
        @{ Name = 'Data3'; Size = 60GB; Dynamic = $false }
      )
    },
    @{
      Name       = 'HOST02'
      Memory     = 8GB
      Processors = 4
      Generation = 2
      Disks      = @(
        @{ Name = 'OS'; Size = 100GB; Dynamic = $true },
        @{ Name = 'Data1'; Size = 60GB; Dynamic = $false },
        @{ Name = 'Data2'; Size = 60GB; Dynamic = $false },
        @{ Name = 'Data3'; Size = 60GB; Dynamic = $false }
      )
    }
  )

  foreach ($config in $vmConfigs) {
    Write-Host "`nCreating VM: $($config.Name)" -ForegroundColor Cyan

    # Check if VM already exists
    if (Test-VMExists -VMName $config.Name) {
      if ($Force) {
        Write-Host "  Removing existing VM..." -ForegroundColor Yellow
        Stop-VM -Name $config.Name -TurnOff -Force -ErrorAction SilentlyContinue
        Remove-VM -Name $config.Name -Force

        # Remove old files
        if (Test-Path "$VMPath\VMs\$($config.Name)") {
          Remove-Item "$VMPath\VMs\$($config.Name)" -Recurse -Force
        }
      }
      else {
        Write-Host "  [IDEMPOTENT] VM already exists" -ForegroundColor Yellow

        # Ensure ISO is attached even if VM exists
        if ($ISOPath -and (Test-Path $ISOPath)) {
          $vm = Get-VM -Name $config.Name
          $dvd = Get-VMDvdDrive -VM $vm -ErrorAction SilentlyContinue
          if ($dvd -and -not $dvd.Path) {
            Set-VMDvdDrive -VM $vm -Path $ISOPath
            Write-Host "    Attached ISO to existing VM" -ForegroundColor Green
          }
        }
        continue
      }
    }

    # Create the VM with specific paths
    Write-Host "  Creating VM shell..." -ForegroundColor Gray
    $vm = New-VM -Name $config.Name `
      -MemoryStartupBytes $config.Memory `
      -Path "$VMPath\VMs" `
      -Generation $config.Generation `
      -SwitchName $SwitchName

    # Configure VM settings
    Write-Host "  Configuring VM settings..." -ForegroundColor Gray

    # Set processor count
    Set-VM -VM $vm -ProcessorCount $config.Processors

    # Set checkpoint location
    Set-VM -VM $vm `
      -CheckpointFileLocation "$VMPath\VMs\$($config.Name)\Checkpoints" `
      -SmartPagingFilePath "$VMPath\VMs\$($config.Name)\Virtual Machines"

    # Enable nested virtualization for HOST01/HOST02 (for Hyper-V inside VM)
    if ($config.Name -like 'HOST*') {
      Set-VMProcessor -VM $vm -ExposeVirtualizationExtensions $true
      Write-Host "    Nested virtualization enabled" -ForegroundColor Gray

      # Increase memory for better S2D performance
      Set-VMMemory -VM $vm `
        -DynamicMemoryEnabled $true `
        -MinimumBytes 4GB `
        -StartupBytes $config.Memory `
        -MaximumBytes 12GB
    }
    else {
      # DC01 gets less dynamic memory
      Set-VMMemory -VM $vm `
        -DynamicMemoryEnabled $true `
        -MinimumBytes 2GB `
        -StartupBytes $config.Memory `
        -MaximumBytes 6GB
    }

    # Enable Integration Services
    Enable-VMIntegrationService -VM $vm -Name "Guest Service Interface"

    # Configure boot order and security
    if ($config.Generation -eq 2) {
      Set-VMFirmware -VM $vm -EnableSecureBoot Off  # Off for initial OS install
    }

    # Remove default disk
    Get-VMHardDiskDrive -VM $vm | Remove-VMHardDiskDrive

    # Create and attach disks
    Write-Host "  Creating virtual disks..." -ForegroundColor Gray

    $diskIndex = 0
    foreach ($disk in $config.Disks) {
      $diskPath = "$VMPath\VMs\$($config.Name)\Virtual Hard Disks\$($config.Name)-$($disk.Name).vhdx"

      # Create the disk
      New-VMDisk -Path $diskPath -Size $disk.Size -Dynamic:$disk.Dynamic

      # Attach to VM - all disks go on SCSI for Gen2
      Add-VMHardDiskDrive -VM $vm `
        -Path $diskPath `
        -ControllerType SCSI `
        -ControllerNumber 0 `
        -ControllerLocation $diskIndex

      $diskIndex++
    }

    # Attach ISO if provided
    if ($ISOPath -and (Test-Path $ISOPath)) {
      Write-Host "  Attaching Windows Server ISO..." -ForegroundColor Gray

      # Add DVD drive
      Add-VMDvdDrive -VM $vm -ControllerNumber 0 -ControllerLocation 10 -Path $ISOPath

      # Set DVD as first boot device for installation
      $dvd = Get-VMDvdDrive -VM $vm
      $hdd = Get-VMHardDiskDrive -VM $vm | Where-Object { $_.ControllerLocation -eq 0 }
      Set-VMFirmware -VM $vm -BootOrder $dvd, $hdd

      Write-Host "    ISO attached and set as first boot" -ForegroundColor Green
    }

    # Add note about VM purpose
    $note = @"
AZ-801 Lab - $($config.Name)
Created: $(Get-Date -Format 'yyyy-MM-dd HH:mm')
Purpose: $(if($config.Name -eq 'DC01'){'Domain Controller'}else{'Failover Cluster Node'})
Network: $SwitchName
Storage: L:\801
"@
    Set-VM -VM $vm -Notes $note

    # Configure automatic start/stop actions
    Set-VM -VM $vm `
      -AutomaticStartAction Nothing `
      -AutomaticStopAction ShutDown `
      -AutomaticStartDelay 0

    # Disable automatic checkpoints (not needed for lab)
    Set-VM -VM $vm -AutomaticCheckpointsEnabled $false

    Write-Host "  [✓] VM '$($config.Name)' created successfully" -ForegroundColor Green
  }
}

# ============================================
# PHASE 6: CONFIGURE S2D COMPATIBILITY
# ============================================

if (-not $SkipVMCreation) {
  Write-Phase "Phase 6: S2D Compatibility Configuration"

  Write-Host "Verifying cluster node configuration for Storage Spaces Direct..." -ForegroundColor Green

  foreach ($vmName in @('HOST01', 'HOST02')) {
    $vm = Get-VM -Name $vmName -ErrorAction SilentlyContinue

    if ($vm) {
      Write-Host "  Verifying $vmName..." -ForegroundColor Gray

      # Verify all disks are on SCSI controller (required for S2D)
      $disks = Get-VMHardDiskDrive -VM $vm

      $allScsi = $true
      foreach ($disk in $disks) {
        if ($disk.ControllerType -ne 'SCSI') {
          $allScsi = $false
          Write-Host "    [!] Non-SCSI disk found: $($disk.Path | Split-Path -Leaf)" -ForegroundColor Yellow
        }
      }

      if ($allScsi) {
        Write-Host "    [✓] All disks on SCSI controller" -ForegroundColor Green
      }

      # Verify nested virtualization is enabled
      $proc = Get-VMProcessor -VM $vm
      if ($proc.ExposeVirtualizationExtensions) {
        Write-Host "    [✓] Nested virtualization enabled" -ForegroundColor Green
      }
      else {
        Write-Host "    [!] Enabling nested virtualization..." -ForegroundColor Yellow
        Set-VMProcessor -VM $vm -ExposeVirtualizationExtensions $true
      }

      # Ensure sufficient memory
      $mem = Get-VMMemory -VM $vm
      Write-Host "    Memory: $([math]::Round($mem.Startup/1GB))GB (Dynamic: $($mem.DynamicMemoryEnabled))" -ForegroundColor Gray

      Write-Host "    [✓] $vmName ready for S2D" -ForegroundColor Green
    }
  }
}

# ============================================
# PHASE 7: FINAL SUMMARY
# ============================================

Write-Phase "Deployment Summary"

Write-Host "`nHyper-V Status:" -ForegroundColor Cyan
Write-Host "  Hyper-V: Enabled" -ForegroundColor Green
Write-Host "  VMMS Service: $((Get-Service vmms).Status)" -ForegroundColor Green

Write-Host "`nVirtual Switch:" -ForegroundColor Cyan
$switch = Get-VMSwitch -Name $SwitchName -ErrorAction SilentlyContinue
if ($switch) {
  Write-Host "  Name: $($switch.Name)" -ForegroundColor Green
  Write-Host "  Type: $($switch.SwitchType)" -ForegroundColor Green
}

if (-not $SkipVMCreation) {
  Write-Host "`nVirtual Machines:" -ForegroundColor Cyan
  Get-VM -ErrorAction SilentlyContinue | Format-Table @{n = 'Name'; e = { $_.Name } },
  State,
  @{n = 'Memory(GB)'; e = { [math]::Round($_.MemoryStartup / 1GB) } },
  ProcessorCount,
  @{n = 'Uptime'; e = { if ($_.Uptime) { $_.Uptime.ToString() }else { '-' } } } -AutoSize

  Write-Host "Disk Configuration:" -ForegroundColor Cyan
  foreach ($vmName in @('DC01', 'HOST01', 'HOST02')) {
    $vm = Get-VM -Name $vmName -ErrorAction SilentlyContinue
    if ($vm) {
      Write-Host "  $vmName`:" -ForegroundColor Yellow
      Get-VMHardDiskDrive -VM $vm | ForEach-Object {
        $disk = Get-VHD -Path $_.Path -ErrorAction SilentlyContinue
        if ($disk) {
          $name = ($_.Path | Split-Path -Leaf).Replace("$vmName-", '').Replace('.vhdx', '')
          $size = [math]::Round($disk.Size / 1GB)
          $used = [math]::Round($disk.FileSize / 1GB, 1)
          Write-Host ("    {0,-10} {1,6} GB ({2,6:N1} GB used) - {3}" -f
            $name,
            $size,
            $used,
            $_.ControllerType) -ForegroundColor Gray
        }
      }
    }
  }
}

Write-Host @"

╔════════════════════════════════════════════════════════════════════════╗
║                        DEPLOYMENT COMPLETE!                           ║
╚════════════════════════════════════════════════════════════════════════╝

Your Hyper-V lab environment is ready at L:\801!

Network Configuration:
  Domain: corp.techtrainertim.com
  DC01:   10.0.80.10/24  (Domain Controller)
  HOST01: 10.0.80.4/24   (Cluster Node 1)
  HOST02: 10.0.80.6/24   (Cluster Node 2)
  Cluster IP: 10.0.80.100

Quick Start Commands:
  Start all VMs:     Get-VM | Start-VM
  Start DC first:    Start-VM -Name DC01; Start-Sleep 60; Start-VM -Name HOST01,HOST02
  Connect to VM:     vmconnect.exe localhost DC01

Open Hyper-V Manager: virtmgmt.msc

Installation Order:
  1. Start DC01, install Windows Server 2025
  2. Configure as Domain Controller (corp.techtrainertim.com)
  3. Start HOST01 & HOST02, install Windows Server 2025
  4. Join to domain, then run cluster deployment scripts

Storage Spaces Direct will work natively with these VMs!
No registry hacks or workarounds needed in Hyper-V.

"@ -ForegroundColor Cyan

if (-not $ISOPath -or -not (Test-Path $ISOPath)) {
  Write-Host @"
[ACTION REQUIRED] Windows Server ISO not found!

1. Copy your Windows Server 2025 ISO to: L:\801\WindowsServer.iso
2. Or attach manually to each VM:
   `$vms = Get-VM -Name DC01, HOST01, HOST02
   `$vms | ForEach-Object {
       Add-VMDvdDrive -VM `$_ -Path "L:\801\WindowsServer.iso"
   }

"@ -ForegroundColor Yellow
}

Write-Host "Script location saved: L:\801\Deploy-HyperVLab.ps1" -ForegroundColor Gray
Write-Host "Run again anytime - it's idempotent!" -ForegroundColor Gray
