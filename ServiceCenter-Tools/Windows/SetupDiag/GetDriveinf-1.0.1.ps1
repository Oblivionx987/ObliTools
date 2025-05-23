$description = "This script lists all drivers on the device and their associated .inf files, if available"
$version = "1.0.1"
$author = "Seth Burns - System Administarator II - Service Center"
$live = "Retired"
$bmgr = "Retired"

# Get all PnP signed drivers
$pnpDrivers = Get-WmiObject Win32_PnPSignedDriver

# Get all system drivers
$systemDrivers = Get-WmiObject Win32_SystemDriver

# Create an array to store the results
$result = @()

foreach ($driver in $pnpDrivers) {
    $driverInfo = [PSCustomObject]@{
        DriverName = $driver.DriverName
        DeviceName = $driver.DeviceName
        InfName    = $driver.InfName
        DriverType = "PnP Signed Driver"
    }
    $result += $driverInfo
}

foreach ($driver in $systemDrivers) {
    $driverInfo = [PSCustomObject]@{
        DriverName = $driver.Name
        DeviceName = $driver.DisplayName
        InfName    = "N/A" # System drivers do not have an INF file
        DriverType = "System Driver"
    }
    $result += $driverInfo
}

# Output the results
$result | Sort-Object DriverName | Format-Table -AutoSize
