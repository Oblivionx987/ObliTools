## This script is for deprovisioning any YubiKey for an already existing user who has turned their YubiKey in to IT.

## 1. Enables all applications on the YubiKey.
## 2. Resets all applications on the YubiKey.
## 3. Disables all applications except for FIDO2.
## 4. Stores the serial number of the YubiKey in a variable called SerialNumber

## This script requires YubiKey Manager to be installed on the computer where the script runs. The default location is C:\Program Files\Yubico\YubiKey Manager.


powershell.exe

# This script is for deprovisioning any YubiKey for an already existing user who has turned their YubiKey in to IT.
# 
# 1. Enables all applications on the YubiKey.
# 2. Resets all applications on the YubiKey.
# 3. Disables all applications except for FIDO2.
# 4. Stores the serial number of the YubiKey in a variable called SerialNumber
#
# This script requires YubiKey Manager to be installed on the computer where the script runs. The default
# location is C:\Program Files\Yubico\YubiKey Manager.
#
#################################################################################################################

Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force

# Change to YubiKey Manager directory
Set-Location "C:\Program Files\Yubico\YubiKey Manager"

# Enables all applications over USB and NFC interfaces.
.\ykman config usb -a -f
Start-Sleep -Seconds 2
.\ykman config nfc -a -f
Start-Sleep -Seconds 2

# Reset all applications as a good measure
Read-Host -Prompt "Remove and reinsert YubiKey, then press Enter within 5 seconds of reinserting the Yubikey"
.\ykman fido reset -f
Write-Host "FIDO2 application was reset." -ForegroundColor Green
Start-Sleep -Seconds 2
.\ykman oath reset -f
Write-Host "OATH application was reset." -ForegroundColor Green
Start-Sleep -Seconds 2
.\ykman openpgp reset -f
Write-Host "OPENPGP application was reset." -ForegroundColor Green
Start-Sleep -Seconds 2
.\ykman otp delete 1 -f
Write-Host "OTP slot 1 was deleted. If there is an error, it is likely because there was nothing to delete." -ForegroundColor Green
Start-Sleep -Seconds 2
.\ykman otp delete 2 -f
Write-Host "OTP slot 2 was deleted. If there is an error, it is likely because there was nothing to delete." -ForegroundColor Green
Start-Sleep -Seconds 2
.\ykman piv reset -f
Write-Host "PIV application was reset." -ForegroundColor Green

# Gets serial number of YubiKey and stores it in the SerialNumber variable. This will be used in the process to update CMDB, when that gets added to this script later.
$SerialNumber = .\ykman info | Where-Object {$_ -like "Serial number:*"} | ForEach-Object {$_ -replace "Serial number: ",""}

# Steps need to be added to get the data in the SerialNumber variable into CMDB to disassociate the serial number with the user, mark the YubiKey as unassigned, etc

Write-Host "YubiKey was successfully deprovisioned. S/N: $SerialNumber" -ForegroundColor Green
Read-Host -Prompt "Press any key to exit"
exit