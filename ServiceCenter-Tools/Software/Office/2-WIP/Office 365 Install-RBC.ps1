Powershell

## Functions
function Red { process { Write-Host $_ -ForegroundColor Red }}
function Green { process { Write-Host $_ -ForegroundColor Green }}
function Yellow { process { Write-Host $_ -ForegroundColor Yellow }}
function DarkRed { process { Write-Host $_ -ForegroundColor DarkRed }}

## Variables
$Source = "\\sncorp\internal\Corp_Software\ServiceCenter_SNC_Software\"
$DestinationFolder = "C:\temp\"
$File = "Microsoft365_Professional_64bit_v3.zip"
$MainInstaller = "O365Pro_64bit_install.bat"
$MainUnInstaller = "O365Pro_uninstall.bat"
$vpn_test = Test-NetConnection -ComputerName "sncorp.intranet.com"
$ping_test = $vpn_test | Select-Object PingSucceeded -Wait

## Author Info
Write-Output ("Author Seth Burns - System Administrator II - Service Center
Tested On : 01-08-2024
This script will Install Office 365 With Titus
Associated Resource $File") | DarkRed

## Description
Write-Output ("Description
This script will Uninstall Office if it exists then it will Install Office 365 With Titus") | Green

read-host "Please read the description, then press ENTER to Continue"

## Checking That Machine Is Online
if ($ping_test -match "False") { Write-Output "Please Connect To Internet & VPN" | Red}
if ($ping_test -match "False") { EXIT }
if ($ping_test -match "True") { Write-Output "Computer Is Connected To Network" | Green}
if ($ping_test -match "True") {
	
## File Transfer
Write-Output ("Starting File Transfer") | Green
Robocopy $Source $DestinationFolder $File /mt:4 /z /e /xo | Green
Write-Output ("Finished File Transfer") | Green
## Finished File Transfer

## Expanding Archive File
Write-Output "Starting Archive Exspansion" | Green
Expand-Archive "C:\temp\Microsoft365_Professional_64bit_v3.zip" -Destination "C:\temp" -force
Write-Output "Done Expanding Archive" | Green
## Archive Expansion Completed

## Kill Running Titus Services
net stop Titus.Enterprise.Client.Service
net stop Titus.Enterprise.HealthMonitor.Service

taskkill /IM Titus* /F

## Starting Uninstallation
Write-Output "Starting $MainUnInstaller" | Green
Start-Process "C:\temp\Microsoft365_Professional_64bit_v3\$MainUnInstaller" -wait
Write-Output "Finished $MainUnInstaller" | Green
## Uninstall Completed

## Kill Running Titus Services
net stop Titus.Enterprise.Client.Service
net stop Titus.Enterprise.HealthMonitor.Service

taskkill /IM Titus* /F

## Starting Software Installation
Write-Output "Starting $MainInstaller" | Green
Start-Process "C:\temp\Microsoft365_Professional_64bit_v3\$MainInstaller" -wait
Write-Output "Finished $MainInstaller" | Green
## Software Installation Completed

## Start Titus Services
net start Titus.Enterprise.Client.Service
net start Titus.Enterprise.HealthMonitor.Service

EXIT}

