## This script will install Embrava Busy Light

Powershell

## Variables
$Destination = "C:\temp"
$Source = "\\sncorp\internal\Corp_Software\ServiceCenter_SNC_Software\WinSSHOfflineInstaller_2_21_0.zip"
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
Expand-Archive "C:\temp\WinSSHOfflineInstaller_2_21_0.zip" -Destination "C:\temp" -force
## Archive Expansion Completed

## Starting Installation
Start-Process "C:\temp\WinSSHOfflineInstaller_2_21_0.exe" -wait
## Installation Completed

EXIT}

## Associated resource file "N/A"
## Author = Seth Burns
## Last Tested on - 02-15-2024 - Working