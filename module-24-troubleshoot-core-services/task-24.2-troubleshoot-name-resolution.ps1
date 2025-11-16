<#
.SYNOPSIS
    AZ-801 Module 24 Task 2 - Troubleshoot DNS Name Resolution

.DESCRIPTION
    This script demonstrates DNS troubleshooting techniques for Windows Server environments.
    It covers DNS queries, cache management, server testing, and resolution validation
    using Resolve-DnsName, nslookup equivalents, and cache operations.

.NOTES
    Module: 24 - Troubleshoot Core Services
    Task: 24.2 - Troubleshoot DNS Name Resolution
    Exam: AZ-801 - Configuring Windows Server Hybrid Advanced Services

.LINK
    https://learn.microsoft.com/en-us/windows-server/networking/dns/
#>

#Requires -RunAsAdministrator

# Configuration
$testDomains = @(
    @{Name = "Domain Controller"; FQDN = "dc01.contoso.com"; Type = "A"}
    @{Name = "Web Server"; FQDN = "www.contoso.com"; Type = "A"}
    @{Name = "Mail Server"; FQDN = "mail.contoso.com"; Type = "MX"}
    @{Name = "Microsoft"; FQDN = "microsoft.com"; Type = "A"}
    @{Name = "Azure Portal"; FQDN = "portal.azure.com"; Type = "CNAME"}
    @{Name = "Google DNS"; FQDN = "dns.google"; Type = "A"}
)

#region Current DNS Configuration

Write-Host "`n=== DNS CLIENT CONFIGURATION ===" -ForegroundColor Cyan
Write-Host "Displaying current DNS configuration" -ForegroundColor Yellow

# Get DNS client configuration for all adapters
$dnsConfig = Get-DnsClientServerAddress | Where-Object {$_.ServerAddresses.Count -gt 0}

foreach ($config in $dnsConfig) {
    Write-Host "`nInterface: $($config.InterfaceAlias)" -ForegroundColor Green
    Write-Host "  Address Family: $($config.AddressFamily)" -ForegroundColor White
    Write-Host "  DNS Servers:" -ForegroundColor White

    $config.ServerAddresses | ForEach-Object {
        Write-Host "    - $_" -ForegroundColor Gray

        # Test DNS server responsiveness
        $dnsTest = Test-NetConnection -ComputerName $_ -Port 53 -WarningAction SilentlyContinue
        if ($dnsTest.TcpTestSucceeded) {
            Write-Host "      Status: RESPONDING" -ForegroundColor Green
        } else {
            Write-Host "      Status: NOT RESPONDING" -ForegroundColor Red
        }
    }
}

# Display DNS client cache settings
Write-Host "`nDNS Cache Settings:" -ForegroundColor Green
$dnsCache = Get-DnsClientCache | Measure-Object
Write-Host "  Cached Entries: $($dnsCache.Count)" -ForegroundColor White

#endregion

#region DNS Resolution Tests

Write-Host "`n`n=== DNS RESOLUTION TESTS ===" -ForegroundColor Cyan
Write-Host "Testing DNS resolution for various record types" -ForegroundColor Yellow

