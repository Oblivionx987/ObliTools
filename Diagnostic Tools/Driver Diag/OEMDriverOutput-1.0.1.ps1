powershell

#region Script Info
$Script_Name = "OEM Driver Output"
$Description = "This script will generate an HTML report of OEM drivers installed on the local machine and save it as an HTML file"
$Author = "Seth Burns - System Administrator II - Service Center"
$last_tested = "01-18-25"
$version = "1.0.1"
$live = "Retired"
$bmgr = "Retired"
#endregion

#region Text Colors 
function Red     { process { Write-Host $_ -ForegroundColor Red }}
function Green   { process { Write-Host $_ -ForegroundColor Green }}
function Yellow  { process { Write-Host $_ -ForegroundColor Yellow }}
function Blue    { process { Write-Host $_ -ForegroundColor Blue }}
function Cyan    { process { Write-Host $_ -ForegroundColor Cyan }}
function Magenta { process { Write-Host $_ -ForegroundColor Magenta }}
function White   { process { Write-Host $_ -ForegroundColor White }}
function Gray    { process { Write-Host $_ -ForegroundColor Gray }}
#endregion

#region Main Descriptor
## START Main Descriptor
Write-Output "---------------------------------------------" | Yellow
Write-Output "$Author" | Yellow
Write-Output "$Script_Name" | Yellow
Write-Output "Current Version - $version , Last Test - $last_tested" | Yellow
Write-Output "Testing stage - $live , Bomgar stage - $bmgr" | Yellow
Write-Output "Description - $Description" | Yellow
Write-Output "---------------------------------------------" | Yellow
## END Main Descriptor
#endregion

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