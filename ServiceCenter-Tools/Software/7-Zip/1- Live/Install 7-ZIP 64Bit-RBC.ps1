## This script will Install 7-ZIP 64Bit
## NEEDS UPDATE
Powershell

## Functions
function Red { process { Write-Host $_ -ForegroundColor Red }}
function Green { process { Write-Host $_ -ForegroundColor Green }}
function Yellow { process { Write-Host $_ -ForegroundColor Yellow }}
function DarkRed { process { Write-Host $_ -ForegroundColor DarkRed }}

## Variables
$Source = "\\sncorp\internal\Corp_Software\ServiceCenter_SNC_Software\"
$DestinationFolder = "C:\temp\"
$File = "7-ZIP-64bit.zip"
$MainInstaller = "7-Zip-64bit_install.bat"
$MainUnInstaller = "7-Zip-64bit_uninstall.bat"
$vpn_test = Test-NetConnection -ComputerName "sncorp.intranet.com"
$ping_test = $vpn_test | Select-Object PingSucceeded -Wait

## Author Info
Write-Output ("Author Seth Burns - System Administrator II - Service Center
Tested On : 01-08-2024
This script will Install 7-ZIP 64Bit
Associated Resource $File") | DarkRed

## Description
Write-Output ("Description
This script will Uninstall 7-ZIP 64 Bit if it exists and then it will Install 7-Zip 64bit") | Green

Read-Host "Please read the Description, then press ENTER to Continue"

## Checking That Machine Is Online
if ($ping_test -match "False") { Write-Output "Please Connect To Internet & VPN" | Red}
if ($ping_test -match "False") { EXIT }
if ($ping_test -match "True") { Write-Output "Computer Is Connected To Network" | Green}
if ($ping_test -match "True") {

## Starting File Transfer
Write-Output ("Starting File Transfer") | Green
Robocopy $Source $DestinationFolder $File /mt:4 /z /e /xo | Green
Write-Output ("Finished File Transfer") | Green
## Finished File Transfer

## Expanding Archive File
Write-Output "Starting Archive Exspansion" | Green
Expand-Archive "C:\temp\$File" -Destination $DestinationFolder -force
Write-Output "Done Expanding Archive" | Green
## Archive Expansion Completed

## Starting Uninstallation
Write-Output "Starting $MainUnInstaller" | Green
Start-Process "C:\temp\7-ZIP-64bit\$MainUnInstaller" -Wait
Write-Output "Finished $MainUnInstaller" | Green
## Finished Uninstallation

## Starting Installation
Write-Output "Starting $MainInstaller" | Green
Start-Process "C:\temp\7-ZIP-64bit\$MainInstaller" -Wait
Write-Output "Finished $MainInstaller" | Green
## Finished Installation

EXIT}

