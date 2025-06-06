# Define the output directory
$outputDirectory = "C:\temp"
$machinename = $env:COMPUTERNAME

$live = "Retired"
$bmgr = "Retired"
$Author = "Seth Burns - System Administarator II - Service Center"
$description = "Preliminary script for checking and testing Credential guard"
$version = "1.0.0"

# Create the output directory if it doesn't exist
if (-Not (Test-Path -Path $outputDirectory)) {
    New-Item -ItemType Directory -Path $outputDirectory
}

# Check if Credential Guard is enabled
$cgStatus = Get-CimInstance -Namespace "root\Microsoft\Windows\DeviceGuard" -ClassName "Win32_DeviceGuard" | Select-Object -ExpandProperty SecurityServicesRunning

if ($cgStatus -contains 2) {
    Write-Output "Credential Guard is enabled on this machine." | Out-File -FilePath "$outputDirectory\CredentialGuardStatus.txt"
} else {
    Write-Output "Credential Guard is NOT enabled on this machine." | Out-File -FilePath "$outputDirectory\CredentialGuardStatus.txt"
}

# Export related logs
# Here, we perform a broader search to capture more events that might be related to Credential Guard.
$events = Get-WinEvent -LogName System | Where-Object { $_.ProviderName -like "*CredentialGuard*" -or $_.Message -like "*CredentialGuard*" }

if ($events) {
    $events | Export-Csv -Path "$outputDirectory\CredentialGuardLogs.csv" -NoTypeInformation
} else {
    Write-Output "No related events found." | Out-File -FilePath "$outputDirectory\$machinename-CredentialGuardLogs.csv"
}

Write-Output "Logs exported to $outputDirectory"
