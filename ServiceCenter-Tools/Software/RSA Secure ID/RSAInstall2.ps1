## This Script will install Titus for Office365

Powershell

## Variables
$Destination = "C:\temp"
$Source = "\\sncorp\internal\Corp_Software\ServiceCenter_SNC_Software\RSA_SecurID_Software_Token.zip"
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
Expand-Archive "C:\temp\RSA_SecurID_Software_Token.zip" -Destination "C:\temp" -Force
## Archive Expansion Completed

## Starting Installation
Start-Process "c:\temp\RSA_SecurID_Software_Token\5.0.2.440\Deploy-Application.exe" -wait
## Installation Started

EXIT}

## Associated resource file "RSA_SecurID_Software_Token.zip"
## Author = Seth Burns & Frank Coates
## Script Last Test Date - 2/9/2023 - Working