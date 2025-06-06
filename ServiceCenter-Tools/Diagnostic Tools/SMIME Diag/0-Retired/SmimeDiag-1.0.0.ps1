#region Script Info
$Script_Name = "SMIME Diagnostic Script"
$Description = "This script performs diagnostics on S/MIME configurations."
$Author = "Seth Burns - System Administrator II - Service Center"
$last_tested = "04-18-25"
$version = "1.0.0"
$live = "Retired"
$bmgr = "Retired"
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
Write-Output "---------------------------------------------" | Yellow
Write-Output "$Author" | Yellow
Write-Output "$Script_Name" | Yellow
Write-Output "Current Version - $version , Last Test - $last_tested" | Yellow
Write-Output "Testing stage - $live , Bomgar stage - $bmgr" | Yellow
Write-Output "Description - $Description" | Yellow
Write-Output "---------------------------------------------" | Yellow
## END Main Descriptor
#endregion



# Check if Outlook is installed
Write-Output "Checking for Microsoft Outlook installation..." | Yellow
$outlook = Get-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\App Paths\OUTLOOK.EXE" -ErrorAction SilentlyContinue
if ($outlook) {
    Write-Output "Outlook is installed: $($outlook.'(default)')" | Green
} else {
    Write-Output "Outlook is not installed." | Red
}

# Check for S/MIME certificates in the Current User store
Write-Output "Checking for valid S/MIME certificates in the user's store..." | Yellow
$certs = Get-ChildItem -Path Cert:\CurrentUser\My | Where-Object {
    $_.EnhancedKeyUsageList.FriendlyName -contains "Secure Email" -and $_.NotAfter -gt (Get-Date)
}

if ($certs.Count -gt 0) {
    Write-Output "Found $($certs.Count) valid S/MIME certificate(s):"
    $certs | ForEach-Object {
        Write-Output " - Subject: $($_.Subject)"
        Write-Output "   Issuer: $($_.Issuer)"
        Write-Output "   Valid To: $($_.NotAfter)"
    }
} else {
    Write-Output "No valid S/MIME certificates found." | Red
}

# Check for S/MIME registry settings in Outlook (Current User)
Write-Output "Checking S/MIME-related Outlook registry settings..." | Yellow
$regPath = "HKCU:\Software\Microsoft\Office"
$officeVersions = Get-ChildItem -Path $regPath | Where-Object { $_.Name -match '\\\d+\.\d+$' }

foreach ($version in $officeVersions) {
    $smimeSettings = Get-ItemProperty -Path "$($version.PSPath)\Outlook\Security" -ErrorAction SilentlyContinue
    if ($smimeSettings) {
        Write-Output "Found S/MIME settings under $($version.PSChildName):"
        Write-Output " - Encryption Algorithm: $($smimeSettings.EncryptAlgName)"
        Write-Output " - Signing Algorithm: $($smimeSettings.SignAlgName)"
    } else {
        Write-Output "No S/MIME settings found under version $($version.PSChildName)." | Red
    }
}

Write-Output "S/MIME check complete." | Green