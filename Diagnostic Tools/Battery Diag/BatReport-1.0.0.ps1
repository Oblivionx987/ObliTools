

Powershell

#region Script Info
$Script_Name = "Battery Report"
$Description = "This script will generate a battery report for the local machine and save it as an HTML file"
$Author = "Seth Burns - System Administrator II - Service Center"
$last_tested = "05/23/2025"
$version = "1.0.0"
$live = "Retired"
$bmgr = "Retired"
#endregion

## Functions
function Red { process { Write-Host $_ -ForegroundColor Red }}
function Green { process { Write-Host $_ -ForegroundColor Green }}
function Yellow { process { Write-Host $_ -ForegroundColor Yellow }}
function DarkRed { process { Write-Host $_ -ForegroundColor DarkRed }}

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



# Get the local machine name
$machineName = $env:COMPUTERNAME
Write-Output ("$machineName detected")

# Define the output file
$outputFile = "C:\Temp\Battery Report for $machineName.html"

# Gather battery information (supports multiple batteries)
$batteries = Get-CimInstance Win32_Battery

# Create a timestamp
$timeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# Begin constructing HTML
$htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>Battery Report for $machineName</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h2 { margin-bottom: 5px; }
        h4 { margin-top: 5px; color: #666; }
        table { width: 100%; border-collapse: collapse; margin-bottom: 40px; }
        th, td { border: 1px solid #ccc; padding: 10px; text-align: left; }
        th { background-color: #f2f2f2; }
        .battery-bar-container {
            width: 200px;
            height: 20px;
            border: 1px solid #999;
            background-color: #f9f9f9;
        }
        .battery-bar {
            height: 100%;
        }
        .low { background-color: red; }
        .medium { background-color: orange; }
        .high { background-color: green; }
        .no-battery {
            font-weight: bold;
            color: red;
            margin-top: 20px;
        }
    </style>
</head>
<body>
    <h2>Battery Report for $machineName</h2>
    <h4>Report Generated: $timeStamp</h4>
"@

# Check for battery presence
if (!$batteries -or $batteries.Count -eq 0) {
    $htmlContent += @"
    <div class="no-battery">
        No battery detected. This machine may be a desktop or otherwise hardwired for power.
    </div>
</body>
</html>
"@
}
else {
    # Build battery tables if one or more batteries are found
    foreach ($battery in $batteries) {
        # Determine a user-friendly battery status
        $batteryStatusDesc = switch ($battery.BatteryStatus) {
            1 { "Discharging" }
            2 { "AC Power" }
            3 { "Fully Charged" }
            Default { "Unknown" }
        }

        # Map numeric chemistry to a friendly label
        $batteryChemistryDesc = switch ($battery.Chemistry) {
            1 { "Other" }
            2 { "Unknown" }
            3 { "Lead Acid" }
            4 { "Nickel Cadmium" }
            5 { "Nickel Metal Hydride" }
            6 { "Lithium-ion" }
            7 { "Zinc Air" }
            8 { "Lithium Polymer" }
            Default { "Undocumented" }
        }

        # Determine color-coded class for the battery bar based on percentage
        $chargePercentage = $battery.EstimatedChargeRemaining
        if ($chargePercentage -lt 30) {
            $barClass = "low"
        }
        elseif ($chargePercentage -lt 60) {
            $barClass = "medium"
        }
        else {
            $barClass = "high"
        }

        # Build the HTML table for this battery
        $htmlContent += @"
        <table>
            <tr>
                <th colspan="2">Battery: $($battery.DeviceID)</th>
            </tr>
            <tr>
                <td><strong>Device ID</strong></td>
                <td>$($battery.DeviceID)</td>
            </tr>
            <tr>
                <td><strong>Battery Status</strong></td>
                <td>$($battery.BatteryStatus) ($batteryStatusDesc)</td>
            </tr>
            <tr>
                <td><strong>Estimated Charge Remaining</strong></td>
                <td>
                    $chargePercentage %
                    <div class="battery-bar-container">
                        <div class="battery-bar $barClass" style="width: $chargePercentage%;"></div>
                    </div>
                </td>
            </tr>
            <tr>
                <td><strong>Estimated Run Time</strong></td>
                <td>$($battery.EstimatedRunTime) minutes</td>
            </tr>
            <tr>
                <td><strong>Battery Chemistry</strong></td>
                <td>$batteryChemistryDesc</td>
            </tr>
            <tr>
                <td><strong>Full Charge Capacity</strong></td>
                <td>$($battery.FullChargeCapacity) mWh</td>
            </tr>
            <tr>
                <td><strong>Design Capacity</strong></td>
                <td>$($battery.DesignCapacity) mWh</td>
            </tr>
            <tr>
                <td><strong>Manufacturer</strong></td>
                <td>$($battery.Manufacturer)</td>
            </tr>
            <tr>
                <td><strong>Name</strong></td>
                <td>$($battery.Name)</td>
            </tr>
        </table>
"@
    }

    # Close out the HTML if battery info exists
    $htmlContent += @"
</body>
</html>
"@
}

# Ensure the output directory exists
if (!(Test-Path "C:\Temp")) {
    New-Item -ItemType Directory -Path "C:\Temp" | Out-Null
}

# Write HTML content to file
$htmlContent | Out-File -Encoding utf8 -FilePath $outputFile

Write-Host "Battery report generated at $outputFile"
Start-Process $outputFile