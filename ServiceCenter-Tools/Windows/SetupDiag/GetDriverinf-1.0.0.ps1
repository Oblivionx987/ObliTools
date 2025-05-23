
$version = "1.0.0"
$author = "Seth Burns - System Administarator II - Service Center"
$live = "Retired"
$bmgr = "Retired"

$description = "This script lists all active drivers and their associated .inf files"

# Get all PnP signed drivers
$drivers = Get-WmiObject Win32_PnPSignedDriver

# Create an array to store the results
$result = @()

foreach ($driver in $drivers) {
    $driverInfo = [PSCustomObject]@{
        DriverName = $driver.DriverName
        DeviceName = $driver.DeviceName
        InfName    = $driver.InfName
    }
    $result += $driverInfo
}

# Output the results
$result | Format-Table -AutoSize
