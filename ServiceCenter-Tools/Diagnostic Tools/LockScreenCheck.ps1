# Define registry paths to check
$registryPaths = @(
    "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization",
    "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Personalization",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP",
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager",
    "HKCU:\Control Panel\Desktop",
    "HKLM:\Control Panel\Desktop"
)

# Function to read all registry values under a given path
function Get-RegistryValues {
    param($Path)
    try {
        $key = Get-Item -Path $Path -ErrorAction Stop
        $values = Get-ItemProperty -Path $Path
        [PSCustomObject]@{
            Path = $Path
            Values = $values.PSObject.Properties | ForEach-Object {
                "$($_.Name) = $($_.Value)"
            }
        }
    } catch {
        [PSCustomObject]@{
            Path = $Path
            Values = "Path not found or inaccessible"
        }
    }
}

# Collect and display all settings
$results = foreach ($path in $registryPaths) {
    Get-RegistryValues -Path $path
}

# Output results in table
$results | ForEach-Object {
    Write-Host "`nRegistry Path: $($_.Path)" -ForegroundColor Cyan
    if ($_.Values -is [string]) {
        Write-Host "  $_.Values" -ForegroundColor DarkGray
    } else {
        $_.Values | ForEach-Object {
            Write-Host "  $_"
        }
    }
}