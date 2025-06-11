#region Script Info
$Script_Name = "Disk Usage Report"
$Description = "This script will generate a disk usage report for the local machine and save it as an HTML file"
$Author = "Seth Burns - System Administrator II - Service Center"
$last_tested = "05-23-2025"
$version = "1.0.0"
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



# Ensure the output directory exists
if (!(Test-Path -Path "C:\temp")) {
    New-Item -Path "C:\" -Name "temp" -ItemType "Directory" | Out-Null
}

# Collect disk data for local hard drives (DriveType 3 represents local disks)
$diskData = Get-WmiObject -Class Win32_LogicalDisk -Filter "DriveType=3" | 
    Select-Object `
        DeviceID, 
        VolumeName, 
        FileSystem,
        @{Name="Size (GB)"; Expression = { "{0:N2}" -f ($_.Size / 1GB) } },
        @{Name="FreeSpace (GB)"; Expression = { "{0:N2}" -f ($_.FreeSpace / 1GB) } }

# Convert the disk data to HTML with a title and simple CSS for styling
$htmlReport = $diskData | ConvertTo-Html -Title "Disk Data Report" -PreContent "<h1>Disk Data Report</h1>" -Head @"
<style>
    table { border-collapse: collapse; width: 100%; }
    th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
    th { background-color: #f2f2f2; }
</style>
"@

# Output the HTML content to a file in C:\temp
$htmlReport | Out-File -FilePath "C:\temp\DiskData.html" -Encoding UTF8

# Optional: Open the HTML report in the default browser
Start-Process "C:\temp\DiskData.html"
