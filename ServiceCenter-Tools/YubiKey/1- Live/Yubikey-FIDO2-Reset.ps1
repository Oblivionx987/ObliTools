## This script is for resetting a YubiKey for a user who has locked their PIN or forgot their PIN. CMDB is not updated in this script since the YubiKey remains assigned to the same user.

## 1. Resets FIDO2 application only on the YubiKey.

## This script requires YubiKey Manager to be installed on the computer where the script runs. The default location is C:\Program Files\Yubico\YubiKey Manager.




powershell.exe

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