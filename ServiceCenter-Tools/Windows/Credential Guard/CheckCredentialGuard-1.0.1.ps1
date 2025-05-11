<# 
.SYNOPSIS
    Checks for Credential Guard and related LSA events on Windows 10/11.
.DESCRIPTION
    This script:
      1. Creates C:\temp if it doesn't exist.
      2. Searches the System log for messages containing "Credential Guard" or "LSA".
      3. Retrieves events from the Microsoft-Windows-DeviceGuard/Operational log.
      4. Exports both sets of events to CSV in C:\temp.
.PARAMETER None
    This script does not accept parameters.
.EXAMPLE
    .\Check-CredentialGuardLogs.ps1 -Verbose
#>

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