## How to use this script:
## 1. Ensure the paths to the scripts you want to test are correct in the $scriptsToTest array.
## 2. Run the script in a PowerShell environment with appropriate permissions.


#region Script Info
$Script_Name = "MultiScriptTester.ps1"
$Description = "This script will test multiple PowerShell scripts in a specified order and log the results.
                The log file will be stored in C:\testing."
$Author = "Seth Burns - System Administrator II - Service Center"
$last_tested = "05-24-2024"
$version = "1.0.0"
$live = "Live"
$bmgr = "Live"

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

# Debugging: Confirm script execution
Write-Output "MultiScriptTester.ps1 is running..." | Green

# Define the scripts to test in the desired order
$scriptsToTest = @(
    "C:\Testing\Install 7-ZIP 32Bit.ps1",
    "C:\Testing\Install 7-ZIP 64Bit.ps1",
    "C:\testing\Adobe_Acrobat_DC_InstallOnly.ps1",
    "C:\testing\Adobe_Acrobat_DC_AIO.ps1",
    "C:\testing\Adobe_Acrobat_DC_UninstallOnly.ps1",
    "C:\testing\Adobe_Acrobat_Reader_InstallOnly.ps1",
    "C:\testing\Adobe_Acrobat_Reader_AIO.ps1",
    "C:\testing\Adobe_Acrobat_Reader_UninstallOnly.ps1"
)

# Update the log file path to store it in C:\testing
$logFile = "C:\testing\MultiScriptTester.log"

# Ensure the directory exists
if (-not (Test-Path "C:\testing")) {
    New-Item -ItemType Directory -Path "C:\testing" | Out-Null
}

# Clear previous log file if it exists
if (Test-Path $logFile) {
    Remove-Item $logFile
    Write-Host "Previous log file removed." | Yellow
} else {
    Write-Host "No previous log file found." | Yellow
}

# Function to log messages
function LogMessage {
    param (
        [string]$message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $message" | Out-File -FilePath $logFile -Append
    Write-Host "$timestamp - $message"  # Output to console for debugging
}

# Start testing scripts
foreach ($script in $scriptsToTest) {
    if (Test-Path $script) {
        LogMessage "Starting test for $script"
        $startTime = Get-Date

        try {
            # Execute the script
            & $script
            $endTime = Get-Date
            $duration = ($endTime - $startTime).TotalSeconds
            LogMessage "SUCCESS: $script completed in $duration seconds"
            LogMessage "$script"
            LogMessage "Total Duration: $duration"
        } catch {
            $endTime = Get-Date
            $duration = ($endTime - $startTime).TotalSeconds
            LogMessage "FAILURE: $script failed after $duration seconds"
            LogMessage "Error: $_"
        }
    } else {
        LogMessage "ERROR: $script not found"
    }
}

LogMessage "All scripts have been tested."
Write-Host "MultiScriptTester.ps1 has completed." | Green
