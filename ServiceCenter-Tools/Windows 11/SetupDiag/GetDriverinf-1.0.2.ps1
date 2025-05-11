# Ensure the C:\temp directory exists
$directory = "C:\temp"
if (-not (Test-Path -Path $directory)) {
    New-Item -Path $directory -ItemType Directory
}

# Get the machine's actual name
$machineName = $env:COMPUTERNAME

# Define the output file path
$outputFilePath = "$directory\$machineName driver output.html"

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

# Convert the results to HTML format
$htmlContent = $result | Sort-Object DriverName | ConvertTo-Html -Property DriverName, DeviceName, InfName, DriverType -Title "Driver Information for $machineName"

# Output the HTML content to a file
$htmlContent | Out-File -FilePath $outputFilePath

# Inform the user about the location of the output file
Write-Output "The driver information has been saved to $outputFilePath"
