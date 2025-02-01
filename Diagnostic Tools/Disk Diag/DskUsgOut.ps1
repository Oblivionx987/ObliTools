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
