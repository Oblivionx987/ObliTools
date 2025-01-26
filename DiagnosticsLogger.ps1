<#
.SYNOPSIS
    Collect extensive diagnostic information from the local machine and output to an HTML file,
    including a summary section with links to each major section.

.DESCRIPTION
    This script gathers:
      1. System Information (name, manufacturer, model, OS, BIOS, CPU, memory, uptime, serial number).
      2. Installed Software (name, version, install date).
      3. Hotfixes / updates installed.
      4. Security policies (machine and user scope via gpresult).
      5. Disk usage.
      6. Network configuration details & currently connected adapters, plus network profile names.
      7. All services (running, stopped, disabled, etc.).
      8. Scheduled tasks.
      9. Local users and groups.
      10. Environment variables.
      11. Recent system errors from the Windows event log (last 24 hours).
      12. Startup apps and their status.
      13. Top processes by CPU and memory usage.

    It creates a summary section at the top of the HTML report with quick link buttons to each section.

.NOTES
    - Requires elevated privileges (Administrator).
    - Compatible with Windows 10/11, Server 2016/2019/2022 (PowerShell 5.1+).

.EXAMPLE
    .\Collect-Diagnostics-Extended.ps1
#>

# -----------------------------------------------------
#              CONFIGURATION
# -----------------------------------------------------
$outputPath = "C:\Temp\currentmachine_diag.html"

Write-Host "`nStarting extended diagnostics collection...`n"

# -----------------------------------------------------
#              1. SYSTEM INFORMATION
# -----------------------------------------------------
Write-Host "Collecting system information..."
$compSys  = Get-CimInstance -ClassName Win32_ComputerSystem
$operSys  = Get-CimInstance -ClassName Win32_OperatingSystem
$biosInfo = Get-CimInstance -ClassName Win32_BIOS
$cpuInfo  = Get-CimInstance -ClassName Win32_Processor

# Memory Info
$totalMemGB = [math]::Round($operSys.TotalVisibleMemorySize / 1MB, 2)
$freeMemGB  = [math]::Round($operSys.FreePhysicalMemory / 1MB, 2)

# System Uptime
$uptime = (Get-Date) - ([Management.ManagementDateTimeConverter]::ToDateTime($operSys.LastBootUpTime))
$uptimeFormatted = ("{0} days, {1} hours, {2} minutes, {3} seconds" -f $uptime.Days, $uptime.Hours, $uptime.Minutes, $uptime.Seconds)

# Create a custom object with consolidated system info
$systemInfo = [PSCustomObject]@{
    ComputerName          = $compSys.Name
    Manufacturer          = $compSys.Manufacturer
    Model                 = $compSys.Model
    SerialNumber          = $biosInfo.SerialNumber     # Often the Service Tag / Serial
    BIOS_Version          = $biosInfo.SMBIOSBIOSVersion
    BIOS_ReleaseDate      = ([Management.ManagementDateTimeConverter]::ToDateTime($biosInfo.ReleaseDate) -join ';')
    OSName                = $operSys.Caption
    OSVersion             = $operSys.Version
    SystemType            = $compSys.SystemType
    CPU_Name              = ($cpuInfo.Name -join ', ')
    CPU_Cores             = ($cpuInfo.NumberOfCores -join ', ')
    CPU_LogicalProcessors = ($cpuInfo.NumberOfLogicalProcessors -join ', ')
    CPU_MaxClockSpeedMHz  = ($cpuInfo.MaxClockSpeed -join ', ')
    TotalMemoryGB         = $totalMemGB
    FreeMemoryGB          = $freeMemGB
    SystemUptime          = $uptimeFormatted
}

# We'll add an ID to the <h2> tag for quick links
$systemInfoHtml = $systemInfo |
    ConvertTo-Html -Fragment -As Table -PreContent "<h2 id='systemInfo'>System Information</h2>"

