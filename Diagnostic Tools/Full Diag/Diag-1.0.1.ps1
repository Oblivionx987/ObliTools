<#
.SYNOPSIS
    Collect extensive diagnostic information from the local machine and output an interactive HTML report.

.DESCRIPTION
    This script gathers and displays in a collapsible HTML report:
      1. System Information (computer, BIOS, OS, CPU, memory, uptime).
      2. Motherboard Information.
      3. GPU (Graphics Adapter) Details.
      4. Physical Memory Modules.
      5. Installed Software (queried via the registry instead of Win32_Product).
      6. Installed Hotfixes / Updates.
      7. Security Policies (machine and user scope via gpresult).
      8. Disk Usage.
      9. SMART Disk Health.
      10. Network Configuration (including DNS settings).
      11. All Services.
      12. Scheduled Tasks.
      13. Local Users.
      14. Local Groups.
      15. Environment Variables.
      16. Recent System Errors from the Event Log.
      17. Startup Applications.
      18. Top Processes by CPU and Memory usage.
      19. Windows Defender/Antivirus Status.
      20. Performance Metrics (CPU load, available memory, disk I/O).
      21. An Error Log (if any issues were encountered).

    The HTML report is interactive with a table of contents and collapsible sections.

.NOTES
    - Requires elevated privileges (run as Administrator).
    - Compatible with Windows 10/11, Server 2016/2019/2022 (PowerShell 5.1+).

.EXAMPLE
    .\Collect-Diagnostics-Extended.ps1 -OutputPath "C:\Temp\MyDiag.html"
#>

[CmdletBinding()]
param(
    [string]$OutputPath = "C:\Temp\$env:COMPUTERNAME`_diag.html"
)

# Create an array to log any errors encountered in the various sections
$global:ErrorLog = @()

Write-Host "`nStarting extended diagnostics collection...`n"

# Optimize redundant operations by caching frequently used data
$now = Get-Date
$compSys  = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction SilentlyContinue
$operSys  = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction SilentlyContinue
$biosInfo = Get-CimInstance -ClassName Win32_BIOS -ErrorAction SilentlyContinue
$cpuInfo  = Get-CimInstance -ClassName Win32_Processor -ErrorAction SilentlyContinue

$uptime = if ($operSys) { $now - ([Management.ManagementDateTimeConverter]::ToDateTime($operSys.LastBootUpTime)) } else { $null }
$uptimeFormatted = if ($uptime) { "{0} days, {1} hours, {2} minutes, {3} seconds" -f $uptime.Days, $uptime.Hours, $uptime.Minutes, $uptime.Seconds } else { "N/A" }

# Ensure all collected data is utilized
$systemInfo = if ($compSys -and $operSys -and $biosInfo -and $cpuInfo) {
    [PSCustomObject]@{
        ComputerName          = $compSys.Name
        Manufacturer          = $compSys.Manufacturer
        Model                 = $compSys.Model
        SerialNumber          = $biosInfo.SerialNumber
        BIOS_Version          = $biosInfo.SMBIOSBIOSVersion
        BIOS_ReleaseDate      = ([Management.ManagementDateTimeConverter]::ToDateTime($biosInfo.ReleaseDate))
        OSName                = $operSys.Caption
        OSVersion             = $operSys.Version
        SystemType            = $compSys.SystemType
        CPU_Name              = $cpuInfo.Name
        CPU_Cores             = $cpuInfo.NumberOfCores
        CPU_LogicalProcessors = $cpuInfo.NumberOfLogicalProcessors
        CPU_MaxClockSpeedMHz  = $cpuInfo.MaxClockSpeed
        TotalMemoryGB         = [math]::Round($operSys.TotalVisibleMemorySize / 1MB, 2)
        FreeMemoryGB          = [math]::Round($operSys.FreePhysicalMemory / 1MB, 2)
        SystemUptime          = $uptimeFormatted
    }
} else {
    $global:ErrorLog += "Failed to collect complete system information."
    $null
}

# Use parallel processing where possible (e.g., for collecting data from multiple sources)
$tasks = @{
    "BaseBoard" = {
        Get-CimInstance -ClassName Win32_BaseBoard -ErrorAction SilentlyContinue |
        Select-Object Manufacturer, Product, Version, SerialNumber
    }
    "GPUInfo" = {
        Get-CimInstance -ClassName Win32_VideoController -ErrorAction SilentlyContinue |
        Select-Object Name, DriverVersion, VideoModeDescription
    }
    "MemoryModules" = {
        Get-CimInstance -ClassName Win32_PhysicalMemory -ErrorAction SilentlyContinue |
        Select-Object Manufacturer, @{Name="Capacity(GB)"; Expression={[math]::Round($_.Capacity/1GB,2)}}, Speed, PartNumber
    }
}

