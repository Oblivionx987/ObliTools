# Define the registry paths to check for IM providers and default chat app settings
$imProviderPaths = @(
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKCU:\Software\Microsoft\Office\Outlook\Addins",
    "HKLM:\Software\Microsoft\Office\Outlook\Addins",
    "HKCU:\Software\IM Providers",
    "HKLM:\Software\IM Providers"
)

$defaultChatAppPaths = @(
    "HKCU:\Software\IM Providers",
    "HKLM:\Software\IM Providers"
)

# Function to get registry values from a specific path
function Get-RegistryValues {
    param (
        [string]$path
    )
    try {
        Get-ItemProperty -Path $path -ErrorAction Stop
    } catch {
        Write-Verbose "No registry keys found at path: $path"
        return $null
    }
}

# Check each path and collect information about IM providers
$imProviders = @()
foreach ($path in $imProviderPaths) {
    $keys = Get-ChildItem -Path $path -ErrorAction SilentlyContinue
    if ($keys) {
        foreach ($key in $keys) {
            $regValues = Get-RegistryValues -path $key.PSPath
            if ($regValues) {
                $imProviders += [PSCustomObject]@{
                    Path      = $key.PSPath
                    Name      = $regValues.DisplayName
                    Version   = $regValues.DisplayVersion
                    Publisher = $regValues.Publisher
                }
            }
        }
    }
}

# Display the collected IM provider information
if ($imProviders.Count -gt 0) {
    $imProviders | Format-Table -AutoSize
} else {
    Write-Output "No IM providers found."
}

# Check the default chat app settings
Write-Output "`nChecking default chat app settings..."

$defaultChatAppSettings = @()
foreach ($path in $defaultChatAppPaths) {
    $defaultRegValues = Get-RegistryValues -path $path
    if ($defaultRegValues) {
        $defaultChatAppSettings += [PSCustomObject]@{
            Path         = $path
            DefaultIMApp = $defaultRegValues.DefaultIMApp
            UpgradedIM   = $defaultRegValues.UpgradedIM
        }
    }
}

# Display the default chat app settings
if ($defaultChatAppSettings.Count -gt 0) {
    $defaultChatAppSettings | Format-Table -AutoSize
} else {
    Write-Output "No default chat app settings found."
}

# Additional check for Teams-specific registry keys
$teamsRegistryPath = "HKCU:\Software\Microsoft\Office\Teams"
$teamsSettings = Get-RegistryValues -path $teamsRegistryPath

if ($teamsSettings) {
    Write-Output "`nMicrosoft Teams Registry Settings:"
    $teamsSettings.PSObject.Properties | Format-Table Name, Value -AutoSize
} else {
    Write-Output "No Microsoft Teams specific settings found."
}
