#region Script Info
$Script_Name = "RDP Smart Card Configuration.ps1"
$Description = "This script will enable RDP smart card redirection and configure local security policy settings."
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
