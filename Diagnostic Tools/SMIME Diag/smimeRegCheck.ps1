# Function to check a registry path and output its contents
function Check-RegistryPath {
    param (
        [string]$Path
    )

    Write-Host "Checking registry path: $Path"

    if (Test-Path $Path) {
        Get-ItemProperty -Path $Path | ForEach-Object {
            $_ | Get-Member -MemberType Properties | ForEach-Object {
                $name = $_.Name
                $value = (Get-ItemProperty -Path $Path).$name
                Write-Host "$name : $value"
            }
        }
    } else {
        Write-Host "Path not found: $Path"
    }

    Write-Host "`n" # New line for better readability
}

# Registry paths to check
$registryPaths = @(
    "HKCU\Software\Microsoft\Office\16.0\Outlook\Security",
    "HKCU\Software\Microsoft\Office\15.0\Outlook\Security",
    "HKCU\Software\Microsoft\Office\14.0\Outlook\Security",
    "HKCU\Software\Microsoft\Office\13.0\Outlook\Security",
    "HKCU\Software\Microsoft\Office\12.0\Outlook\Security",
    "HKCU\Software\Policies\Microsoft\Office\16.0\Outlook\Security",
    "HKCU\Software\Policies\Microsoft\Office\15.0\Outlook\Security",
    "HKCU\Software\Policies\Microsoft\Office\14.0\Outlook\Security",
    "HKCU\Software\Policies\Microsoft\Office\13.0\Outlook\Security",
    "HKCU\Software\Policies\Microsoft\Office\12.0\Outlook\Security"
)

# Iterate over each registry path and check its contents
foreach ($path in $registryPaths) {
    Check-RegistryPath -Path $path
}

Write-Host "Registry check completed."
