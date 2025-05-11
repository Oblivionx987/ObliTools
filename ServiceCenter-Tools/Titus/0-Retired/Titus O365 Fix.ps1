## This script will install Titus for Office365

Powershell

## Variables
$Destination = "C:\temp"
$Source = "\\sncorp\internal\Corp_Software\ServiceCenter_SNC_Software\TITUS_O365_FIX.zip"
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
Expand-Archive "C:\temp\TITUS_O365_FIX.zip" -Destination "C:\temp" -force
## Archive Expansion Completed

## Starting Uninstallation
Start-Process "C:\temp\TITUS_Classification_v20.3.2108.2_msi_sync\TITUS_Classification_v20.3.2108.2_uninstall.bat" -wait
## Uninstall Completed

## Starting Software Installation
Start-Process "C:\temp\TITUS_Classification_v20.3.2108.2_msi_sync\TITUS_Classification_v20.3.2108.2_install.bat" -wait
## Software Installation Completed

EXIT}

## Associated resource file "TITUS_O365_FIX.zip"
## Author = Seth Burns & Frank Coates
## Last Tested on - 02-21-2023 - Working