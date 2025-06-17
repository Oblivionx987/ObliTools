# Define the path to the mapped drives in the registry
$mappedDrivesPath = "HKCU:\Network"

# Get all subkeys under the mapped drives path
$mappedDrives = Get-ChildItem -Path $mappedDrivesPath

# Initialize an array to hold the mapped drives information
$mappedDrivesInfo = @()

# Loop through each mapped drive
foreach ($drive in $mappedDrives) {
    # Get the properties of each mapped drive
    $driveProperties = Get-ItemProperty -Path $drive.PSPath
    
    # Create a custom object to hold the drive information
    $driveInfo = [PSCustomObject]@{
        DriveLetter = $drive.PSChildName
        RemotePath  = $driveProperties.RemotePath
        UserName    = $driveProperties.UserName
        ProviderName = $driveProperties.ProviderName
    }
    
    # Add the drive information to the array
    $mappedDrivesInfo += $driveInfo
}

# Output the list of mapped drives
$mappedDrivesInfo | Format-Table -AutoSize

# Get all physical drives (local and network) using Get-PSDrive
$allDrives = Get-PSDrive | Where-Object { $_.Provider.Name -eq 'FileSystem' }
$physicalDrivesInfo = $allDrives | ForEach-Object {
    [PSCustomObject]@{
        DriveLetter = $_.Name
        Root        = $_.Root
        Provider    = $_.Provider.Name
        Description = $_.Description
    }
}

# Output the list of physical drives
Write-Host "Physical Drives:" -ForegroundColor Cyan
$physicalDrivesInfo | Format-Table -AutoSize

# Compare mapped drives and physical drives for conflicts
$conflicts = @()
foreach ($mapped in $mappedDrivesInfo) {
    foreach ($physical in $physicalDrivesInfo) {
        if ($mapped.DriveLetter -eq $physical.DriveLetter) {
            $conflicts += [PSCustomObject]@{
                DriveLetter = $mapped.DriveLetter
                MappedPath  = $mapped.RemotePath
                PhysicalRoot = $physical.Root
                Issue = "Drive letter conflict (Mapped and Physical)"
            }
        }
    }
}

if ($conflicts.Count -gt 0) {
    Write-Host "Conflicts Detected:" -ForegroundColor Red
    $conflicts | Format-Table -AutoSize
} else {
    Write-Host "No drive letter conflicts detected." -ForegroundColor Green
}
