# Function to check if Java is installed by looking for common installation paths
function Check-JavaInstallation {
    $commonPaths = @(
        "C:\Program Files\Java",
        "C:\Program Files (x86)\Java"
    )

    foreach ($path in $commonPaths) {
        if (Test-Path -Path $path) {
            return $true
        }
    }

    return $false
}

# Function to check if Java is installed by looking for registry keys
function Check-JavaRegistry {
    $javaKeyPaths = @(
        "HKLM:\SOFTWARE\JavaSoft\Java Runtime Environment",
        "HKLM:\SOFTWARE\Wow6432Node\JavaSoft\Java Runtime Environment"
    )

    foreach ($keyPath in $javaKeyPaths) {
        if (Test-Path -Path $keyPath) {
            return $true
        }
    }

    return $false
}

# Main script execution
$javaInstalled = $false

if (Check-JavaInstallation -or Check-JavaRegistry) {
    $javaInstalled = $true
}

if ($javaInstalled) {
    Write-Output "Java is installed on this device."
} else {
    Write-Output "Java is not installed on this device."
}
