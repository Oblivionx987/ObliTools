# S/MIME Troubleshooter for Outlook on Windows - Office 365
# Created by ChatGPT | Rev: 2025-05

Write-Host "`n=== Outlook S/MIME Troubleshooter (Office 365 Desktop) ===`n"

function Check-OutlookInstallation {
    Write-Host "[1] Checking Outlook installation..."
    $outlook = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\OUTLOOK.EXE" -ErrorAction SilentlyContinue
    if ($outlook) {
        Write-Host " - Outlook installed at: $($outlook.'(Default)')" -ForegroundColor Green
    } else {
        Write-Host " - Outlook is not installed or registry entry missing." -ForegroundColor Red
        return $false
    }
    return $true
}

function Check-OutlookS/MIMESettings {
    Write-Host "`n[2] Checking Outlook S/MIME registry settings..."
    $regPath = "HKCU:\Software\Microsoft\Office\16.0\Outlook\Security"
    if (Test-Path $regPath) {
        $smimeSettings = Get-ItemProperty -Path $regPath
        Write-Host " - Found Outlook S/MIME registry settings." -ForegroundColor Green
        Write-Host "   EncryptMessage: $($smimeSettings.EncryptMessage)"
        Write-Host "   SignMessage: $($smimeSettings.SignMessage)"
        Write-Host "   ReadAsPlain: $($smimeSettings.ReadAsPlain)"
    } else {
        Write-Host " - Could not find Outlook S/MIME settings. Profile may be default or missing." -ForegroundColor Yellow
    }
}

function Check-SmimeCertificates {
    Write-Host "`n[3] Checking Personal certificate store for S/MIME certificates..."
    $certs = Get-ChildItem -Path Cert:\CurrentUser\My | Where-Object {
        $_.EnhancedKeyUsageList.FriendlyName -contains "Secure Email"
    }
    if ($certs) {
        foreach ($cert in $certs) {
            Write-Host " - Found certificate: $($cert.Subject)"
            Write-Host "   Issuer: $($cert.Issuer)"
            Write-Host "   Expiration: $($cert.NotAfter)"
            Write-Host "   Thumbprint: $($cert.Thumbprint)"
        }
        Write-Host " - Valid S/MIME certificates found." -ForegroundColor Green
    } else {
        Write-Host " - No valid S/MIME certificates found in Personal store." -ForegroundColor Red
        Write-Host "   Suggestion: Import your secure email certificate into the Current User > Personal store."
    }
}

function Check-OutlookEncryptionSettings {
    Write-Host "`n[4] Checking Outlook encryption settings via COM automation..."
    try {
        $outlook = New-Object -ComObject Outlook.Application
        $namespace = $outlook.GetNamespace("MAPI")
        $account = $namespace.Accounts | Select-Object -First 1
        if ($account) {
            Write-Host " - Default Outlook account: $($account.DisplayName)"
            Write-Host "   Email Address: $($account.SmtpAddress)"
            Write-Host "   Account Type: $($account.AccountType)"
        } else {
            Write-Host " - No Outlook profiles or accounts found." -ForegroundColor Red
        }
    } catch {
        Write-Host " - Outlook COM automation failed. Is Outlook installed and configured?" -ForegroundColor Red
    }
}

function Check-GroupPolicyOverrides {
    Write-Host "`n[5] Checking for Group Policy overrides on Outlook security settings..."
    $gpoPath = "HKCU:\Software\Policies\Microsoft\Office\16.0\Outlook\Security"
    if (Test-Path $gpoPath) {
        Write-Host " - Found Group Policy path. The following values may override UI settings:" -ForegroundColor Yellow
        Get-ItemProperty -Path $gpoPath | Format-List
    } else {
        Write-Host " - No GPO overrides found for Outlook S/MIME." -ForegroundColor Green
    }
}

# Start Checks
if (Check-OutlookInstallation) {
    Check-OutlookS/MIMESettings
    Check-SmimeCertificates
    Check-OutlookEncryptionSettings
    Check-GroupPolicyOverrides
}

Write-Host "`n=== S/MIME Troubleshooting Complete ===`n"