
#region Script Info
$Script_Name = "checkps1s-2.0.0.ps1"
$Description = "This script will check a supplied directory and check all powershell scripts for summary info."
$Author = "Seth Burns - System Administrator II - Service Center"
$last_tested = "05-27-25"
$version = "2.0.0"
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
Write-Output "--------------------" | Yellow
Write-Output "$Author" | Yellow
Write-Output "$Script_Name" | Yellow
Write-Output "$version , $last_tested" | Yellow
Write-Output "$live , $bmgr" | Yellow
Write-Output "$Description" | Yellow
Write-Output "--------------------" | Yellow
## END Main Descriptor
#endregion

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
$htmlContent += "<table border='1'><tr><th>Live</th><th>BMGR</th><th>Folder Name</th><th>File Name</th><th>Version</th><th>Author</th><th>Description</th><th>Path</th></tr>"

foreach ($file in $ps1Files) {
    # Read the content of the file
    $fileContent = Get-Content -Path $file.FullName

    # Initialize variables
    $description = "No description found."
    $author = "No author found."
    $version = "No version found."
    $live = "No live status found."
    $bmgr = "No Bomgar status found."

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
        if ($line -match '^\s*\$bmgr\s*=\s*"(.*)"') {
            $bmgr = $matches[1]
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