# Collect data in parallel
$results = $tasks.GetEnumerator() | ForEach-Object -Parallel {
    $name = $_.Key
    $scriptBlock = $_.Value
    try {
        [PSCustomObject]@{
            Name = $name
            Data = & $scriptBlock
        }
    } catch {
        [PSCustomObject]@{
            Name = $name
            Data = $null
            Error = $_.Exception.Message
        }
    }
}

# Process results
$htmlSections = @{}

# Generate HTML for system information
if ($systemInfo) {
    $systemInfoHtmlFragment = $systemInfo | ConvertTo-Html -Fragment -As Table
    $htmlSections["SystemInfo"] = $systemInfoHtmlFragment
}

foreach ($result in $results) {
    if ($result.Error) {
        $global:ErrorLog += "Error collecting $($result.Name): $($result.Error)"
    }
    # Generate HTML fragments for each section
    if ($result.Data) {
        $htmlFragment = $result.Data | ConvertTo-Html -Fragment -As Table
        $htmlSections[$result.Name] = $htmlFragment
    }
}

# ======================================================
# 5. INSTALLED SOFTWARE (FROM REGISTRY)
# ======================================================
Write-Host "Collecting installed software from registry..."
$softwareList = @()
$uninstallPaths = @(
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)
foreach ($path in $uninstallPaths) {
    try {
        $items = Get-ItemProperty $path -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName }
        if ($items) { $softwareList += $items }
    } catch {
        $global:ErrorLog += "Error retrieving software from path $($path): " + $_.Exception.Message
    }
}
$softwareList = $softwareList | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate
$installedSoftwareHtmlFragment = $softwareList | ConvertTo-Html -Fragment -As Table
$htmlSections["InstalledSoftware"] = $installedSoftwareHtmlFragment

# ======================================================
# 6. HOTFIXES / UPDATES
# ======================================================
Write-Host "Collecting installed hotfixes..."
try {
    $hotfixes = Get-HotFix -ErrorAction Stop | Select-Object HotFixID, Description, InstalledOn
} catch {
    $global:ErrorLog += "Error retrieving hotfixes: " + $_.Exception.Message
    $hotfixes = @()
}
$hotfixesHtmlFragment = $hotfixes | ConvertTo-Html -Fragment -As Table
$htmlSections["Hotfixes"] = $hotfixesHtmlFragment

# ======================================================
# 7. SECURITY POLICIES (GPRESULT)
# ======================================================
Write-Host "Collecting security policy information..."
try {
    $machinePolicy = gpresult /Scope Computer /R | Out-String
} catch {
    $global:ErrorLog += "Error retrieving machine policies: " + $_.Exception.Message
    $machinePolicy = "Not available."
}
try {
    $userPolicy = gpresult /Scope User /R | Out-String
} catch {
    $global:ErrorLog += "Error retrieving user policies: " + $_.Exception.Message
    $userPolicy = "Not available."
}
$machinePolicyHtmlFragment = $machinePolicy -replace "`n", "<br>"
$userPolicyHtmlFragment    = $userPolicy -replace "`n", "<br>"
$htmlSections["MachinePolicy"] = $machinePolicyHtmlFragment
$htmlSections["UserPolicy"] = $userPolicyHtmlFragment

# ======================================================
# 8. DISK USAGE
# ======================================================
Write-Host "Collecting disk usage information..."
$diskUsage = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" -ErrorAction SilentlyContinue |
    Select-Object DeviceID,
                  @{Name='Size(GB)'; Expression={[math]::Round($_.Size/1GB,2)}},
                  @{Name='FreeSpace(GB)'; Expression={[math]::Round($_.FreeSpace/1GB,2)}},
                  @{Name='Used(GB)'; Expression={[math]::Round(($_.Size - $_.FreeSpace)/1GB,2)}},
                  @{Name='PercentFree'; Expression={ if ($_.Size -eq 0) { 0 } else { [math]::Round(($_.FreeSpace / $_.Size) * 100,2) } } }
$diskUsageHtmlFragment = $diskUsage | ConvertTo-Html -Fragment -As Table
$htmlSections["DiskUsage"] = $diskUsageHtmlFragment

