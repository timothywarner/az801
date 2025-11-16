<#
.SYNOPSIS
    AZ-801 Module 24 Task 1 - Troubleshoot Network Connectivity

.DESCRIPTION
    This script demonstrates comprehensive network connectivity troubleshooting techniques
    for Windows Server environments. It covers testing connections, diagnosing routing issues,
    and analyzing network paths using Test-NetConnection, Test-Connection, traceroute, and more.

.NOTES
    Module: 24 - Troubleshoot Core Services
    Task: 24.1 - Troubleshoot Network Connectivity
    Exam: AZ-801 - Configuring Windows Server Hybrid Advanced Services

.LINK
    https://learn.microsoft.com/en-us/windows-server/networking/technologies/
#>

#Requires -RunAsAdministrator

# Configuration
$targetServers = @(
    @{Name = "Domain Controller"; Host = "dc01.contoso.com"; Port = 389}
    @{Name = "Web Server"; Host = "web01.contoso.com"; Port = 443}
    @{Name = "SQL Server"; Host = "sql01.contoso.com"; Port = 1433}
    @{Name = "File Server"; Host = "fs01.contoso.com"; Port = 445}
    @{Name = "DNS Server"; Host = "8.8.8.8"; Port = 53}
    @{Name = "Azure Public"; Host = "portal.azure.com"; Port = 443}
)

#region Basic Connectivity Testing

Write-Host "`n=== BASIC CONNECTIVITY TESTS ===" -ForegroundColor Cyan
Write-Host "Testing basic network connectivity using Test-Connection (ICMP)" -ForegroundColor Yellow

