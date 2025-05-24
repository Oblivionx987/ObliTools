

Powershell

## Variables
$Destination = "C:\temp"
$Source = "\\sncorp\internal\Corp_Software\ServiceCenter_SNC_Software\AutoCAD2022_64bit_IAS.zip"
$vpn_test = Test-NetConnection -ComputerName "sncorp.intranet.com"
$ping_test = $vpn_test | Select-Object PingSucceeded -Wait
$description = "This script will Uninstall AutoCad 2022 if it exists then it will Install AutoCad 2022"
$author = "Author: Seth Burns - System Administrator II - Service Center"
$live = "Live"
$Version = "1.0.0"
$bmgr = "Live"



## Functions
function Red { process { Write-Host $_ -ForegroundColor Red }}
function Green { process { Write-Host $_ -ForegroundColor Green }}
function Yellow { process { Write-Host $_ -ForegroundColor Yellow }}
function DarkRed { process { Write-Host $_ -ForegroundColor DarkRed }}


## Author Info
Write-Output ("Author Seth Burns - System Administrator II - Service Center
Tested On : 01-08-2024
This script will Install AutoCad 2022
Associated Resource: $File") | DarkRed

## Description
Write-Output ("Description:
This script will Uninstall AutoCad 2022 if it exists then it will Install AutoCad 2022") | Green

read-host "Please read the description, then press ENTER to Continue"


## Checking That Machine Is Online
Write-Output "Checking that Machine is connected to SNC"
if ($ping_test -match "False") { Write-Output "Please Connect To Internet & VPN If Needed" | Red}
if ($ping_test -match "False") { EXIT }
if ($ping_test -match "True") { Write-Output "Computer Is Connected To SNC Network" | Green}
if ($ping_test -match "True") {
	
## Starting File Transfer
Write-Output "Starting Archive File Transfer"
$FOF_CREATEPROGRESSDLG = "&H0&"
$objShell = New-Object -ComObject "Shell.Application"
$objFolder = $objShell.NameSpace($Destination) 
$objFolder.CopyHere($Source, $FOF_CREATEPROGRESSDLG)
Write-Output "Finished Archive File Transfer" | Green
## Finished File Transfer

## Expanding Archive File
Write-Output "Expanding Archive File"
Expand-Archive "C:\temp\AutoCAD2022_64bit_IAS.zip" -Destination "C:\temp" -force
Write-Output "Finished Expanding Archive File" | Green
## Archive Expansion Completed

## Starting Uninstallation
Write-Output "Starting Autocad Uninstall for Cleanup"
Start-Process "C:\temp\AutoCAD2022_64bit_IAS\autocad_2022_64bit_uninstall.bat" -wait
Write-Output "Finished Expanding Archive File" | Green
## Finished Uninstallation

## Starting Installation
Write-Output "Starting Autocad Installer"
Start-Process "C:\temp\AutoCAD2022_64bit_IAS\autocad_2022_64bit_install.bat" -wait
Write-Output "Finished Autocad Install"
## Finished Installation


EXIT}
Exit
