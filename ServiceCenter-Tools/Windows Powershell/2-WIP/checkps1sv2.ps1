



$author = "Seth Burns - System Administrator II - Service Center"
$description = "This script will check a supplied directory and check all powershell scripts for summary info."
$live = "T"
$Version = "1.0.2"





# Define the directory to search
$directory = "C:\Users\114825\OneDrive - Sierra Nevada Corporation\ObliTools"

# Check if the directory exists
if (-Not (Test-Path -Path $directory)) {
    Write-Host "The directory $directory does not exist."
    exit
}

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
$htmlContent += "<table border='1'><tr><th>Live</th><th>Folder Name</th><th>File Name</th><th>Version</th><th>Author</th><th>Description</th><th>Path</th></tr>"

foreach ($file in $ps1Files) {
    # Read the content of the file
    $fileContent = Get-Content -Path $file.FullName

    # Initialize variables
    $description = "No description found."
    $author = "No author found."
    $version = "No version found."
    $live = "No live status found."

    # Check for the variables in the file content
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
    }

    # Determine color based on live value
    switch ($live) {
        "T" { $color = "orange" }
        "=" { $color = "green" }
        "w" { $color = "moccasin" }
        "r" { $color = "red" }
        "rs" { $color = "darkred" }
        default { $color = "lightgray" }
    }

    # Get the folder name
    $folderName = Split-Path -Path $file.FullName -Parent | Split-Path -Leaf

    # Add file information to HTML content
    $htmlContent += "<tr>"
    $htmlContent += "<td style='background-color:$color;'>$live</td>"
    $htmlContent += "<td>$folderName</td>"
    $htmlContent += "<td>$($file.Name)</td>"
    $htmlContent += "<td>$version</td>"
    $htmlContent += "<td>$author</td>"
    $htmlContent += "<td>$description</td>"
    $htmlContent += "<td>$($file.FullName)</td>"
    $htmlContent += "</tr>"
}

# Add HTML footer
$htmlContent += "</table></body></html>"

# Define the output file path
$outputFile = "C:\temp\Summary.html"

# Ensure the temp directory exists
if (-Not (Test-Path -Path "C:\temp")) {
    New-Item -Path "C:\temp" -ItemType Directory
}

# Save the HTML content to the output file
$htmlContent | Out-File -FilePath $outputFile -Encoding UTF8

Write-Host "Summary has been saved to $outputFile"
Start-Process "$outputFile"