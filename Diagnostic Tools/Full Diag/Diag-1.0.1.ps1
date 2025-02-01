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

# ======================================================
# 1. SYSTEM INFORMATION
# ======================================================
Write-Host "Collecting system information..."
$compSys  = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction SilentlyContinue
if (-not $compSys) { $global:ErrorLog += "Failed to retrieve Win32_ComputerSystem information." }
$operSys  = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction SilentlyContinue
if (-not $operSys) { $global:ErrorLog += "Failed to retrieve Win32_OperatingSystem information." }
$biosInfo = Get-CimInstance -ClassName Win32_BIOS -ErrorAction SilentlyContinue
if (-not $biosInfo) { $global:ErrorLog += "Failed to retrieve Win32_BIOS information." }
$cpuInfo  = Get-CimInstance -ClassName Win32_Processor -ErrorAction SilentlyContinue
if (-not $cpuInfo) { $global:ErrorLog += "Failed to retrieve Win32_Processor information." }

$totalMemGB = [math]::Round($operSys.TotalVisibleMemorySize / 1MB, 2)
$freeMemGB  = [math]::Round($operSys.FreePhysicalMemory / 1MB, 2)
$uptime     = (Get-Date) - ([Management.ManagementDateTimeConverter]::ToDateTime($operSys.LastBootUpTime))
$uptimeFormatted = "{0} days, {1} hours, {2} minutes, {3} seconds" -f $uptime.Days, $uptime.Hours, $uptime.Minutes, $uptime.Seconds

$systemInfo = [PSCustomObject]@{
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
    TotalMemoryGB         = $totalMemGB
    FreeMemoryGB          = $freeMemGB
    SystemUptime          = $uptimeFormatted
}

$systemInfoHtmlFragment = $systemInfo | ConvertTo-Html -Fragment -As Table
$systemInfoHtml = @"
<div class='section' id='systemInfoSection'>
  <h2 onclick="toggleSection('systemInfoContent')">System Information <span class='toggle'>[Toggle]</span></h2>
  <div id='systemInfoContent'>
    <a href='#toc' class='button'>Table of Contents</a>
    $systemInfoHtmlFragment
  </div>
</div>
"@

# ======================================================
# 2. MOTHERBOARD INFORMATION
# ======================================================
Write-Host "Collecting motherboard information..."
$baseBoard = Get-CimInstance -ClassName Win32_BaseBoard -ErrorAction SilentlyContinue
if (-not $baseBoard) { $global:ErrorLog += "Failed to retrieve Win32_BaseBoard information." }
$baseBoardHtmlFragment = $baseBoard | Select-Object Manufacturer, Product, Version, SerialNumber | ConvertTo-Html -Fragment -As Table
$baseBoardHtml = @"
<div class='section' id='baseBoardSection'>
  <h2 onclick="toggleSection('baseBoardContent')">Motherboard Information <span class='toggle'>[Toggle]</span></h2>
  <div id='baseBoardContent'>
    <a href='#toc' class='button'>Table of Contents</a>
    $baseBoardHtmlFragment
  </div>
</div>
"@

# ======================================================
# 3. GPU (GRAPHICS ADAPTER) INFORMATION
# ======================================================
Write-Host "Collecting GPU information..."
$gpuInfo = Get-CimInstance -ClassName Win32_VideoController -ErrorAction SilentlyContinue
if (-not $gpuInfo) { $global:ErrorLog += "Failed to retrieve Win32_VideoController information." }
$gpuInfoHtmlFragment = $gpuInfo | Select-Object Name, DriverVersion, VideoModeDescription | ConvertTo-Html -Fragment -As Table
$gpuInfoHtml = @"
<div class='section' id='gpuInfoSection'>
  <h2 onclick="toggleSection('gpuInfoContent')">Graphics Adapter Details <span class='toggle'>[Toggle]</span></h2>
  <div id='gpuInfoContent'>
    <a href='#toc' class='button'>Table of Contents</a>
    $gpuInfoHtmlFragment
  </div>
</div>
"@

# ======================================================
# 4. PHYSICAL MEMORY MODULES
# ======================================================
Write-Host "Collecting physical memory module details..."
$memoryModules = Get-CimInstance -ClassName Win32_PhysicalMemory -ErrorAction SilentlyContinue
if (-not $memoryModules) { $global:ErrorLog += "Failed to retrieve Win32_PhysicalMemory information." }
$memoryModules = $memoryModules | Select-Object Manufacturer, @{Name="Capacity(GB)"; Expression={[math]::Round($_.Capacity/1GB,2)}}, Speed, PartNumber
$memoryModulesHtmlFragment = $memoryModules | ConvertTo-Html -Fragment -As Table
$memoryModulesHtml = @"
<div class='section' id='memoryModulesSection'>
  <h2 onclick="toggleSection('memoryModulesContent')">Physical Memory Modules <span class='toggle'>[Toggle]</span></h2>
  <div id='memoryModulesContent'>
    <a href='#toc' class='button'>Table of Contents</a>
    $memoryModulesHtmlFragment
  </div>
