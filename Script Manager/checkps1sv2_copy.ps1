$author = "Seth Burns - System Administrator II - Service Center"
$description = "This script will check a supplied directory and check all powershell scripts for summary info."
$live = "Restricted"
$bmgr = "Restricted"
$Version = "1.0.2"


# Hardcode the directory path
$directory = "C:\Users\114825\OneDrive - Sierra Nevada Corporation\ObliTools"

# Hardcode the output directory
$outputDir = "C:\temp"

# Ensure the output directory exists
if (-Not (Test-Path -Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory
}

# Define the output file path
$outputFile = Join-Path -Path $outputDir -ChildPath "Summary.html"

# Get all .ps1 files in the directory and its subdirectories
$ps1Files = Get-ChildItem -Path $directory -Recurse -Filter *.ps1

# Check if any .ps1 files were found
if ($ps1Files.Count -eq 0) {
    Write-Host "No .ps1 files found in the directory $directory."
    exit
}

# Initialize an array to store HTML content
$htmlContent = @()

# Add HTML header
$htmlContent += "<html><head><title>PowerShell Script Summary</title></head><body>"
$htmlContent += "<h1>Summary of .ps1 files in the directory $directory and its subdirectories:</h1>"
$htmlContent += "<table id='sortableTable' border='1'><tr><th onclick='sortTable(0)' style='cursor:pointer;'>Live</th><th onclick='sortTable(1)' style='cursor:pointer;'>BMGR</th><th onclick='sortTable(2)' style='cursor:pointer;'>Folder Name</th><th onclick='sortTable(3)' style='cursor:pointer;'>File Name</th><th onclick='sortTable(4)' style='cursor:pointer;'>Version</th><th onclick='sortTable(5)' style='cursor:pointer;'>Last Tested</th><th onclick='sortTable(6)' style='cursor:pointer;'>Author</th><th onclick='sortTable(7)' style='cursor:pointer;'>Description</th><th onclick='sortTable(8)' style='cursor:pointer;'>Path</th><th onclick='sortTable(9)' style='cursor:pointer;'>Source</th><th onclick='sortTable(10)' style='cursor:pointer;'>Zip File Name</th></tr>"

# Add logging to a log file
$logFile = "C:\temp\ScriptLog.txt"

# Function to log messages
function LogMessage {
    param (
        [string]$Message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Out-File -FilePath $logFile -Append -Encoding UTF8
}

# Log the start of the script
LogMessage "Script execution started."

# Ensure all variables are used and properly close the foreach loop
foreach ($file in $ps1Files) {
    try {
        $fileContent = Get-Content -Path $file.FullName -ErrorAction Stop
        if (-Not $fileContent) {
            LogMessage "File is empty: $($file.FullName)"
            continue
        }
    } catch {
        LogMessage "Error reading file: $($file.FullName). $_"
        continue
    }

    # Initialize variables
    $description = "No description found."
    $author = "No author found."
    $version = "No version found."
    $live = "No live status found."
    $bmgr = "No Bomgar status found."
    $last_tested = "No last tested date found."
    $source = "No source found."
    $zipFileName = "No zip file name found."

    # Ensure $source and $zipFileName are extracted correctly
    foreach ($line in $fileContent) {
        if ($line -match '^\s*\$description\s*=\s*"(.*)"') {
            $description = $matches[1]
        }
        if ($line -match '^\s*\$author\s*=\s*"(.*)"') {
            $author = $matches[1]
        }
        if ($line -match '^\s*\$version\s*=\s*"(.*)"') {
            $version = $matches[1]
        }
        if ($line -match '^\s*\$live\s*=\s*"(.*)"') {
            $live = $matches[1]
        }
        if ($line -match '^\s*\$bmgr\s*=\s*"(.*)"') {
            $bmgr = $matches[1]
        }
        if ($line -match '^\s*\$last_tested\s*=\s*"(.*)"') {
            $last_tested = $matches[1]
        }
        if ($line -match '^\s*\$source\s*=\s*"(.*)"') {
            $source = $matches[1]
        }
        if ($line -match '^\s*\$zipFileName\s*=\s*"(.*)"') {
            $zipFileName = $matches[1]
        }
    }

    # Determine color based on live value
    switch ($live) {
        "Test" { $livecolor = "orange" }
        "Live" { $livecolor = "green" }
        "WIP" { $livecolor = "moccasin" }
        "Retired" { $livecolor = "salmon" }
        "Restricted" { $livecolor = "darkred" }
        default { $livecolor = "lightgray" }
    }

    # Determine color based on bmgr value
    switch ($bmgr) {
        "Test" { $bmgrcolor = "orange" }
        "Live" { $bmgrcolor = "green" }
        "WIP" { $bmgrcolor = "moccasin" }
        "Retired" { $bmgrcolor = "salmon" }
        "Restricted" { $bmgrcolor = "darkred" }
        default { $bmgrcolor = "lightgray" }
    }

    # Get the folder name
    $folderName = Split-Path -Path $file.FullName -Parent | Split-Path -Leaf

    # Add file information to HTML content
    $htmlContent += "<tr>"
    $htmlContent += "<td style='background-color:$livecolor;'>$live</td>"
    $htmlContent += "<td style='background-color:$bmgrcolor;'>$bmgr</td>"
    $htmlContent += "<td>$folderName</td>"
    $htmlContent += "<td>$($file.Name)</td>"
    $htmlContent += "<td>$version</td>"
    $htmlContent += "<td>$last_tested</td>"
    $htmlContent += "<td>$author</td>"
    $htmlContent += "<td>$description</td>"
    $htmlContent += "<td>$($file.FullName)</td>"
    $htmlContent += "<td>$source</td>"
    $htmlContent += "<td>$zipFileName</td>"
    $htmlContent += "</tr>"
}

# Ensure the JavaScript is properly embedded and functional
$htmlContent += "<script>"
$htmlContent += "function sortTable(n) {"
$htmlContent += "  var table, rows, switching, i, x, y, shouldSwitch, dir, switchcount = 0;"
$htmlContent += "  table = document.getElementById('sortableTable');"
$htmlContent += "  switching = true;"
$htmlContent += "  dir = 'asc';"
$htmlContent += "  while (switching) {"
$htmlContent += "    switching = false;"
$htmlContent += "    rows = table.rows;"
$htmlContent += "    for (i = 1; i < (rows.length - 1); i++) {"
$htmlContent += "      shouldSwitch = false;"
$htmlContent += "      x = rows[i].getElementsByTagName('TD')[n];"
$htmlContent += "      y = rows[i + 1].getElementsByTagName('TD')[n];"
$htmlContent += "      if (dir == 'asc') {"
$htmlContent += "        if (x.innerHTML.toLowerCase() > y.innerHTML.toLowerCase()) {"
$htmlContent += "          shouldSwitch = true;"
$htmlContent += "          break;"
$htmlContent += "        }"
$htmlContent += "      } else if (dir == 'desc') {"
$htmlContent += "        if (x.innerHTML.toLowerCase() < y.innerHTML.toLowerCase()) {"
$htmlContent += "          shouldSwitch = true;"
$htmlContent += "          break;"
$htmlContent += "        }"
$htmlContent += "      }"
$htmlContent += "    }"
$htmlContent += "    if (shouldSwitch) {"
$htmlContent += "      rows[i].parentNode.insertBefore(rows[i + 1], rows[i]);"
$htmlContent += "      switching = true;"
$htmlContent += "      switchcount ++;"
$htmlContent += "    } else {"
$htmlContent += "      if (switchcount == 0 && dir == 'asc') {"
$htmlContent += "        dir = 'desc';"
$htmlContent += "        switching = true;"
$htmlContent += "      }"
$htmlContent += "    }"
$htmlContent += "  }"
$htmlContent += "}"
$htmlContent += "</script>"

# Add CSS styling to HTML table
$htmlContent += "<style>"
$htmlContent += "table { width: 100%; border-collapse: collapse; }"
$htmlContent += "th, td { padding: 8px; text-align: left; border: 1px solid #ddd; }"
$htmlContent += "th { background-color: #f2f2f2; cursor: pointer; }"
$htmlContent += "tr:nth-child(even) { background-color: #f9f9f9; }"
$htmlContent += "tr:hover { background-color: #f1f1f1; }"
$htmlContent += "</style>"

# Add HTML footer
$htmlContent += "</table>"
$htmlContent += "<p>Report generated on: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>"
$htmlContent += "</body></html>"

# Save the HTML content to the output file
$htmlContent | Out-File -FilePath $outputFile -Encoding UTF8

# Log the completion of the script
LogMessage "Script execution completed. Report saved to $outputFile."

Write-Output "Summary has been saved to $outputFile"
Start-Process "$outputFile"