foreach ($domain in $testDomains) {
    Write-Host "`nTesting: $($domain.Name) - $($domain.FQDN)" -ForegroundColor Green
    Write-Host "  Record Type: $($domain.Type)" -ForegroundColor White

    try {
        # Resolve-DnsName with specific record type
        $result = Resolve-DnsName -Name $domain.FQDN -Type $domain.Type -ErrorAction Stop

        Write-Host "  Resolution: SUCCESS" -ForegroundColor Green

        foreach ($record in $result) {
            switch ($record.Type) {
                'A' {
                    Write-Host "    IPv4 Address: $($record.IPAddress)" -ForegroundColor White
                    Write-Host "    TTL: $($record.TTL) seconds" -ForegroundColor Gray
                }
                'AAAA' {
                    Write-Host "    IPv6 Address: $($record.IPAddress)" -ForegroundColor White
                    Write-Host "    TTL: $($record.TTL) seconds" -ForegroundColor Gray
                }
                'CNAME' {
                    Write-Host "    Canonical Name: $($record.NameHost)" -ForegroundColor White
                    Write-Host "    TTL: $($record.TTL) seconds" -ForegroundColor Gray
                }
                'MX' {
                    Write-Host "    Mail Server: $($record.NameExchange)" -ForegroundColor White
                    Write-Host "    Preference: $($record.Preference)" -ForegroundColor White
                    Write-Host "    TTL: $($record.TTL) seconds" -ForegroundColor Gray
                }
                'NS' {
                    Write-Host "    Name Server: $($record.NameHost)" -ForegroundColor White
                }
                default {
                    Write-Host "    Data: $($record.Strings -join ', ')" -ForegroundColor White
                }
            }
        }
    }
    catch {
        Write-Host "  Resolution: FAILED" -ForegroundColor Red
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

#endregion

#region Detailed DNS Query (nslookup equivalent)

Write-Host "`n`n=== DETAILED DNS QUERIES ===" -ForegroundColor Cyan
Write-Host "Performing detailed DNS queries (nslookup equivalent)" -ForegroundColor Yellow

# Query specific DNS server
$primaryDNS = (Get-DnsClientServerAddress -AddressFamily IPv4 |
    Where-Object {$_.ServerAddresses.Count -gt 0} |
    Select-Object -First 1).ServerAddresses[0]

if ($primaryDNS) {
    Write-Host "`nQuerying DNS Server: $primaryDNS" -ForegroundColor Green

    $testName = "microsoft.com"
    Write-Host "`nQuerying for: $testName" -ForegroundColor White

    # Query for all records
    try {
        $allRecords = Resolve-DnsName -Name $testName -Server $primaryDNS -ErrorAction Stop

        Write-Host "  Query successful. Records found:" -ForegroundColor Green
        $allRecords | ForEach-Object {
            Write-Host "    Type: $($_.Type) - Name: $($_.Name) - Data: $($_.IPAddress)$($_.NameHost)" -ForegroundColor White
        }
    }
    catch {
        Write-Host "  Query failed: $($_.Exception.Message)" -ForegroundColor Red
    }

    # Query for SOA record (Start of Authority)
    Write-Host "`nQuerying for SOA record:" -ForegroundColor White
    try {
        $soa = Resolve-DnsName -Name $testName -Type SOA -Server $primaryDNS -ErrorAction Stop
        Write-Host "  Primary Name Server: $($soa.PrimaryServer)" -ForegroundColor Green
        Write-Host "  Responsible Person: $($soa.NameAdministrator)" -ForegroundColor White
        Write-Host "  Serial Number: $($soa.SerialNumber)" -ForegroundColor White
    }
    catch {
        Write-Host "  SOA query failed" -ForegroundColor Yellow
    }
}

#endregion

#region DNS Cache Management

Write-Host "`n`n=== DNS CACHE MANAGEMENT ===" -ForegroundColor Cyan
Write-Host "Analyzing and managing DNS client cache" -ForegroundColor Yellow

# Display current DNS cache
Write-Host "`nCurrent DNS Cache Entries:" -ForegroundColor Green
$cacheEntries = Get-DnsClientCache | Select-Object -First 10
if ($cacheEntries) {
    $cacheEntries | Format-Table Entry, RecordName, TimeToLive, Data -AutoSize
} else {
    Write-Host "  Cache is empty" -ForegroundColor Yellow
}

# Display cache statistics
Write-Host "`nCache Statistics:" -ForegroundColor Green
$allCache = Get-DnsClientCache
$cacheStats = @{
    TotalEntries = $allCache.Count
    PositiveEntries = ($allCache | Where-Object {$_.Status -eq 0}).Count
    NegativeEntries = ($allCache | Where-Object {$_.Status -ne 0}).Count
}

Write-Host "  Total Cached Entries: $($cacheStats.TotalEntries)" -ForegroundColor White
Write-Host "  Positive Cache: $($cacheStats.PositiveEntries)" -ForegroundColor Green
Write-Host "  Negative Cache: $($cacheStats.NegativeEntries)" -ForegroundColor Yellow

# Demonstrate cache flush
Write-Host "`nDNS Cache Flush Operation:" -ForegroundColor Green
Write-Host "  Command to flush cache: Clear-DnsClientCache" -ForegroundColor White
Write-Host "  Alternative: ipconfig /flushdns" -ForegroundColor Gray
Write-Host "  (Not executing - demonstration only)" -ForegroundColor Yellow

# Show how to view cache using ipconfig
Write-Host "`nTo display DNS cache using ipconfig:" -ForegroundColor Green
Write-Host "  ipconfig /displaydns | more" -ForegroundColor White

#endregion

#region DNS Server Responsiveness Test

Write-Host "`n`n=== DNS SERVER RESPONSIVENESS ===" -ForegroundColor Cyan
Write-Host "Testing DNS server response times" -ForegroundColor Yellow

$commonDNSServers = @(
    @{Name = "Google DNS 1"; Server = "8.8.8.8"}
    @{Name = "Google DNS 2"; Server = "8.8.4.4"}
    @{Name = "Cloudflare DNS 1"; Server = "1.1.1.1"}
    @{Name = "Cloudflare DNS 2"; Server = "1.0.0.1"}
)

# Add configured DNS servers
$configuredDNS = Get-DnsClientServerAddress -AddressFamily IPv4 |
    Where-Object {$_.ServerAddresses.Count -gt 0} |
    Select-Object -First 1

if ($configuredDNS) {
    $configuredDNS.ServerAddresses | ForEach-Object {
        $commonDNSServers += @{Name = "Configured DNS"; Server = $_}
    }
}

foreach ($dns in $commonDNSServers) {
    Write-Host "`nTesting: $($dns.Name) - $($dns.Server)" -ForegroundColor Green

    # Test connectivity to DNS port
    $portTest = Test-NetConnection -ComputerName $dns.Server -Port 53 -WarningAction SilentlyContinue

    if ($portTest.TcpTestSucceeded) {
        # Measure DNS query time
        $queryStart = Get-Date
        try {
            $queryResult = Resolve-DnsName -Name "microsoft.com" -Server $dns.Server -Type A -ErrorAction Stop
            $queryEnd = Get-Date
            $queryTime = ($queryEnd - $queryStart).TotalMilliseconds

            Write-Host "  Status: RESPONDING" -ForegroundColor Green
            Write-Host "  Query Time: $([math]::Round($queryTime, 2)) ms" -ForegroundColor White
            Write-Host "  Records Returned: $($queryResult.Count)" -ForegroundColor White
        }
        catch {
            Write-Host "  Status: ERROR" -ForegroundColor Red
            Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    else {
        Write-Host "  Status: NOT REACHABLE" -ForegroundColor Red
    }
}

#endregion

#region DNS Troubleshooting Tools

Write-Host "`n`n=== DNS TROUBLESHOOTING PROCEDURES ===" -ForegroundColor Cyan

$troubleshootingGuide = @"

Common DNS Issues and Solutions:

1. NAME RESOLUTION FAILS
   - Check DNS server configuration: Get-DnsClientServerAddress
   - Verify DNS server is reachable: Test-NetConnection -ComputerName DNS_IP -Port 53
   - Test resolution: Resolve-DnsName -Name hostname -Server DNS_IP
   - Clear cache: Clear-DnsClientCache

2. INTERMITTENT RESOLUTION FAILURES
   - Check for negative caching: Get-DnsClientCache | Where {`$_.Status -ne 0}
   - Verify DNS server load and performance
   - Check network connectivity to DNS servers
   - Review DNS server logs

3. SLOW DNS RESOLUTION
   - Test multiple DNS servers: Resolve-DnsName -Name test.com -Server SERVER
   - Check DNS server response time (should be < 100ms)
   - Consider closer DNS servers or caching
   - Review TTL values (too low = frequent queries)

4. WRONG IP ADDRESS RETURNED
   - Clear local cache: Clear-DnsClientCache
   - Verify correct DNS server: Get-DnsClientServerAddress
   - Check hosts file: Get-Content C:\Windows\System32\drivers\etc\hosts
   - Test directly against authoritative DNS

5. CANNOT RESOLVE INTERNAL NAMES
   - Check DNS suffix list: Get-DnsClientGlobalSetting
   - Verify domain membership: (Get-WmiObject Win32_ComputerSystem).Domain
   - Check search suffixes: Get-DnsClient
   - Test FQDN resolution vs short name

USEFUL COMMANDS:
- Resolve-DnsName -Name hostname -Type A -Server DNS_IP
- Clear-DnsClientCache (flush cache)
- Get-DnsClientCache | Format-Table (view cache)
- Test-NetConnection -ComputerName DNS_IP -Port 53
- ipconfig /flushdns (alternative cache flush)
- ipconfig /displaydns (alternative cache view)
- nslookup hostname DNS_IP (interactive queries)
- Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses "8.8.8.8","8.8.4.4"

TESTING SPECIFIC RECORD TYPES:
- Resolve-DnsName -Name domain.com -Type A (IPv4)
- Resolve-DnsName -Name domain.com -Type AAAA (IPv6)
- Resolve-DnsName -Name domain.com -Type MX (Mail)
- Resolve-DnsName -Name domain.com -Type NS (Name Servers)
- Resolve-DnsName -Name domain.com -Type SOA (Authority)
- Resolve-DnsName -Name domain.com -Type TXT (Text records)
- Resolve-DnsName -Name domain.com -Type CNAME (Aliases)

"@

Write-Host $troubleshootingGuide -ForegroundColor White

#endregion

Write-Host "`n=== DNS TROUBLESHOOTING COMPLETE ===" -ForegroundColor Green
Write-Host "Review the results above for any DNS issues`n" -ForegroundColor Yellow
