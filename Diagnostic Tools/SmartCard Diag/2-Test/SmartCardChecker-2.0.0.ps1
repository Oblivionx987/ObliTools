#region Script Info
$Script_Name = "Certutil Output to HTML"
$Description = "This script captures the output of 'certutil -scinfo' and saves it as an HTML file in C:\temp. It ensures the output directory exists before writing the file."
$Author = "Seth Burns - System Administrator II - Service Center"
$last_tested = "04-18-25"
$version = "2.0.0"
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


# Ensure the output directory exists
$outputDirectory = "C:\temp"
if (-Not (Test-Path -Path $outputDirectory)) {
    New-Item -Path $outputDirectory -ItemType Directory
}

# Output file path
$outputFile = "$outputDirectory\CertutilOutput.html"

# Run Certutil -scinfo and capture the output
$certutilOutput = certutil -scinfo

# Convert the output to HTML
$htmlContent = "<html><body><pre>$certutilOutput</pre></body></html>"

# Write the HTML content to the output file
Set-Content -Path $outputFile -Value $htmlContent

Write-Host "Certutil output has been written to $outputFile" | Green