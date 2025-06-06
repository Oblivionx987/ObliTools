## This script will install Office 2016 Pro 32Bit - No TITUS

Powershell

## Variables
$Destination = "C:\temp"
$Source = "\\sncorp\internal\Corp_Software\ServiceCenter_SNC_Software\Office2016_Professional_64bit_v5.zip"
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
Expand-Archive "C:\temp\Office2016_Professional_64bit_v5.zip" -Destination "C:\temp" -force
## Archive Expansion Completed

## Starting Uninstallation
Start-Process "C:\temp\Office2016_Professional_64bit_v5\office_pro_2016_64bit_uninstall.bat" -wait
## Uninstall Completed

## Starting Software Installation
Start-Process "C:\temp\Office2016_Professional_64bit_v5\office_pro_2016_64bit_install_Outlook.bat" -wait
## Software Installation Completed

EXIT}

## Associated resource file "Office2016_Professional_64bit_v5.zip"
## Author = Seth Burns & Frank Coates
## Last Tested on - 02-21-2023 - Working

