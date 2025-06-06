#region Script Info
$Script_Name = "Application Log Export"
$Description = "Exports the application logs from device."
$Author = "Seth Burns - System Administrator II - Service Center"
$last_tested = "05-27-25"
$version = "5.0.0"
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
Write-Output "$Script_Name"
Write-Output "$version , $last_tested" | Yellow
Write-Output "$live , $bmgr"
Write-Output "$Description" | Yellow
Write-Output "--------------------"
## END Main Descriptor
#endregion


# Adjust the file path to include the machine name
$machineName = $env:COMPUTERNAME
$outputFilePath = "C:\Temp\ApplicationLogs-$machineName.evtx"

# Ensure the temp folder exists
if (-not (Test-Path "C:\Temp")) {
    New-Item -Path "C:\Temp" -ItemType Directory -Force
}

# Define event log parameters for Application logs
$logName = "Application"

# Define the time range for logs
$startTime = (Get-Date).AddDays(-7) # Logs from the past week
$endTime = Get-Date # Logs up to current time

# Define the FilterHashtable to filter logs by time
$filter = @{
    LogName = $logName
    StartTime = $startTime
    EndTime = $endTime
}

# Fetch event logs with filter using -FilterHashtable
try {
    $eventLogs = Get-WinEvent -FilterHashtable $filter -ErrorAction Stop -MaxEvents 1000
    Write-Host "Successfully retrieved $($eventLogs.Count) logs for $logName."
} catch {
    Write-Host "Error fetching event logs: $_"
    exit
}

# Check if any logs were retrieved
if ($eventLogs.Count -eq 0) {
    Write-Host "No logs found for the specified period."
    exit
}

# Export the event logs to a usable .evtx file
try {
    # Create a temporary log name for export
    $tempLogName = "TempApplicationLog.txt"

    # Check if the temporary log already exists and remove it
    if (Get-EventLog -LogName $tempLogName -ErrorAction SilentlyContinue) {
        Remove-EventLog -LogName $tempLogName
    }

    # Create a new temporary event log
    New-EventLog -LogName $tempLogName -Source "ApplicationLogExporter"

    # Write each event to the temporary log
    foreach ($event in $eventLogs) {
        Write-EventLog -LogName $tempLogName -Source "ApplicationLogExporter" -EventId $event.Id -EntryType $event.LevelDisplayName -Message $event.Message
    }

    # Export the temporary log to the .evtx file
    $wevtutilCommand = "wevtutil epl $tempLogName $outputFilePath"
    Invoke-Expression $wevtutilCommand

    # Remove the temporary log
    Remove-EventLog -LogName $tempLogName

    Write-Host "Application logs have been exported to $outputFilePath"
} catch {
    Write-Host "Error exporting event logs: $_"
    exit
}

# Open the folder containing the exported file
Start-Process -FilePath "C:\Temp"