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

Write-Host "Certutil output has been written to $outputFile"