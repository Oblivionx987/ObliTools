# LockScreenCheck.ps1 - Checks relevant registry keys for lock screen and personalization settings
# Usage: Run as standard or admin. Outputs registry values for lock screen related settings.

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

# Function to read all registry values under a given path, filtering out default properties
function Get-RegistryValues {
    param($Path)
    try {
        $key = Get-Item -Path $Path -ErrorAction Stop
        $values = Get-ItemProperty -Path $Path
        $filtered = $values.PSObject.Properties | Where-Object { $_.Name -notin @('PSPath','PSParentPath','PSChildName','PSDrive','PSProvider') }
        [PSCustomObject]@{
            Path = $Path
            Values = if ($filtered) {
                $filtered | ForEach-Object { "$($_.Name) = $($_.Value)" }
            } else {
                "No custom values set."
            }
        }
    } catch {
        [PSCustomObject]@{
            Path = $Path
            Values = "Path not found or inaccessible"
        }
    }
}

# Collect all settings
$results = foreach ($path in $registryPaths) {
    Get-RegistryValues -Path $path
}

# Output results in readable format
foreach ($result in $results) {
    Write-Host "`nRegistry Path: $($result.Path)" -ForegroundColor Cyan
    if ($result.Values -is [string]) {
        Write-Host "  $($result.Values)" -ForegroundColor DarkGray
    } else {
        $result.Values | ForEach-Object {
            Write-Host "  $_"
        }
    }
}

# Optional: Export to file (uncomment to use)
# $results | ConvertTo-Json -Depth 4 | Out-File -FilePath "LockScreenCheckResults.json" -Encoding UTF8