# -----------------------------------------------------
#              2. INSTALLED SOFTWARE
# -----------------------------------------------------
Write-Host "Collecting installed software (Win32_Product). This may take a while..."
$installedSoftware = Get-CimInstance -ClassName Win32_Product | 
    Select-Object Name, Version, InstallDate

$installedSoftwareHtml = $installedSoftware |
    ConvertTo-Html -Fragment -As Table -PreContent "<h2 id='installedSoftware'>Installed Software</h2>"

# -----------------------------------------------------
#              3. HOTFIXES / UPDATES
# -----------------------------------------------------
Write-Host "Collecting installed hotfixes..."
$hotfixes = Get-HotFix | Select-Object HotFixID, Description, InstalledOn

$hotfixesHtml = $hotfixes |
    ConvertTo-Html -Fragment -As Table -PreContent "<h2 id='hotfixes'>Installed Hotfixes / Updates</h2>"

# -----------------------------------------------------
#              4. SECURITY POLICIES
# -----------------------------------------------------
Write-Host "Collecting security policy information (machine and user scope)..."
$machinePolicy = gpresult /Scope Computer /R
$userPolicy    = gpresult /Scope User /R

$machinePolicyHtml = ($machinePolicy -join "<br>") |
    ConvertTo-Html -Fragment -PreContent "<h2 id='machineUserPolicies'>Machine Policies (gpresult)</h2>"

$userPolicyHtml = ($userPolicy -join "<br>") |
    ConvertTo-Html -Fragment -PreContent "<h3>User Policies (gpresult)</h3>"

# -----------------------------------------------------
#              5. DISK USAGE
# -----------------------------------------------------
Write-Host "Collecting disk usage..."
$diskUsage = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | 
    Select-Object DeviceID,
                  @{Name='SizeGB';Expression={[math]::Round($_.Size/1GB,2)}},
                  @{Name='FreeSpaceGB';Expression={[math]::Round($_.FreeSpace/1GB,2)}},
                  @{Name='UsedGB';Expression={[math]::Round(($_.Size - $_.FreeSpace)/1GB,2)}},
                  @{Name='PercentFree';Expression={
                      if ($_.Size -eq 0) { 0 }
                      else { [math]::Round(($_.FreeSpace / $_.Size) * 100,2) }
                  }}

$diskUsageHtml = $diskUsage |
    ConvertTo-Html -Fragment -As Table -PreContent "<h2 id='diskUsage'>Disk Usage</h2>"

# -----------------------------------------------------
#              6. NETWORK INFO
# -----------------------------------------------------
Write-Host "Collecting network information..."

# 6a. Current network adapter details (physical, status = up)
$currentAdapters = Get-NetAdapter -Physical | Where-Object { $_.Status -eq 'Up' } |
    Select-Object Name, InterfaceDescription, MacAddress, LinkSpeed, Status

$currentAdaptersHtml = $currentAdapters |
    ConvertTo-Html -Fragment -As Table -PreContent "<h3>Active Network Adapters</h3>"

# 6b. All IP addresses assigned (IPv4 and IPv6)
$ipConfigs = Get-NetIPAddress | 
    Select-Object InterfaceAlias, IPAddress, AddressFamily, PrefixLength, Type

$ipConfigsHtml = $ipConfigs |
    ConvertTo-Html -Fragment -As Table -PreContent "<h3>IP Addresses</h3>"

# 6c. Network Profiles (shows the “Name” of current networks)
$networkProfiles = Get-NetConnectionProfile | 
    Select-Object Name, NetworkCategory, IPv4Connectivity, IPv6Connectivity

$networkProfilesHtml = $networkProfiles |
    ConvertTo-Html -Fragment -As Table -PreContent "<h3>Network Profiles</h3>"

$networkHtml = "<h2 id='network'>Network Configuration</h2>" + $currentAdaptersHtml + $ipConfigsHtml + $networkProfilesHtml

