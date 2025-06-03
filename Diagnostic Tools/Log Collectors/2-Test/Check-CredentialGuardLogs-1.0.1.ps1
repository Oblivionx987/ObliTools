#region Script Info
$Script_Name = "Check Credential Guard & Logs"
$Description = "Checks for Credential Guard and related LSA events on Windows 10/11. It exports the results to CSV files in temp directory"
$Author = "Seth Burns - System Administrator II - Service Center"
$last_tested = "05-23-25"
$version = "1.0.1"
$live = "Test"
$bmgr = "Test"
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

# Verbose Credential Guard Troubleshooter

# Enable verbose output
$VerbosePreference = "Continue"

Write-Output "Starting Credential Guard Troubleshooter..." | Blue

# Check if Credential Guard is enabled
Write-Output "Checking if Credential Guard is enabled..." | Cyan
$cgStatus = Get-CimInstance -Namespace "Root\Microsoft\Windows\DeviceGuard" -ClassName "Win32_DeviceGuard" | Select-Object -ExpandProperty SecurityServicesConfigured

if ($cgStatus -contains 1) {
    Write-Output "Credential Guard is enabled." | Green
} else {
    Write-Output "Credential Guard is not enabled." | Red
    return
}

# Check for errors in the Event Log
Write-Output "Checking for errors in the Event Log..." | Cyan
$eventLogs = Get-WinEvent -LogName "Microsoft-Windows-DeviceGuard/Operational" -ErrorAction SilentlyContinue

if ($eventLogs) {
    $errorEvents = $eventLogs | Where-Object { $_.LevelDisplayName -eq "Error" }

    if ($errorEvents) {
        Write-Output "Errors found in the Event Log. Exporting logs..." | Red

        # Export the logs to a file
        $exportPath = "C:\temp\CredentialGuardErrors.evtx"
        $errorEvents | Export-Clixml -Path $exportPath

        Write-Output "Errors found in the Event Log. Logs have been exported to: $exportPath"
    } else {
        Write-Output "No errors found in the Event Log." | Green
    }
} else {
    Write-Output "No logs found in the Event Log." | Red
}

Write-Output "Credential Guard Troubleshooter completed." | Blue