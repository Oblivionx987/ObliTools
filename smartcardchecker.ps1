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
   .\TroubleshootSmartCard.ps1 -ReportPath "C:\Temp\MyReport.html" -MaxEvents 50 -CheckCertUtil $true

.NOTES
   Requires Administrator privileges.
#>

[CmdletBinding()]
Param(
    [string]
    $ReportPath = "C:\Temp\SmartCardReport_{0:yyyy-MM-dd_HH-mm-ss}.html" -f (Get-Date),

    [ValidateRange(1, 1000)]
    [int]
    $MaxEvents = 20,

    [switch]
    $CheckCertUtil
)

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
    $certutilPath = (Get-Command "certutil.exe" -ErrorAction SilentlyContinue)?.Source
    if ($certutilPath) {
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