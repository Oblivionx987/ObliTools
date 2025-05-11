Powershell

## Functions
function Red { process { Write-Host $_ -ForegroundColor Red }}
function Green { process { Write-Host $_ -ForegroundColor Green }}
function Yellow { process { Write-Host $_ -ForegroundColor Yellow }}
function DarkRed { process { Write-Host $_ -ForegroundColor DarkRed }}


## Variables
$Source = "\\sncorp\internal\Corp_Software\ServiceCenter_SNC_Software\"
$DestinationFolder = "C:\temp\"
$File = "Acrobat_DC_Std.zip"
$MainInstaller = "acrobat_DC_install_STD.bat"
$MainUnInstaller = "acrobat_DC_uninstall.bat"
$vpn_test = Test-NetConnection -ComputerName "sncorp.intranet.com"
$ping_test = $vpn_test | Select-Object PingSucceeded -Wait

## Author Info
Write-Output ("Author Seth Burns - System Administrator II - Service Center
Tested On : 01-08-2024
This script will Install Adobe DC Standard & Pro
Associated Resource $File") | DarkRed

## Description
Write-Output ("Description
This script will Uninstall Adobe with AcroCleaner if it exists then it will Install Adobe DC Standard & Pro") | Green

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
Expand-Archive "C:\temp\Acrobat_DC_Std.zip" -Destination "C:\temp" -force
Write-Output "Done Expanding Archive" | Green
## Archive Expansion Completed

## Starting Uninstallation
Write-Output "Starting $MainUnInstaller" | Green
Start-Process "C:\temp\Acrobat_DC_Std\acrobat_DC_uninstall.bat" -wait
Write-Output "Finished $MainUnInstaller" | Green
## Uninstall Completed

## Starting Installation
Write-Output "Starting $MainInstaller" | Green
Start-Process "C:\temp\Acrobat_DC_Std\acrobat_DC_install_STD.bat" -wait
Write-Output "Finished $MainInstaller" | Green
## Installation Completed

EXIT}
