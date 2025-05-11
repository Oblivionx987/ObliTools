<#
.SYNOPSIS
    A script to collect system diagnostics, fan information (if available), installed software,
    group policy, security policy, machine policy, system info, event logs, disk usage,
    network configuration, and user accounts.

.DESCRIPTION
    This script creates (or uses) a specified logging directory, then collects the following:
        - Fan info + basic BIOS info + system uptime in an HTML report
        - Installed software in an HTML report
        - GPO report (via gpresult)
        - Security policy (via secedit)
        - Machine policy (via RSOP_SecuritySettingNumeric)
        - System info (via Get-ComputerInfo)
        - Event logs (latest 100 from Application)
        - Disk usage
        - Network configuration
        - Local user accounts

    It requires administrative privileges for many commands to succeed (e.g., gpresult, secedit).
#>
Param(
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = "C:\temp"
)

function Test-Admin {
    # Return $true if running elevated
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Admin)) {
    Write-Warning "This script is not running with administrative privileges."
    Write-Warning "Some operations (gpresult, secedit, etc.) may fail or produce incomplete results."
    # You can optionally prompt or force elevation if desired
    # For example:
    # Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    # return
}

$machineName = $env:COMPUTERNAME

# Ensure logging directory exists
if (-not (Test-Path -Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath | Out-Null
    Write-Host "Created directory: $OutputPath" -ForegroundColor Green
}

# Build log file paths
$logFile           = Join-Path -Path $OutputPath -ChildPath "$machineName`_FanCheck.html"
$softwareLogFile   = Join-Path -Path $OutputPath -ChildPath "$machineName`_SoftwareReport.html"
$gpoReportFile     = Join-Path -Path $OutputPath -ChildPath "$machineName`_GPOReport.html"
$securityPolicyFile= Join-Path -Path $OutputPath -ChildPath "$machineName`_SecurityPolicy.inf"
$machinePolicyFile = Join-Path -Path $OutputPath -ChildPath "$machineName`_MachinePolicyReport.txt"
$systemInfoFile    = Join-Path -Path $OutputPath -ChildPath "$machineName`_SystemInfo.txt"
$eventLogFile      = Join-Path -Path $OutputPath -ChildPath "$machineName`_EventLog.txt"
$diskUsageFile     = Join-Path -Path $OutputPath -ChildPath "$machineName`_DiskUsage.txt"
$networkConfigFile = Join-Path -Path $OutputPath -ChildPath "$machineName`_NetworkConfig.txt"
$userAccountsFile  = Join-Path -Path $OutputPath -ChildPath "$machineName`_UserAccounts.txt"

# Common styles for HTML usage
$commonStyles = @"
<style>
    body { font-family: Arial, sans-serif; margin: 20px; }
    h1 { color: #0078D7; }
    table { width: 100%; border-collapse: collapse; margin-top: 20px; }
    th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
    th { background-color: #f4f4f4; }
</style>
"@

# --- Fan and System Diagnostics Report ---
Write-Host "`nGenerating Fan and System Diagnostics Report..." -ForegroundColor Cyan

$htmlContent = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Fan and System Diagnostics Report - $machineName</title>
    $commonStyles
</head>
<body>
    <h1>Fan and System Diagnostics Report - $machineName</h1>
"@

# Fan Information
try {
    $fanInfo = Get-CimInstance -ClassName Win32_Fan -ErrorAction Stop
    if ($fanInfo) {
        $htmlContent += "<h2>Fan Information</h2><table><tr><th>Device ID</th><th>Status</th><th>Desired Speed (RPM)</th><th>Current Speed (RPM)</th><th>System Name</th></tr>"
        foreach ($fan in $fanInfo) {
            $htmlContent += "<tr>
                <td>$($fan.DeviceID)</td>
                <td>$($fan.Status)</td>
                <td>$($fan.DesiredSpeed)</td>
                <td>$($fan.CurrentSpeed)</td>
                <td>$($fan.SystemName)</td>
            </tr>"
        }
        $htmlContent += "</table>"
    }
    else {
        $htmlContent += "<h2>Fan Information</h2><p>No fan information is available. Ensure your system supports fan monitoring via WMI sensors.</p>"
    }
}
catch {
    $htmlContent += "<h2>Fan Information</h2><p>Failed to retrieve fan information. Error: $($_.Exception.Message)</p>"
}

# BIOS Information
$htmlContent += "<h2>System Diagnostics</h2>"
$htmlContent += "<h3>BIOS</h3><ul>"
try {
    $biosInfo = Get-CimInstance -ClassName Win32_BIOS -ErrorAction Stop
    foreach ($bios in $biosInfo) {
        if ($bios.ReleaseDate -and $bios.ReleaseDate.Length -ge 8) {
            $releaseDate = [datetime]::ParseExact($bios.ReleaseDate.Substring(0, 8), 'yyyyMMdd', $null)
        } else {
            $releaseDate = "Unknown"
        }
        $htmlContent += "<li>Manufacturer: $($bios.Manufacturer)</li>
        <li>Version: $($bios.SMBIOSBIOSVersion)</li>
        <li>Release Date: $releaseDate</li>"
    }
}
catch {
    $htmlContent += "<li>Failed to retrieve BIOS information. Error: $($_.Exception.Message)</li>"
}
$htmlContent += "</ul>"

# System Uptime
try {
    $lastBoot = (Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop).LastBootUpTime
    $htmlContent += "<h3>System Uptime</h3><p>Last Boot: $lastBoot</p>"
}
catch {
    $htmlContent += "<h3>System Uptime</h3><p>Could not retrieve system uptime. Error: $($_.Exception.Message)</p>"
}

$htmlContent += "</body></html>"

# Save Fan and System Report
$htmlContent | Out-File -FilePath $logFile -Encoding UTF8
Write-Host "Fan and System Diagnostics report saved: $logFile" -ForegroundColor Green

# --- Installed Software Report ---
Write-Host "`nGenerating Installed Software Report..." -ForegroundColor Cyan

$softwareContent = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Installed Software Report - $machineName</title>
    $commonStyles
</head>
<body>
    <h1>Installed Software Report - $machineName</h1>
    <table>
        <tr><th>Name</th><th>Version</th><th>Install Date</th><th>Publisher</th><th>Estimated Size (MB)</th><th>Install Location</th></tr>
"@

try {
    $installedSoftware = Get-ItemProperty `
        HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* , `
        HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* `
        -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -ne $null } |
        Select-Object DisplayName, DisplayVersion, InstallDate, Publisher, EstimatedSize, InstallLocation

    foreach ($software in $installedSoftware) {
        # Handle InstallDate which might come in different formats
        $rawDate = $software.InstallDate
        $parsedDate = "N/A"
        if ($rawDate -and $rawDate -match '^\d{8}$') {
            # Attempt to parse YYYYMMDD
            try {
                $parsedDate = [datetime]::ParseExact($rawDate, 'yyyyMMdd', $null)
            }
            catch {
                $parsedDate = $rawDate
            }
        }
        elseif ($rawDate -and ([datetime]::TryParse($rawDate, [ref] $null))) {
            # If it’s a parseable date format
            $parsedDate = [datetime]$rawDate
        }
        else {
            $parsedDate = if ($rawDate) { $rawDate } else { "N/A" }
        }

        $publisher = if ($software.Publisher) { $software.Publisher } else { "N/A" }
        $estimatedSize = if ($software.EstimatedSize) {
            [math]::round([double]$software.EstimatedSize / 1024, 2)
        } else {
            "N/A"
        }
        $installLocation = if ($software.InstallLocation) { $software.InstallLocation } else { "N/A" }

        $softwareContent += "<tr>
            <td>$($software.DisplayName)</td>
            <td>$($software.DisplayVersion)</td>
            <td>$parsedDate</td>
            <td>$publisher</td>
            <td>$estimatedSize</td>
            <td>$installLocation</td>
        </tr>"
    }
}
catch {
    $softwareContent += "<tr><td colspan='6'>Failed to retrieve software information. Error: $($_.Exception.Message)</td></tr>"
}

$softwareContent += "</table></body></html>"

# Save Installed Software Report
$softwareContent | Out-File -FilePath $softwareLogFile -Encoding UTF8
Write-Host "Installed Software report saved: $softwareLogFile" -ForegroundColor Green

# --- Other Reports ---
Write-Host "`nGenerating Group Policy Report..." -ForegroundColor Cyan
try {
    gpresult /h $gpoReportFile
    Write-Host "Group Policy report generated: $gpoReportFile" -ForegroundColor Green
}
catch {
    Write-Warning "Failed to run gpresult. Error: $($_.Exception.Message)"
}

Write-Host "`nExporting Security Policies..." -ForegroundColor Cyan
try {
    secedit /export /cfg $securityPolicyFile
    Write-Host "Security policies exported: $securityPolicyFile" -ForegroundColor Green
}
catch {
    Write-Warning "Failed to export security policies via secedit. Error: $($_.Exception.Message)"
}

Write-Host "`nSaving Machine Policy Report..." -ForegroundColor Cyan
try {
    $machinePolicy = Get-CimInstance -Namespace "ROOT\RSOP\Computer" -ClassName "RSOP_SecuritySettingNumeric"
    $machinePolicy | Out-File -FilePath $machinePolicyFile -Encoding UTF8
    Write-Host "Machine policy report saved: $machinePolicyFile" -ForegroundColor Green
}
catch {
    Write-Warning "Failed to retrieve machine policy. Error: $($_.Exception.Message)"
}

Write-Host "`nSaving System Information..." -ForegroundColor Cyan
try {
    $systemInfo = Get-ComputerInfo
    $systemInfo | Out-File -FilePath $systemInfoFile -Encoding UTF8
    Write-Host "System information report saved: $systemInfoFile" -ForegroundColor Green
}
catch {
    Write-Warning "Failed to retrieve system information. Error: $($_.Exception.Message)"
}

Write-Host "`nSaving Event Log (Application)..." -ForegroundColor Cyan
try {
    $eventLogs = Get-EventLog -LogName Application -Newest 100
    $eventLogs | Out-File -FilePath $eventLogFile -Encoding UTF8
    Write-Host "Event log report saved: $eventLogFile" -ForegroundColor Green
}
catch {
    Write-Warning "Failed to retrieve event logs. Error: $($_.Exception.Message)"
}

Write-Host "`nSaving Disk Usage Information..." -ForegroundColor Cyan
try {
    $diskUsage = Get-PSDrive -PSProvider FileSystem
    $diskUsage | Out-File -FilePath $diskUsageFile -Encoding UTF8
    Write-Host "Disk usage report saved: $diskUsageFile" -ForegroundColor Green
}
catch {
    Write-Warning "Failed to retrieve disk usage. Error: $($_.Exception.Message)"
}

Write-Host "`nSaving Network Configuration..." -ForegroundColor Cyan
try {
    $networkAdapters = Get-NetAdapter
    $networkAdapters | Out-File -FilePath $networkConfigFile -Encoding UTF8
    Write-Host "Network configuration report saved: $networkConfigFile" -ForegroundColor Green
}
catch {
    Write-Warning "Failed to retrieve network adapters. Error: $($_.Exception.Message)"
}

Write-Host "`nSaving Local User Accounts..." -ForegroundColor Cyan
try {
    $userAccounts = Get-LocalUser
    $userAccounts | Out-File -FilePath $userAccountsFile -Encoding UTF8
    Write-Host "User accounts report saved: $userAccountsFile" -ForegroundColor Green
}
catch {
    Write-Warning "Failed to retrieve local user accounts. Error: $($_.Exception.Message)"
}

Write-Host "`nAll tasks complete."
