## This script will install MS Calculator

Powershell

## Variables
$Destination = "C:\temp"
$Source = "\\sncorp\internal\Corp_Software\ServiceCenter_SNC_Software\Microsoft.WindowsCalculator_2021.2307.4.0_neutral_~_8wekyb3d8bbwe.zip"
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
Expand-Archive "C:\temp\Microsoft.WindowsCalculator_2021.2307.4.0_neutral_~_8wekyb3d8bbwe.zip" -Destination "C:\temp" -force
## Archive Expansion Completed

explorer "c:\temp\"

## Install App Packagage
## Add-AppxPackage -Path C:\temp\Microsoft.WindowsCalculator_2021.2307.4.0_neutral_~_8wekyb3d8bbwe.Msixbundle
## Install App Package Completed

EXIT}

## Associated resource file "Microsoft.WindowsCalculator_2021.2307.4.0_neutral_~_8wekyb3d8bbwe.zip"
## Author = Seth Burns
## Last Tested on - 04-05-2023 - Working