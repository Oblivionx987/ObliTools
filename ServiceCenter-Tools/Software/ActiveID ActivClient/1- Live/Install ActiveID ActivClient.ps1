## This script will install ActiveID Active Client

Powershell

## Variables
$Destination = "C:\temp"
$Source = "\\sncorp\internal\Corp_Software\ServiceCenter_SNC_Software\ActiveClient_7.4.1.zip"
$vpn_test = Test-NetConnection -ComputerName "sncorp.intranet.com"
$ping_test = $vpn_test | Select-Object PingSucceeded -Wait


$version = "1.0.0"
$live = "Live"
$bmgr = "Live"
$description = "This script will install activeid active client for use with checking dod cac cards or setting up a pin on a cac card. Can also be used to check info on a card."




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
Expand-Archive "C:\temp\ActiveClient_7.4.1.zip" -Destination "C:\temp" -force
## Archive Expansion Completed

## Starting Software Installation
Start-Process "C:\temp\ActiveClient_7.4.1\setup_ActivClient7.4.1.exe" -wait
## Software Installation Completed

EXIT}

## Associated resource file "ActiveClient_7.4.1.zip"
## Author = Seth Burns
## Last Tested on - 11-29-2023 - Working