# ======================================================
# 9. SMART DISK HEALTH
# ======================================================
Write-Host "Collecting SMART disk health information..."
try {
    $smartData = Get-WmiObject -Namespace root\wmi -Class MSStorageDriver_FailurePredictStatus -ErrorAction Stop |
                 Select-Object InstanceName, PredictFailure, Reason
} catch {
    $global:ErrorLog += "Error retrieving SMART disk health: " + $_.Exception.Message
    $smartData = @()
}
$smartDataHtmlFragment = $smartData | ConvertTo-Html -Fragment -As Table
$htmlSections["SmartDiskHealth"] = $smartDataHtmlFragment

# ======================================================
# 10. NETWORK INFORMATION (EXTENDED)
# ======================================================
Write-Host "Collecting network configuration details..."
$currentAdapters = Get-NetAdapter -Physical -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq 'Up' } | Select-Object Name, InterfaceDescription, MacAddress, LinkSpeed, Status
$ipConfigs = Get-NetIPAddress -ErrorAction SilentlyContinue | Select-Object InterfaceAlias, IPAddress, AddressFamily, PrefixLength, Type
$networkProfiles = Get-NetConnectionProfile -ErrorAction SilentlyContinue | Select-Object Name, NetworkCategory, IPv4Connectivity, IPv6Connectivity
$dnsSettings = Get-DnsClientServerAddress -ErrorAction SilentlyContinue | Select-Object InterfaceAlias, ServerAddresses
$networkContent = $currentAdapters | ConvertTo-Html -Fragment -As Table -PreContent "<h3>Active Network Adapters</h3>" +
                  $ipConfigs | ConvertTo-Html -Fragment -As Table -PreContent "<h3>IP Addresses</h3>" +
                  $networkProfiles | ConvertTo-Html -Fragment -As Table -PreContent "<h3>Network Profiles</h3>" +
                  $dnsSettings | ConvertTo-Html -Fragment -As Table -PreContent "<h3>DNS Settings</h3>"
$htmlSections["Network"] = $networkContent

# ======================================================
# 11. ALL SERVICES
# ======================================================
Write-Host "Collecting services information..."
$allServices = Get-Service -ErrorAction SilentlyContinue | Select-Object Name, DisplayName, Status, StartType
$allServicesHtmlFragment = $allServices | ConvertTo-Html -Fragment -As Table
$htmlSections["Services"] = $allServicesHtmlFragment

# ======================================================
# 12. SCHEDULED TASKS
# ======================================================
Write-Host "Collecting scheduled tasks..."
try {
    $scheduledTasks = Get-ScheduledTask -ErrorAction Stop | Select-Object TaskName, TaskPath, State, LastRunTime, NextRunTime
} catch {
    $global:ErrorLog += "Error retrieving scheduled tasks: " + $_.Exception.Message
    $scheduledTasks = @()
}
$scheduledTasksHtmlFragment = $scheduledTasks | ConvertTo-Html -Fragment -As Table
$htmlSections["ScheduledTasks"] = $scheduledTasksHtmlFragment

# ======================================================
# 13. LOCAL USERS
# ======================================================
Write-Host "Collecting local users..."
try {
    $localUsers = Get-LocalUser -ErrorAction Stop | Select-Object Name, Enabled, LastLogon
} catch {
    $global:ErrorLog += "Error retrieving local users: " + $_.Exception.Message
    $localUsers = @()
}
$localUsersHtmlFragment = $localUsers | ConvertTo-Html -Fragment -As Table
$htmlSections["LocalUsers"] = $localUsersHtmlFragment

# ======================================================
# 14. LOCAL GROUPS
# ======================================================
Write-Host "Collecting local groups..."
try {
    $localGroups = Get-LocalGroup -ErrorAction Stop | Select-Object Name, Description
} catch {
    $global:ErrorLog += "Error retrieving local groups: " + $_.Exception.Message
    $localGroups = @()
}
$localGroupsHtmlFragment = $localGroups | ConvertTo-Html -Fragment -As Table
$htmlSections["LocalGroups"] = $localGroupsHtmlFragment

# ======================================================
# 15. ENVIRONMENT VARIABLES
# ======================================================
Write-Host "Collecting environment variables..."
$envVars = Get-ChildItem env: | Select-Object Name, Value
$envVarsHtmlFragment = $envVars | ConvertTo-Html -Fragment -As Table
$htmlSections["EnvironmentVariables"] = $envVarsHtmlFragment

