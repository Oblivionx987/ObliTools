## This script will install Tortoise SVN

Powershell

## Variables
$Destination = "C:\temp"
$Source = "\\sncorp\internal\Corp_Software\ServiceCenter_SNC_Software\TortoiseSVN_1.9.4.zip"
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
Expand-Archive "C:\temp\TortoiseSVN_1.9.4.zip" -Destination "C:\temp" -force
## Archive Expansion Completed

## Starting Software Installation
Start-Process "C:\temp\TortoiseSVN_1.9.4\64bit\TortoiseSVN-64bit_install.bat" -wait
## Software Installation Completed

EXIT}

## Associated resource file "TortoiseSVN_1.9.4.zip"
## Author = Seth Burns
## Last Tested on - 08-02-2024 - Working


