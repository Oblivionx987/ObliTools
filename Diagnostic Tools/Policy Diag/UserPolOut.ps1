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
