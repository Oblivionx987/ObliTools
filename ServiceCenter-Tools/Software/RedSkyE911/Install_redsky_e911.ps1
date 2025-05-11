## This script will install redskye911 V 

Powershell

## Variables
$Destination = "C:\temp"
$Source = "\\sncorp\internal\Corp_Software\ServiceCenter_SNC_Software\redsky-mye911.zip"
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
Expand-Archive "C:\temp\redsky-mye911.zip" -Destination "C:\temp" -force
## Archive Expansion Completed

Write-Output "Starting redsky Install do not close the command window that pops up" | Red
Write-Output "If host is missing use "https://anywhere.e911cloud.com""

## Starting Software Installation
Start-Process "C:\temp\redsky-mye911-5.0.0-2406120906 13.msi"
## Software Installation Completed

EXIT}

## Associated resource file "redsky-mye911.zip"
## Author = Seth Burns
## Last Tested on - 09-29-2022 - UNK