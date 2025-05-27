Powershell

## Summary
## This script is designed to diagnose S/MIME issues in Outlook on Windows, specifically for Office 365 installations.
## It checks for Outlook installation, version, S/MIME settings, certificates, and group policy overrides.
## It provides detailed output and logs the results to a file on the user's desktop.

#region Script Info
$Script_Name = "S/MIME Diagnostic Script"
$Description = "S/MIME Troubleshooter for Outlook on Windows - Office 365"
$Author = "Seth Burns - System Administrator II - Service Center"
$last_tested = "05-25-2025"
$version = "3.0.0"
$live = "Live"
$bmgr = "Live"
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


$LogPath = "$env:USERPROFILE\Desktop\Outlook_SMIME_Troubleshooter.log"
Start-Transcript -Path $LogPath -Force

Write-Output "`n=== Outlook S/MIME Troubleshooter (Office 365 Desktop) ===`n" | Blue

$Summary = @()

function Add-Summary {
    param($msg) 
    $Summary += $msg
}

function CheckOutlookInstallation {
    Write-Output "[1] Checking Outlook installation..." | Cyan
    try {
        $outlook = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\OUTLOOK.EXE" -ErrorAction Stop
        Write-Output " - Outlook installed at: $($outlook.'(Default)')" | Green
        Add-Summary "Outlook Installed: Yes"
        return $true
    } catch {
        Write-Output " - Outlook is not installed or registry entry missing." | Red
        Add-Summary "Outlook Installed: No"
        return $false
    }
}

function CheckOutlookVersion {
    Write-Output "`n[2] Checking Outlook version..." | Cyan
    try {
        $outlook = New-Object -ComObject Outlook.Application
        $version = $outlook.Version
        Write-Output " - Outlook Version: $version" | Green
        Add-Summary "Outlook Version: $version"
    } catch {
        Write-Output " - Unable to retrieve Outlook version." | Yellow
        Add-Summary "Outlook Version: Unknown"
    }
}

function CheckOutlookSMIMESettings {
    Write-Output "`n[3] Checking Outlook S/MIME registry settings..." | Cyan
    $regPath = "HKCU:\Software\Microsoft\Office\16.0\Outlook\Security"
    if (Test-Path $regPath) {
        $settings = Get-ItemProperty -Path $regPath
        Write-Output " - Found S/MIME settings." | Green
        Write-Output "   EncryptMessage: $($settings.EncryptMessage)"
        Write-Output "   SignMessage: $($settings.SignMessage)"
        Write-Output "   ReadAsPlain: $($settings.ReadAsPlain)"
        Add-Summary "S/MIME Registry Settings: Found"
    } else {
        Write-Output " - Could not find S/MIME settings." | Yellow
        Add-Summary "S/MIME Registry Settings: Not Found"
    }
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

Write-Output "Searching for Outlook S/MIME-related registry keys..."

foreach ($path in $registryPaths) {
    if (Test-Path $path) {
        Write-Output "`nFound registry path: $path" | Green
        try {
            Get-ItemProperty -Path $path | Format-List
        } catch {
            Write-Output "  Could not read values from: $path" | Yellow
        }
    } else {
        Write-Output "Not found: $path"
    }
}

Write-Output "`nRegistry scan complete."
}

function CheckSmimeCertificates {
    Write-Output "`n[4] Checking Personal certificate store for S/MIME certificates..." | Cyan
    try {
        $certs = Get-ChildItem -Path Cert:\CurrentUser\My | Where-Object {
            $_.EnhancedKeyUsageList.FriendlyName -contains "Secure Email"
        }

        if ($certs) {
            foreach ($cert in $certs) {
                $daysLeft = ($cert.NotAfter - (Get-Date)).Days
                Write-Output " - Found: $($cert.Subject)"
                Write-Output "   Issuer: $($cert.Issuer)"
                Write-Output "   Expires: $($cert.NotAfter) ($daysLeft days left)"
                Write-Output "   Thumbprint: $($cert.Thumbprint)"
                if ($daysLeft -lt 30) {
                    Write-Output "   WARNING: Certificate expires soon!" | Yellow
                    Add-Summary "S/MIME Cert '$($cert.Subject)' - Expires in $daysLeft days"
                } else {
                    Add-Summary "S/MIME Cert '$($cert.Subject)' - Valid"
                }
            }
        } else {
            Write-Output " - No valid S/MIME certificates found." | Red
            Add-Summary "S/MIME Certificates: None Found"
        }
    } catch {
        Write-Output " - Error checking certificates: $_" | Red
    }
}

function CheckOutlookEncryptionSettings {
    Write-Output "`n[5] Checking Outlook encryption settings via COM..." | Cyan
    try {
        $outlook = New-Object -ComObject Outlook.Application
        $namespace = $outlook.GetNamespace("MAPI")
        $account = $namespace.Accounts | Select-Object -First 1
        if ($account) {
            Write-Output " - Default Account: $($account.DisplayName)"
            Write-Output "   Email: $($account.SmtpAddress)"
            Write-Output "   Type: $($account.AccountType)"
            Add-Summary "Outlook Default Account: $($account.DisplayName) ($($account.SmtpAddress))"
        } else {
            Write-Output " - No accounts found." | Red
            Add-Summary "Outlook Account: Not Found"
        }
    } catch {
        Write-Output " - COM Error: $_" | Red
        Add-Summary "Outlook Encryption Settings: Error"
    }
}

function CheckGroupPolicyOverrides {
    Write-Output "`n[6] Checking Group Policy for Outlook S/MIME settings..." | Cyan
    $gpoPath = "HKCU:\Software\Policies\Microsoft\Office\16.0\Outlook\Security"
    if (Test-Path $gpoPath) {
        Write-Output " - Group Policy overrides found:" | Yellow
        Get-ItemProperty -Path $gpoPath | Format-List
        Add-Summary "GPO Overrides: Present"
    } else {
        Write-Output " - No GPO overrides found." | Green
        Add-Summary "GPO Overrides: None"
    }
}

# Main Execution
if (CheckOutlookInstallation) {
    CheckOutlookVersion
    CheckOutlookSMIMESettings
    CheckSmimeCertificates
    CheckOutlookEncryptionSettings
    CheckGroupPolicyOverrides
}

Write-Output "`n=== S/MIME Troubleshooting Complete ===`n" | Blue