# Function to enable smart card redirection via Group Policy
function Enable-SmartCardRedirection {
    # Registry path for RDP device and resource redirection policies
    $regPath = "HKLM:\Software\Policies\Microsoft\Windows NT\Terminal Services"

    # Ensure the registry path exists
    if (-not (Test-Path $regPath)) {
        New-Item -Path $regPath -Force | Out-Null
    }

    # Enable smart card redirection
    $policyName = "fEnableSmartCard"
    Set-ItemProperty -Path $regPath -Name $policyName -Value 1

    Write-Output "Smart Card Redirection Enabled in Group Policy"
}

# Function to configure local security policy for smart card removal behavior
function Configure-SmartCardRemovalPolicy {
    # Temporary file path for secedit export
    $tempFilePath = "C:\Windows\Temp\secpol.cfg"

    # Export current security policy settings
    secedit /export /areas SECURITYPOLICY /cfg $tempFilePath

    # Read the current settings into a variable
    $lines = Get-Content -Path $tempFilePath

    # Modify the smart card removal behavior setting
    $settingName = "ScRemoveOption"
    $newSetting = "ScRemoveOption = 1"

    # Update or add the setting
    $settingLine = $lines | Where-Object { $_ -match $settingName }
    if ($settingLine) {
        $lines = $lines -replace "$settingLine", "$newSetting"
    } else {
        $lines += $newSetting
    }

    # Write the updated settings back to the temporary file
    Set-Content -Path $tempFilePath -Value $lines

    # Apply the updated security policy settings
    secedit /configure /db C:\Windows\security\database\secedit.sdb /cfg $tempFilePath /areas SECURITYPOLICY

    # Clean up temporary file
    Remove-Item -Path $tempFilePath -Force

    Write-Output "Smart Card Removal Policy Configured"
}

# Enable smart card redirection for RDP
Enable-SmartCardRedirection

# Configure local security policy for smart card removal behavior
Configure-SmartCardRemovalPolicy

Write-Output "Smart Card Redirection and Policies have been configured successfully."
