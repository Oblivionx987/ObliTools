powershell

#region Script Info
$Script_Name = "OEM Driver Output"
$Description = "This script will generate an HTML report of OEM drivers installed on the local machine and save it as an HTML file"
$Author = "Seth Burns - System Administrator II - Service Center"
$last_tested = "05-23-25"
$version = "1.0.3"
$live = "test"
$bmgr = "test"
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


param (
    [string]$InfName = "oem*.inf"  # Can be any pattern like "oem123.inf" or "mydriver.inf"
)

# Validate input parameter
if (-not $InfName) {
    Write-Error "The InfName parameter cannot be empty. Please provide a valid INF file name or pattern."
    exit 1
}

# Get all matching .inf files from driver store
$infPaths = Get-ChildItem -Path "C:\Windows\INF" -Filter $InfName -ErrorAction SilentlyContinue

if ($infPaths.Count -eq 0) {
    Write-Host "No matching INF files found for pattern: $InfName" -ForegroundColor Yellow
    exit
}

# Prepare HTML output
$reportPath = "C:\Temp\INF_Report_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
$htmlHeader = @"
<html>
<head>
    <meta charset='UTF-8'>
    <title>INF File Report</title>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; }
        h2 { color: #2E86C1; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #D5D8DC; padding: 8px; text-align: left; }
        th { background-color: #2E86C1; color: white; }
    </style>
</head>
<body>
    <h2>INF File Report</h2>
    <p>Report generated on $(Get-Date)</p>
    <table>
        <tr>
            <th>File</th>
            <th>Provider</th>
            <th>Class</th>
            <th>Description</th>
            <th>Signed Status</th>
        </tr>
"@

$htmlBody = ""

foreach ($infFile in $infPaths) {
    Write-Host "`nFound: $($infFile.FullName)" -ForegroundColor Cyan
    try {
        # Read contents of the INF file
        $lines = Get-Content $infFile.FullName -ErrorAction Stop

        # Attempt to extract useful info from common INF sections
        $providerMatch = $lines | Select-String -Pattern "^Provider="
        $classMatch    = $lines | Select-String -Pattern "^Class="
        $descMatch     = $lines | Select-String -Pattern "^DeviceDesc="

        $provider = if ($providerMatch) { $providerMatch.Line -replace '.*Provider\s*=\s*','' } else { "Not Found" }
        $class    = if ($classMatch) { $classMatch.Line -replace '.*Class\s*=\s*','' } else { "Not Found" }
        $desc     = if ($descMatch) { $descMatch.Line -replace '.*DeviceDesc\s*=\s*','' } else { "Not Found" }

        # Check if the driver is signed (Windows 11 compatibility requirement)
        $isSigned = $lines | Select-String -Pattern "^CatalogFile="
        $signedStatus = if ($isSigned) { "Signed" } else { "Unsigned" }

        # Append to HTML body with signed status
        $htmlBody += "<tr><td>$($infFile.FullName)</td><td>$provider</td><td>$class</td><td>$desc</td><td>$signedStatus</td></tr>"

        # Additional check for missing fields or unsigned drivers
        if ($provider -eq "Not Found" -or $class -eq "Not Found" -or $desc -eq "Not Found" -or $signedStatus -eq "Unsigned") {
            Write-Warning "Some fields are missing or the driver is unsigned in: $($infFile.FullName)"
        }
    } catch {
        Write-Warning "Failed to read or parse file: $($infFile.FullName). Error: $_"
        $htmlBody += "<tr><td>$($infFile.FullName)</td><td colspan='4'>Error parsing file</td></tr>"
    }
}

$htmlFooter = @"
    </table>
</body>
</html>
"@

# Write HTML to file
$htmlContent = $htmlHeader + $htmlBody + $htmlFooter
try {
    $htmlContent | Out-File -FilePath $reportPath -Encoding UTF8
    Write-Host "Report generated at: $reportPath" -ForegroundColor Green
    Start-Process $reportPath
} catch {
    Write-Error "Failed to write report to $reportPath. Error: $_"
}

Write-Host "`nProcessing completed." -ForegroundColor Cyan

#usage
# .\Get-InfInfo.ps1 -InfName "oem56.inf"