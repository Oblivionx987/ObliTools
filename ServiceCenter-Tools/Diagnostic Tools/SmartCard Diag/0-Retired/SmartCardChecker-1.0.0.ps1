#region Script Info
$Script_Name = "Smart Card Troubleshooting Script"
$Description = "This script checks the status of smart card services, lists smart card readers, retrieves relevant event logs, and optionally runs certutil -scinfo to gather information about smart cards. It compiles the findings into an HTML report for easy review."
$Author = "Seth Burns - System Administrator II - Service Center"
$last_tested = "04-18-25"
$version = "1.0.0"
$live = "Retired"
$bmgr = "Retired"
#endregion

#region Text Colors 
function Red     { process { Write-Host $_ -ForegroundColor Red }}
function Green   { process { Write-Host $_ -ForegroundColor Green }}
function Yellow  { process { Write-Host $_ -ForegroundColor Yellow }}
function Blue    { process { Write-Host $_ -ForegroundColor Blue }}
function Cyan    { process { Write-Host $_ -ForegroundColor Cyan }}
function Magenta { process { Write-Host $_ -ForegroundColor Magenta }}
function White   { process { Write-Host $_ -ForegroundColor White }}
function Gray    { process { Write-Host $_ -ForegroundColor Gray }}
#endregion

#region Main Descriptor
## START Main Descriptor
Write-Output "---------------------------------------------" | Yellow
Write-Output "$Author" | Yellow
Write-Output "$Script_Name" | Yellow
Write-Output "Current Version - $version , Last Test - $last_tested" | Yellow
Write-Output "Testing stage - $live , Bomgar stage - $bmgr" | Yellow
Write-Output "Description - $Description" | Yellow
Write-Output "---------------------------------------------" | Yellow
## END Main Descriptor
#endregion

<#
.SYNOPSIS
   Troubleshoots common smart card issues and outputs findings to an HTML report.

.DESCRIPTION
   This script:
    1. Checks the status of key Windows services related to smart cards.
    2. Attempts to list any smart card readers and relevant info (if available).
    3. Retrieves recent related event log entries from both Application and System logs containing 'smart card' or 'SCard'.
    4. (Optional) Attempts to execute certutil -scinfo to probe the smart card subsystem further if certutil is available.
    5. Compiles the findings into an HTML report.

.PARAMETER ReportPath
   The file path where the HTML report will be saved. Defaults to C:\Temp\SmartCardReport_<timestamp>.html

.PARAMETER MaxEvents
   The maximum number of events to retrieve from each log.

.PARAMETER CheckCertUtil
   If $true, attempts a certutil -scinfo command to collect additional info.

.EXAMPLE
   .\SmartCardChecker-1.0.0.ps1 -ReportPath "C:\Temp\MyReport.html" -MaxEvents 50 -CheckCertUtil $true

.NOTES
   Requires Administrator privileges.
#>

Param(
    [string]$ReportPath,
    [int]$MaxEvents = 50,
    [switch]$CheckCertUtil
)

# Convert SwitchParameter to boolean
$CheckCertUtil = [bool]$CheckCertUtil

# Ensure $ReportPath is a valid string
if (-not [string]::IsNullOrWhiteSpace($ReportPath) -and -not ($ReportPath -is [string])) {
    Write-Error "The value for -ReportPath must be a valid string. You provided: $ReportPath" -ErrorAction Stop
}

# Assign default value if $ReportPath is not provided or is invalid
if (-not $ReportPath -or $ReportPath -eq $false) {
    $ReportPath = "C:\Temp\SmartCardReport_{0:yyyy-MM-dd_HH-mm-ss}.html" -f (Get-Date)
}

# Validate $MaxEvents range
if (-not $MaxEvents -or $MaxEvents -lt 1 -or $MaxEvents -gt 1000) {
    Write-Warning "Invalid value for -MaxEvents. Defaulting to 50."
    $MaxEvents = 50
}

Set-StrictMode -Version Latest

# Ensure script is running with Administrator privileges:
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Error "You must run this script as an Administrator!" -ErrorAction Stop
}

# Create directory if it doesn't exist
$reportDir = Split-Path $ReportPath
if (-not (Test-Path $reportDir)) {
    try {
        New-Item -ItemType Directory -Path $reportDir -ErrorAction Stop | Out-Null
    } catch {
        Write-Error "Failed to create directory $reportDir. Error: $_" -ErrorAction Stop
    }
}

# A list of results that will be combined into HTML later
$reportSections = New-Object System.Collections.Generic.List[System.Object]

#------------------------------------------------------------------------------
# 1. Check the status of key Windows services
#------------------------------------------------------------------------------
$servicesToCheck = @(
    "SCardSvr",       # Smart Card service
    "ScDeviceEnum",   # Smart Card Device Enumeration Service (on some systems)
    "SCPolicySvc"     # Smart Card Removal Policy
)

