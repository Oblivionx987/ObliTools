# Export-SecurityPolicy.ps1

# Define the output file path
$outputFile = "$env:USERPROFILE\SecurityPolicy.txt"

# Export Local Security Policy Settings
secedit /export /cfg $outputFile

Write-Output "Security policy settings exported to $outputFile"
