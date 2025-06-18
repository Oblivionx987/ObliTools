Powershell

#region Script Info
$Script_Name = "FolderMappingChecker-2.0.0.ps1"
$Description = "This script will compare mapped drives (from registry) and physical drives, detects conflicts, and outputs detailed info."
$Author = "Seth Burns - System Administrator II - Service Center"
$last_tested = "06-17-25"
$version = "2.0.0"
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

<#
.SYNOPSIS
    Compares mapped drives (from registry) and physical drives, detects conflicts, and outputs detailed info.
.DESCRIPTION
    This script lists mapped drives (with registry location), physical drives, and highlights conflicts. It includes error handling, accessibility checks, and can export results. Modularized for maintainability.
.PARAMETER ExportCsv
    Optional path to export results as CSV.
.EXAMPLE
    .\Foldermaps2.ps1 -ExportCsv C:\temp\DriveReport.csv
#>
param(
    [string]$ExportCsv
)

function Get-MappedDrives {
    # List of registry locations to check for mapped drives
    $mappedDrivesPaths = @(
        "HKCU:\Network", # Current user
        "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Shares", # Server shares
        "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\NetworkProvider\HardenedPaths", # Hardened paths
        "HKU:\.DEFAULT\Network" # Default user profile
    )
    $mappedDrivesInfo = @()
    foreach ($mappedDrivesPath in $mappedDrivesPaths) {
        try {
            $mappedDrives = Get-ChildItem -Path $mappedDrivesPath -ErrorAction Stop
            foreach ($drive in $mappedDrives) {
                try {
                    $driveProperties = Get-ItemProperty -Path $drive.PSPath -ErrorAction Stop
                    $driveInfo = [PSCustomObject]@{
                        DriveLetter   = $drive.PSChildName
                        RemotePath    = $driveProperties.RemotePath
                        UserName      = $driveProperties.UserName
                        ProviderName  = $driveProperties.ProviderName
                        RegistryPath  = $drive.PSPath
                        RegistryRoot  = $mappedDrivesPath
                    }
                    $mappedDrivesInfo += $driveInfo
                } catch {
                    Write-Warning "Failed to read properties for mapped drive: $($drive.PSChildName) in $mappedDrivesPath ($_)."
                }
            }
        } catch {
            # Only warn if the path exists but is inaccessible, not if it simply doesn't exist
            if (Test-Path $mappedDrivesPath) {
                Write-Warning "Failed to enumerate mapped drives in registry path: $mappedDrivesPath ($_)."
            }
        }
    }
    return $mappedDrivesInfo
}

function Get-PhysicalDrives {
    $allDrives = Get-PSDrive | Where-Object { $_.Provider.Name -eq 'FileSystem' }
    $physicalDrivesInfo = $allDrives | ForEach-Object {
        [PSCustomObject]@{
            DriveLetter = $_.Name
            Root        = $_.Root
            Provider    = $_.Provider.Name
            Description = $_.Description
        }
    }
    return $physicalDrivesInfo
}

function Test-DriveAccessibility {
    param($RemotePath)
    if ([string]::IsNullOrWhiteSpace($RemotePath)) { return $false }
    try {
        Test-Path $RemotePath -ErrorAction Stop
    } catch {
        return $false
    }
}

function Find-DriveConflicts {
    param($mappedDrivesInfo, $physicalDrivesInfo)
    $conflicts = @()
    foreach ($mapped in $mappedDrivesInfo) {
        foreach ($physical in $physicalDrivesInfo) {
            if ($mapped.DriveLetter -eq $physical.DriveLetter) {
                $conflicts += [PSCustomObject]@{
                    DriveLetter  = $mapped.DriveLetter
                    MappedPath   = $mapped.RemotePath
                    PhysicalRoot = $physical.Root
                    RegistryPath = $mapped.RegistryPath
                    Issue        = "Drive letter conflict (Mapped and Physical)"
                }
            }
        }
    }
    return $conflicts
}

# Main logic
Write-Host "==== Mapped Drives (from Registry) ====" -ForegroundColor Cyan
$mappedDrivesInfo = Get-MappedDrives
if ($mappedDrivesInfo.Count -eq 0) {
    Write-Host "No mapped drives found in registry." -ForegroundColor Yellow
} else {
    $mappedDrivesInfo | Format-Table -AutoSize
}

Write-Host "==== Physical Drives ====" -ForegroundColor Cyan
$physicalDrivesInfo = Get-PhysicalDrives
if ($physicalDrivesInfo.Count -eq 0) {
    Write-Host "No physical drives found." -ForegroundColor Yellow
} else {
    $physicalDrivesInfo | Format-Table -AutoSize
}

Write-Host "==== Accessibility Check for Mapped Drives ====" -ForegroundColor Cyan
foreach ($mapped in $mappedDrivesInfo) {
    $isAccessible = Test-DriveAccessibility $mapped.RemotePath
    $status = if ($isAccessible) { 'Accessible' } else { 'NOT Accessible' }
    Write-Host ("Drive {0}: {1} [{2}]" -f $mapped.DriveLetter, $mapped.RemotePath, $status) -ForegroundColor ($isAccessible ? 'Green' : 'Red')
}

Write-Host "==== Conflict Report ====" -ForegroundColor Cyan
$conflicts = Find-DriveConflicts -mappedDrivesInfo $mappedDrivesInfo -physicalDrivesInfo $physicalDrivesInfo
if ($conflicts.Count -gt 0) {
    Write-Host "Conflicts Detected:" -ForegroundColor Red
    $conflicts | Format-Table -AutoSize
} else {
    Write-Host "No drive letter conflicts detected." -ForegroundColor Green
}

# Summary
Write-Host "==== Summary ====" -ForegroundColor Cyan
Write-Host ("Mapped Drives: {0}" -f $mappedDrivesInfo.Count)
Write-Host ("Physical Drives: {0}" -f $physicalDrivesInfo.Count)
Write-Host ("Conflicts: {0}" -f $conflicts.Count)

# Optional export
if ($ExportCsv) {
    try {
        $report = $mappedDrivesInfo + $physicalDrivesInfo + $conflicts
        $report | Export-Csv -Path $ExportCsv -NoTypeInformation -Force
        Write-Host "Results exported to $ExportCsv" -ForegroundColor Green
    } catch {
        Write-Warning "Failed to export results: $_"
    }
}
