# Module 24: Troubleshoot Core Services

**Duration:** ~20 minutes

## Learning Objectives

After completing this module, you will be able to:

- Troubleshoot connectivity
- Troubleshoot name resolution
- Troubleshoot Windows Update
- Troubleshoot Time Service
- Troubleshoot deployment failures
- Troubleshoot booting failures

## Topics Covered

### 24.1. Troubleshoot Connectivity
Diagnose and resolve network connectivity issues.

### 24.2. Troubleshoot Name Resolution
Troubleshoot DNS and name resolution problems.

### 24.3. Troubleshoot Windows Update
Resolve Windows Update errors and failures.

### 24.4. Troubleshoot Time Service
Fix time synchronization issues using W32Time.

### 24.5. Troubleshoot Deployment Failures
Diagnose issues with server deployment and provisioning.

### 24.6. Troubleshoot Booting Failures
Recover from boot failures and startup problems.

## Supplemental Resources

- [Network Troubleshooting](https://learn.microsoft.com/en-us/windows-server/networking/technologies/network-subsystem/net-sub-performance-top)
- [DNS Troubleshooting](https://learn.microsoft.com/en-us/windows-server/networking/dns/troubleshoot/troubleshoot-dns-server)
- [Windows Update Troubleshooting](https://learn.microsoft.com/en-us/windows/deployment/update/windows-update-troubleshooting)
- [Time Service](https://learn.microsoft.com/en-us/windows-server/networking/windows-time-service/windows-time-service-top)
- [Boot Configuration](https://learn.microsoft.com/en-us/windows-hardware/drivers/devtest/bcd-boot-options-reference)

## Hands-on Labs

Check the `/labs` subdirectory for hands-on exercises related to this module.

## Notes

- Common tools: ping, tracert, nslookup, Test-NetConnection
- DNS cache can be cleared with `ipconfig /flushdns`
- Windows Update logs are in C:\Windows\Logs\WindowsUpdate
- W32Time service must be running for time sync
- Safe Mode and WinRE help troubleshoot boot issues
