param (
    [string]$InfName = "oem*.inf"  # Can be any pattern like "oem123.inf" or "mydriver.inf"
)

# Get all matching .inf files from driver store
$infPaths = Get-ChildItem -Path "C:\Windows\INF" -Filter $InfName -ErrorAction SilentlyContinue

if ($infPaths.Count -eq 0) {
    Write-Host "No matching INF files found for pattern: $InfName"
    exit
}

foreach ($infFile in $infPaths) {
    Write-Host "`nFound: $($infFile.FullName)" -ForegroundColor Cyan
    try {
        # Read contents of the INF file
        $lines = Get-Content $infFile.FullName

        # Attempt to extract useful info from common INF sections
        $provider = ($lines | Select-String -Pattern "Provider=").Line -replace '.*Provider\s*=\s*',''
        $class    = ($lines | Select-String -Pattern "Class=").Line -replace '.*Class\s*=\s*',''
        $desc     = ($lines | Select-String -Pattern "DeviceDesc=").Line -replace '.*DeviceDesc\s*=\s*',''

        Write-Host "Provider     : $provider"
        Write-Host "Class        : $class"
        Write-Host "Description  : $desc"
    } catch {
        Write-Warning "Failed to read or parse file: $($infFile.FullName)"
    }
}


#usage
#.\Get-InfInfo.ps1 -InfName "oem56.inf"
#