# ======================================================
# 16. RECENT SYSTEM ERRORS
# ======================================================
Write-Host "Collecting recent system errors from Event Log..."
try {
    $eventErrors = Get-EventLog -LogName System -EntryType Error -After (Get-Date).AddDays(-1) -Newest 20 -ErrorAction Stop |
                   Select-Object TimeGenerated, Source, EventID, Message
} catch {
    $global:ErrorLog += "Error retrieving system errors: " + $_.Exception.Message
    $eventErrors = @()
}
$eventErrorsHtmlFragment = $eventErrors | ConvertTo-Html -Fragment -As Table
$htmlSections["SystemErrors"] = $eventErrorsHtmlFragment

# ======================================================
# 17. STARTUP APPLICATIONS
# ======================================================
Write-Host "Collecting startup applications..."
try {
    $startupApps = Get-CimInstance Win32_StartupCommand -ErrorAction Stop | Select-Object Name, Command, Location, User, Caption
} catch {
    $global:ErrorLog += "Error retrieving startup applications: " + $_.Exception.Message
    $startupApps = @()
}
$startupAppsHtmlFragment = $startupApps | ConvertTo-Html -Fragment -As Table
$htmlSections["StartupApplications"] = $startupAppsHtmlFragment

# ======================================================
# 18. TOP PROCESSES BY CPU AND MEMORY
# ======================================================
Write-Host "Collecting top processes..."
try {
    $topCPUProcesses = Get-Process -ErrorAction Stop | Sort-Object CPU -Descending | Select-Object Name, CPU, Id, WS, VM, StartTime -First 10
    $topMemProcesses = Get-Process -ErrorAction Stop | Sort-Object WS -Descending | Select-Object Name, @{Name='WorkingSet(MB)'; Expression={[math]::Round($_.WS/1MB,2)}}, Id, CPU, StartTime -First 10
} catch {
    $global:ErrorLog += "Error retrieving process information: " + $_.Exception.Message
    $topCPUProcesses = @()
    $topMemProcesses = @()
}
$topCPUHtmlFragment = $topCPUProcesses | ConvertTo-Html -Fragment -As Table
$topMemHtmlFragment = $topMemProcesses | ConvertTo-Html -Fragment -As Table
$htmlSections["TopCPUProcesses"] = $topCPUHtmlFragment
$htmlSections["TopMemoryProcesses"] = $topMemHtmlFragment

# ======================================================
# 19. WINDOWS DEFENDER / ANTIVIRUS STATUS
# ======================================================
Write-Host "Collecting Windows Defender status..."
try {
    $defenderStatus = Get-MpComputerStatus -ErrorAction Stop | Select-Object AMServiceEnabled, AntispywareEnabled, AntivirusEnabled, RealTimeProtectionEnabled
} catch {
    $global:ErrorLog += "Error retrieving Windows Defender status: " + $_.Exception.Message
    $defenderStatus = @{ "Status" = "Not Available" }
}
$defenderStatusHtmlFragment = $defenderStatus | ConvertTo-Html -Fragment -As Table
$htmlSections["DefenderStatus"] = $defenderStatusHtmlFragment

# ======================================================
# 20. PERFORMANCE METRICS
# ======================================================
Write-Host "Collecting performance metrics..."
try {
    $cpuCounter = Get-Counter "\Processor(_Total)\% Processor Time" -ErrorAction Stop
    $cpuLoad = [math]::Round($cpuCounter.CounterSamples[0].CookedValue,2)
} catch {
    $global:ErrorLog += "Error retrieving CPU counter: " + $_.Exception.Message
    $cpuLoad = "N/A"
}
try {
    $memCounter = Get-Counter "\Memory\Available MBytes" -ErrorAction Stop
    $memAvailable = [math]::Round($memCounter.CounterSamples[0].CookedValue,2)
} catch {
    $global:ErrorLog += "Error retrieving memory counter: " + $_.Exception.Message
    $memAvailable = "N/A"
}
try {
    $diskReadCounter = Get-Counter "\PhysicalDisk(_Total)\Disk Reads/sec" -ErrorAction Stop
    $diskWriteCounter = Get-Counter "\PhysicalDisk(_Total)\Disk Writes/sec" -ErrorAction Stop
    $diskReads = [math]::Round($diskReadCounter.CounterSamples[0].CookedValue,2)
    $diskWrites = [math]::Round($diskWriteCounter.CounterSamples[0].CookedValue,2)
} catch {
    $global:ErrorLog += "Error retrieving disk I/O counters: " + $_.Exception.Message
    $diskReads = "N/A"
    $diskWrites = "N/A"
}
$perfMetrics = [PSCustomObject]@{
    "CPU Load (%)"           = $cpuLoad
    "Available Memory (MB)"  = $memAvailable
    "Disk Reads/sec"         = $diskReads
    "Disk Writes/sec"        = $diskWrites
}
$perfMetricsHtmlFragment = $perfMetrics | ConvertTo-Html -Fragment -As Table
$htmlSections["PerformanceMetrics"] = $perfMetricsHtmlFragment

