## This script will install Office365 Project 2019 Std 64Bit

Powershell

## Variables
$Destination = "C:\temp"
$Source = "\\sncorp\internal\Corp_Software\ServiceCenter_SNC_Software\Project2019_Std_64bit_v3.zip"
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
Expand-Archive "C:\temp\Project2019_Std_64bit_v3.zip" -Destination "C:\temp" -force
## Archive Expansion Completed

## Starting Uninstallation
Start-Process "C:\temp\Project2019_Std_64bit_v3\Project2019_Std_64bit_uninstall.bat" -wait
## Uninstall Completed

## Starting Software Installation
Start-Process "C:\temp\Project2019_Std_64bit_v3\Project2019_Std_64bit_install.bat" -wait
## Software Installation Completed

EXIT}

## Associated resource file "Project2019_Std_64bit_v3.zip"
## Author = Seth Burns & Frank Coates
## Last Tested on - 05-09-2023 - Working


