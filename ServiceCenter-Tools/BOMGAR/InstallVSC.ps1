powershell


## Functions
function Red { process { Write-Host $_ -ForegroundColor Red }}
function Green { process { Write-Host $_ -ForegroundColor Green }}
function Yellow { process { Write-Host $_ -ForegroundColor Yellow }}
function DarkRed { process { Write-Host $_ -ForegroundColor DarkRed }}


## Author Info
Write-Output ("
Author Seth Burns - System Administrator II - Service Center
Tested On : 12-20-2024
This script will install the bomgar Virtual Smart Card Controller, this allows a remote techniciain to push credentials to a remote device.
") | DarkRed


## Description
Write-Output ("This script is designed to be run in the command shell in bomgar while user is signed out of the rig.
Steps:
Sign user out
Go to Command Shell tab in bomgar and run the VSC Installer
Disconnect from the bomgar session, reconnect
Smart card option should now be Available") | Yellow

read-host "Please read the description, then press any ENTER to Continue"

## Variables
$Source = "\\colofs01\Internal\Corp_Software\ServiceCenter_SNC_Software\"
$DestinationFolder = "C:\temp\"
$File = "bomgar-vsccust-win64.zip"
$MainInstaller = "bomgar-vsccust-win64.msi"
$vpn_test = Test-NetConnection -ComputerName "sncorp.intranet.com"
$ping_test = $vpn_test | Select-Object PingSucceeded -Wait


## Checking That Machine Is Online
if ($ping_test -match "False") { Write-Output "Please Connect To Internet & VPN" | Red}
if ($ping_test -match "False") { EXIT }
if ($ping_test -match "True") { Write-Output "Computer Is Connected To Network" | Green}
if ($ping_test -match "True") {

## File Transfer
Robocopy $Source $DestinationFolder $File /mt:4 /z /e /xo | Green

## Archive Exspansion
Write-Output "Starting Archive Exspansion" | Green
Expand-Archive "C:\temp\$File" -Destination $DestinationFolder -force
Write-Output "Done Expanding Archive" | Green

## Main Installer Start
Write-Output "Starting $MainInstaller Installer" | Green
Start-Process "C:\temp\$MainInstaller"

Exit}