</div>
"@

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
$installedSoftwareHtml = @"
<div class='section' id='installedSoftwareSection'>
  <h2 onclick="toggleSection('installedSoftwareContent')">Installed Software <span class='toggle'>[Toggle]</span></h2>
  <div id='installedSoftwareContent'>
    <a href='#toc' class='button'>Table of Contents</a>
    $installedSoftwareHtmlFragment
  </div>
</div>
"@

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
$hotfixesHtml = @"
<div class='section' id='hotfixesSection'>
  <h2 onclick="toggleSection('hotfixesContent')">Installed Hotfixes / Updates <span class='toggle'>[Toggle]</span></h2>
  <div id='hotfixesContent'>
    <a href='#toc' class='button'>Table of Contents</a>
    $hotfixesHtmlFragment
  </div>
</div>
"@

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
$machinePolicyHtml = @"
<div class='section' id='machinePolicySection'>
  <h2 onclick="toggleSection('machinePolicyContent')">Machine Policies (gpresult) <span class='toggle'>[Toggle]</span></h2>
  <div id='machinePolicyContent'>
    <a href='#toc' class='button'>Table of Contents</a>
    $machinePolicyHtmlFragment
  </div>
</div>
"@
$userPolicyHtml = @"
<div class='section' id='userPolicySection'>
  <h2 onclick="toggleSection('userPolicyContent')">User Policies (gpresult) <span class='toggle'>[Toggle]</span></h2>
  <div id='userPolicyContent'>
    <a href='#toc' class='button'>Table of Contents</a>
    $userPolicyHtmlFragment
  </div>
</div>
"@

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
$diskUsageHtml = @"
<div class='section' id='diskUsageSection'>
  <h2 onclick="toggleSection('diskUsageContent')">Disk Usage <span class='toggle'>[Toggle]</span></h2>
  <div id='diskUsageContent'>
    <a href='#toc' class='button'>Table of Contents</a>
    $diskUsageHtmlFragment
  </div>
</div>
"@

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
$smartDataHtml = @"
<div class='section' id='smartDiskSection'>
  <h2 onclick="toggleSection('smartDiskContent')">SMART Disk Health <span class='toggle'>[Toggle]</span></h2>
  <div id='smartDiskContent'>
    <a href='#toc' class='button'>Table of Contents</a>
    $smartDataHtmlFragment
  </div>
</div>
"@

# ======================================================
# 10. NETWORK INFORMATION (EXTENDED)
# ======================================================
Write-Host "Collecting network configuration details..."
# Active network adapters
$currentAdapters = Get-NetAdapter -Physical -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq 'Up' } | Select-Object Name, InterfaceDescription, MacAddress, LinkSpeed, Status
$currentAdaptersHtmlFragment = $currentAdapters | ConvertTo-Html -Fragment -As Table -PreContent "<h3>Active Network Adapters</h3>"

# IP addresses
$ipConfigs = Get-NetIPAddress -ErrorAction SilentlyContinue | Select-Object InterfaceAlias, IPAddress, AddressFamily, PrefixLength, Type
$ipConfigsHtmlFragment = $ipConfigs | ConvertTo-Html -Fragment -As Table -PreContent "<h3>IP Addresses</h3>"

# Network Profiles
$networkProfiles = Get-NetConnectionProfile -ErrorAction SilentlyContinue | Select-Object Name, NetworkCategory, IPv4Connectivity, IPv6Connectivity
$networkProfilesHtmlFragment = $networkProfiles | ConvertTo-Html -Fragment -As Table -PreContent "<h3>Network Profiles</h3>"

# DNS Settings
$dnsSettings = Get-DnsClientServerAddress -ErrorAction SilentlyContinue | Select-Object InterfaceAlias, ServerAddresses
$dnsSettingsHtmlFragment = $dnsSettings | ConvertTo-Html -Fragment -As Table -PreContent "<h3>DNS Settings</h3>"

$networkContent = $currentAdaptersHtmlFragment + $ipConfigsHtmlFragment + $networkProfilesHtmlFragment + $dnsSettingsHtmlFragment
$networkHtml = @"
<div class='section' id='networkSection'>
  <h2 onclick="toggleSection('networkContent')">Network Configuration <span class='toggle'>[Toggle]</span></h2>
  <div id='networkContent'>
    <a href='#toc' class='button'>Table of Contents</a>
    $networkContent
  </div>
