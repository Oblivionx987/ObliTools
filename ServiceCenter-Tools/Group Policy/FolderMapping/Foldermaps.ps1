# Check all local drives
Write-Output "Local Drives:"
Get-PSDrive -PSProvider FileSystem | ForEach-Object {
    $drive = $_
    $freeSpace = [math]::round($drive.Free / 1GB, 2)
    $usedSpace = [math]::round(($drive.Used - $drive.Free) / 1GB, 2)
    $totalSpace = [math]::round($drive.Used / 1GB, 2)
    Write-Output "Drive: $($drive.Name)"
    Write-Output "  Free Space: $freeSpace GB"
    Write-Output "  Used Space: $usedSpace GB"
    Write-Output "  Total Space: $totalSpace GB"
    Write-Output ""
}

# Check all network location mappings
Write-Output "Network Location Mappings:"
Get-WmiObject -Class Win32_NetworkConnection | ForEach-Object {
    $networkConnection = $_
    Write-Output "Name: $($networkConnection.Name)"
    Write-Output "  LocalName: $($networkConnection.LocalName)"
    Write-Output "  RemoteName: $($networkConnection.RemoteName)"
    Write-Output "  ProviderName: $($networkConnection.ProviderName)"
    Write-Output ""
}

Write-Output "Script completed."
