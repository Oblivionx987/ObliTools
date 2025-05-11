# Get the security policy settings
$secPolicies = Get-LocalGroupPolicy

# Convert the output to HTML format
$htmlOutput = $secPolicies | ConvertTo-Html -Property Name, Setting -Head "<style>body {font-family: Arial, sans-serif;}</style>" -Title "Local Security Policy Report"

# Output the HTML content to a log file
$htmlOutput | Out-File "C:\temp\logfile.html"

Write-Host "HTML report generated at C:\temp\logfile.html"
