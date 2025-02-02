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