# -----------------------------------------------------
#              7. ALL SERVICES
# -----------------------------------------------------
Write-Host "Collecting all services (including inactive/disabled)..."
$allServices = Get-Service | 
    Select-Object Name, DisplayName, Status, StartType

$allServicesHtml = $allServices |
    ConvertTo-Html -Fragment -As Table -PreContent "<h2 id='allServices'>All Services</h2>"

# -----------------------------------------------------
#              8. SCHEDULED TASKS
# -----------------------------------------------------
Write-Host "Collecting scheduled tasks..."
Try {
    $scheduledTasks = Get-ScheduledTask | 
        Select-Object TaskName, TaskPath, State, LastRunTime, NextRunTime
} Catch {
    Write-Warning "Unable to retrieve scheduled tasks. Check OS version or permissions."
    $scheduledTasks = @()
}

$scheduledTasksHtml = $scheduledTasks |
    ConvertTo-Html -Fragment -As Table -PreContent "<h2 id='scheduledTasks'>Scheduled Tasks</h2>"

# -----------------------------------------------------
#              9. LOCAL USERS / GROUPS
# -----------------------------------------------------
Write-Host "Collecting local user and group info..."
Try {
    $localUsers = Get-LocalUser | Select-Object Name, Enabled, LastLogon
    $localGroups = Get-LocalGroup | Select-Object Name, Description
} Catch {
    Write-Warning "Unable to gather local user/group info. Requires admin privileges or a compatible OS."
    $localUsers = @()
    $localGroups = @()
}

$localUsersHtml = $localUsers |
    ConvertTo-Html -Fragment -As Table -PreContent "<h2 id='localUsers'>Local Users</h2>"

$localGroupsHtml = $localGroups |
    ConvertTo-Html -Fragment -As Table -PreContent "<h3>Local Groups</h3>"

# -----------------------------------------------------
#              10. ENVIRONMENT VARIABLES
# -----------------------------------------------------
Write-Host "Collecting environment variables..."
$envVars = Get-ChildItem env: | Select-Object Name, Value

$envVarsHtml = $envVars |
    ConvertTo-Html -Fragment -As Table -PreContent "<h2 id='envVars'>Environment Variables</h2>"

# -----------------------------------------------------
#              11. RECENT SYSTEM ERRORS
# -----------------------------------------------------
Write-Host "Collecting recent system errors from Event Log (last 24 hours, max 20 entries)..."
Try {
    $eventErrors = Get-EventLog -LogName System -EntryType Error -After (Get-Date).AddDays(-1) -Newest 20 | 
        Select-Object TimeGenerated, Source, EventID, Message
} Catch {
    Write-Warning "Unable to gather event logs. This might require admin privileges or OS compatibility."
    $eventErrors = @()
}

$eventErrorsHtml = $eventErrors |
    ConvertTo-Html -Fragment -As Table -PreContent "<h2 id='eventErrors'>Recent System Errors (Event Log)</h2>"

# -----------------------------------------------------
#              12. STARTUP APPS
# -----------------------------------------------------
Write-Host "Collecting startup applications..."
Try {
    # Win32_StartupCommand
    $startupApps = Get-CimInstance Win32_StartupCommand | 
        Select-Object Name, Command, Location, User, Caption
} Catch {
    Write-Warning "Unable to get startup apps. Requires admin privileges or a compatible OS."
    $startupApps = @()
}

$startupAppsHtml = $startupApps |
    ConvertTo-Html -Fragment -As Table -PreContent "<h2 id='startupApps'>Startup Applications</h2>"

