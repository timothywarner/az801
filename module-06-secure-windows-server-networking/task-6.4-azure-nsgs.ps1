<#
.SYNOPSIS
    Task 6.4 - Configure Azure Network Security Groups
.DESCRIPTION
    Comprehensive demonstration of Azure NSG configuration for Windows Server VMs.
    Covers NSG creation, security rules, service tags, and monitoring.
.EXAMPLE
    .\task-6.4-azure-nsgs.ps1
.NOTES
    Module: Module 6 - Secure Windows Server Networking
    Task: 6.4 - Configure Azure Network Security Groups
    Prerequisites:
    - Azure subscription with appropriate permissions
    - Az PowerShell modules (Az.Accounts, Az.Network)
    PowerShell Version: 5.1+
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

Write-Host "=== AZ-801 Module 6: Task 6.4 - Configure Azure Network Security Groups ===" -ForegroundColor Cyan
Write-Host ""

try {
    # Step 1: Azure NSG Overview
    Write-Host "[Step 1] Azure Network Security Groups Overview" -ForegroundColor Yellow

    Write-Host "NSG capabilities:" -ForegroundColor Cyan
    Write-Host "  - Filter network traffic to and from Azure resources" -ForegroundColor White
    Write-Host "  - Define security rules with priority-based processing" -ForegroundColor White
    Write-Host "  - Use service tags for Microsoft services" -ForegroundColor White
    Write-Host "  - Apply to subnets or individual NICs" -ForegroundColor White
    Write-Host "  - Log traffic with NSG flow logs" -ForegroundColor White
    Write-Host ""

    # Step 2: Check Azure PowerShell modules
    Write-Host "[Step 2] Checking Azure PowerShell modules" -ForegroundColor Yellow

    $requiredModules = @('Az.Accounts', 'Az.Network', 'Az.Resources')
    foreach ($module in $requiredModules) {
        $installedModule = Get-Module -ListAvailable -Name $module | Select-Object -First 1
        if ($installedModule) {
            Write-Host "  $module : Version $($installedModule.Version) [OK]" -ForegroundColor Green
        } else {
            Write-Host "  $module : Not installed" -ForegroundColor Yellow
        }
    }
    Write-Host ""

    # Step 3: Connect to Azure
    Write-Host "[Step 3] Connecting to Azure" -ForegroundColor Yellow

    try {
        $context = Get-AzContext
        if ($context) {
            Write-Host "Connected to Azure" -ForegroundColor Green
            Write-Host "  Subscription: $($context.Subscription.Name)" -ForegroundColor White
        } else {
            Write-Host "Not connected. Run: Connect-AzAccount" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "Run: Connect-AzAccount" -ForegroundColor Yellow
    }
    Write-Host ""

    # Step 4: Create NSG with rules
    Write-Host "[Step 4] Creating Network Security Group" -ForegroundColor Yellow

    Write-Host "Example: Create NSG for web servers" -ForegroundColor Cyan
    Write-Host @'
  $resourceGroupName = "rg-webservers"
  $location = "East US"
  $nsgName = "nsg-webservers"

  # Create RDP rule
  $rdpRule = New-AzNetworkSecurityRuleConfig `
      -Name "Allow-RDP-Management" `
      -Description "Allow RDP from management subnet" `
      -Access Allow `
      -Protocol Tcp `
      -Direction Inbound `
      -Priority 1000 `
      -SourceAddressPrefix "10.0.1.0/24" `
      -SourcePortRange * `
      -DestinationAddressPrefix * `
      -DestinationPortRange 3389

  # Create HTTP rule
  $httpRule = New-AzNetworkSecurityRuleConfig `
      -Name "Allow-HTTP-Internet" `
      -Description "Allow HTTP from Internet" `
      -Access Allow `
      -Protocol Tcp `
      -Direction Inbound `
      -Priority 1010 `
      -SourceAddressPrefix Internet `
      -SourcePortRange * `
      -DestinationAddressPrefix * `
      -DestinationPortRange 80

  # Create HTTPS rule
  $httpsRule = New-AzNetworkSecurityRuleConfig `
      -Name "Allow-HTTPS-Internet" `
      -Description "Allow HTTPS from Internet" `
      -Access Allow `
      -Protocol Tcp `
      -Direction Inbound `
      -Priority 1020 `
      -SourceAddressPrefix Internet `
      -SourcePortRange * `
      -DestinationAddressPrefix * `
      -DestinationPortRange 443

  # Create NSG
  $nsg = New-AzNetworkSecurityGroup `
      -ResourceGroupName $resourceGroupName `
      -Location $location `
      -Name $nsgName `
      -SecurityRules $rdpRule,$httpRule,$httpsRule
'@ -ForegroundColor Gray
    Write-Host ""

    # Step 5: Add rules to existing NSG
    Write-Host "[Step 5] Adding rules to existing NSG" -ForegroundColor Yellow

    Write-Host "Example: Add SQL Server rule" -ForegroundColor Cyan
    Write-Host @'
  # Get existing NSG
  $nsg = Get-AzNetworkSecurityGroup `
      -ResourceGroupName $resourceGroupName `
      -Name $nsgName

  # Add SQL rule
  $nsg | Add-AzNetworkSecurityRuleConfig `
      -Name "Allow-SQL-AppSubnet" `
      -Description "Allow SQL from application subnet" `
      -Access Allow `
      -Protocol Tcp `
      -Direction Inbound `
      -Priority 1030 `
      -SourceAddressPrefix "10.0.2.0/24" `
      -SourcePortRange * `
      -DestinationAddressPrefix * `
      -DestinationPortRange 1433 |
  Set-AzNetworkSecurityGroup
'@ -ForegroundColor Gray
    Write-Host ""

    # Step 6: Use service tags
    Write-Host "[Step 6] Using service tags" -ForegroundColor Yellow

    Write-Host "Service tags simplify NSG rules for Microsoft services..." -ForegroundColor Cyan
    Write-Host ""

    Write-Host "Common service tags:" -ForegroundColor White
    Write-Host "  - AzureCloud: All Azure datacenter IPs" -ForegroundColor Gray
    Write-Host "  - AzureLoadBalancer: Azure load balancer" -ForegroundColor Gray
    Write-Host "  - Storage: Azure Storage service" -ForegroundColor Gray
    Write-Host "  - Sql: Azure SQL Database" -ForegroundColor Gray
    Write-Host "  - AzureActiveDirectory: Azure AD service" -ForegroundColor Gray
    Write-Host "  - Internet: Public Internet" -ForegroundColor Gray
    Write-Host ""

    Write-Host "Example: Allow Azure Monitor" -ForegroundColor Cyan
    Write-Host @'
  Add-AzNetworkSecurityRuleConfig `
      -NetworkSecurityGroup $nsg `
      -Name "Allow-AzureMonitor" `
      -Access Allow `
      -Protocol Tcp `
      -Direction Outbound `
      -Priority 2000 `
      -SourceAddressPrefix * `
      -SourcePortRange * `
      -DestinationAddressPrefix AzureMonitor `
      -DestinationPortRange 443 |
  Set-AzNetworkSecurityGroup
'@ -ForegroundColor Gray
    Write-Host ""

    # Step 7: Associate NSG
    Write-Host "[Step 7] Associating NSG with resources" -ForegroundColor Yellow

    Write-Host "Associate NSG with subnet:" -ForegroundColor Cyan
    Write-Host @'
  $vnet = Get-AzVirtualNetwork -ResourceGroupName $resourceGroupName -Name "vnet-prod"
  $subnet = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name "subnet-web"
  $subnet.NetworkSecurityGroup = $nsg
  Set-AzVirtualNetwork -VirtualNetwork $vnet
'@ -ForegroundColor Gray

    Write-Host ""
    Write-Host "Associate NSG with NIC:" -ForegroundColor Cyan
    Write-Host @'
  $nic = Get-AzNetworkInterface -ResourceGroupName $resourceGroupName -Name "nic-webserver01"
  $nic.NetworkSecurityGroup = $nsg
  Set-AzNetworkInterface -NetworkInterface $nic
'@ -ForegroundColor Gray
    Write-Host ""

    # Step 8: View NSG rules
    Write-Host "[Step 8] Viewing NSG configuration" -ForegroundColor Yellow

    Write-Host "Get NSG and rules:" -ForegroundColor Cyan
    Write-Host @'
  $nsg = Get-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Name $nsgName

  $nsg.SecurityRules |
      Select-Object Name, Priority, Direction, Access, Protocol,
          SourceAddressPrefix, DestinationPortRange |
      Sort-Object Priority |
      Format-Table -AutoSize
'@ -ForegroundColor Gray
    Write-Host ""

    # Step 9: NSG flow logs
    Write-Host "[Step 9] Configuring NSG flow logs" -ForegroundColor Yellow

    Write-Host "Enable flow logs for traffic analysis..." -ForegroundColor Cyan
    Write-Host @'
  # Create storage account for logs
  $storageAccount = New-AzStorageAccount `
      -ResourceGroupName $resourceGroupName `
      -Name "nsglogsstorage123" `
      -Location $location `
      -SkuName Standard_LRS

  # Enable NSG flow logs
  Set-AzNetworkWatcherFlowLog `
      -NetworkWatcher $networkWatcher `
      -TargetResourceId $nsg.Id `
      -StorageId $storageAccount.Id `
      -EnableFlowLog $true `
      -FormatType Json `
      -FormatVersion 2 `
      -EnableTrafficAnalytics $true
'@ -ForegroundColor Gray
    Write-Host ""

    # Step 10: Best practices
    Write-Host "[Step 10] NSG best practices" -ForegroundColor Yellow

    Write-Host "Best practices:" -ForegroundColor Cyan
    Write-Host "  1. Use deny-by-default approach (Azure does this automatically)" -ForegroundColor White
    Write-Host "  2. Apply NSGs at subnet level for broad protection" -ForegroundColor White
    Write-Host "  3. Use service tags instead of hardcoding IP addresses" -ForegroundColor White
    Write-Host "  4. Assign priority carefully (lower number = higher priority)" -ForegroundColor White
    Write-Host "  5. Document all custom NSG rules" -ForegroundColor White
    Write-Host "  6. Enable NSG flow logs for security monitoring" -ForegroundColor White
    Write-Host "  7. Review effective security rules periodically" -ForegroundColor White
    Write-Host "  8. Use application security groups for complex scenarios" -ForegroundColor White
    Write-Host "  9. Test NSG rules before production deployment" -ForegroundColor White
    Write-Host "  10. Monitor NSG flow logs with Traffic Analytics" -ForegroundColor White
    Write-Host ""

    Write-Host "Useful commands:" -ForegroundColor Cyan
    Write-Host '  Get-AzNetworkSecurityGroup -ResourceGroupName "rg" -Name "nsg"' -ForegroundColor Gray
    Write-Host '  Get-AzEffectiveNetworkSecurityGroup -NetworkInterfaceName "nic"' -ForegroundColor Gray
    Write-Host '  Remove-AzNetworkSecurityRuleConfig -Name "RuleName" -NetworkSecurityGroup $nsg' -ForegroundColor Gray
    Write-Host ""

} catch {
    Write-Host "[ERROR] $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

Write-Host "Demo completed successfully!" -ForegroundColor Green
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Create NSGs for each subnet or workload" -ForegroundColor White
Write-Host "  2. Define security rules based on least privilege" -ForegroundColor White
Write-Host "  3. Enable NSG flow logs for monitoring" -ForegroundColor White
Write-Host "  4. Use Traffic Analytics to identify security issues" -ForegroundColor White
Write-Host "  5. Review effective security rules on VMs" -ForegroundColor White
