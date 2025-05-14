# Check if Outlook is installed
Write-Host "Checking for Microsoft Outlook installation..."
$outlook = Get-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\App Paths\OUTLOOK.EXE" -ErrorAction SilentlyContinue
if ($outlook) {
    Write-Host "Outlook is installed: $($outlook.'(default)')"
} else {
    Write-Warning "Outlook is not installed."
}

# Check for S/MIME certificates in the Current User store
Write-Host "Checking for valid S/MIME certificates in the user's store..."
$certs = Get-ChildItem -Path Cert:\CurrentUser\My | Where-Object {
    $_.EnhancedKeyUsageList.FriendlyName -contains "Secure Email" -and $_.NotAfter -gt (Get-Date)
}

if ($certs.Count -gt 0) {
    Write-Host "Found $($certs.Count) valid S/MIME certificate(s):"
    $certs | ForEach-Object {
        Write-Host " - Subject: $($_.Subject)"
        Write-Host "   Issuer: $($_.Issuer)"
        Write-Host "   Valid To: $($_.NotAfter)"
    }
} else {
    Write-Warning "No valid S/MIME certificates found."
}

# Check for S/MIME registry settings in Outlook (Current User)
Write-Host "Checking S/MIME-related Outlook registry settings..."
$regPath = "HKCU:\Software\Microsoft\Office"
$officeVersions = Get-ChildItem -Path $regPath | Where-Object { $_.Name -match '\\\d+\.\d+$' }

foreach ($version in $officeVersions) {
    $smimeSettings = Get-ItemProperty -Path "$($version.PSPath)\Outlook\Security" -ErrorAction SilentlyContinue
    if ($smimeSettings) {
        Write-Host "Found S/MIME settings under $($version.PSChildName):"
        Write-Host " - Encryption Algorithm: $($smimeSettings.EncryptAlgName)"
        Write-Host " - Signing Algorithm: $($smimeSettings.SignAlgName)"
    } else {
        Write-Warning "No S/MIME settings found under version $($version.PSChildName)."
    }
}

Write-Host "S/MIME check complete."