<#
.SYNOPSIS
    Task 22.4 - Use System Insights

.DESCRIPTION
    Demo script for AZ-801 Module 22: Monitor Windows Server Performance
    Shows predictive analytics with System Insights for capacity forecasting and
    anomaly detection in Windows Server 2019+.

.NOTES
    Module: Module 22 - Monitor Windows Server Performance
    Task: 22.4 - Use System Insights
    Prerequisites: Windows Server 2019+, Administrative privileges
    PowerShell Version: 5.1+
#>

#Requires -RunAsAdministrator

$ErrorActionPreference = 'Stop'
Write-Host "=== AZ-801 Module 22: Task 22.4 - Use System Insights ===" -ForegroundColor Cyan
Write-Host ""

try {
    # Check if System Insights is available
    Write-Host "[Step 1] Check System Insights Availability" -ForegroundColor Yellow

    $osVersion = [System.Environment]::OSVersion.Version
    $buildNumber = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').CurrentBuildNumber

    Write-Host "Operating System Version: $osVersion" -ForegroundColor Cyan
    Write-Host "Build Number: $buildNumber" -ForegroundColor Cyan

    if ($buildNumber -ge 17763) {
        Write-Host "[OK] System Insights is supported (Windows Server 2019+)" -ForegroundColor Green
    } else {
        Write-Host "[WARNING] System Insights requires Windows Server 2019 or later" -ForegroundColor Yellow
        Write-Host "          This demo will show concepts and commands" -ForegroundColor Yellow
    }
    Write-Host ""

    # Check if System Insights feature is installed
    Write-Host "[Step 2] Verify System Insights Installation" -ForegroundColor Yellow

    $siFeature = Get-WindowsFeature -Name System-Insights -ErrorAction SilentlyContinue

    if ($siFeature) {
        Write-Host "Feature Name: $($siFeature.Name)" -ForegroundColor Cyan
        Write-Host "Display Name: $($siFeature.DisplayName)" -ForegroundColor Cyan
        Write-Host "Install State: $($siFeature.InstallState)" -ForegroundColor Cyan

        if ($siFeature.InstallState -ne 'Installed') {
            Write-Host "`nTo install System Insights:" -ForegroundColor Yellow
            Write-Host "  Install-WindowsFeature -Name System-Insights -IncludeManagementTools" -ForegroundColor White
        } else {
            Write-Host "[SUCCESS] System Insights is installed" -ForegroundColor Green
        }
    } else {
        Write-Host "[INFO] System Insights feature check requires Windows Server 2019+" -ForegroundColor Yellow
    }
    Write-Host ""

    # Get System Insights capabilities
    Write-Host "[Step 3] List System Insights Capabilities" -ForegroundColor Yellow

    Write-Host "Attempting to enumerate System Insights capabilities..." -ForegroundColor Cyan

    try {
        $capabilities = Get-InsightsCapability -ErrorAction Stop

        if ($capabilities) {
            Write-Host "`nAvailable Capabilities:" -ForegroundColor Cyan
            $capabilities | Format-Table Name, State, @{Name='LastRun';Expression={$_.LastUpdatedTime}} -AutoSize
        }
    } catch {
        Write-Host "[INFO] System Insights cmdlets require Windows Server 2019+ with feature installed" -ForegroundColor Yellow
        Write-Host "`nBuilt-in Capabilities:" -ForegroundColor Cyan
        $builtInCapabilities = @(
            'CPU capacity forecasting'
            'Networking capacity forecasting'
            'Total storage consumption forecasting'
            'Volume consumption forecasting'
        )
        $builtInCapabilities | ForEach-Object { Write-Host "  - $_" -ForegroundColor White }
    }
    Write-Host ""

    # Configure System Insights
    Write-Host "[Step 4] System Insights Configuration" -ForegroundColor Yellow

    Write-Host "Key Configuration Parameters:" -ForegroundColor Cyan
    Write-Host "  - Schedule: When predictions are generated" -ForegroundColor White
    Write-Host "  - Actions: Automated responses to predictions" -ForegroundColor White
    Write-Host "  - Remediation: How to address predicted issues" -ForegroundColor White
    Write-Host ""

    Write-Host "Example: Enable and configure CPU capacity forecasting" -ForegroundColor Cyan
    Write-Host "  Enable-InsightsCapability -Name 'CPU capacity forecasting'" -ForegroundColor Gray
    Write-Host "  Set-InsightsCapabilitySchedule -Name 'CPU capacity forecasting' -Daily -DaysOfWeek Monday,Wednesday,Friday -At 03:00" -ForegroundColor Gray
    Write-Host ""

    # Demonstrate capability management
    Write-Host "[Step 5] Capability Management Commands" -ForegroundColor Yellow

    Write-Host "Enable a capability:" -ForegroundColor Cyan
    Write-Host "  Enable-InsightsCapability -Name 'Volume consumption forecasting'" -ForegroundColor White
    Write-Host ""

    Write-Host "Disable a capability:" -ForegroundColor Cyan
    Write-Host "  Disable-InsightsCapability -Name 'Volume consumption forecasting'" -ForegroundColor White
    Write-Host ""

    Write-Host "Run prediction immediately:" -ForegroundColor Cyan
    Write-Host "  Invoke-InsightsCapability -Name 'CPU capacity forecasting'" -ForegroundColor White
    Write-Host ""

    Write-Host "Get prediction results:" -ForegroundColor Cyan
    Write-Host "  Get-InsightsCapabilityResult -Name 'CPU capacity forecasting'" -ForegroundColor White
    Write-Host ""

    # Scheduling predictions
    Write-Host "[Step 6] Schedule Predictions" -ForegroundColor Yellow

    Write-Host "Daily schedule:" -ForegroundColor Cyan
    Write-Host "  Set-InsightsCapabilitySchedule -Name 'CPU capacity forecasting' -Daily -At 02:00" -ForegroundColor White
    Write-Host ""

    Write-Host "Weekly schedule:" -ForegroundColor Cyan
    Write-Host "  Set-InsightsCapabilitySchedule -Name 'Networking capacity forecasting' ``" -ForegroundColor White
    Write-Host "    -Daily -DaysOfWeek Sunday,Wednesday -At 03:00" -ForegroundColor White
    Write-Host ""

    Write-Host "Default schedule (runs every hour):" -ForegroundColor Cyan
    Write-Host "  Set-InsightsCapabilitySchedule -Name 'Volume consumption forecasting' -Default" -ForegroundColor White
    Write-Host ""

    # Actions and remediation
    Write-Host "[Step 7] Configure Actions and Remediation" -ForegroundColor Yellow

    Write-Host "Add PowerShell script action:" -ForegroundColor Cyan
    Write-Host "  Add-InsightsCapabilityAction -Name 'Volume consumption forecasting' ``" -ForegroundColor White
    Write-Host "    -Type Action ``" -ForegroundColor White
    Write-Host "    -Action { param(`$InsightsCapability, `$Prediction) ``" -ForegroundColor White
    Write-Host "      Send-MailMessage -To 'admin@contoso.com' ``" -ForegroundColor White
    Write-Host "        -Subject 'Storage Alert' ``" -ForegroundColor White
    Write-Host "        -Body `"Predicted storage issue: `$Prediction`" }" -ForegroundColor White
    Write-Host ""

    Write-Host "Configure Windows Event Log action:" -ForegroundColor Cyan
    Write-Host "  Add-InsightsCapabilityAction -Name 'CPU capacity forecasting' ``" -ForegroundColor White
    Write-Host "    -Type WindowsEvent ``" -ForegroundColor White
    Write-Host "    -WindowsEventSourceName 'System Insights'" -ForegroundColor White
    Write-Host ""

    # View prediction results
    Write-Host "[Step 8] Analyzing Prediction Results" -ForegroundColor Yellow

    Write-Host "Example prediction result structure:" -ForegroundColor Cyan

    $samplePrediction = [PSCustomObject]@{
        CapabilityName = 'Volume consumption forecasting'
        Status = 'Ok'
        ForecastingTime = Get-Date
        LastUpdatedTime = (Get-Date).AddHours(-2)
        PredictedValue = '950 GB'
        CurrentValue = '750 GB'
        Threshold = '900 GB'
        DaysToThreshold = 14
        Description = 'Predicted to reach 90% capacity in 14 days'
    }

    $samplePrediction | Format-List
    Write-Host ""

    # Integration with Windows Admin Center
    Write-Host "[Step 9] Integration with Management Tools" -ForegroundColor Yellow

    Write-Host "Windows Admin Center Integration:" -ForegroundColor Cyan
    Write-Host "  - View predictions in WAC System Insights extension" -ForegroundColor White
    Write-Host "  - Configure capabilities through GUI" -ForegroundColor White
    Write-Host "  - Historical prediction tracking" -ForegroundColor White
    Write-Host "  - Visualization of trends" -ForegroundColor White
    Write-Host ""

    Write-Host "PowerShell Management:" -ForegroundColor Cyan
    Write-Host "  - Get-InsightsCapability: List all capabilities" -ForegroundColor White
    Write-Host "  - Enable/Disable-InsightsCapability: Manage capability state" -ForegroundColor White
    Write-Host "  - Invoke-InsightsCapability: Run predictions on-demand" -ForegroundColor White
    Write-Host "  - Get-InsightsCapabilityResult: View prediction results" -ForegroundColor White
    Write-Host "  - Set-InsightsCapabilitySchedule: Configure prediction schedule" -ForegroundColor White
    Write-Host "  - Add/Remove-InsightsCapabilityAction: Manage automated actions" -ForegroundColor White
    Write-Host ""

    # Best practices
    Write-Host "[Step 10] Capacity Planning Workflow" -ForegroundColor Yellow

    Write-Host "1. Enable forecasting capabilities:" -ForegroundColor Cyan
    Write-Host "   Enable-InsightsCapability -Name 'CPU capacity forecasting'" -ForegroundColor Gray
    Write-Host "   Enable-InsightsCapability -Name 'Volume consumption forecasting'" -ForegroundColor Gray
    Write-Host ""

    Write-Host "2. Configure schedules (allow data collection period):" -ForegroundColor Cyan
    Write-Host "   Set-InsightsCapabilitySchedule -Name 'CPU capacity forecasting' -Default" -ForegroundColor Gray
    Write-Host ""

    Write-Host "3. Wait for initial predictions (requires historical data):" -ForegroundColor Cyan
    Write-Host "   # Typically 24-48 hours for meaningful predictions" -ForegroundColor Gray
    Write-Host ""

    Write-Host "4. Review predictions regularly:" -ForegroundColor Cyan
    Write-Host "   Get-InsightsCapability | ForEach-Object {" -ForegroundColor Gray
    Write-Host "     Get-InsightsCapabilityResult -Name `$_.Name" -ForegroundColor Gray
    Write-Host "   }" -ForegroundColor Gray
    Write-Host ""

    Write-Host "5. Set up automated actions:" -ForegroundColor Cyan
    Write-Host "   Add-InsightsCapabilityAction -Name 'Volume consumption forecasting' ``" -ForegroundColor Gray
    Write-Host "     -Type Action -Action { # Remediation script }" -ForegroundColor Gray
    Write-Host ""

    # Monitoring and alerting
    Write-Host "[Step 11] Monitoring System Insights Status" -ForegroundColor Yellow

    Write-Host "Check capability status:" -ForegroundColor Cyan
    $statusCheck = @'
$capabilities = Get-InsightsCapability
foreach ($cap in $capabilities) {
    $result = Get-InsightsCapabilityResult -Name $cap.Name
    [PSCustomObject]@{
        Capability = $cap.Name
        State = $cap.State
        LastRun = $cap.LastUpdatedTime
        Status = $result.Status
        Description = $result.Description
    }
}
'@
    Write-Host $statusCheck -ForegroundColor Gray
    Write-Host ""

    # Alternative: Manual capacity planning
    Write-Host "[Step 12] Manual Capacity Planning (Alternative Approach)" -ForegroundColor Yellow

    Write-Host "Collecting current capacity metrics..." -ForegroundColor Cyan

    # CPU capacity
    $cpuData = @()
    for ($i = 1; $i -le 5; $i++) {
        $cpu = Get-Counter '\Processor(_Total)\% Processor Time'
        $cpuData += $cpu.CounterSamples.CookedValue
        Start-Sleep -Seconds 1
    }
    $avgCPU = ($cpuData | Measure-Object -Average).Average

    # Memory capacity
    $totalMem = (Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory
    $availMem = (Get-Counter '\Memory\Available MBytes').CounterSamples.CookedValue
    $memUsagePercent = (($totalMem / 1MB - $availMem) / ($totalMem / 1MB)) * 100

    # Disk capacity
    $volumes = Get-Volume | Where-Object { $_.DriveLetter -ne $null }

    Write-Host "`nCurrent Capacity Status:" -ForegroundColor Cyan
    Write-Host "  CPU Average: $([math]::Round($avgCPU, 2))%" -ForegroundColor White
    Write-Host "  Memory Usage: $([math]::Round($memUsagePercent, 2))%" -ForegroundColor White
    Write-Host "  Disk Volumes:" -ForegroundColor White

    foreach ($vol in $volumes) {
        $usedPercent = (($vol.Size - $vol.SizeRemaining) / $vol.Size) * 100
        $freeGB = [math]::Round($vol.SizeRemaining / 1GB, 2)
        Write-Host "    - Drive $($vol.DriveLetter): $([math]::Round($usedPercent, 2))% used, $freeGB GB free" -ForegroundColor White
    }
    Write-Host ""

    Write-Host "[INFO] System Insights Best Practices:" -ForegroundColor Cyan
    Write-Host "  - Allow sufficient time for data collection (24-48 hours minimum)" -ForegroundColor White
    Write-Host "  - Review predictions regularly to validate accuracy" -ForegroundColor White
    Write-Host "  - Configure automated actions for proactive remediation" -ForegroundColor White
    Write-Host "  - Use predictions for capacity planning and budgeting" -ForegroundColor White
    Write-Host "  - Integrate with monitoring and alerting systems" -ForegroundColor White
    Write-Host "  - Document prediction trends for long-term planning" -ForegroundColor White
    Write-Host "  - Test remediation actions before deploying to production" -ForegroundColor White
    Write-Host ""

    Write-Host "[INFO] Common Use Cases:" -ForegroundColor Cyan
    Write-Host "  - Predict when storage volumes will reach capacity" -ForegroundColor White
    Write-Host "  - Forecast CPU utilization for capacity planning" -ForegroundColor White
    Write-Host "  - Anticipate network bandwidth requirements" -ForegroundColor White
    Write-Host "  - Identify trends before they become problems" -ForegroundColor White
    Write-Host "  - Automate capacity expansion workflows" -ForegroundColor White
    Write-Host ""

} catch {
    Write-Host "[ERROR] $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

Write-Host "Demo completed successfully!" -ForegroundColor Green
Write-Host "Next Steps: Enable System Insights capabilities and configure prediction schedules" -ForegroundColor Yellow
