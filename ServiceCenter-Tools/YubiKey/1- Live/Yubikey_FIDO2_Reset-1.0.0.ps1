## This script is for resetting a YubiKey for a user who has locked their PIN or forgot their PIN. CMDB is not updated in this script since the YubiKey remains assigned to the same user.

## 1. Resets FIDO2 application only on the YubiKey.

## This script requires YubiKey Manager to be installed on the computer where the script runs. The default location is C:\Program Files\Yubico\YubiKey Manager.




powershell.exe


#region Script Info
$Script_Name = "Yubikey_FIDO2_Reset-1.0.0.ps1"
$Description = "This script is for resetting a YubiKey for a user who has locked their PIN or forgot their PIN. CMDB is not updated in this script since the YubiKey remains assigned to the same user.
                This script requires YubiKey Manager to be installed on the computer where the script runs. The default location is C:\Program Files\Yubico\YubiKey Manager. "
$Author = "Seth Burns - System Administrator II - Service Center"
$last_tested = "05-27-25"
$version = "5.0.0"
$live = "Live"
$bmgr = "Live"
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

# This script is for resetting a YubiKey for a user who has locked their PIN or forgot their PIN. CMDB is
# not updated in this script since the YubiKey remains assigned to the same user.
#
# 1. Resets FIDO2 application only on the YubiKey.
#
# This script requires YubiKey Manager to be installed on the computer where the script runs. The default
# location is C:\Program Files\Yubico\YubiKey Manager.
#
#################################################################################################################

Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force

# Change to YubiKey Manager directory
Set-Location "C:\Program Files\Yubico\YubiKey Manager"

# Reset all applications as a good measure
Read-Host -Prompt "Remove and reinsert YubiKey, then press Enter within 5 seconds of reinserting the Yubikey"
.\ykman fido reset -f

# Gets serial number of YubiKey and stores it in the SerialNumber variable. This will be used in the process to update CMDB, when that gets added to this script later.
$SerialNumber = .\ykman info | Where-Object {$_ -like "Serial number:*"} | ForEach-Object {$_ -replace "Serial number: ",""}

Write-Host "FIDO2 application was reset successfully. S/N: $SerialNumber" -ForegroundColor Green
Read-Host -Prompt "Press any key to exit" 
Exit