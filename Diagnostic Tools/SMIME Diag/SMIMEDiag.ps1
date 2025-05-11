<#
.SYNOPSIS
   Diagnoses and troubleshoots S/MIME issues in Microsoft Outlook.

.DESCRIPTION
   This script performs the following tasks:
    1. Checks if the required S/MIME components are installed.
    2. Verifies the presence of valid S/MIME certificates.
    3. Checks Outlook settings related to S/MIME.
    4. Collects relevant event logs for S/MIME-related errors.
    5. Generates a diagnostic report in HTML format.

.PARAMETER ReportPath
   The file path where the HTML report will be saved. Defaults to C:\Temp\SMIMEDiagReport_<timestamp>.html

.EXAMPLE
   .\SMIMEDiag.ps1 -ReportPath "C:\Temp\MySMIMEDiagReport.html"

.NOTES
   Requires Administrator privileges.
#>

[CmdletBinding()]
Param(
    [string]
    $ReportPath = "C:\Temp\SMIMEDiagReport_{0:yyyy-MM-dd_HH-mm-ss}.html" -f (Get-Date)
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
# 1. Check if S/MIME components are installed
#------------------------------------------------------------------------------
try {
    $smimeComponents = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Cryptography\OID" -ErrorAction Stop
    $reportSections.Add("<h3>1. S/MIME Components</h3><p>S/MIME components are installed.</p>")
} catch {
    $reportSections.Add("<h3>1. S/MIME Components</h3><p>S/MIME components are not installed or could not be verified.</p>")
}

#------------------------------------------------------------------------------
# 2. Verify the presence of valid S/MIME certificates
#------------------------------------------------------------------------------
try {
    $certificates = Get-ChildItem -Path Cert:\CurrentUser\My | Where-Object { $_.EnhancedKeyUsageList -match "Secure Email" }
    if ($certificates) {
        $certReport = foreach ($cert in $certificates) {
            [pscustomobject]@{
                Subject = $cert.Subject
                Issuer  = $cert.Issuer
                Expiry  = $cert.NotAfter
            }
        }
        $reportSections.Add(
            ("<h3>2. S/MIME Certificates</h3>" +
             ($certReport | ConvertTo-Html -Fragment -Property Subject,Issuer,Expiry))
        )
    } else {
        $reportSections.Add("<h3>2. S/MIME Certificates</h3><p>No valid S/MIME certificates found.</p>")
    }
} catch {
    $reportSections.Add("<h3>2. S/MIME Certificates</h3><p>Error retrieving S/MIME certificates: $_</p>")
}

#------------------------------------------------------------------------------
# 3. Check Outlook settings related to S/MIME
#------------------------------------------------------------------------------
try {
    $outlookSettings = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Office\*\Outlook\Security" -ErrorAction Stop
    $reportSections.Add("<h3>3. Outlook S/MIME Settings</h3><pre>$(ConvertTo-Json $outlookSettings -Depth 2)</pre>")
} catch {
    $reportSections.Add("<h3>3. Outlook S/MIME Settings</h3><p>Could not retrieve Outlook S/MIME settings.</p>")
}

#------------------------------------------------------------------------------
# 4. Collect relevant event logs for S/MIME-related errors
#------------------------------------------------------------------------------
try {
    $events = Get-EventLog -LogName Application -Newest 500 -ErrorAction SilentlyContinue |
        Where-Object { $_.Message -match "S/MIME|Secure Email" } |
        Select-Object -First 50

    if ($events) {
        $eventReport = foreach ($evt in $events) {
            [pscustomobject]@{
                EventID     = $evt.EventID
                EntryType   = $evt.EntryType
                Source      = $evt.Source
                TimeWritten = $evt.TimeWritten
                Message     = ($evt.Message -replace "`r|`n"," ")
            }
        }
        $reportSections.Add(
            ("<h3>4. Relevant Event Logs</h3>" +
             ($eventReport | ConvertTo-Html -Fragment -Property EventID,EntryType,Source,TimeWritten,Message))
        )
    } else {
        $reportSections.Add("<h3>4. Relevant Event Logs</h3><p>No relevant event logs found.</p>")
    }
} catch {
    $reportSections.Add("<h3>4. Relevant Event Logs</h3><p>Error retrieving event logs: $_</p>")
}

#------------------------------------------------------------------------------
# Combine HTML and output
#------------------------------------------------------------------------------
# Build final HTML
$htmlHeader = @"
<html>
<head>
    <meta charset='UTF-8'>
    <title>S/MIME Diagnostic Report</title>
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
    <h2>S/MIME Diagnostic Report</h2>
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
    Write-Host "S/MIME Diagnostic Report generated at: $ReportPath"
} catch {
    Write-Error "Failed to write report to $ReportPath. Error: $_"
}