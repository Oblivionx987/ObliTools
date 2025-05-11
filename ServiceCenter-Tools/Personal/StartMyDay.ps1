
## Author Info
Write-Output ("Author Seth Burns - System Administrator II - Service Center
Tested On : 03/10/2025
This script will Launch applications as admin, Used for technician day startup without needing to key credentials multiple times.") | DarkRed

## Description
Write-Output ("Description:
This script will Launch applications as admin, Used for technician day startup without needing to key credentials multiple times.") | Green

read-host "Please read the description, then press ENTER to Continue"







## Begin AText as Admin
Write-Output "Begining Atext as Admin"
Start-Process "C:\Users\114825\AppData\Local\Tran Ky Nam\aText\aText.exe"

## Begin Active Roles as Admin
Write-Output "Begining Active Roles as Admin"
Start-Process "C:\Program Files\One Identity\Active Roles\8.1\Console\ActiveRoles.msc"

## Begin Powertoys as Admin
Write-Output "Begining PowerToys as Admin"
Start-Process "C:\Users\114825\AppData\Local\PowerToys\WinUI3Apps\PowerToys.Settings.exe"

## Begin Configuration Manager as Admin
Write-Output "Begining Configuration Manager as Admin"
Start-Process "C:\Program Files (x86)\Configuration Manager Console\bin\Microsoft.ConfigurationManagement.exe"

## Begin Computer Management as Admin
Write-Output "Begining Computer Management as Admin"
Start-Process "%windir%\system32\compmgmt.msc /s"

