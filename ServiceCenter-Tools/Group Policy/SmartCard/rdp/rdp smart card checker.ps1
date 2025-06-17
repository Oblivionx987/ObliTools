# Function to check if a Group Policy setting is enabled
function Get-PolicySetting($policyPath, $policyName) {
    $regPath = "HKLM:\Software\Policies\Microsoft\Windows NT\Terminal Services"
    if (Test-Path -Path "$regPath\$policyName") {
        $policyValue = Get-ItemProperty -Path $regPath -Name $policyName
        return $policyValue.$policyName -eq 1
    }
    return $false
}

# Function to check local security policy settings
function Get-LocalSecuritySetting($settingName) {
    $seceditOutput = secedit /export /areas SECURITYPOLICY /cfg C:\Windows\Temp\secpol.cfg
    $lines = Get-Content -Path C:\Windows\Temp\secpol.cfg
    $settingLine = $lines | Where-Object { $_ -match $settingName }
    if ($settingLine) {
        $settingValue = $settingLine -split "="
        return $settingValue[1].Trim()
    }
    return $null
}

# Check if smart card redirection is enabled via Group Policy
$gpSmartCardRedirectionEnabled = Get-PolicySetting "Terminal Services" "fEnableSmartCard"

# Check local security policy for smart card removal behavior
$localSecPolicySmartCardRemoval = Get-LocalSecuritySetting "ScRemoveOption"

# Display the results
Write-Output "Smart Card Redirection Enabled via Group Policy: $gpSmartCardRedirectionEnabled"
Write-Output "Local Security Policy for Smart Card Removal Behavior: $localSecPolicySmartCardRemoval"

# Clean up temporary file
Remove-Item -Path C:\Windows\Temp\secpol.cfg -Force