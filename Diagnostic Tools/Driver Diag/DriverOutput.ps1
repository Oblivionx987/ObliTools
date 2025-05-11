# Get the local machine name
$MachineName = $env:COMPUTERNAME
Write-Output ("$MachineName detected")

# Define the output file path
$outputFile = "C:\temp\$MachineName-driversoutput.html"

# Run the PNPUTIL command and capture the output
$driverData = pnputil /enum-drivers /files

# Convert the output to HTML format
$htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>Driver Information</title>
    <style>
        body { font-family: Arial, sans-serif; }
        table { width: 100%; border-collapse: collapse; }
        th, td { border: 1px solid #ddd; padding: 8px; }
        th { background-color: #f2f2f2; }
    </style>
</head>
<body>
    <h1>Driver Information</h1>
    <table>
        <tr>
            <th>Driver Information</th>
        </tr>
"@

# Loop through the output and add it to the HTML content
foreach ($line in $driverData) {
    $htmlContent += "        <tr><td>$line</td></tr>`r`n"
}

$htmlContent += @"
    </table>
</body>
</html>
"@

# Save the HTML content to a file
Set-Content -Path $outputFile -Value $htmlContent

Write-Host "Driver information has been exported to $outputFile"
Start-Process $outputFile
