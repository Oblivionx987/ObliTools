# Define file path for the HTML output
$outputFilePath = "C:\Temp\WindowsEventLogs.html"

# Ensure the temp folder exists
if (-not (Test-Path "C:\Temp")) {
    New-Item -Path "C:\Temp" -ItemType Directory
}

# Define event log parameters
$logName = "System" # Example log, can be changed to "Application", "Security", etc.
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
    $eventLogs = Get-WinEvent -FilterHashtable $filter -ErrorAction Stop
} catch {
    Write-Host "Error fetching event logs: $_"
    exit
}

# Check if any logs were retrieved
if ($eventLogs.Count -eq 0) {
    Write-Host "No logs found for the specified period."
    exit
}

# Prepare a header for the HTML output
$htmlContent = @"
<html>
<head>
    <title>Windows Event Logs</title>
    <style>
        body { font-family: Arial, sans-serif; background-color: #f4f4f9; padding: 20px; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th, td { padding: 10px; text-align: left; border: 1px solid #ddd; }
        th { background-color: #4CAF50; color: white; }
        td { background-color: #f2f2f2; }
        .level-info { background-color: #d4f4e3; }
        .level-error { background-color: #f8d7da; }
        .level-warning { background-color: #fff3cd; }
        .level-critical { background-color: #f8d7da; }
    </style>
</head>
<body>
    <h1>Windows Event Logs from $startTime to $endTime</h1>
    <h3>Log Name: $logName</h3>
    <h3>Total Logs Found: $($eventLogs.Count)</h3>
    <table>
        <tr>
            <th>Event ID</th>
            <th>Level</th>
            <th>Time Created</th>
            <th>Message</th>
        </tr>
"@

# Process and filter the event logs into the HTML content
foreach ($event in $eventLogs) {
    $levelClass = ""

    # Evaluate the event level for coloring the rows
    switch ($event.LevelDisplayName) {
        "Information" { $levelClass = "level-info" }
        "Error" { $levelClass = "level-error" }
        "Warning" { $levelClass = "level-warning" }
        "Critical" { $levelClass = "level-critical" }
        default { $levelClass = "level-info" }
    }

    $htmlContent += "<tr class='$levelClass'>
                        <td>$($event.Id)</td>
                        <td>$($event.LevelDisplayName)</td>
                        <td>$($event.TimeCreated)</td>
                        <td>$($event.Message)</td>
                     </tr>"
}

# Add closing HTML tags
$htmlContent += @"
    </table>
</body>
</html>
"@

# Output the HTML content to the file
$htmlContent | Out-File -FilePath $outputFilePath -Encoding utf8

Write-Host "Event logs have been exported to $outputFilePath"

# Optional: Open the HTML file in the default browser
Start-Process "chrome.exe" $outputFilePath
