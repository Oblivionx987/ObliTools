# Define file path for the HTML output
$outputFilePath = "C:\Temp\ApplicationLogs.html"

# Ensure the temp folder exists
if (-not (Test-Path "C:\Temp")) {
    New-Item -Path "C:\Temp" -ItemType Directory -Force
}

# Define event log parameters for Application logs
$logName = "Application"

# Define the time range for logs
$startTime = (Get-Date).AddDays(-7) # Logs from the past week
$endTime = Get-Date # Logs up to current time

# Initialize HTML content
$htmlContent = @"
<html>
<head>
    <title>Application Event Logs</title>
    <style>
        body { font-family: Arial, sans-serif; background-color: #f4f4f9; padding: 20px; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th, td { padding: 10px; text-align: left; border: 1px solid #ddd; }
        th { background-color: #4CAF50; color: white; cursor: pointer; }
        td { background-color: #f2f2f2; }
        .level-info { background-color: #d4f4e3; }
        .level-error { background-color: #f8d7da; }
        .level-warning { background-color: #fff3cd; }
        .level-critical { background-color: #f8d7da; }
    </style>
    <script>
        function sortTable(n) {
            var table, rows, switching, i, x, y, shouldSwitch, dir, switchcount = 0;
            table = document.getElementById("eventLogTable");
            switching = true;
            dir = "asc"; 
            while (switching) {
                switching = false;
                rows = table.rows;
                for (i = 1; i < (rows.length - 1); i++) {
                    shouldSwitch = false;
                    x = rows[i].getElementsByTagName("TD")[n];
                    y = rows[i + 1].getElementsByTagName("TD")[n];
                    if (dir == "asc") {
                        if (x.innerHTML.toLowerCase() > y.innerHTML.toLowerCase()) {
                            shouldSwitch = true;
                            break;
                        }
                    } else if (dir == "desc") {
                        if (x.innerHTML.toLowerCase() < y.innerHTML.toLowerCase()) {
                            shouldSwitch = true;
                            break;
                        }
                    }
                }
                if (shouldSwitch) {
                    rows[i].parentNode.insertBefore(rows[i + 1], rows[i]);
                    switching = true;
                    switchcount ++; 
                } else {
                    if (switchcount == 0 && dir == "asc") {
                        dir = "desc";
                        switching = true;
                    }
                }
            }
        }
    </script>
</head>
<body>
    <h1>Application Event Logs from $startTime to $endTime</h1>
    <table id="eventLogTable">
        <tr>
            <th onclick="sortTable(0)">Event ID</th>
            <th onclick="sortTable(1)">Level</th>
            <th onclick="sortTable(2)">Time Created</th>
            <th onclick="sortTable(3)">Message</th>
        </tr>
"@

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

    $htmlContent += "<tr class='$levelClass'>"
    $htmlContent += "<td>$($event.Id)</td>"
    $htmlContent += "<td>$($event.LevelDisplayName)</td>"
    $htmlContent += "<td>$($event.TimeCreated)</td>"
    $htmlContent += "<td>$($event.Message)</td>"
    $htmlContent += "</tr>"
}

# Add closing HTML tags
$htmlContent += @"
    </table>
</body>
</html>
"@

# Output the HTML content to the file
$htmlContent | Out-File -FilePath $outputFilePath -Encoding utf8

Write-Host "Application logs have been exported to $outputFilePath"

# Open the generated HTML file in the default browser
Start-Process -FilePath $outputFilePath