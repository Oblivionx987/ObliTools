# Get the security policy settings
try {
    $secPolicies = Get-LocalGroupPolicy
    if (-not $secPolicies) {
        Write-Error "No security policies found. Exiting script."
        exit 1
    }

    # Ensure the output directory exists
    if (-not (Test-Path "C:\temp")) {
        New-Item -ItemType Directory -Path "C:\temp" -Force | Out-Null
    }

    # Convert the output to HTML format with customizable title and style
    $htmlTitle = "Local Security Policy Report"
    $htmlStyle = "<style>body {font-family: Arial, sans-serif;}</style>"
    $htmlOutput = $secPolicies | ConvertTo-Html -Property Name, Setting -Head $htmlStyle -Title $htmlTitle

    # Output the HTML content to a log file
    $htmlOutput | Out-File -FilePath "C:\temp\logfile.html" -Encoding UTF8

    Write-Host "HTML report generated at C:\temp\logfile.html"
} catch {
    Write-Error "An error occurred: $_"
    exit 1
}
