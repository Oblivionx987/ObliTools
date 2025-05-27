# Define the scripts to run in the specified order
$scripts = @(
    "C:\Users\Oblivion\OneDrive\Seth\Oblivion Vault\ObliTools\ObliTools-1\Diagnostic Tools\Script Testing\checkps1sv2_copy.ps1",
    "C:\Users\Oblivion\OneDrive\Seth\Oblivion Vault\ObliTools\ObliTools-1\Diagnostic Tools\Script Testing\testing.ps1"
)

# Define the log file path
$logFile = "C:\testing\script_execution_log.txt"

# Ensure the log directory exists
$logDir = [System.IO.Path]::GetDirectoryName($logFile)
if (-not (Test-Path -Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir | Out-Null
}

# Initialize the log file
"Script Execution Log - $(Get-Date)" | Out-File -FilePath $logFile -Encoding UTF8

# Run each script and log the results
foreach ($script in $scripts) {
    if (-not (Test-Path -Path $script)) {
        "[ERROR] Script not found: $script" | Out-File -FilePath $logFile -Append
        continue
    }

    $startTime = Get-Date
    try {
        # Execute the script
        . $script
        $status = "SUCCESS"
    } catch {
        $status = "FAILURE"
        $errorMessage = $_.Exception.Message
    }
    $endTime = Get-Date

    # Calculate runtime
    $runtime = ($endTime - $startTime).TotalSeconds

    # Log the result
    if ($status -eq "SUCCESS") {
        "[SUCCESS] $script completed in $runtime seconds." | Out-File -FilePath $logFile -Append
    } else {
        "[FAILURE] $script failed after $runtime seconds. Error: $errorMessage" | Out-File -FilePath $logFile -Append
    }
}

"All scripts executed. Log saved to $logFile."
Start-Process $logFile