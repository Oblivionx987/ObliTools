#region Script Info
$Script_Name = "Check Credential Guard Logs"
$Description = "Checks for Credential Guard and related LSA events on Windows 10/11. It exports the results to CSV files in a specified output directory."
$Author = "Seth Burns - System Administrator II - Service Center"
$last_tested = "04-18-25"
$version = "1.0.0"
$live = "Retired"
$bmgr = "Retired"
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
Write-Output "---------------------------------------------" | Yellow
Write-Output "$Author" | Yellow
Write-Output "$Script_Name" | Yellow
Write-Output "Current Version - $version , Last Test - $last_tested" | Yellow
Write-Output "Testing stage - $live , Bomgar stage - $bmgr" | Yellow
Write-Output "Description - $Description" | Yellow
Write-Output "---------------------------------------------" | Yellow
## END Main Descriptor
#endregion



<# 
#SYNOPSIS
    Checks for Credential Guard and related LSA events on Windows 10/11.
#DESCRIPTION
    This script:
      1. Creates the output directory if it doesn't exist.
      2. Searches the System log for messages containing "Credential Guard" or "LSA".
      3. Retrieves events from the Microsoft-Windows-DeviceGuard/Operational log related to Credential Guard or LSA.
      4. Exports both sets of events to CSV in the output directory.
#PARAMETER OutputDirectory
    The directory to save exported CSV files. Defaults to C:\temp.
#EXAMPLE
    .\Check-CredentialGuardLogs.ps1 -Verbose
    .\Check-CredentialGuardLogs.ps1 -OutputDirectory "D:\Logs" -Verbose
#>

$OutputDirectory = "C:\temp"
Write-Verbose "Starting Credential Guard log check..."

# 1. Ensure output directory exists
try {
    if (!(Test-Path $OutputDirectory)) {
        Write-Verbose "Creating output directory at $OutputDirectory."
        New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
    }
} catch {
    Write-Error "Failed to create output directory: $_"
    exit 1
}

# 2. Query the System log for possible Credential Guard or LSA events
Write-Verbose "Gathering System log events mentioning 'Credential Guard' or 'LSA'..."
try {
    $SystemLogEvents = Get-WinEvent -LogName System -ErrorAction Stop | Where-Object {
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
} catch {
    Write-Warning "Error querying System log: $_"
}

# 3. Query the Device Guard Operational log for additional relevant events
Write-Verbose "Gathering Device Guard Operational log events..."
$DeviceGuardLog = 'Microsoft-Windows-DeviceGuard/Operational'
try {
    if ($null -ne (Get-WinEvent -ListLog $DeviceGuardLog -ErrorAction SilentlyContinue)) {
        $DeviceGuardEvents = Get-WinEvent -LogName $DeviceGuardLog -ErrorAction Stop | Where-Object {
            $_.Message -like "*Credential Guard*" -or
            $_.Message -like "*LSA*"
        }
        if ($DeviceGuardEvents) {
            $DeviceGuardCsv = Join-Path $OutputDirectory "CredentialGuard_DeviceGuardLog.csv"
            Write-Verbose "Exporting Device Guard events to $DeviceGuardCsv"
            $DeviceGuardEvents | Export-Csv -Path $DeviceGuardCsv -NoTypeInformation
        } else {
            Write-Verbose "No relevant events found in the Device Guard Operational log."
        }
    } else {
        Write-Verbose "Device Guard Operational log not found on this system."
    }
} catch {
    Write-Warning "Error querying Device Guard log: $_"
}

Write-Verbose "Credential Guard log check complete."
Write-Host "Credential Guard log collection finished. Check CSV files in $OutputDirectory."

Start-Process 