foreach ($server in $targetServers) {
    Write-Host "`nTesting: $($server.Name) - $($server.Host)" -ForegroundColor Green

    try {
        # Test-Connection (ping equivalent)
        $pingResult = Test-Connection -ComputerName $server.Host -Count 4 -ErrorAction Stop

        $avgLatency = ($pingResult | Measure-Object -Property ResponseTime -Average).Average
        $successRate = ($pingResult.Count / 4) * 100

        Write-Host "  Status: SUCCESS" -ForegroundColor Green
        Write-Host "  Packets: Sent=4, Received=$($pingResult.Count), Lost=$(4 - $pingResult.Count)" -ForegroundColor White
        Write-Host "  Average Latency: $([math]::Round($avgLatency, 2)) ms" -ForegroundColor White

        # Display detailed results
        $pingResult | ForEach-Object {
            Write-Host "    Reply from $($_.Address): bytes=32 time=$($_.ResponseTime)ms TTL=$($_.TimeToLive)" -ForegroundColor Gray
        }
    }
    catch {
        Write-Host "  Status: FAILED" -ForegroundColor Red
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

#endregion

#region Advanced Port Connectivity Testing

Write-Host "`n`n=== PORT CONNECTIVITY TESTS ===" -ForegroundColor Cyan
Write-Host "Testing specific port connectivity using Test-NetConnection" -ForegroundColor Yellow

foreach ($server in $targetServers) {
    Write-Host "`nTesting: $($server.Name) - $($server.Host):$($server.Port)" -ForegroundColor Green

    $portTest = Test-NetConnection -ComputerName $server.Host -Port $server.Port -WarningAction SilentlyContinue

    Write-Host "  Ping Success: $($portTest.PingSucceeded)" -ForegroundColor $(if($portTest.PingSucceeded){'Green'}else{'Red'})
    Write-Host "  TCP Port $($server.Port): $($portTest.TcpTestSucceeded)" -ForegroundColor $(if($portTest.TcpTestSucceeded){'Green'}else{'Red'})
    Write-Host "  Remote Address: $($portTest.RemoteAddress)" -ForegroundColor White

    if ($portTest.TcpTestSucceeded) {
        Write-Host "  Service Status: LISTENING" -ForegroundColor Green
    }
    else {
        Write-Host "  Service Status: NOT REACHABLE" -ForegroundColor Red
        Write-Host "  Possible issues: Firewall blocking, service not running, wrong port" -ForegroundColor Yellow
    }
}

#endregion

#region Network Route Analysis

Write-Host "`n`n=== ROUTE ANALYSIS ===" -ForegroundColor Cyan
Write-Host "Analyzing network routes" -ForegroundColor Yellow

# Display local routing table
Write-Host "`nLocal Routing Table:" -ForegroundColor Green
Get-NetRoute | Where-Object {$_.DestinationPrefix -ne '::/0'} |
    Select-Object DestinationPrefix, NextHop, InterfaceAlias, RouteMetric |
    Sort-Object RouteMetric |
    Format-Table -AutoSize

# Get default gateway
Write-Host "`nDefault Gateway Configuration:" -ForegroundColor Green
$defaultGateway = Get-NetRoute -DestinationPrefix "0.0.0.0/0" | Select-Object -First 1
if ($defaultGateway) {
    Write-Host "  Gateway: $($defaultGateway.NextHop)" -ForegroundColor White
    Write-Host "  Interface: $($defaultGateway.InterfaceAlias)" -ForegroundColor White
    Write-Host "  Metric: $($defaultGateway.RouteMetric)" -ForegroundColor White
}

#endregion

#region Traceroute Analysis

Write-Host "`n`n=== TRACEROUTE ANALYSIS ===" -ForegroundColor Cyan
Write-Host "Tracing route to external target" -ForegroundColor Yellow

# Traceroute to Azure portal
$traceTarget = "portal.azure.com"
Write-Host "`nTracing route to $traceTarget" -ForegroundColor Green
Write-Host "This may take a moment..." -ForegroundColor Yellow

# Use Test-NetConnection with TraceRoute
$traceResult = Test-NetConnection -ComputerName $traceTarget -TraceRoute -WarningAction SilentlyContinue

if ($traceResult.TraceRoute) {
    Write-Host "`nRoute hops:" -ForegroundColor White
    $hopNumber = 1
    foreach ($hop in $traceResult.TraceRoute) {
        Write-Host "  $hopNumber. $hop" -ForegroundColor Gray
        $hopNumber++
    }
}

# Alternative: Using tracert.exe for more detailed output
Write-Host "`nAlternative: Using tracert.exe" -ForegroundColor Green
Write-Host "Command: tracert -d -h 15 $traceTarget" -ForegroundColor Gray
Write-Host "(Use 'tracert -d -h 15 $traceTarget' for detailed trace)" -ForegroundColor Yellow

#endregion

#region IP Configuration Analysis

Write-Host "`n`n=== IP CONFIGURATION ANALYSIS ===" -ForegroundColor Cyan
Write-Host "Analyzing network adapter configuration" -ForegroundColor Yellow

$adapters = Get-NetIPAddress | Where-Object {$_.InterfaceAlias -notlike "*Loopback*"} |
    Group-Object InterfaceAlias

foreach ($adapter in $adapters) {
    Write-Host "`nAdapter: $($adapter.Name)" -ForegroundColor Green

    foreach ($ip in $adapter.Group) {
        Write-Host "  Address Family: $($ip.AddressFamily)" -ForegroundColor White
        Write-Host "  IP Address: $($ip.IPAddress)" -ForegroundColor White
        Write-Host "  Prefix Length: $($ip.PrefixLength)" -ForegroundColor White
        Write-Host "  Status: $($ip.AddressState)" -ForegroundColor $(if($ip.AddressState -eq 'Preferred'){'Green'}else{'Yellow'})
    }

    # Get DNS servers for this interface
    $dnsServers = Get-DnsClientServerAddress -InterfaceAlias $adapter.Name -AddressFamily IPv4 -ErrorAction SilentlyContinue
    if ($dnsServers -and $dnsServers.ServerAddresses) {
        Write-Host "  DNS Servers: $($dnsServers.ServerAddresses -join ', ')" -ForegroundColor White
    }
}

#endregion

#region Network Diagnostics

Write-Host "`n`n=== NETWORK DIAGNOSTICS ===" -ForegroundColor Cyan
Write-Host "Running network diagnostic checks" -ForegroundColor Yellow

# Check for duplicate IP addresses
Write-Host "`nChecking for IP conflicts:" -ForegroundColor Green
$ipConfig = Get-NetIPConfiguration
$duplicateIPs = $ipConfig | Group-Object IPv4Address | Where-Object {$_.Count -gt 1}

if ($duplicateIPs) {
    Write-Host "  WARNING: Duplicate IP addresses detected!" -ForegroundColor Red
    $duplicateIPs | ForEach-Object {
        Write-Host "    IP $($_.Name) is assigned to multiple interfaces" -ForegroundColor Yellow
    }
}
else {
    Write-Host "  No IP conflicts detected" -ForegroundColor Green
}

# Check network adapter status
Write-Host "`nNetwork Adapter Status:" -ForegroundColor Green
Get-NetAdapter | Where-Object {$_.InterfaceDescription -notlike "*Loopback*"} |
    Select-Object Name, Status, LinkSpeed, MediaType |
    Format-Table -AutoSize

# Check Windows Firewall status
Write-Host "Windows Firewall Status:" -ForegroundColor Green
Get-NetFirewallProfile | Select-Object Name, Enabled | Format-Table -AutoSize

#endregion

#region Path Quality Test

Write-Host "`n=== NETWORK PATH QUALITY TEST ===" -ForegroundColor Cyan
Write-Host "Testing network path quality (simplified pathping)" -ForegroundColor Yellow

$pathTestTarget = "8.8.8.8"
Write-Host "`nTesting path to $pathTestTarget with multiple pings" -ForegroundColor Green

$pathResults = @()
for ($i = 1; $i -le 10; $i++) {
    $result = Test-Connection -ComputerName $pathTestTarget -Count 1 -ErrorAction SilentlyContinue
    if ($result) {
        $pathResults += $result
    }
    Start-Sleep -Milliseconds 100
}

if ($pathResults.Count -gt 0) {
    $avgLatency = ($pathResults | Measure-Object -Property ResponseTime -Average).Average
    $minLatency = ($pathResults | Measure-Object -Property ResponseTime -Minimum).Minimum
    $maxLatency = ($pathResults | Measure-Object -Property ResponseTime -Maximum).Maximum
    $successRate = ($pathResults.Count / 10) * 100

    Write-Host "`nPath Quality Results:" -ForegroundColor White
    Write-Host "  Success Rate: $successRate%" -ForegroundColor $(if($successRate -eq 100){'Green'}else{'Yellow'})
    Write-Host "  Average Latency: $([math]::Round($avgLatency, 2)) ms" -ForegroundColor White
    Write-Host "  Min Latency: $minLatency ms" -ForegroundColor White
    Write-Host "  Max Latency: $maxLatency ms" -ForegroundColor White
    Write-Host "  Jitter: $($maxLatency - $minLatency) ms" -ForegroundColor White

    if ($maxLatency - $minLatency -gt 50) {
        Write-Host "  WARNING: High jitter detected - network may be unstable" -ForegroundColor Yellow
    }
}

#endregion

#region Troubleshooting Recommendations

Write-Host "`n`n=== TROUBLESHOOTING RECOMMENDATIONS ===" -ForegroundColor Cyan

$recommendations = @"

Common Network Connectivity Issues and Solutions:

1. PING FAILS BUT SERVICE RESPONDS
   - ICMP may be blocked by firewall
   - Use Test-NetConnection with -Port parameter instead
   - Check: Get-NetFirewallRule | Where-Object {`$_.DisplayName -like "*ICMP*"}

2. INTERMITTENT CONNECTIVITY
   - Check for network cable/wireless issues
   - Review adapter events: Get-WinEvent -LogName System -MaxEvents 50
   - Test with: Test-Connection -Count 100 -Delay 1

3. SLOW NETWORK PERFORMANCE
   - Check interface speed: Get-NetAdapter | Select Name, LinkSpeed
   - Verify duplex settings: Get-NetAdapterAdvancedProperty
   - Monitor counters: Get-Counter '\Network Interface(*)\*'

4. ROUTING PROBLEMS
   - Verify default gateway: Get-NetRoute -DestinationPrefix "0.0.0.0/0"
   - Add static route: New-NetRoute -DestinationPrefix "10.0.0.0/8" -NextHop "192.168.1.1"
   - Check: route print

5. FIREWALL BLOCKING
   - Check rules: Get-NetFirewallRule | Where {`$_.Enabled -eq 'True'}
   - Test specific port: Test-NetConnection -Port 443
   - Create allow rule: New-NetFirewallRule -DisplayName "Allow" -Direction Inbound -LocalPort 80 -Protocol TCP -Action Allow

USEFUL COMMANDS:
- Test-NetConnection -ComputerName host -Port 443 -InformationLevel Detailed
- Test-Connection -ComputerName host -Count 4
- Get-NetTCPConnection -State Established
- Get-NetIPConfiguration -Detailed
- tracert hostname
- pathping hostname (detailed path analysis)
- Get-NetAdapter | Reset-NetAdapter (reset adapter)

"@

Write-Host $recommendations -ForegroundColor White

#endregion

Write-Host "`n=== CONNECTIVITY TROUBLESHOOTING COMPLETE ===" -ForegroundColor Green
Write-Host "Review the results above for any connectivity issues`n" -ForegroundColor Yellow