# ======================================================
# 21. ERROR LOG (IF ANY)
# ======================================================
$errorLogHtml = ""
if ($global:ErrorLog.Count -gt 0) {
    $errorLogHtmlFragment = $global:ErrorLog | ConvertTo-Html -Fragment -As List
    $htmlSections["ErrorLog"] = $errorLogHtmlFragment
}

# Combine all HTML sections into the final report
$htmlHeader = @"
<html>
  <head>
    <meta charset='utf-8' />
    <title>Diagnostic Report - $($env:COMPUTERNAME)</title>
    <style>
      body { font-family: Arial, sans-serif; margin: 20px; }
      .button { display: inline-block; background-color: #007BFF; color: #fff; padding: 6px 12px; margin: 4px; text-decoration: none; border-radius: 4px; }
      .button:hover { background-color: #0056b3; }
      table { border-collapse: collapse; margin: 10px 0; width: 100%; }
      th, td { border: 1px solid #ccc; padding: 8px; }
      th { background: #f2f2f2; }
      h1, h2, h3 { margin-top: 35px; }
      #toc { margin-bottom: 20px; border: 1px solid #ccc; padding: 10px; }
      .section { margin-bottom: 30px; }
      .section h2 { cursor: pointer; }
      .toggle { font-size: 0.8em; color: #555; }
    </style>
    <script>
      function toggleSection(id) {
        var x = document.getElementById(id);
        if (x.style.display === "none") {
          x.style.display = "block";
        } else {
          x.style.display = "none";
        }
      }
    </script>
  </head>
  <body>
    <h1>Comprehensive Diagnostic Report for $($env:COMPUTERNAME)</h1>
    <p><strong>Report Generated on:</strong> $(Get-Date)</p>
    <div id='toc'>
      <h2>Summary / Table of Contents</h2>
      <div>
        <a href='#SystemInfo' class='button'>System Info</a>
        <a href='#BaseBoard' class='button'>Motherboard</a>
        <a href='#GPUInfo' class='button'>GPU</a>
        <a href='#MemoryModules' class='button'>Memory Modules</a>
        <a href='#InstalledSoftware' class='button'>Installed Software</a>
        <a href='#Hotfixes' class='button'>Hotfixes</a>
        <a href='#MachinePolicy' class='button'>Machine Policy</a>
        <a href='#UserPolicy' class='button'>User Policy</a>
        <a href='#DiskUsage' class='button'>Disk Usage</a>
        <a href='#SmartDiskHealth' class='button'>SMART Disk Health</a>
        <a href='#Network' class='button'>Network</a>
        <a href='#Services' class='button'>Services</a>
        <a href='#ScheduledTasks' class='button'>Scheduled Tasks</a>
        <a href='#LocalUsers' class='button'>Local Users</a>
        <a href='#LocalGroups' class='button'>Local Groups</a>
        <a href='#EnvironmentVariables' class='button'>Environment Variables</a>
        <a href='#SystemErrors' class='button'>System Errors</a>
        <a href='#StartupApplications' class='button'>Startup Applications</a>
        <a href='#TopCPUProcesses' class='button'>Top CPU Processes</a>
        <a href='#TopMemoryProcesses' class='button'>Top Memory Processes</a>
        <a href='#DefenderStatus' class='button'>Defender Status</a>
        <a href='#PerformanceMetrics' class='button'>Performance Metrics</a>
        <a href='#ErrorLog' class='button'>Error Log</a>
      </div>
    </div>
"@

$htmlFooter = @"
  </body>
</html>
"@

$htmlContent = $htmlHeader + ($htmlSections.Values -join "") + $htmlFooter

# Write the report to the output path
try {
    $htmlContent | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-Host "Report generated at: $OutputPath" -ForegroundColor Green
    Start-Process $OutputPath
} catch {
    Write-Error "Failed to write report to $OutputPath. Error: $_"
}

Write-Host "`nProcessing completed." -ForegroundColor Cyan
