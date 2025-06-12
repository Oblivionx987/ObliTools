#region Parameters
param (
    [string]$OutputDirectory = "C:\temp",
    [switch]$OpenReport
)
#endregion

#region Script Info
$Script_Name = "Disk Usage Report"
$Description = "This script will generate a disk usage report for the local machine and save it as an HTML file"
$Author = "Seth Burns - System Administrator II - Service Center"
$last_tested = "06-11-2025"
$version = "1.1.0"
$live = "Test"
$bmgr = "Test"
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
Write-Output "--------------------" | Yellow
Write-Output "$Author" | Yellow
Write-Output "$Script_Name" | Yellow
Write-Output "$version , $last_tested" | Yellow
Write-Output "$live , $bmgr" | Yellow
Write-Output "$Description" | Yellow
Write-Output "--------------------" | Yellow
## END Main Descriptor
#endregion

#region Ensure Output Directory Exists
if (!(Test-Path -Path $OutputDirectory)) {
    try {
        New-Item -Path $OutputDirectory -ItemType "Directory" -Force | Out-Null
    } catch {
        Write-Error "Failed to create output directory: $OutputDirectory"
        exit 1
    }
}
#endregion

#region Collect Disk Data
try {
    $diskData = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3" | 
        Select-Object `
            DeviceID, 
            VolumeName, 
            FileSystem,
            @{Name="Size (GB)"; Expression = { "{0:N2}" -f ($_.Size / 1GB) } },
            @{Name="FreeSpace (GB)"; Expression = { "{0:N2}" -f ($_.FreeSpace / 1GB) } }
} catch {
    Write-Error "Failed to retrieve disk data"
    exit 1
}
#endregion

#region Generate HTML Report
$htmlReport = $diskData | ConvertTo-Html -Title "Disk Data Report" -PreContent "<h1>Disk Data Report</h1>" -Head @"
<style>
    table { border-collapse: collapse; width: 100%; }
    th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
    th { background-color: #f2f2f2; }
    h1 { font-family: Arial, sans-serif; color: #333; }
</style>
"@

$htmlFilePath = Join-Path -Path $OutputDirectory -ChildPath "DiskData.html"
try {
    $htmlReport | Out-File -FilePath $htmlFilePath -Encoding UTF8
} catch {
    Write-Error "Failed to write HTML report to file: $htmlFilePath"
    exit 1
}
#endregion

#region Open HTML Report
if ($OpenReport) {
    try {
        Start-Process $htmlFilePath
    } catch {
        Write-Error "Failed to open HTML report: $htmlFilePath"
    }
}
#endregion
