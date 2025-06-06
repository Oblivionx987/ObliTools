powershell 

#region Script Info
$Script_Name = "CheckCredentialGuard-1.0.1.ps1"
$Description = "Checks for Credential Guard and related LSA events on Windows 10/11."
$Author = "Seth Burns - System Administrator II - Service Center"
$last_tested = "05-27-25"
$version = "1.0.1"
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
Write-Output "--------------------" | Yellow
Write-Output "$Author" | Yellow
Write-Output "$Script_Name" | Yellow
Write-Output "$version , $last_tested" | Yellow
Write-Output "$live , $bmgr" | Yellow
Write-Output "$Description" | Yellow
Write-Output "--------------------" | Yellow
## END Main Descriptor
#endregion


[CmdletBinding()]
param()

Write-Verbose "Starting Credential Guard log check..."

Check if Credential Guard is enabled
$cgStatus = Get-CimInstance -Namespace "root\Microsoft\Windows\DeviceGuard" -ClassName "Win32_DeviceGuard" | Select-Object -ExpandProperty SecurityServicesRunning

if ($cgStatus -contains 2) {
    Write-Output "Credential Guard is enabled on this machine." | Out-File -FilePath "$outputDirectory\CredentialGuardStatus.txt"
} else {
    Write-Output "Credential Guard is NOT enabled on this machine." | Out-File -FilePath "$outputDirectory\CredentialGuardStatus.txt"
}

# 1. Ensure output directory exists
$OutputDirectory = 'C:\temp'
if (!(Test-Path $OutputDirectory)) {
    Write-Verbose "Creating output directory at $OutputDirectory."
    New-Item -ItemType Directory -Path $OutputDirectory | Out-Null
}

# 2. Query the System log for possible Credential Guard or LSA events
Write-Verbose "Gathering System log events mentioning 'Credential Guard' or 'LSA'..."
$SystemLogEvents = Get-WinEvent -LogName System -ErrorAction SilentlyContinue | Where-Object {
    $_.Message -like "*Credential Guard*" -or
    $_.Message -like "*LSA*"
}

if ($SystemLogEvents) {
    $SystemLogCsv = Join-Path $OutputDirectory "CredentialGuard_SystemLog.csv"
    Write-Verbose "Exporting System log events to $SystemLogCsv"
    $SystemLogEvents | Export-Csv -Path $SystemLogCsv -NoTypeInformation
} else {
    Write-Verbose "No System log events found containing 'Credential Guard' or 'LSA'."
}

# 3. Query the Device Guard Operational log for additional relevant events
Write-Verbose "Gathering Device Guard Operational log events..."
# Note: This log includes VBS-related events that can pertain to Credential Guard.
$DeviceGuardLog = 'Microsoft-Windows-DeviceGuard/Operational'
if ((Get-WinEvent -ListLog $DeviceGuardLog -ErrorAction SilentlyContinue) -ne $null) {
    $DeviceGuardEvents = Get-WinEvent -LogName $DeviceGuardLog -ErrorAction SilentlyContinue
    
    if ($DeviceGuardEvents) {
        $DeviceGuardCsv = Join-Path $OutputDirectory "CredentialGuard_DeviceGuardLog.csv"
        Write-Verbose "Exporting Device Guard events to $DeviceGuardCsv"
        $DeviceGuardEvents | Export-Csv -Path $DeviceGuardCsv -NoTypeInformation
    } else {
        Write-Verbose "No events found in the Device Guard Operational log."
    }
} else {
    Write-Verbose "Device Guard Operational log not found on this system."
}

Write-Verbose "Credential Guard log check complete."