</div>
"@

# ======================================================
# 11. ALL SERVICES
# ======================================================
Write-Host "Collecting services information..."
$allServices = Get-Service -ErrorAction SilentlyContinue | Select-Object Name, DisplayName, Status, StartType
$allServicesHtmlFragment = $allServices | ConvertTo-Html -Fragment -As Table
$allServicesHtml = @"
<div class='section' id='servicesSection'>
  <h2 onclick="toggleSection('servicesContent')">All Services <span class='toggle'>[Toggle]</span></h2>
  <div id='servicesContent'>
    <a href='#toc' class='button'>Table of Contents</a>
    $allServicesHtmlFragment
  </div>
</div>
"@

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
$scheduledTasksHtml = @"
<div class='section' id='scheduledTasksSection'>
  <h2 onclick="toggleSection('scheduledTasksContent')">Scheduled Tasks <span class='toggle'>[Toggle]</span></h2>
  <div id='scheduledTasksContent'>
    <a href='#toc' class='button'>Table of Contents</a>
    $scheduledTasksHtmlFragment
  </div>
</div>
"@

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
$localUsersHtml = @"
<div class='section' id='localUsersSection'>
  <h2 onclick="toggleSection('localUsersContent')">Local Users <span class='toggle'>[Toggle]</span></h2>
  <div id='localUsersContent'>
    <a href='#toc' class='button'>Table of Contents</a>
    $localUsersHtmlFragment
  </div>
</div>
"@

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
$localGroupsHtmlFragment = $localGroups | ConvertTo-Html -Fragment -As Table -PreContent "<h3>Local Groups</h3>"
$localGroupsHtml = @"
<div class='section' id='localGroupsSection'>
  <h2 onclick="toggleSection('localGroupsContent')">Local Groups <span class='toggle'>[Toggle]</span></h2>
  <div id='localGroupsContent'>
    <a href='#toc' class='button'>Table of Contents</a>
    $localGroupsHtmlFragment
  </div>
</div>
"@

# ======================================================
# 15. ENVIRONMENT VARIABLES
# ======================================================
Write-Host "Collecting environment variables..."
$envVars = Get-ChildItem env: | Select-Object Name, Value
$envVarsHtmlFragment = $envVars | ConvertTo-Html -Fragment -As Table
$envVarsHtml = @"
<div class='section' id='envVarsSection'>
  <h2 onclick="toggleSection('envVarsContent')">Environment Variables <span class='toggle'>[Toggle]</span></h2>
  <div id='envVarsContent'>
    <a href='#toc' class='button'>Table of Contents</a>
    $envVarsHtmlFragment
  </div>
</div>
"@

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
$eventErrorsHtml = @"
<div class='section' id='eventErrorsSection'>
  <h2 onclick="toggleSection('eventErrorsContent')">Recent System Errors (Event Log) <span class='toggle'>[Toggle]</span></h2>
  <div id='eventErrorsContent'>
    <a href='#toc' class='button'>Table of Contents</a>
    $eventErrorsHtmlFragment
  </div>
</div>
"@

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
$startupAppsHtml = @"
<div class='section' id='startupAppsSection'>
  <h2 onclick="toggleSection('startupAppsContent')">Startup Applications <span class='toggle'>[Toggle]</span></h2>
  <div id='startupAppsContent'>
    <a href='#toc' class='button'>Table of Contents</a>
    $startupAppsHtmlFragment
  </div>
</div>
"@

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
$topCPUHtml = @"
<div class='section' id='topCPUSection'>
  <h2 onclick="toggleSection('topCPUContent')">Top 10 Processes by CPU Usage <span class='toggle'>[Toggle]</span></h2>
  <div id='topCPUContent'>
    <a href='#toc' class='button'>Table of Contents</a>
    $topCPUHtmlFragment
  </div>
</div>
"@
$topMemHtmlFragment = $topMemProcesses | ConvertTo-Html -Fragment -As Table
$topMemHtml = @"
<div class='section' id='topMemSection'>
  <h2 onclick="toggleSection('topMemContent')">Top 10 Processes by Memory Usage <span class='toggle'>[Toggle]</span></h2>
  <div id='topMemContent'>
    <a href='#toc' class='button'>Table of Contents</a>
    $topMemHtmlFragment
  </div>
</div>
"@

