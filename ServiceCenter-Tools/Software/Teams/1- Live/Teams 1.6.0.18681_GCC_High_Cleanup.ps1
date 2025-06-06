## This script will install Teams 1.6.0.18681_GCC_High

Powershell

## Variables
$Destination = "C:\temp"
$Source = "\\sncorp\internal\Corp_Software\ServiceCenter_SNC_Software\Teams_1.6.0.18681_GCC_High_Cleanup.zip"
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
Expand-Archive "C:\temp\Teams_1.6.0.18681_GCC_High_Cleanup.zip" -Destination "C:\temp" -force
## Archive Expansion Completed

## Starting Uninstallation
Start-Process "C:\temp\Teams_1.6.0.18681_GCC_High_Cleanup\Teams_1.6.0.18681_GCC_High_uninstall_silent.bat" -wait
## Uninstall Completed

## Starting Software Installation
Start-Process "C:\temp\Teams_1.6.0.18681_GCC_High_Cleanup\Teams_1.6.0.18681_GCC_High_install_silent.bat" -wait
## Software Installation Completed

EXIT}

## Associated resource file "Teams_1.6.0.18681_GCC_High_Cleanup.zip"
## Author = Seth Burns
## Last Tested on - 09-29-2022 - UNK