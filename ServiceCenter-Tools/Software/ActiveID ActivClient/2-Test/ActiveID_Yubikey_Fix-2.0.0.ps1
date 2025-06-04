Powershell


#region Script Info
$Script_Name = "ActiveID_Yubikey_Fix-2.0.0.ps1"
$Description = "This script will correct registry values for active client that stop yubikey from working."
$Author = "Seth Burns - System Administrator II - Service Center"
$last_tested = "05-27-25"
$version = "2.0.0"
$live = "Test"
$bmgr = "Test"
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
Write-Output "--------------------" | Yellow
Write-Output "$Author" | Yellow
Write-Output "$Script_Name" | Yellow
Write-Output "$version , $last_tested" | Yellow
Write-Output "$live , $bmgr" | Yellow
Write-Output "$Description" | Yellow
Write-Output "--------------------" | Yellow
## END Main Descriptor
#endregion

# Define the path to the registry key
$registryPath = "HKLM:\SOFTWARE\Microsoft\Cryptography\Calais\SmartCards\ActivID ActivClient (YubiKey 5)"
# Define the name of the registry value
$valueName = "80000001"
# Define the value to set
$valueData = "ykmd.dll"
# Set the registry value
Set-ItemProperty -Path $registryPath -Name $valueName -Value $valueData

# Define the path to the registry key
$registryPath1 = "HKLM:\SOFTWARE\Microsoft\Cryptography\Calais\SmartCards\ActivID ActivClient (YubiKey FIPS)"
# Define the name of the registry value
$valueName1 = "80000001"
# Define the value to set
$valueData1 = "ykmd.dll"
# Set the registry value
Set-ItemProperty -Path $registryPath1 -Name $valueName1 -Value $valueData1


Write-Output "Fix completed" | Green

Exit