# ======================================================
# 19. WINDOWS DEFENDER / ANTIVIRUS STATUS
# ======================================================
Write-Host "Collecting Windows Defender status..."
try {
    $defenderStatus = Get-MpComputerStatus -ErrorAction Stop | Select-Object AMServiceEnabled, AntispywareEnabled, AntivirusEnabled, RealTimeProtectionEnabled
} catch {
    $global:ErrorLog += "Error retrieving Windows Defender status: " + $_.Exception.Message
    $defenderStatus = @{}
}
$defenderStatusHtmlFragment = $defenderStatus | ConvertTo-Html -Fragment -As Table
$defenderStatusHtml = @"
<div class='section' id='defenderSection'>
  <h2 onclick="toggleSection('defenderContent')">Windows Defender/Antivirus Status <span class='toggle'>[Toggle]</span></h2>
  <div id='defenderContent'>
    <a href='#toc' class='button'>Table of Contents</a>
    $defenderStatusHtmlFragment
  </div>
</div>
"@

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
$perfMetricsHtml = @"
<div class='section' id='perfMetricsSection'>
  <h2 onclick="toggleSection('perfMetricsContent')">Performance Metrics <span class='toggle'>[Toggle]</span></h2>
  <div id='perfMetricsContent'>
    <a href='#toc' class='button'>Table of Contents</a>
    $perfMetricsHtmlFragment
  </div>
</div>
"@

# ======================================================
# 21. ERROR LOG (IF ANY)
# ======================================================
$errorLogHtml = ""
if ($global:ErrorLog.Count -gt 0) {
    $errorLogHtmlFragment = $global:ErrorLog | ConvertTo-Html -Fragment -As List
    $errorLogHtml = @"
<div class='section' id='errorLogSection'>
  <h2 onclick="toggleSection('errorLogContent')">Error Log <span class='toggle'>[Toggle]</span></h2>
  <div id='errorLogContent'>
    <a href='#toc' class='button'>Table of Contents</a>
    $errorLogHtmlFragment
  </div>
</div>
"@
}

# ======================================================
# TABLE OF CONTENTS
# ======================================================
$tableOfContents = @"
<div id='toc'>
  <h2>Summary / Table of Contents</h2>
  <div>
    <a href='#systemInfoSection' class='button'>System Info</a>
    <a href='#baseBoardSection' class='button'>Motherboard</a>
    <a href='#gpuInfoSection' class='button'>GPU</a>
    <a href='#memoryModulesSection' class='button'>Memory Modules</a>
    <a href='#installedSoftwareSection' class='button'>Installed Software</a>
    <a href='#hotfixesSection' class='button'>Hotfixes/Updates</a>
    <a href='#machinePolicySection' class='button'>Machine Policies</a>
    <a href='#userPolicySection' class='button'>User Policies</a>
    <a href='#diskUsageSection' class='button'>Disk Usage</a>
    <a href='#smartDiskSection' class='button'>SMART Health</a>
    <a href='#networkSection' class='button'>Network</a>
    <a href='#servicesSection' class='button'>Services</a>
    <a href='#scheduledTasksSection' class='button'>Scheduled Tasks</a>
    <a href='#localUsersSection' class='button'>Local Users</a>
    <a href='#localGroupsSection' class='button'>Local Groups</a>
    <a href='#envVarsSection' class='button'>Env Variables</a>
    <a href='#eventErrorsSection' class='button'>System Errors</a>
    <a href='#startupAppsSection' class='button'>Startup Apps</a>
    <a href='#topCPUSection' class='button'>Top CPU</a>
    <a href='#topMemSection' class='button'>Top Memory</a>
    <a href='#defenderSection' class='button'>Defender Status</a>
    <a href='#perfMetricsSection' class='button'>Performance Metrics</a>
    <a href='#errorLogSection' class='button'>Error Log</a>
  </div>
</div>
"@

# ======================================================
# BUILDING THE FINAL HTML REPORT
# ======================================================
$reportDate = Get-Date
$reportHtml = @"
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
    <p><strong>Report Generated on:</strong> $reportDate</p>
    $tableOfContents
    $systemInfoHtml
    $baseBoardHtml
    $gpuInfoHtml
    $memoryModulesHtml
    $installedSoftwareHtml
    $hotfixesHtml
    $machinePolicyHtml
    $userPolicyHtml
    $diskUsageHtml
    $smartDataHtml
    $networkHtml
    $allServicesHtml
    $scheduledTasksHtml
    $localUsersHtml
    $localGroupsHtml
    $envVarsHtml
    $eventErrorsHtml
    $startupAppsHtml
    $topCPUHtml
    $topMemHtml
    $defenderStatusHtml
    $perfMetricsHtml
    $errorLogHtml
  </body>
</html>
"@

Write-Host "`nSaving report to $OutputPath"
$reportHtml | Out-File -FilePath $OutputPath -Encoding UTF8

Write-Host "`nExtended diagnostic report created successfully!"
Write-Host "Location: $OutputPath"
Write-Host "Opening the report..."
Start-Process $OutputPath
