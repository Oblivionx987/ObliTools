param (
    [string]$TempFilePath = "C:\Windows\Temp\secpol.cfg"
)

# Function to check if a Group Policy setting is enabled
function Get-PolicySetting {
    param (
        [string]$policyPath,
        [string]$policyName
    )
    try {
        $regPath = "HKLM:\Software\Policies\Microsoft\Windows NT\Terminal Services"
        if (Test-Path -Path "$regPath\$policyName") {
            $policyValue = Get-ItemProperty -Path $regPath -Name $policyName
            return $policyValue.$policyName -eq 1
        }
        return $false
    } catch {
        Write-Error "Error checking policy setting: $_"
        return $null
    }
}

# Function to check local security policy settings
function Get-LocalSecuritySetting {
    param (
        [string]$settingName,
        [string]$tempFilePath
    )
    try {
        $seceditOutput = secedit /export /areas SECURITYPOLICY /cfg $tempFilePath
        $lines = Get-Content -Path $tempFilePath
        $settingLine = $lines | Where-Object { $_ -match $settingName }
        if ($settingLine) {
            $settingValue = $settingLine -split "="
            return $settingValue[1].Trim()
        }
        return $null
    } catch {
        Write-Error "Error checking local security setting: $_"
        return $null
    } finally {
        # Clean up temporary file
        if (Test-Path -Path $tempFilePath) {
            Remove-Item -Path $tempFilePath -Force
        }
    }
}

# Check if smart card redirection is enabled via Group Policy
$gpSmartCardRedirectionEnabled = Get-PolicySetting -policyPath "Terminal Services" -policyName "fEnableSmartCard"

# Check local security policy for smart card removal behavior
$localSecPolicySmartCardRemoval = Get-LocalSecuritySetting -settingName "ScRemoveOption" -tempFilePath $TempFilePath

# Display the results
Write-Output "Smart Card Redirection Enabled via Group Policy: $gpSmartCardRedirectionEnabled"
Write-Output "Local Security Policy for Smart Card Removal Behavior: $localSecPolicySmartCardRemoval"

# Additional Policy Checks (if needed)
# Example: Check if smart card is required for interactive logon
function CheckSmartCardInteractiveLogon {
    try {
        $interactiveLogonSetting = Get-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ScForceOption" -ErrorAction SilentlyContinue
        if ($interactiveLogonSetting) {
            return $interactiveLogonSetting.ScForceOption -eq 1
        }
        return $false
    } catch {
        Write-Error "Error checking interactive logon policy: $_"
        return $null
    }
}

$interactiveLogonRequired = CheckSmartCardInteractiveLogon
Write-Output "Smart Card Required for Interactive Logon: $interactiveLogonRequired"
