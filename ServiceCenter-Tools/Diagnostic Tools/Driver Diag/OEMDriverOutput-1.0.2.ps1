powershell

#region Script Info
$Script_Name = "OEM Driver Output"
$Description = "This script will generate an HTML report of OEM drivers installed on the local machine and save it as an HTML file"
$Author = "Seth Burns - System Administrator II - Service Center"
$last_tested = "04-18-25"
$version = "1.0.2"
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


## Get the local machine name
$MachineName = $env:COMPUTERNAME
Write-Output ("$MachineName detected")

# Ensure output directory exists
if (-not (Test-Path "C:\temp")) {
    New-Item -Path "C:\temp" -ItemType Directory -Force | Out-Null
}

# Define the output file path
$outputFile = "C:\temp\$MachineName-driversoutput.html"

# Run the PNPUTIL command and capture the output
$driverData = pnputil /enum-drivers /files

# Parse the driver data into objects
$drivers = @()
$current = @{}
foreach ($line in $driverData) {
    if ($line -match '^\s*$') { continue }
    if ($line -match '^[=\-]+$') { continue }
    if ($line -match '^Published Name\s*:\s*(.+)$') {
        if ($current.Count) { $drivers += [PSCustomObject]$current; $current = @{} }
        $current["PublishedName"] = $Matches[1].Trim()
    } elseif ($line -match '^Driver Package Provider\s*:\s*(.+)$') {
        $current["Provider"] = $Matches[1].Trim()
    } elseif ($line -match '^Class\s*:\s*(.+)$') {
        $current["Class"] = $Matches[1].Trim()
    } elseif ($line -match '^Driver Version and Date\s*:\s*(.+)$') {
        $current["VersionDate"] = $Matches[1].Trim()
    } elseif ($line -match '^Signer Name\s*:\s*(.+)$') {
        $current["Signer"] = $Matches[1].Trim()
    } elseif ($line -match '^Inbox\s*:\s*(.+)$') {
        $current["Inbox"] = $Matches[1].Trim()
    } elseif ($line -match '^Files\s*:\s*(.+)$') {
        $current["Files"] = $Matches[1].Trim()
    } elseif ($line -match '^Original Name\s*:\s*(.+)$') {
        $current["OriginalName"] = $Matches[1].Trim()
    } elseif ($line -match '^Provider Name\s*:\s*(.+)$') {
        $current["ProviderName"] = $Matches[1].Trim()
    } elseif ($line -match '^Catalog File\s*:\s*(.+)$') {
        $current["CatalogFile"] = $Matches[1].Trim()
    } elseif ($line -match '^Driver INF\s*:\s*(.+)$') {
        $current["INF"] = $Matches[1].Trim()
    } elseif ($line -match '^Section Name\s*:\s*(.+)$') {
        $current["SectionName"] = $Matches[1].Trim()
    } elseif ($line -match '^Device Name\s*:\s*(.+)$') {
        $current["DeviceName"] = $Matches[1].Trim()
    } elseif ($line -match '^Device ID\s*:\s*(.+)$') {
        $current["DeviceID"] = $Matches[1].Trim()
    } elseif ($line -match '^Driver Node Strong Name\s*:\s*(.+)$') {
        $current["StrongName"] = $Matches[1].Trim()
    } elseif ($line -match '^Driver Store Path\s*:\s*(.+)$') {
        $current["StorePath"] = $Matches[1].Trim()
    }
}
if ($current.Count) { $drivers += [PSCustomObject]$current }

# Build HTML header with sortable table
$htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>Driver Information</title>
    <style>
        body { font-family: Arial, sans-serif; }
        table { width: 100%; border-collapse: collapse; }
        th, td { border: 1px solid #ddd; padding: 8px; }
        th { background-color: #4CAF50; color: white; cursor: pointer; }
        tr:nth-child(even) { background-color: #f2f2f2; }
    </style>
    <script>
        function sortTable(n) {
            var table, rows, switching, i, x, y, shouldSwitch, dir, switchcount = 0;
            table = document.getElementById("driverTable");
            switching = true;
            dir = "asc";
            while (switching) {
                switching = false;
                rows = table.rows;
                for (i = 1; i < (rows.length - 1); i++) {
                    shouldSwitch = false;
                    x = rows[i].getElementsByTagName("TD")[n];
                    y = rows[i + 1].getElementsByTagName("TD")[n];
                    if (dir == "asc") {
                        if (x.innerHTML.toLowerCase() > y.innerHTML.toLowerCase()) {
                            shouldSwitch = true;
                            break;
                        }
                    } else if (dir == "desc") {
                        if (x.innerHTML.toLowerCase() < y.innerHTML.toLowerCase()) {
                            shouldSwitch = true;
                            break;
                        }
                    }
                }
                if (shouldSwitch) {
                    rows[i].parentNode.insertBefore(rows[i + 1], rows[i]);
                    switching = true;
                    switchcount ++;
                } else {
                    if (switchcount == 0 && dir == "asc") {
                        dir = "desc";
                        switching = true;
                    }
                }
            }
        }
    </script>
</head>
<body>
    <h1>Driver Information for $MachineName</h1>
    <table id="driverTable">
        <tr>
            <th onclick="sortTable(0)">Published Name</th>
            <th onclick="sortTable(1)">Provider</th>
            <th onclick="sortTable(2)">Class</th>
            <th onclick="sortTable(3)">Version/Date</th>
            <th onclick="sortTable(4)">Signer</th>
            <th onclick="sortTable(5)">Device Name</th>
        </tr>
"@

# Add driver rows
foreach ($driver in $drivers) {
    $htmlContent += "<tr>"
    $htmlContent += "<td>$($driver.PublishedName)</td>"
    $htmlContent += "<td>$($driver.Provider)</td>"
    $htmlContent += "<td>$($driver.Class)</td>"
    $htmlContent += "<td>$($driver.VersionDate)</td>"
    $htmlContent += "<td>$($driver.Signer)</td>"
    $htmlContent += "<td>$($driver.DeviceName)</td>"
    $htmlContent += "</tr>"
}

# Close HTML
$htmlContent += @"
    </table>
</body>
</html>
"@

# Save the HTML content to a file
Set-Content -Path $outputFile -Value $htmlContent -Encoding UTF8

Write-Host "Driver information has been exported to $outputFile"
Start-Process -FilePath $outputFile
