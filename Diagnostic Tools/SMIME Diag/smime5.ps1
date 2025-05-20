Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create Form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Outlook S/MIME Troubleshooter"
$form.Size = New-Object System.Drawing.Size(700,600)
$form.StartPosition = "CenterScreen"

# Output TextBox
$outputBox = New-Object System.Windows.Forms.TextBox
$outputBox.Multiline = $true
$outputBox.ScrollBars = "Vertical"
$outputBox.Size = New-Object System.Drawing.Size(660, 400)
$outputBox.Location = New-Object System.Drawing.Point(10, 10)
$outputBox.ReadOnly = $true
$outputBox.Font = 'Consolas,10'

# Run Button
$runButton = New-Object System.Windows.Forms.Button
$runButton.Text = "Run Troubleshooter"
$runButton.Size = New-Object System.Drawing.Size(200,40)
$runButton.Location = New-Object System.Drawing.Point(10, 420)

# Save Log Button
$saveButton = New-Object System.Windows.Forms.Button
$saveButton.Text = "Save Log"
$saveButton.Size = New-Object System.Drawing.Size(200,40)
$saveButton.Location = New-Object System.Drawing.Point(220, 420)

# Exit Button
$exitButton = New-Object System.Windows.Forms.Button
$exitButton.Text = "Exit"
$exitButton.Size = New-Object System.Drawing.Size(200,40)
$exitButton.Location = New-Object System.Drawing.Point(430, 420)

$form.Controls.AddRange(@($outputBox, $runButton, $saveButton, $exitButton))

function Write-Log {
    param([string]$text)
    $outputBox.AppendText($text + "`r`n")
}

function Run-Troubleshooter {
    $outputBox.Clear()
    Write-Log "=== S/MIME Troubleshooter for Outlook (Office 365) ==="
    
    # Outlook install check
    Write-Log "[1] Checking Outlook installation..."
    try {
        $outlook = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\OUTLOOK.EXE"
        Write-Log " - Outlook installed: $($outlook.'(Default)')"
    } catch {
        Write-Log " - Outlook not detected in registry."
    }

    # Registry S/MIME settings
    Write-Log "`n[2] Checking Outlook S/MIME registry settings..."
    $regPath = "HKCU:\Software\Microsoft\Office\16.0\Outlook\Security"
    if (Test-Path $regPath) {
        $smimeSettings = Get-ItemProperty -Path $regPath
        Write-Log " - EncryptMessage: $($smimeSettings.EncryptMessage)"
        Write-Log " - SignMessage: $($smimeSettings.SignMessage)"
        Write-Log " - ReadAsPlain: $($smimeSettings.ReadAsPlain)"
    } else {
        Write-Log " - Registry settings not found. Default profile?"
    }

    # S/MIME certs
    Write-Log "`n[3] Checking for S/MIME certificates..."
    $certs = Get-ChildItem Cert:\CurrentUser\My | Where-Object {
        $_.EnhancedKeyUsageList.FriendlyName -contains "Secure Email"
    }
    if ($certs) {
        foreach ($cert in $certs) {
            Write-Log " - Cert: $($cert.Subject) | Exp: $($cert.NotAfter)"
        }
    } else {
        Write-Log " - No S/MIME certificates found in Personal store."
    }

    # Outlook COM
    Write-Log "`n[4] Checking Outlook profile info..."
    try {
        $ol = New-Object -ComObject Outlook.Application
        $ns = $ol.GetNamespace("MAPI")
        $acc = $ns.Accounts | Select-Object -First 1
        Write-Log " - Account: $($acc.DisplayName) | $($acc.SmtpAddress)"
    } catch {
        Write-Log " - COM automation failed. Outlook may not be configured."
    }

    # GPO Overrides
    Write-Log "`n[5] Checking for Group Policy overrides..."
    $gpoPath = "HKCU:\Software\Policies\Microsoft\Office\16.0\Outlook\Security"
    if (Test-Path $gpoPath) {
        $gpo = Get-ItemProperty $gpoPath
        foreach ($prop in $gpo.PSObject.Properties) {
            Write-Log " - $($prop.Name): $($prop.Value)"
        }
    } else {
        Write-Log " - No GPO S/MIME overrides found."
    }

    Write-Log "`n=== Troubleshooting Complete ==="
}

$runButton.Add_Click({ Run-Troubleshooter })

$saveButton.Add_Click({
    $saveDialog = New-Object System.Windows.Forms.SaveFileDialog
    $saveDialog.Filter = "Text Files (*.txt)|*.txt"
    $saveDialog.Title = "Save Troubleshooting Log"
    $saveDialog.FileName = "smime_troubleshoot_log.txt"
    if ($saveDialog.ShowDialog() -eq "OK") {
        $outputBox.Lines | Out-File -FilePath $saveDialog.FileName -Encoding UTF8
        [System.Windows.Forms.MessageBox]::Show("Log saved to:`n$($saveDialog.FileName)", "Saved")
    }
})

$exitButton.Add_Click({ $form.Close() })

# Run GUI
[void]$form.ShowDialog()