#region Script Info
$Script_Name = "FolderMappingChecker.ps1"
$Description = "This script will check local drives and network location mappings."
$Author = "Seth Burns - System Administrator II - Service Center"
$last_tested = "06-17-25"
$version = "1.0.0"
$live = "WIP"
$bmgr = "WIP"
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
Write-Output "--------------------"
Write-Output "$Author" | Yellow
Write-Output "$Script_Name" | Yellow
Write-Output "$version , $last_tested" | Yellow
Write-Output "$live , $bmgr" | Yellow
Write-Output "$Description" | Yellow
Write-Output "--------------------"
## END Main Descriptor
#endregion

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
