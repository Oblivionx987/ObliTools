#region Script Info
$Script_Name = "Machine Policy check"
$Description = "This script generates an HTML report of machine policies using gpresult. It attempts to use the /h switch for HTML output, and falls back to text output if not supported."
$Author = "Seth Burns - System Administrator II - Service Center"
$last_tested = "05-24-25"
$version = "1.0.0"
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


# Ensure the C:\temp folder exists
$folderPath = "C:\temp"
if (-not (Test-Path $folderPath)) {
    try {
        New-Item -Path $folderPath -ItemType Directory -Force | Out-Null
        Write-Host "Created folder: $folderPath"
    }
    catch {
        Write-Error "Could not create folder $($folderPath): $($_)"
        exit 1
    }
}

# Define the output HTML file path
$outputFile = Join-Path $folderPath "MachinePolicyReport.html"

# Attempt to run gpresult using the /h switch to generate an HTML report.
Write-Host "Attempting to generate HTML report using gpresult /h..."
try {
    # Run gpresult with /scope computer and /h to output directly to the file.
    # Redirecting stderr to stdout so errors are captured.
    & gpresult /scope computer /h $outputFile 2>&1 | Out-String | Write-Verbose

    # Check if the output file was created
    if (Test-Path $outputFile) {
        Write-Host "Machine policy report saved to $outputFile using gpresult's HTML output."
    }
    else {
        throw "The expected output file was not created."
    }
}
catch {
    Write-Warning "gpresult /h option is not supported or failed: $($_)"
    Write-Host "Falling back to capturing text output and converting to HTML..."

    # Run gpresult to capture the verbose text output for computer (machine) policies.
    # We redirect both stdout and stderr to capture any messages.
    $gpResultOutput = & gpresult /scope computer /v 2>&1 | Out-String

    if ([string]::IsNullOrWhiteSpace($gpResultOutput)) {
        Write-Error "No output was captured from gpresult. Please ensure you are running as an administrator."
        exit 1
    }

    # Build a simple HTML template wrapping the gpresult output in <pre> tags
    $htmlContent = @"
<html>
<head>
    <meta charset="utf-8">
    <title>Machine Policy Report</title>
    <style>
        body { font-family: Consolas, monospace; }
        pre { white-space: pre-wrap; }
    </style>
</head>
<body>
<pre>
$gpResultOutput
</pre>
</body>
</html>
"@

    try {
        $htmlContent | Out-File -FilePath $outputFile -Encoding UTF8
        Write-Host "Machine policy report saved to $outputFile (fallback text method)."
    }
    catch {
        Write-Error "Failed to write report to $($outputFile): $($_)"
        exit 1
    }
}

# Optionally, open the report if it exists
if (Test-Path $outputFile) {
    Write-Host "Opening the report..."
    try {
        Start-Process $outputFile
    }
    catch {
        Write-Warning "Unable to open the file automatically. You can open it manually: $outputFile"
    }
}
else {
    Write-Error "The report file was not created."
}
