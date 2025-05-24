$description = "This script will setup base configuration for Dell Command Update"
$version = "1.0.0"
$live = "Live"
$bmgr = "Live"
$author = "Seth Burns - System Administarator II - Service Center"



Powershell

## Variables
$Destination = "C:\temp"
$Source = "\\sncorp\internal\Corp_Software\ServiceCenter_SNC_Software\DCU-Config.zip"
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
Expand-Archive "C:\temp\DCU-Config.zip" -Destination "C:\temp" -force
## Archive Expansion Completed

## Starting Software Installation
Start-Process "C:\temp\DCU-Config\DCU-Config.bat"
## Software Installation Completed

sleep 5

## Remove the DCU Config File
Remove-Item -Path "C:\temp\DCU-Config.zip" -Force
Remove-Item -Path "C:\temp\DCU-Config\DCU-Config.bat" -Force
Remove-Item -Path "C:\temp\DCU-Config" -Force
## Removed the DCU Config File

EXIT}

## Associated resource file "DCU-Config.zip"
## Author = Seth Burns
## Last Tested on - 08-05-2024 - Working