$serviceReport = foreach ($serviceName in $servicesToCheck) {
    $serviceObj = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
    if ($serviceObj) {
        [pscustomobject]@{
            ServiceName = $serviceObj.Name
            Status      = $serviceObj.Status
            StartType   = (Get-CimInstance Win32_Service -Filter "Name='$serviceName'").StartMode
        }
    } else {
        [pscustomobject]@{
            ServiceName = $serviceName
            Status      = "Service not found"
            StartType   = "N/A"
        }
    }
}

$reportSections.Add(
    ("<h3>1. Smart Card Services Status</h3>" +
     ($serviceReport | ConvertTo-Html -Fragment -Property ServiceName,Status,StartType))
)

#------------------------------------------------------------------------------
# 2. Attempt to list any detected smart card readers (via WMI)
#------------------------------------------------------------------------------
try {
    $readers = Get-CimInstance -ClassName Win32_SmartCardReader -ErrorAction Stop
    if ($readers) {
        $readerReport = foreach ($reader in $readers) {
            [pscustomobject]@{
                ReaderName     = $reader.DeviceName
                DeviceID       = $reader.DeviceID
                Status         = "Detected"
            }
        }
    } else {
        $readerReport = ,([pscustomobject]@{
            ReaderName     = "None"
            DeviceID       = "N/A"
            Status         = "No smart card readers found"
        })
    }
} catch {
    $readerReport = ,([pscustomobject]@{
        ReaderName     = "Error"
        DeviceID       = "N/A"
        Status         = "Could not query smart card readers (Win32_SmartCardReader unavailable)"
    })
}

$reportSections.Add(
    ("<h3>2. Smart Card Readers</h3>" +
     ($readerReport | ConvertTo-Html -Fragment -Property ReaderName,DeviceID,Status))
)

#------------------------------------------------------------------------------
# 3. Retrieve recent event logs for errors or warnings related to 'smart card' or 'SCard'
#------------------------------------------------------------------------------
$LogNames = @("Application","System")
$logReport = @()

foreach ($logName in $LogNames) {
    $events = Get-EventLog -LogName $logName -Newest 500 -ErrorAction SilentlyContinue |
        Where-Object { $_.Message -match "smart card|scard" } |
        Select-Object -First $MaxEvents

    if ($events) {
        foreach ($evt in $events) {
            $logReport += [pscustomobject]@{
                LogName     = $logName
                EventID     = $evt.EventID
                EntryType   = $evt.EntryType
                Source      = $evt.Source
                TimeWritten = $evt.TimeWritten
                Message     = ($evt.Message -replace "`r|`n"," ")
            }
        }
    } else {
        $logReport += [pscustomobject]@{
            LogName     = $logName
            EventID     = "N/A"
            EntryType   = "N/A"
            Source      = "N/A"
            TimeWritten = "N/A"
            Message     = "No relevant events found."
        }
    }
}

$reportSections.Add(
    ("<h3>3. Relevant Smart Card Event Logs</h3>" +
     ($logReport | Sort-Object LogName, TimeWritten -Descending |
      ConvertTo-Html -Fragment -Property LogName,EventID,EntryType,Source,TimeWritten,Message))
)

#------------------------------------------------------------------------------
# 4. Optional: Attempt certutil -scinfo if available
#------------------------------------------------------------------------------
if ($CheckCertUtil) {
    Write-Host "Running certutil -scinfo..."
    $certutilCommand = Get-Command "certutil.exe" -ErrorAction SilentlyContinue
    if ($certutilCommand) {
        $certutilPath = $certutilCommand.Source
        try {
            $certutilOutput = certutil -scinfo 2>&1
            $reportSections.Add("<h3>4. Certutil -scinfo Output</h3><pre>$certutilOutput</pre>")
        } catch {
            $reportSections.Add("<h3>4. Certutil -scinfo Output</h3><p>Error running certutil: $_</p>")
        }
    } else {
        $reportSections.Add("<h3>4. Certutil -scinfo Output</h3><p>certutil.exe not found on this system.</p>")
    }
}

#------------------------------------------------------------------------------
# Combine HTML and output
#------------------------------------------------------------------------------
# Build final HTML
$htmlHeader = @"
<html>
<head>
    <meta charset='UTF-8'>
    <title>Smart Card Troubleshooting Report</title>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; }
        h2, h3 { color: #2E86C1; }
        pre { background-color: #F4F6F7; padding: 10px; border: 1px solid #D5D8DC; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #D5D8DC; padding: 8px; text-align: left; }
        th { background-color: #2E86C1; color: white; }
    </style>
</head>
<body>
    <h2>Smart Card Troubleshooting Report</h2>
    <p>Report generated on $(Get-Date)</p>
"@

$htmlFooter = @"
</body>
</html>
"@

$htmlBody = $reportSections -join "<br/>"
$fullHtml = $htmlHeader + $htmlBody + $htmlFooter

try {
    $fullHtml | Out-File -FilePath $ReportPath -Encoding UTF8
    Write-Host "Smart Card Troubleshooting Report generated at: $ReportPath"
} catch {
    Write-Error "Failed to write report to $ReportPath. Error: $_"
}