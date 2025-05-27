#region Script Info
$Script_Name = "Machine Policy Check"
$Description = "This script generates an HTML report of machine policies using gpresult. It attempts to use the /h switch for HTML output, and falls back to text output if not supported."
$Author = "Seth Burns - System Administrator II - Service Center"
$last_tested = "05-24-25"
$version = "1.0.1"
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
Write-Output "---------------------------------------------" | Yellow
Write-Output "$Author" | Yellow
Write-Output "$Script_Name" | Yellow
Write-Output "Current Version - $version , Last Test - $last_tested" | Yellow
Write-Output "Testing stage - $live , Bomgar stage - $bmgr" | Yellow
Write-Output "Description - $Description" | Yellow
Write-Output "---------------------------------------------" | Yellow
## END Main Descriptor
#endregion




# Set the path for the output HTML file
$outputFile = "C:\temp\CurrentUserPolicyReport.html"

# Ensure the C:\temp directory exists
if (-not (Test-Path -Path "C:\temp")) {
    New-Item -Path "C:\temp" -ItemType Directory -Force | Out-Null
}

# Set error action preference so errors are treated as terminating
$ErrorActionPreference = "Stop"

try {
    # Try using the /h option for HTML output
    gpresult /h $outputFile /f

    # Check if the file was created
    if (-not (Test-Path $outputFile)) {
        throw "gpresult did not create the output file."
    }

    Write-Host "HTML report successfully generated using 'gpresult /h'."
}
catch {
    Write-Warning "gpresult /h failed: $_"
    Write-Warning "Falling back to converting text output to HTML."

    # Generate a text report (using /r for a summary; use /v for verbose)
    $gpresultOutput = gpresult /r | Out-String

    # Create a simple HTML page wrapping the gpresult output in a <pre> block
    $htmlContent = @"
<html>
<head>
    <meta charset='UTF-8'>
    <title>Group Policy Report</title>
    <style>
        body { font-family: Consolas, monospace; white-space: pre-wrap; }
    </style>
</head>
<body>
$gpresultOutput
</body>
</html>
"@

    # Save the HTML content to the output file
    $htmlContent | Out-File -FilePath $outputFile -Encoding UTF8
    Write-Host "HTML report created using the fallback method."
}

# Open the generated HTML report in the default browser
Start-Process $outputFile
