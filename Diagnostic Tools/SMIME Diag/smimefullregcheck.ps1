# Define possible registry paths related to Outlook S/MIME
$registryPaths = @(
    "HKLM:\Software\Microsoft\Office\Outlook\Addins\Outlook.SMimeAddin",
    "HKLM:\Software\WOW6432Node\Microsoft\Office\Outlook\Addins\Outlook.SMimeAddin",
    "HKCU:\Software\Microsoft\Office\Outlook\Addins\Outlook.SMimeAddin",
    "HKCU:\Software\Microsoft\Office\16.0\Outlook\Security",
    "HKCU:\Software\Microsoft\Office\15.0\Outlook\Security",
    "HKCU:\Software\Microsoft\Office\14.0\Outlook\Security",
    "HKCU:\Software\Policies\Microsoft\Office\16.0\Outlook\Security",
    "HKCU:\Software\Policies\Microsoft\Office\15.0\Outlook\Security",
    "HKCU:\Software\Policies\Microsoft\Office\14.0\Outlook\Security",
    "HKLM:\Software\Policies\Microsoft\Office\16.0\Outlook\Security",
    "HKLM:\Software\Policies\Microsoft\Office\15.0\Outlook\Security",
    "HKLM:\Software\Policies\Microsoft\Office\14.0\Outlook\Security"
)

Write-Host "Searching for Outlook S/MIME-related registry keys..."

foreach ($path in $registryPaths) {
    if (Test-Path $path) {
        Write-Host "`nFound registry path: $path" -ForegroundColor Green
        try {
            Get-ItemProperty -Path $path | Format-List
        } catch {
            Write-Host "  Could not read values from: $path" -ForegroundColor Yellow
        }
    } else {
        Write-Host "Not found: $path" -ForegroundColor DarkGray
    }
}

Write-Host "`nRegistry scan complete."