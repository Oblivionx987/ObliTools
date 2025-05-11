## This script will install Titus 22.10.2332.3 for Office 365

Powershell

## Variables
$Destination = "C:\temp"
$Source = "\\sncorp\internal\Corp_Software\ServiceCenter_SNC_Software\TITUS_Classification_v22.10.2332.3.zip"
$vpn_test = Test-NetConnection -ComputerName "sncorp.intranet.com"
$ping_test = $vpn_test | Select-Object PingSucceeded -Wait

## Functions
function Red { process { Write-Host $_ -ForegroundColor Red }}
function Green { process { Write-Host $_ -ForegroundColor Green }}

## Checking That Machine Is Online
if ($ping_test -match "False") { Write-Output "Please Connect To Internet & VPN" | Red}
if ($ping_test -match "False") { EXIT }
if ($ping_test -match "True") { Write-Output "Computer Is Connected To Network" | Green}
if ($ping_test -match "True") {
	
## Starting File Transfer
$FOF_CREATEPROGRESSDLG = "&H0&"
$objShell = New-Object -ComObject "Shell.Application"
$objFolder = $objShell.NameSpace($Destination) 
$objFolder.CopyHere($Source, $FOF_CREATEPROGRESSDLG)
## Finished File Transfer

## Expanding Archive File
Expand-Archive "C:\temp\TITUS_Classification_v22.10.2332.3.zip" -Destination "C:\temp" -force
## Archive Expansion Completed

## Kill Running Titus Services
net stop Titus.Enterprise.Client.Service
net stop Titus.Enterprise.HealthMonitor.Service

taskkill /IM Titus* /F


## Starting Uninstallation
Start-Process "C:\temp\TITUS_Classification_v22.10.2332.3\TITUS_Classification_v22.10.2332.3_uninstall.bat" -wait
## Uninstall Completed

## Starting Software Installation
Start-Process "C:\temp\TITUS_Classification_v22.10.2332.3\TITUS_Classification_v22.10.2332.3_install.bat" -wait
## Software Installation Completed

## Start Titus Services
net start Titus.Enterprise.Client.Service
net start Titus.Enterprise.HealthMonitor.Service


EXIT}

## Associated resource file "TITUS_Classification_v22.10.2332.3.zip"
## Author = Seth Burns & Frank Coates
## Last Tested on - 02-21-2023 - Working