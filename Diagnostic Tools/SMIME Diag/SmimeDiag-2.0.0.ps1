#region Script Info
$Script_Name = "SMIME Troubleshooter for Outlook on Windows - Office 365"
$Description = "S/MIME Troubleshooter for Outlook on Windows - Office 365"
$Author = "Seth Burns - System Administrator II - Service Center"
$last_tested = "05-24-2025"
$version = "2.0.0"
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


Write-Output "`n=== Outlook S/MIME Troubleshooter (Office 365 Desktop) ===`n" | Blue

function CheckOutlookInstallation {
    Write-Output "[1] Checking Outlook installation..." | Cyan
    $outlook = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\OUTLOOK.EXE" -ErrorAction SilentlyContinue
    if ($outlook) {
        Write-Output " - Outlook installed at: $($outlook.'(Default)')" | Green
    } else {
        Write-Output " - Outlook is not installed or registry entry missing." | Red
        return $false
    }
    return $true
}

function CheckOutlookS/MIMESettings {
    Write-Output "`n[2] Checking Outlook S/MIME registry settings..." | Cyan
    $regPath = "HKCU:\Software\Microsoft\Office\16.0\Outlook\Security"
    if (Test-Path $regPath) {
        $smimeSettings = Get-ItemProperty -Path $regPath
        Write-Output " - Found Outlook S/MIME registry settings." | Green
        Write-Output "   EncryptMessage: $($smimeSettings.EncryptMessage)"
        Write-Output "   SignMessage: $($smimeSettings.SignMessage)"
        Write-Output "   ReadAsPlain: $($smimeSettings.ReadAsPlain)"
    } else {
        Write-Output " - Could not find Outlook S/MIME settings. Profile may be default or missing." | Yellow
    }
}

function CheckSmimeCertificates {
    Write-Output "`n[3] Checking Personal certificate store for S/MIME certificates..." | Cyan
    $certs = Get-ChildItem -Path Cert:\CurrentUser\My | Where-Object {
        $_.EnhancedKeyUsageList.FriendlyName -contains "Secure Email"
    }
    if ($certs) {
        foreach ($cert in $certs) {
            Write-Output " - Found certificate: $($cert.Subject)"
            Write-Output "   Issuer: $($cert.Issuer)"
            Write-Output "   Expiration: $($cert.NotAfter)"
            Write-Output "   Thumbprint: $($cert.Thumbprint)"
        }
        Write-Output " - Valid S/MIME certificates found." | Green
    } else {
        Write-Output " - No valid S/MIME certificates found in Personal store." | Red
        Write-Output "   Suggestion: Import your secure email certificate into the Current User > Personal store."
    }
}

function CheckOutlookEncryptionSettings {
    Write-Output "`n[4] Checking Outlook encryption settings via COM automation..." | Cyan
    try {
        $outlook = New-Object -ComObject Outlook.Application
        $namespace = $outlook.GetNamespace("MAPI")
        $account = $namespace.Accounts | Select-Object -First 1
        if ($account) {
            Write-Output " - Default Outlook account: $($account.DisplayName)"
            Write-Output "   Email Address: $($account.SmtpAddress)"
            Write-Output "   Account Type: $($account.AccountType)"
        } else {
            Write-Output " - No Outlook profiles or accounts found." | Red
        }
    } catch {
        Write-Output " - Outlook COM automation failed. Is Outlook installed and configured?" | Red
    }
}

function CheckGroupPolicyOverrides {
    Write-Output "`n[5] Checking for Group Policy overrides on Outlook security settings..." | Cyan
    $gpoPath = "HKCU:\Software\Policies\Microsoft\Office\16.0\Outlook\Security"
    if (Test-Path $gpoPath) {
        Write-Output " - Found Group Policy path. The following values may override UI settings:" | Yellow
        Get-ItemProperty -Path $gpoPath | Format-List
    } else {
        Write-Output " - No GPO overrides found for Outlook S/MIME." | Green
    }
}

# Start Checks
if (CheckOutlookInstallation) {
    CheckOutlookS/MIMESettings
    CheckSmimeCertificates
    CheckOutlookEncryptionSettings
    CheckGroupPolicyOverrides
}

Write-Output "`n=== S/MIME Troubleshooting Complete ===`n" | Blue