# S/MIME Troubleshooter for Office 365
# Created by ChatGPT | Rev: 2025-05

Write-Host "`n=== Office 365 S/MIME Troubleshooter ===`n"

function Check-BrowserSupport {
    Write-Host "[1] Checking browser compatibility..."
    $browser = (Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\https\UserChoice").ProgId
    switch -Regex ($browser) {
        "IE.HTTP" { Write-Host " - Internet Explorer detected (OK for legacy S/MIME use)" -ForegroundColor Green }
        "Edge" { Write-Host " - Microsoft Edge detected. May require IE mode for S/MIME." -ForegroundColor Yellow }
        default { Write-Host " - Browser: $browser. S/MIME support varies." -ForegroundColor Yellow }
    }
}

function Check-SmimeControl {
    Write-Host "`n[2] Checking S/MIME control installation..."
    $smimeControl = Get-ChildItem "C:\Windows\Downloaded Program Files" | Where-Object { $_.Name -match "smime" }
    if ($smimeControl) {
        Write-Host " - S/MIME Control is installed." -ForegroundColor Green
    } else {
        Write-Host " - S/MIME Control is NOT installed." -ForegroundColor Red
        Write-Host "   Suggestion: Log into Outlook Web Access (OWA) and install the S/MIME control add-on."
    }
}

function Check-Certificates {
    Write-Host "`n[3] Checking user certificates in Personal store..."
    $certs = Get-ChildItem -Path Cert:\CurrentUser\My | Where-Object { $_.EnhancedKeyUsageList.FriendlyName -match "Secure Email" }
    if ($certs) {
        foreach ($cert in $certs) {
            Write-Host " - Found certificate: $($cert.Subject)"
            Write-Host "   Issuer: $($cert.Issuer)"
            Write-Host "   Expiration: $($cert.NotAfter)"
        }
        Write-Host " - Secure Email certificates found." -ForegroundColor Green
    } else {
        Write-Host " - No secure email certificates found." -ForegroundColor Red
        Write-Host "   Suggestion: Import a valid S/MIME certificate into your Personal certificate store."
    }
}

function Check-ExchangeConnection {
    Write-Host "`n[4] Checking Exchange Online connectivity..."
    try {
        $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ `
            -Credential (Get-Credential) -Authentication Basic -AllowRedirection -ErrorAction Stop
        Write-Host " - Connected to Exchange Online successfully." -ForegroundColor Green
        Remove-PSSession $Session
    } catch {
        Write-Host " - Unable to connect to Exchange Online." -ForegroundColor Red
        Write-Host "   Check: Network connectivity, credentials, and whether WinRM is enabled."
    }
}

function Check-MailboxSmimeSettings {
    Write-Host "`n[5] Checking mailbox S/MIME settings..."
    try {
        Import-Module ExchangeOnlineManagement
        Connect-ExchangeOnline -UserPrincipalName (Read-Host "Enter UPN (user@domain.com)")
        $upn = (Get-ExoMailbox -ResultSize 1).UserPrincipalName
        $smimeSettings = Get-IRMConfiguration
        Write-Host " - IRM Configuration:"
        Write-Host "   InternalLicensingEnabled: $($smimeSettings.InternalLicensingEnabled)"
        Write-Host "   ExternalLicensingEnabled: $($smimeSettings.ExternalLicensingEnabled)"
        Disconnect-ExchangeOnline -Confirm:$false
    } catch {
        Write-Host " - Could not retrieve mailbox settings." -ForegroundColor Red
    }
}

# Run Checks
Check-BrowserSupport
Check-SmimeControl
Check-Certificates
Check-ExchangeConnection
Check-MailboxSmimeSettings

Write-Host "`n=== Troubleshooting Complete ===`n"