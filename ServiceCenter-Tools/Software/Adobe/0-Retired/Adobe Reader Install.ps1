## This script will Install Adobe Reader

Powershell

## Variables
$Destination = "C:\temp"
$Source = "\\sncorp\internal\Corp_Software\ServiceCenter_SNC_Software\Acrobat_Reader_2017.zip"
$vpn_test = Test-NetConnection -ComputerName "sncorp.intranet.com"
$ping_test = $vpn_test | Select-Object PingSucceeded -Wait


$live = "Retired"
$bmgr = "Retired"



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
Expand-Archive "C:\temp\Acrobat_Reader_2017.zip" -Destination "C:\temp" -Force
## Archive Expansion Completed

## Starting Uninstallation
Start-Process "C:\temp\Acrobat_Reader_2017\Acrobat_2017_Reader_uninstall.bat" -wait
## Finished Uninstallation

## Starting Installation
Start-Process "C:\temp\Acrobat_Reader_2017\Acrobat_2017_Reader_install.bat" -wait
## Finished Installation

EXIT}

## Associated resource file "Acrobat_Reader_2017.zip"
## Author = Seth Burns & Frank Coates
## Last Tested on - 02-21-2023 - Working