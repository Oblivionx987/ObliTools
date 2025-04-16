<#
.SYNOPSIS
   Troubleshoots common smart card issues and outputs findings to an HTML report.

.DESCRIPTION
   This script:
    1. Checks the status of key Windows services related to smart cards.
    2. Attempts to list any smart card readers it detects.
    3. Retrieves the 20 most recent related event log entries containing 'smart card' or 'SCard'.
    4. Compiles the findings into an HTML report and saves it to C:\Temp\SmartCardReport.html.

.NOTES
   Written for demonstration purposes. Customize for your environment.

.EXAMPLE
   .\TroubleshootSmartCard.ps1
#>

# Ensure script is running with adequate permissions:
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "You must run this script as an Administrator!" 
    exit 1
}

# Define output report path
$reportPath = "C:\Temp\SmartCardReport.html"

# Create a collection of objects to convert to HTML
$reportData = @()

# 1. Check the status of key smart card services
$servicesToCheck = @(
    "SCardSvr",      # Smart Card service
    "ScDeviceEnum",  # Smart Card Device Enumeration Service (on some systems)
    "SCPolicySvc"    # Smart Card Removal Policy
)

foreach ($serviceName in $servicesToCheck) {
    $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
    if ($service) {
        $reportData += [pscustomobject]@{
            Section      = "Service Status"
            Name         = $serviceName
            Status       = $service.Status
            StartType    = (Get-WmiObject Win32_Service -Filter "Name='$serviceName'").StartMode
        }
    } else {
        $reportData += [pscustomobject]@{
            Section      = "Service Status"
            Name         = $serviceName
            Status       = "Service not found"
            StartType    = "N/A"
        }
    }
}

# 2. Attempt to list any detected smart card readers
try {
    $readers = Get-WmiObject -Class Win32_SmartCardReader -ErrorAction Stop
    if ($readers) {
        foreach ($reader in $readers) {
            $reportData += [pscustomobject]@{
                Section  = "Smart Card Readers"
                Name     = $reader.DeviceName
                Status   = "Detected"
            }
        }
    } else {
        $reportData += [pscustomobject]@{
            Section  = "Smart Card Readers"
            Name     = "None"
            Status   = "No smart card readers found"
        }
    }
} catch {
    $reportData += [pscustomobject]@{
        Section  = "Smart Card Readers"
        Name     = "Error"
        Status   = "Could not query smart card readers (Win32_SmartCardReader unavailable)"
    }
}

# 3. Retrieve recent event logs for errors or warnings related to 'smart card' or 'SCard'
$events = Get-EventLog -LogName Application -Newest 200 `
    | Where-Object { $_.Message -match "smart card|scard" } `
    | Select-Object -First 20

if ($events) {
    foreach ($event in $events) {
        $reportData += [pscustomobject]@{
            Section     = "Event Log"
            EventID     = $event.EventID
            Source      = $event.Source
            TimeWritten = $event.TimeWritten
            Message     = $event.Message -replace "`r|`n", ' ' # replace new lines for cleaner display
        }
    }
} else {
    $reportData += [pscustomobject]@{
        Section     = "Event Log"
        EventID     = "N/A"
        Source      = "N/A"
        TimeWritten = "N/A"
        Message     = "No relevant recent events found."
    }
}

# Generate HTML report
# ConvertTo-Html will generate an HTML table from $reportData
$htmlReport = $reportData |
    Sort-Object Section, Name |
    ConvertTo-Html -Title "Smart Card Troubleshooting Report" `
                   -PreContent "<h2>Smart Card Troubleshooting Results</h2>" `
                   -PostContent "<p>Report generated on $(Get-Date)</p>"

# Write HTML report to file
$htmlReport | Out-File -FilePath $reportPath -Encoding utf8

Write-Host "Smart Card Troubleshooting Report generated at: $reportPath"