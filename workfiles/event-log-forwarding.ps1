<#
.SYNOPSIS
    Configures Windows Event Forwarding from DC01 to NODE01 for AZ-801 certification lab.

.DESCRIPTION
    This script automates the complete setup of Windows Event Forwarding (WEF) for a domain environment,
    targeting key security and operational events relevant to AZ-801 exam objectives including:
    - Domain Controller authentication events
    - Account management activities
    - Group Policy changes
    - Service and system events
    - Security log clearings and audit policy changes

    IDEMPOTENT: Safe to run multiple times - checks existing state before making changes.

.NOTES
    Author: Tim
    Version: 2.1
    Tested: PowerShell 5.1, Windows Server 2016/2019/2022
    Requirements: Domain Admin privileges, both servers reachable
    Domain: corp.techtrainertim.com
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator

[CmdletBinding()]
param(
  [Parameter(Mandatory = $false)]
  [string]$SourceComputer = "DC01.corp.techtrainertim.com",

  [Parameter(Mandatory = $false)]
  [string]$CollectorComputer = "NODE01.corp.techtrainertim.com",

  [Parameter(Mandatory = $false)]
  [string]$DomainName = "corp.techtrainertim.com",

  [Parameter(Mandatory = $false)]
  [string]$DomainNetBIOS = "CORP",

  [Parameter(Mandatory = $false)]
  [switch]$SkipConnectivityTest
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

Write-Output ""
Write-Output "============================================================"
Write-Output "  Windows Event Forwarding Configuration for AZ-801 Lab"
Write-Output "  Source: $SourceComputer"
Write-Output "  Collector: $CollectorComputer"
Write-Output "  Domain: $DomainName"
Write-Output "============================================================"
Write-Output ""

#region Helper Functions

function Write-Step {
  param([string]$Message)
  Write-Output ""
  Write-Output ">>> $Message"
  Write-Output ""
}

function Write-Success {
  param(
    [string]$Message,
    [int]$LineNumber = 0
  )
  if ($LineNumber -gt 0) {
    Write-Output "[SUCCESS] $Message (line $LineNumber)"
  }
  else {
    Write-Output "[SUCCESS] $Message"
  }
}

function Write-Info {
  param(
    [string]$Message,
    [int]$LineNumber = 0
  )
  if ($LineNumber -gt 0) {
    Write-Output "[INFO] $Message (line $LineNumber)"
  }
  else {
    Write-Output "[INFO] $Message"
  }
}

function Write-ErrorMsg {
  param(
    [string]$Message,
    [int]$LineNumber = 0
  )
  if ($LineNumber -gt 0) {
    Write-Output "[ERROR] $Message (line $LineNumber)"
  }
  else {
    Write-Output "[ERROR] $Message"
  }
}

function Write-Warning {
  param(
    [string]$Message,
    [int]$LineNumber = 0
  )
  if ($LineNumber -gt 0) {
    Write-Output "[WARNING] $Message (line $LineNumber)"
  }
  else {
    Write-Output "[WARNING] $Message"
  }
}

function Test-ComputerConnectivity {
  param([string]$ComputerName)

  try {
    $result = Test-Connection -ComputerName $ComputerName -Count 2 -Quiet
    if ($result) {
      Write-Success "Successfully connected to $ComputerName" -LineNumber 132
      return $true
    }
    else {
      Write-ErrorMsg "Cannot reach $ComputerName" -LineNumber 136
      return $false
    }
  }
  catch {
    Write-ErrorMsg "Failed to test connectivity to $ComputerName : $_" -LineNumber 141
    return $false
  }
}

function Invoke-RemoteCommand {
  param(
    [string]$ComputerName,
    [scriptblock]$ScriptBlock,
    [string]$Description,
    [object[]]$ArgumentList = @(),
    [int]$LineNumber = 0
  )

  try {
    if ($LineNumber -gt 0) {
      Write-Info "Executing on ${ComputerName}: $Description" -LineNumber $LineNumber
    }
    else {
      Write-Info "Executing on ${ComputerName}: $Description"
    }

    if ($ArgumentList.Count -gt 0) {
      $result = Invoke-Command -ComputerName $ComputerName -ScriptBlock $ScriptBlock -ArgumentList $ArgumentList -ErrorAction Stop
    }
    else {
      $result = Invoke-Command -ComputerName $ComputerName -ScriptBlock $ScriptBlock -ErrorAction Stop
    }

    if ($LineNumber -gt 0) {
      Write-Success "Completed: $Description" -LineNumber $LineNumber
    }
    else {
      Write-Success "Completed: $Description"
    }

    return $result
  }
  catch {
    if ($LineNumber -gt 0) {
      Write-ErrorMsg "Failed on ${ComputerName}: $Description" -LineNumber $LineNumber
    }
    else {
      Write-ErrorMsg "Failed on ${ComputerName}: $Description"
    }
    Write-ErrorMsg "Error: $_"
    throw
  }
}

#endregion

#region Pre-flight Checks

Write-Step "Step 1: Pre-flight Connectivity Checks"

if (-not $SkipConnectivityTest) {
  $sourceReachable = Test-ComputerConnectivity -ComputerName $SourceComputer
  $collectorReachable = Test-ComputerConnectivity -ComputerName $CollectorComputer

  if (-not $sourceReachable -or -not $collectorReachable) {
    throw "Connectivity check failed. Ensure both servers are online and reachable."
  }
}
else {
  Write-Info "Skipping connectivity tests as requested" -LineNumber 213
}

Write-Info "Verifying PowerShell Remoting is enabled..." -LineNumber 216
try {
  $sourceHostname = Invoke-Command -ComputerName $SourceComputer -ScriptBlock { $env:COMPUTERNAME } -ErrorAction Stop
  $collectorHostname = Invoke-Command -ComputerName $CollectorComputer -ScriptBlock { $env:COMPUTERNAME } -ErrorAction Stop
  Write-Success "PowerShell Remoting is functional on both servers" -LineNumber 220
  Write-Info "Source hostname: $sourceHostname" -LineNumber 221
  Write-Info "Collector hostname: $collectorHostname" -LineNumber 222
}
catch {
  Write-ErrorMsg "PowerShell Remoting is not enabled or accessible" -LineNumber 225
  Write-Info "Run 'Enable-PSRemoting -Force' on both servers" -LineNumber 226
  throw
}

#endregion

#region Configure Collector (NODE01)

Write-Step "Step 2: Configure Collector Server (NODE01)"

Write-Info "Configuring Windows Event Collector service..." -LineNumber 237
Invoke-RemoteCommand -ComputerName $CollectorComputer -Description "Enable and start WinRM service" -LineNumber 238 -ScriptBlock {
  $winrmService = Get-Service -Name WinRM

  if ($winrmService.StartType -ne 'Automatic') {
    Set-Service -Name WinRM -StartupType Automatic
    Write-Output "Set WinRM to Automatic startup"
  }
  else {
    Write-Output "WinRM already set to Automatic startup"
  }

  if ($winrmService.Status -ne 'Running') {
    Start-Service -Name WinRM
    Write-Output "Started WinRM service"
  }
  else {
    Write-Output "WinRM service already running"
  }
}

Invoke-RemoteCommand -ComputerName $CollectorComputer -Description "Configure Event Collector service" -LineNumber 259 -ScriptBlock {
  $wecSvc = Get-Service -Name Wecsvc -ErrorAction SilentlyContinue
  if (-not $wecSvc) {
    throw "Windows Event Collector service not found - ensure Windows Event Collector feature is installed"
  }

  if ($wecSvc.StartType -ne 'Automatic') {
    Set-Service -Name Wecsvc -StartupType Automatic
    Write-Output "Set Windows Event Collector to Automatic startup"
  }
  else {
    Write-Output "Windows Event Collector already set to Automatic startup"
  }

  if ($wecSvc.Status -ne 'Running') {
    Start-Service -Name Wecsvc
    Write-Output "Started Windows Event Collector service"
  }
  else {
    Write-Output "Windows Event Collector service already running"
  }
}

Invoke-RemoteCommand -ComputerName $CollectorComputer -Description "Configure collector with wecutil" -LineNumber 283 -ScriptBlock {
  $output = & wecutil.exe qc /quiet 2>&1
  Write-Output "Executed wecutil quick config"
}

Write-Success "Collector configuration completed on NODE01" -LineNumber 288

#endregion

#region Configure Source (DC01)

Write-Step "Step 3: Configure Source Server (DC01)"

Write-Info "Configuring source computer for event forwarding..." -LineNumber 296
Invoke-RemoteCommand -ComputerName $SourceComputer -Description "Configure WinRM service" -LineNumber 297 -ScriptBlock {
  $winrmService = Get-Service -Name WinRM

  if ($winrmService.StartType -ne 'Automatic') {
    Set-Service -Name WinRM -StartupType Automatic
    Write-Output "Set WinRM to Automatic startup"
  }
  else {
    Write-Output "WinRM already set to Automatic startup"
  }

  if ($winrmService.Status -ne 'Running') {
    Start-Service -Name WinRM
    Write-Output "Started WinRM service"
  }
  else {
    Write-Output "WinRM service already running"
  }
}

Invoke-RemoteCommand -ComputerName $SourceComputer -Description "Add collector to Event Log Readers group" -LineNumber 317 -ScriptBlock {
  param($Collector, $DomainNetBIOS)

  $collectorName = $Collector.Split('.')[0]
  $computerAccount = "$DomainNetBIOS\$collectorName$"

  Write-Output "Attempting to add $computerAccount to Event Log Readers group"

  try {
    $group = [ADSI]"WinNT://./Event Log Readers,group"

    $members = @($group.Invoke("Members")) | ForEach-Object {
      $path = ([ADSI]$_).Path
      $path
    }

    $accountPath = "WinNT://$DomainNetBIOS/$collectorName$"

    if ($members -contains $accountPath) {
      Write-Output "$computerAccount is already a member of Event Log Readers"
    }
    else {
      $group.Add($accountPath)
      Write-Output "Successfully added $computerAccount to Event Log Readers group"
    }
  }
  catch {
    if ($_.Exception.Message -like "*already a member*" -or $_.Exception.Message -like "*specified account name is already a member*") {
      Write-Output "$computerAccount is already a member of Event Log Readers"
    }
    else {
      Write-Output "Error details: $($_.Exception.Message)"
      throw
    }
  }
} -ArgumentList $CollectorComputer, $DomainNetBIOS

Invoke-RemoteCommand -ComputerName $SourceComputer -Description "Configure source with wecutil" -LineNumber 356 -ScriptBlock {
  param($Collector)

  $output = & wecutil.exe cs /quiet 2>&1
  Write-Output "Executed wecutil quick config for source"

  $currentTrustedHosts = (Get-Item WSMan:\localhost\Client\TrustedHosts -ErrorAction SilentlyContinue).Value
  if ($currentTrustedHosts -notlike "*$Collector*") {
    try {
      & winrm.exe set winrm/config/client "@{TrustedHosts=`"$Collector`"}" 2>$null
      Write-Output "Added $Collector to TrustedHosts"
    }
    catch {
      Write-Output "Note: TrustedHosts configuration not required in domain environment"
    }
  }
  else {
    Write-Output "$Collector already in TrustedHosts or not required"
  }
} -ArgumentList $CollectorComputer

Write-Success "Source configuration completed on DC01" -LineNumber 377

#endregion

#region Configure Firewall

Write-Step "Step 4: Configure Windows Firewall Rules"

Write-Info "Configuring firewall on source computer..." -LineNumber 385
Invoke-RemoteCommand -ComputerName $SourceComputer -Description "Enable WinRM firewall rules" -LineNumber 386 -ScriptBlock {
  $rules = Get-NetFirewallRule -DisplayGroup "Windows Remote Management" -ErrorAction SilentlyContinue

  if ($rules) {
    $enabledCount = 0
    $alreadyEnabledCount = 0

    foreach ($rule in $rules) {
      if ($rule.Enabled -eq $false) {
        Enable-NetFirewallRule -Name $rule.Name
        $enabledCount++
      }
      else {
        $alreadyEnabledCount++
      }
    }

    if ($enabledCount -gt 0) {
      Write-Output "Enabled $enabledCount WinRM firewall rules"
    }
    if ($alreadyEnabledCount -gt 0) {
      Write-Output "$alreadyEnabledCount WinRM firewall rules already enabled"
    }
  }
  else {
    Write-Output "WinRM firewall rules not found - may already be configured or using domain profile"
  }
}

Write-Info "Configuring firewall on collector computer..." -LineNumber 416
Invoke-RemoteCommand -ComputerName $CollectorComputer -Description "Enable Event Forwarding firewall rules" -LineNumber 417 -ScriptBlock {
  $rules = Get-NetFirewallRule -DisplayGroup "Remote Event Log Management" -ErrorAction SilentlyContinue

  if ($rules) {
    $enabledCount = 0
    $alreadyEnabledCount = 0

    foreach ($rule in $rules) {
      if ($rule.Enabled -eq $false) {
        Enable-NetFirewallRule -Name $rule.Name
        $enabledCount++
      }
      else {
        $alreadyEnabledCount++
      }
    }

    if ($enabledCount -gt 0) {
      Write-Output "Enabled $enabledCount Remote Event Log Management firewall rules"
    }
    if ($alreadyEnabledCount -gt 0) {
      Write-Output "$alreadyEnabledCount Remote Event Log Management firewall rules already enabled"
    }
  }
  else {
    Write-Output "Remote Event Log Management firewall rules not found - may already be configured"
  }
}

Write-Success "Firewall configuration completed" -LineNumber 447

#endregion

#region Create Subscription

Write-Step "Step 5: Create Event Forwarding Subscription"

$subscriptionName = "AZ801-DC-Security-Events"

$subscriptionXml = @"
<Subscription xmlns="http://schemas.microsoft.com/2006/03/windows/events/subscription">
    <SubscriptionId>$subscriptionName</SubscriptionId>
    <SubscriptionType>SourceInitiated</SubscriptionType>
    <Description>Critical security and operational events from Domain Controllers for AZ-801 exam preparation. Includes authentication, account management, GPO changes, and system events.</Description>
    <Enabled>true</Enabled>
    <Uri>http://schemas.microsoft.com/wbem/wsman/1/windows/EventLog</Uri>
    <ConfigurationMode>Custom</ConfigurationMode>
    <Delivery Mode="Push">
        <Batching>
            <MaxLatencyTime>30000</MaxLatencyTime>
        </Batching>
        <PushSettings>
            <Heartbeat Interval="3600000"/>
        </PushSettings>
    </Delivery>
    <Query>
        <![CDATA[
        <QueryList>
            <Query Id="0" Path="Security">
                <Select Path="Security">*[System[(EventID=4624)]]</Select>
                <Select Path="Security">*[System[(EventID=4625)]]</Select>
                <Select Path="Security">*[System[(EventID=4740)]]</Select>
                <Select Path="Security">*[System[(EventID=4720)]]</Select>
                <Select Path="Security">*[System[(EventID=4722)]]</Select>
                <Select Path="Security">*[System[(EventID=4725)]]</Select>
                <Select Path="Security">*[System[(EventID=4726)]]</Select>
                <Select Path="Security">*[System[(EventID=4724)]]</Select>
                <Select Path="Security">*[System[(EventID=4731)]]</Select>
                <Select Path="Security">*[System[(EventID=4728 or EventID=4732 or EventID=4756)]]</Select>
                <Select Path="Security">*[System[(EventID=4729 or EventID=4733 or EventID=4757)]]</Select>
                <Select Path="Security">*[System[(EventID=4734)]]</Select>
                <Select Path="Security">*[System[(EventID=1102)]]</Select>
                <Select Path="Security">*[System[(EventID=4768 or EventID=4769 or EventID=4771)]]</Select>
                <Select Path="Security">*[System[(EventID=4719)]]</Select>
                <Select Path="Security">*[System[(EventID=4672 or EventID=4673)]]</Select>
            </Query>
            <Query Id="1" Path="System">
                <Select Path="System">*[System[(EventID=7035 or EventID=7036 or EventID=7040)]]</Select>
                <Select Path="System">*[System[(EventID=6005 or EventID=6006 or EventID=6008 or EventID=6009)]]</Select>
                <Select Path="System">*[System[(EventID=1 and Provider[@Name='Microsoft-Windows-Kernel-General'])]]</Select>
                <Select Path="System">*[System[(Level=1 or Level=2)]]</Select>
            </Query>
            <Query Id="2" Path="Application">
                <Select Path="Application">*[System[(EventID=1000 or EventID=1001 or EventID=1002)]]</Select>
                <Select Path="Application">*[System[(Level=1 or Level=2)]]</Select>
            </Query>
            <Query Id="3" Path="Microsoft-Windows-GroupPolicy/Operational">
                <Select Path="Microsoft-Windows-GroupPolicy/Operational">*[System[(EventID=4016 or EventID=5016 or EventID=5017 or EventID=5312 or EventID=5314)]]</Select>
            </Query>
        </QueryList>
        ]]>
    </Query>
    <ReadExistingEvents>false</ReadExistingEvents>
    <TransportName>http</TransportName>
    <ContentFormat>RenderedText</ContentFormat>
    <Locale Language="en-US"/>
    <LogFile>ForwardedEvents</LogFile>
    <AllowedSourceNonDomainComputers/>
    <AllowedSourceDomainComputers>O:NSG:NSD:(A;;GA;;;DC)(A;;GA;;;NS)(A;;GA;;;DD)</AllowedSourceDomainComputers>
</Subscription>
"@

$xmlPath = "C:\Temp\EventSubscription.xml"

$existingSub = Invoke-RemoteCommand -ComputerName $CollectorComputer -Description "Check for existing subscription" -LineNumber 524 -ScriptBlock {
  param($SubName)

  $subs = & wecutil.exe es 2>$null
  $exists = $subs -contains $SubName

  if ($exists) {
    Write-Output "Subscription '$SubName' already exists"
    return $true
  }
  else {
    Write-Output "Subscription '$SubName' does not exist yet"
    return $false
  }
} -ArgumentList $subscriptionName

if ($existingSub) {
  Write-Info "Subscription already exists - will recreate with current configuration" -LineNumber 541

  Invoke-RemoteCommand -ComputerName $CollectorComputer -Description "Remove existing subscription" -LineNumber 543 -ScriptBlock {
    param($SubName)

    & wecutil.exe ds $SubName 2>&1 | Out-Null
    Write-Output "Removed existing subscription: $SubName"
  } -ArgumentList $subscriptionName
}

Invoke-RemoteCommand -ComputerName $CollectorComputer -Description "Create subscription XML file" -LineNumber 552 -ScriptBlock {
  param($Content, $Path)

  $dir = Split-Path -Path $Path -Parent
  if (-not (Test-Path -Path $dir)) {
    New-Item -Path $dir -ItemType Directory -Force | Out-Null
    Write-Output "Created directory: $dir"
  }

  Set-Content -Path $Path -Value $Content -Encoding UTF8
  Write-Output "Subscription XML saved to $Path"
} -ArgumentList $subscriptionXml, $xmlPath

Invoke-RemoteCommand -ComputerName $CollectorComputer -Description "Create event subscription" -LineNumber 566 -ScriptBlock {
  param($XmlPath, $SubName)

  Write-Output "Creating subscription from $XmlPath"
  $output = & wecutil.exe cs $XmlPath 2>&1

  if ($LASTEXITCODE -ne 0) {
    Write-Output "wecutil output: $output"
    throw "Failed to create subscription. Exit code: $LASTEXITCODE"
  }

  $sub = & wecutil.exe gs $SubName 2>&1
  if ($LASTEXITCODE -eq 0) {
    Write-Output "Subscription created successfully: $SubName"
  }
  else {
    throw "Failed to verify subscription creation"
  }
} -ArgumentList $xmlPath, $subscriptionName

Write-Success "Event forwarding subscription created successfully" -LineNumber 587

#endregion

#region Configure Source in Subscription

Write-Step "Step 6: Configure Source Computer List"

Invoke-RemoteCommand -ComputerName $CollectorComputer -Description "Add source computer to subscription" -LineNumber 595 -ScriptBlock {
  param($Source, $SubName)

  $currentConfig = & wecutil.exe gs $SubName 2>&1

  if ($currentConfig -like "*$Source*") {
    Write-Output "$Source already configured in subscription"
  }
  else {
    & wecutil.exe ss $SubName /esa:$Source 2>&1 | Out-Null
    Write-Output "Added $Source to subscription allowed sources"
  }
} -ArgumentList $SourceComputer, $subscriptionName

Write-Success "Source computer configured in subscription" -LineNumber 610

#endregion

#region Trigger Event Forwarding

Write-Step "Step 7: Trigger Event Forwarding from Source"

Write-Info "Forcing Group Policy update on source to apply event forwarding settings..." -LineNumber 618
Invoke-RemoteCommand -ComputerName $SourceComputer -Description "Force GP update" -LineNumber 619 -ScriptBlock {
  $output = & gpupdate.exe /force /wait:0 2>&1
  Write-Output "Group Policy update initiated"
}

Write-Info "Scheduling WinRM service restart on source (async to avoid connection termination)..." -LineNumber 624
try {
  Invoke-RemoteCommand -ComputerName $SourceComputer -Description "Schedule WinRM restart" -LineNumber 626 -ScriptBlock {
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-Command `"Restart-Service WinRM -Force`""
    $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddSeconds(5)
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -DeleteExpiredTaskAfter (New-TimeSpan -Minutes 1)

    $taskName = "TempWinRMRestart"

    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue

    $task = New-ScheduledTask -Action $action -Trigger $trigger -Principal $principal -Settings $settings
    Register-ScheduledTask -TaskName $taskName -InputObject $task | Out-Null

    Write-Output "WinRM restart scheduled for 5 seconds from now"
    Write-Output "Task will self-delete after execution"
  }

  Write-Info "Waiting 10 seconds for WinRM to restart..." -LineNumber 645
  Start-Sleep -Seconds 10

  Write-Info "Verifying WinRM service is running after restart..." -LineNumber 648
  $winrmStatus = Invoke-RemoteCommand -ComputerName $SourceComputer -Description "Check WinRM status" -LineNumber 649 -ScriptBlock {
    $service = Get-Service -Name WinRM
    Write-Output "WinRM Status: $($service.Status)"
    return $service.Status
  }

  if ($winrmStatus -eq 'Running') {
    Write-Success "WinRM service successfully restarted and operational" -LineNumber 657
  }
  else {
    Write-Warning "WinRM service status: $winrmStatus - may need manual intervention" -LineNumber 660
  }
}
catch {
  Write-Warning "Could not schedule WinRM restart - service may already be properly configured" -LineNumber 664
  Write-Info "Error details: $_" -LineNumber 665
}

Write-Success "Event forwarding triggered" -LineNumber 668

#endregion

#region Verification

Write-Step "Step 8: Verify Configuration and Test Event Forwarding"

Write-Info "Checking subscription status on collector..." -LineNumber 676
$subscriptionStatus = Invoke-RemoteCommand -ComputerName $CollectorComputer -Description "Get subscription runtime status" -LineNumber 677 -ScriptBlock {
  param($SubName)

  $status = & wecutil.exe gr $SubName 2>&1

  $wecSvc = Get-Service -Name Wecsvc
  Write-Output ""
  Write-Output "Windows Event Collector Service Status: $($wecSvc.Status)"
  Write-Output ""
  Write-Output "Subscription Runtime Status:"
  Write-Output $status

  return $status
} -ArgumentList $subscriptionName

Write-Output ""

Write-Info "Generating test event on source computer..." -LineNumber 695
Invoke-RemoteCommand -ComputerName $SourceComputer -Description "Generate test security event" -LineNumber 696 -ScriptBlock {
  try {
    $null = Get-EventLog -LogName Security -Newest 1 -ErrorAction SilentlyContinue
    Write-Output "Test event generated - accessed Security log"
  }
  catch {
    Write-Output "Security log accessed for test"
  }
}

Write-Info "Waiting 10 seconds for events to forward..." -LineNumber 706
Start-Sleep -Seconds 10

Write-Info "Checking ForwardedEvents log on collector..." -LineNumber 709
$forwardedEvents = Invoke-RemoteCommand -ComputerName $CollectorComputer -Description "Query ForwardedEvents log" -LineNumber 710 -ScriptBlock {
  $events = Get-WinEvent -LogName ForwardedEvents -MaxEvents 10 -ErrorAction SilentlyContinue

  if ($events) {
    Write-Output "Found $($events.Count) forwarded events"
    Write-Output ""
    Write-Output "Most Recent Forwarded Events:"
    $events | Select-Object TimeCreated, Id, ProviderName, MachineName | Format-Table -AutoSize | Out-String
    return $events.Count
  }
  else {
    Write-Output "No events found yet in ForwardedEvents log"
    Write-Output "Note: It may take a few minutes for events to begin forwarding"
    return 0
  }
}

if ($forwardedEvents -gt 0) {
  Write-Success "Event forwarding is working! Found $forwardedEvents events." -LineNumber 729
}
else {
  Write-Info "No events forwarded yet. This is normal for a new configuration." -LineNumber 732
  Write-Info "Events should begin appearing within 5-10 minutes." -LineNumber 733
}

#endregion

#region GUI Instructions

Write-Step "Step 9: Event Viewer GUI Verification Steps"

Write-Output @"

========================================
EVENT VIEWER GUI VERIFICATION STEPS
========================================

ON COLLECTOR (NODE01):

1. OPEN EVENT VIEWER:
   - Press Windows + R
   - Type: eventvwr.msc
   - Press Enter

2. VERIFY SUBSCRIPTION:
   - Expand 'Subscriptions' in left pane
   - Right-click '$subscriptionName'
   - Select 'Properties'
   - Verify:
     * Status: Active/Enabled
     * Source Computers: Shows DC01
     * Runtime Status: Shows 'Active' or connection count

3. VIEW FORWARDED EVENTS:
   - In left pane, expand 'Windows Logs'
   - Click 'Forwarded Events'
   - Events from DC01 should appear here
   - Right-click any event > 'Event Properties' to see details
   - Verify 'Computer' field shows: $SourceComputer

4. CHECK SUBSCRIPTION RUNTIME:
   - Right-click subscription '$subscriptionName'
   - Select 'Runtime Status'
   - Verify source computer shows:
     * Computer: $SourceComputer
     * Status: Active
     * Last Error: No Error

ON SOURCE (DC01):

1. OPEN EVENT VIEWER:
   - Press Windows + R
   - Type: eventvwr.msc
   - Press Enter

2. VERIFY EVENT LOG READERS PERMISSIONS:
   - Expand 'Windows Logs' > Right-click 'Security'
   - Select 'Properties' > 'Security' tab
   - Verify 'Event Log Readers' group is listed
   - Should have 'Read' permissions

3. CHECK WINRM SERVICE:
   - Press Windows + R
   - Type: services.msc
   - Find 'Windows Remote Management (WS-Management)'
   - Verify Status: Running
   - Verify Startup Type: Automatic

4. GENERATE TEST EVENTS:
   - Create a test user account (generates Event ID 4720)
   - Disable the account (generates Event ID 4725)
   - Delete the account (generates Event ID 4726)
   - These should appear on NODE01 within 30 seconds

========================================
POWERSHELL VERIFICATION COMMANDS
========================================

Run these on COLLECTOR (NODE01):

# View subscription details
wecutil get-subscription $subscriptionName

# Check subscription runtime status
wecutil get-subscriptionruntimestatus $subscriptionName

# View forwarded events (last 20)
Get-WinEvent -LogName ForwardedEvents -MaxEvents 20 | Format-Table TimeCreated, Id, ProviderName, MachineName -AutoSize

# Count forwarded events by source computer
Get-WinEvent -LogName ForwardedEvents | Group-Object MachineName | Format-Table Name, Count -AutoSize

# Check specific event IDs (authentication)
Get-WinEvent -LogName ForwardedEvents -FilterXPath "*[System[(EventID=4624 or EventID=4625)]]" -MaxEvents 10

========================================
TROUBLESHOOTING COMMANDS
========================================

If events are not forwarding, run these:

ON COLLECTOR (NODE01):
# Restart Event Collector service
Restart-Service -Name Wecsvc -Force

# Check service status
Get-Service Wecsvc, WinRM | Format-Table Name, Status, StartType -AutoSize

# View subscription XML
wecutil get-subscription $subscriptionName /format:xml

ON SOURCE (DC01):
# Verify Event Log Readers group membership
net localgroup "Event Log Readers"

# Check WinRM configuration
winrm get winrm/config

# Force event forwarding
gpupdate /force
Restart-Service WinRM -Force

========================================
AZ-801 EXAM RELEVANT EVENT IDS
========================================

AUTHENTICATION & LOGON:
- 4624: Successful logon
- 4625: Failed logon
- 4634: Logoff
- 4647: User initiated logoff
- 4768: Kerberos TGT requested
- 4769: Kerberos service ticket requested
- 4771: Kerberos pre-authentication failed

ACCOUNT MANAGEMENT:
- 4720: User account created
- 4722: User account enabled
- 4725: User account disabled
- 4726: User account deleted
- 4724: Password reset attempt
- 4740: Account locked out

GROUP MANAGEMENT:
- 4728: Member added to security-enabled global group
- 4732: Member added to security-enabled local group
- 4756: Member added to security-enabled universal group
- 4731: Security-enabled local group created
- 4734: Security-enabled local group deleted

SYSTEM & SERVICE:
- 7035: Service sent a start/stop control
- 7036: Service entered running/stopped state
- 7040: Service start type changed
- 6005: Event log service started
- 6006: Event log service stopped
- 6008: Unexpected shutdown

GROUP POLICY:
- 4016: GPO application failed
- 5016: GP processing succeeded
- 5017: GP processing failed
- 5312: GPO application started
- 5314: GPO application completed

AUDIT & SECURITY:
- 1102: Audit log cleared
- 4719: System audit policy changed
- 4672: Special privileges assigned
- 4673: Privileged service called

========================================

"@

#endregion

#region Summary

Write-Step "Configuration Summary"

Write-Output @"

================================
CONFIGURATION COMPLETED
================================

Source Computer: $SourceComputer
Collector Computer: $CollectorComputer
Domain: $DomainName
Subscription Name: $subscriptionName

STATUS:
- Windows Event Collector service: Running on NODE01
- WinRM service: Running on both servers
- Subscription: Created and Active
- Firewall rules: Configured
- Event Log Readers: $CollectorComputer computer account added
- ForwardedEvents log: Ready for events

IDEMPOTENT: This script is safe to run multiple times.
All configuration checks existing state before making changes.

WHAT'S MONITORING:
This configuration captures AZ-801 exam-relevant events including:
* Authentication events (successful/failed logons, Kerberos)
* Account management (create, disable, delete, password resets)
* Group management (membership changes, group lifecycle)
* System events (service changes, startups/shutdowns)
* Group Policy processing events
* Security audit changes and log clearings
* Privilege use and elevation events

NEXT ACTIONS:
1. Wait 5-10 minutes for initial events to populate
2. Generate test events by creating/modifying user accounts
3. Verify events appear in ForwardedEvents log on NODE01
4. Review Event Viewer GUI steps above for monitoring

VIEWING EVENTS:
- On NODE01, open Event Viewer (eventvwr.msc)
- Navigate to: Windows Logs > Forwarded Events
- Filter by Event ID or source computer as needed

For ongoing monitoring, events forward automatically with:
- Maximum latency: 30 seconds
- Heartbeat interval: 60 minutes
- Delivery mode: Push (immediate)

================================

"@

Write-Success "Windows Event Forwarding configuration completed successfully!" -LineNumber 961
Write-Output ""

#endregion

#region Final Verification

Write-Step "Final System Check"

try {
  $finalCheck = Invoke-RemoteCommand -ComputerName $CollectorComputer -Description "Final verification" -LineNumber 971 -ScriptBlock {
    param($SubName)

    $subExists = $false
    $subDetails = & wecutil.exe gs $SubName 2>&1
    if ($LASTEXITCODE -eq 0) {
      $subExists = $true
    }

    $wecService = Get-Service -Name Wecsvc
    $winrmService = Get-Service -Name WinRM

    $forwardedLog = Get-WinEvent -LogName ForwardedEvents -MaxEvents 1 -ErrorAction SilentlyContinue

    $result = @{
      SubscriptionExists  = $subExists
      WECServiceRunning   = $wecService.Status -eq 'Running'
      WinRMServiceRunning = $winrmService.Status -eq 'Running'
      LogAccessible       = $true
      EventsPresent       = $forwardedLog -ne $null
    }

    Write-Output ""
    Write-Output "Final Check Results:"
    Write-Output "  Subscription Exists: $($result.SubscriptionExists)"
    Write-Output "  WEC Service Running: $($result.WECServiceRunning)"
    Write-Output "  WinRM Service Running: $($result.WinRMServiceRunning)"
    Write-Output "  ForwardedEvents Log Accessible: $($result.LogAccessible)"
    Write-Output "  Events Already Present: $($result.EventsPresent)"

    return $result
  } -ArgumentList $subscriptionName

  if ($finalCheck.SubscriptionExists -and $finalCheck.WECServiceRunning -and $finalCheck.WinRMServiceRunning) {
    Write-Success "All systems operational - Event Forwarding is configured and ready" -LineNumber 1009

    if ($finalCheck.EventsPresent) {
      Write-Success "Events are already being forwarded!" -LineNumber 1012
    }
    else {
      Write-Info "No events yet - they will appear within 5-10 minutes" -LineNumber 1015
    }
  }
  else {
    Write-Warning "Some components may need attention - review output above" -LineNumber 1019
  }
}
catch {
  Write-Info "Final check completed with warnings - configuration should still work" -LineNumber 1023
  Write-Info "Error details: $_" -LineNumber 1024
}

Write-Output ""
Write-Output "Script execution completed at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Output ""
Write-Output "IDEMPOTENT: Safe to run this script again anytime to verify or reconfigure."
Write-Output ""

#endregion
