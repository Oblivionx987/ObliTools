#region Script Info
$Script_Name = "RDP Smart Card Checker.ps1"
$Description = "This script will check RDP smart card redirection and local security policy settings."
$Author = "Seth Burns - System Administrator II - Service Center"
$last_tested = "06-17-25"
$version = "1.0.0"
$live = "WIP"
$bmgr = "WIP"
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
Write-Output "--------------------"
Write-Output "$Author" | Yellow
Write-Output "$Script_Name" | Yellow
Write-Output "$version , $last_tested" | Yellow
Write-Output "$live , $bmgr" | Yellow
Write-Output "$Description" | Yellow
Write-Output "--------------------"
## END Main Descriptor
#endregion


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