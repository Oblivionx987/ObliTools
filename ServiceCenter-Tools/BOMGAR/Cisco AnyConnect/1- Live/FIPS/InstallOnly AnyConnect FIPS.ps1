## This script will install Fips onto vpn.

Powershell

## Variables
$Destination = "C:\temp"
$Source = "\\sncorp\internal\Corp_Software\ServiceCenter_SNC_Software\Cisco_AnyConnect_FIPS.zip"
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
Expand-Archive "C:\temp\Cisco_AnyConnect_FIPS.zip" -Destination "C:\temp" -force
## Archive Expansion Completed

## Starting Installation
Start-Process "C:\temp\Cisco_AnyConnect_FIPS\Cisco_AnyConnect_FIPS_install.bat" -wait
## Installation Completed

EXIT}

## Associated resource file "Cisco_AnyConnect_FIPS.zip"
## Author = Seth Burns
## Last Tested on - 04-05-2023 - Working