# -----------------------------------------------------
#              13. TOP PROCESSES
# -----------------------------------------------------
Write-Host "Collecting top processes by CPU and memory usage..."
Try {
    # Top 10 by CPU
    $topCPUProcesses = Get-Process | 
        Sort-Object CPU -Descending | 
        Select-Object Name, CPU, Id, WS, VM, StartTime -First 10

    # Top 10 by WorkingSet (MB)
    $topMemProcesses = Get-Process | 
        Sort-Object WS -Descending | 
        Select-Object Name,
                      @{Name='WorkingSet(MB)';Expression={[math]::Round($_.WS / 1MB,2)}},
                      Id, CPU, StartTime -First 10
} Catch {
    Write-Warning "Unable to retrieve process info. Requires admin privileges."
    $topCPUProcesses = @()
    $topMemProcesses = @()
}

$topCPUHtml = $topCPUProcesses |
    ConvertTo-Html -Fragment -As Table -PreContent "<h2 id='topCPU'>Top 10 Processes by CPU Usage</h2>"

$topMemHtml = $topMemProcesses |
    ConvertTo-Html -Fragment -As Table -PreContent "<h2 id='topMem'>Top 10 Processes by Memory Usage</h2>"

# -----------------------------------------------------
#              TABLE OF CONTENTS
# -----------------------------------------------------
# We'll build a small "Summary" or "Table of Contents" section at the top
# Each link (styled like a button) jumps to the relevant anchor in the report
$tableOfContents = @"
<div id='toc'>
    <h2>Summary / Table of Contents</h2>
    <div>
        <a href="#systemInfo" class="button">System Info</a>
        <a href="#installedSoftware" class="button">Installed Software</a>
        <a href="#hotfixes" class="button">Hotfixes / Updates</a>
        <a href="#machineUserPolicies" class="button">Policies (Machine/User)</a>
        <a href="#diskUsage" class="button">Disk Usage</a>
        <a href="#network" class="button">Network</a>
        <a href="#allServices" class="button">All Services</a>
        <a href="#scheduledTasks" class="button">Scheduled Tasks</a>
        <a href="#localUsers" class="button">Local Users</a>
        <a href="#envVars" class="button">Env Variables</a>
        <a href="#eventErrors" class="button">System Errors</a>
        <a href="#startupApps" class="button">Startup Apps</a>
        <a href="#topCPU" class="button">Top CPU</a>
        <a href="#topMem" class="button">Top Memory</a>
    </div>
</div>
"@

# -----------------------------------------------------
#             BUILDING THE HTML REPORT
# -----------------------------------------------------
Write-Host "Compiling HTML report..."

$reportHtml = @"
<html>
    <head>
        <meta charset="utf-8" />
        <title>Diagnostic Report - $($env:COMPUTERNAME)</title>
        <style>
            body {
                font-family: Arial, sans-serif; 
                margin: 20px;
            }
            .button {
                display: inline-block;
                background-color: #007BFF;
                color: #fff;
                padding: 6px 12px;
                margin: 4px;
                text-decoration: none;
                border-radius: 4px;
            }
            .button:hover {
                background-color: #0056b3;
            }
            table {
                border-collapse: collapse;
                margin: 10px 0; 
                width: 100%;
            }
            th, td {
                border: 1px solid #ccc;
                padding: 8px;
            }
            th {
                background: #f2f2f2;
            }
            h1, h2, h3 {
                font-family: Arial, sans-serif;
                margin-top: 35px;
            }
            .section {
                margin-bottom: 30px;
            }
            #toc {
                margin-bottom: 20px;
                border: 1px solid #ccc;
                padding: 10px;
            }
        </style>
    </head>
    <body>
        <h1>Comprehensive Diagnostic Report for $($env:COMPUTERNAME)</h1>

        $tableOfContents

        $systemInfoHtml
        $installedSoftwareHtml
        $hotfixesHtml
        $machinePolicyHtml
        $userPolicyHtml
        $diskUsageHtml
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
    </body>
</html>
"@

Write-Host "Saving report to $outputPath"
$reportHtml | Out-File -FilePath $outputPath -Encoding UTF8

Write-Host "`nExtended diagnostic report created successfully!"
Write-Host "Location: $outputPath"
Write-Host "Opening the report..."
Start-Process $outputPath
