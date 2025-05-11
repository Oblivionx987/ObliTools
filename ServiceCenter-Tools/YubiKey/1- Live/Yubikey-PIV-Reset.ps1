##This script is for resetting a YubiKey for a PIV user who has locked their PIN or forgot their PIN. CMDB is
## not updated in this script since the YubiKey remains assigned to the same user.

## 1. Resets PIV application on the YubiKey.

## This script requires YubiKey Manager to be installed on the computer where the script runs. The default location is C:\Program Files\Yubico\YubiKey Manager.



powershell.exe

# This script is for resetting a YubiKey for a PIV user who has locked their PIN or forgot their PIN. CMDB is
# not updated in this script since the YubiKey remains assigned to the same user.
#
# 1. Resets PIV application on the YubiKey.
#
# This script requires YubiKey Manager to be installed on the computer where the script runs. The default
# location is C:\Program Files\Yubico\YubiKey Manager.
#
#################################################################################################################

Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force

# Change to YubiKey Manager directory
Set-Location "C:\Program Files\Yubico\YubiKey Manager"

# Reset all applications as a good measure. User must remove and reinsert the YubiKey when prompted.
Read-Host -Prompt "Remove and reinsert YubiKey, then press Enter within 5 seconds of reinserting the Yubikey"
.\ykman piv reset -f

$SerialNumber = .\ykman info | Where-Object {$_ -like "Serial number:*"} | ForEach-Object {$_ -replace "Serial number: ",""}

# Generates CHUID for PIV
.\ykman piv objects generate chuid -m 010203040506070801020304050607080102030405060708

Write-Host "PIV application was reset successfully. S/N: $SerialNumber" -ForegroundColor Green

# Enters the default PIV PIN and prompts the user to set their own PIN.
Write-Host "Please set a new PIV PIN for the YubiKey that contains 6-8 alphanumeric characters." -ForegroundColor Yellow
.\ykman piv access change-pin -P 123456
Read-Host -Prompt "Press any key to exit"
Exit




