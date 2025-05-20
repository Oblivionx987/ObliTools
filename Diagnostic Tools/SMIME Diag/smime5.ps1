# S/MIME Troubleshooter for Outlook on Windows - Office 365
# Enhanced by ChatGPT | Rev: 2025-05-20

$LogPath = "$env:USERPROFILE\Desktop\Outlook_SMIME_Troubleshooter.log"
Start-Transcript -Path $LogPath -Force

Write-Host "`n=== Outlook S/MIME Troubleshooter (Office 365 Desktop) ===`n"

$Summary = @()

function Add-Summary {
    param($msg) 
    $Summary += $msg
}

function Check-OutlookInstallation {
    Write-Host "[1] Checking Outlook installation..."
    try {
        $outlook = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\OUTLOOK.EXE" -ErrorAction Stop
        Write-Host " - Outlook installed at: $($outlook.'(Default)')" -ForegroundColor Green
        Add-Summary "Outlook Installed: Yes"
        return $true
    } catch {
        Write-Host " - Outlook is not installed or registry entry missing." -ForegroundColor Red
        Add-Summary "Outlook Installed: No"
        return $false
    }
}

function Check-OutlookVersion {
    Write-Host "`n[2] Checking Outlook version..."
    try {
        $outlook = New-Object -ComObject Outlook.Application
        $version = $outlook.Version
        Write-Host " - Outlook Version: $version"
        Add-Summary "Outlook Version: $version"
    } catch {
        Write-Host " - Unable to retrieve Outlook version." -ForegroundColor Yellow
        Add-Summary "Outlook Version: Unknown"
    }
}

function Check-OutlookS/MIMESettings {
    Write-Host "`n[3] Checking Outlook S/MIME registry settings..."
    $regPath = "HKCU:\Software\Microsoft\Office\16.0\Outlook\Security"
    if (Test-Path $regPath) {
        $settings = Get-ItemProperty -Path $regPath
        Write-Host " - Found S/MIME settings." -ForegroundColor Green
        Write-Host "   EncryptMessage: $($settings.EncryptMessage)"
        Write-Host "   SignMessage: $($settings.SignMessage)"
        Write-Host "   ReadAsPlain: $($settings.ReadAsPlain)"
        Add-Summary "S/MIME Registry Settings: Found"
    } else {
        Write-Host " - Could not find S/MIME settings." -ForegroundColor Yellow
        Add-Summary "S/MIME Registry Settings: Not Found"
    }
}

function Check-SmimeCertificates {
    Write-Host "`n[4] Checking Personal certificate store for S/MIME certificates..."
    try {
        $certs = Get-ChildItem -Path Cert:\CurrentUser\My | Where-Object {
            $_.EnhancedKeyUsageList.FriendlyName -contains "Secure Email"
        }

        if ($certs) {
            foreach ($cert in $certs) {
                $daysLeft = ($cert.NotAfter - (Get-Date)).Days
                Write-Host " - Found: $($cert.Subject)"
                Write-Host "   Issuer: $($cert.Issuer)"
                Write-Host "   Expires: $($cert.NotAfter) ($daysLeft days left)"
                Write-Host "   Thumbprint: $($cert.Thumbprint)"
                if ($daysLeft -lt 30) {
                    Write-Host "   WARNING: Certificate expires soon!" -ForegroundColor Yellow
                    Add-Summary "S/MIME Cert '$($cert.Subject)' - Expires in $daysLeft days"
                } else {
                    Add-Summary "S/MIME Cert '$($cert.Subject)' - Valid"
                }
            }
        } else {
            Write-Host " - No valid S/MIME certificates found." -ForegroundColor Red
            Add-Summary "S/MIME Certificates: None Found"
        }
    } catch {
        Write-Host " - Error checking certificates: $_" -ForegroundColor Red
    }
}

function Check-OutlookEncryptionSettings {
    Write-Host "`n[5] Checking Outlook encryption settings via COM..."
    try {
        $outlook = New-Object -ComObject Outlook.Application
        $namespace = $outlook.GetNamespace("MAPI")
        $account = $namespace.Accounts | Select-Object -First 1
        if ($account) {
            Write-Host " - Default Account: $($account.DisplayName)"
            Write-Host "   Email: $($account.SmtpAddress)"
            Write-Host "   Type: $($account.AccountType)"
            Add-Summary "Outlook Default Account: $($account.DisplayName) ($($account.SmtpAddress))"
        } else {
            Write-Host " - No accounts found." -ForegroundColor Red
            Add-Summary "Outlook Account: Not Found"
        }
    } catch {
        Write-Host " - COM Error: $_" -ForegroundColor Red
        Add-Summary "Outlook Encryption Settings: Error"
    }
}

function Check-GroupPolicyOverrides {
    Write-Host "`n[6] Checking Group Policy for Outlook S/MIME settings..."
    $gpoPath = "HKCU:\Software\Policies\Microsoft\Office\16.0\Outlook\Security"
    if (Test-Path $gpoPath) {
        Write-Host " - Group Policy overrides found:" -ForegroundColor Yellow
        Get-ItemProperty -Path $gpoPath | Format-List
        Add-Summary "GPO Overrides: Present"
    } else {
        Write-Host " - No GPO overrides found." -ForegroundColor Green
        Add-Summary "GPO Overrides: None"
    }
}

# Main Execution
if (Check-OutlookInstallation) {
    Check-OutlookVersion
    Check-OutlookS/MIMESettings
    Check-SmimeCertificates
    Check-OutlookEncryptionSettings
    Check-GroupPolicyOverrides
}

Write-Host "`n=== S/MIME Troubleshooting Complete ===`n"
Stop-Transcript

# GUI Summary (Popup)
Add-Type -AssemblyName PresentationFramework
[System.Windows.MessageBox]::Show(($Summary -join "`n"), "Outlook S/MIME Troubleshooter Summary", 'OK', 'Information')