## This script will Install 7-ZIP 64Bit

## Powershell

#region Script Info
$Description = "This script will Install 7-ZIP 64Bit"
$Script_Name = "Install 7-ZIP 64Bit-1.0.0.ps1"
$Author = "Seth Burns - System Administrator II - Service Center"
$last_tested = "06-17-25"
$version = "1.0.0"
$live = "Retired"
$bmgr = "Retired"
#endregion

#region Text Colors 
function Red     { process { Write-Host $_ -ForegroundColor Red }}
function Green   { process { Write-Host $_ -ForegroundColor Green }}
function Yellow  { process { Write-Host $_ -ForegroundColor Yellow }}
function Blue    { process { Write-Host $_ -ForegroundColor Blue }}
function Cyan    { process { Write-Host $_ -ForegroundColor Cyan }}
function Magenta { process { Write-Host $_ -ForegroundColor Magenta }}
function White   { process { Write-Host $_ -ForegroundColor White }}
function Gray    { process { Write-Host $_ -ForegroundColor Gray }}
#endregion

#region Main Descriptor
## START Main Descriptor
Write-Output "--------------------"
Write-Output "$Author" | Yellow
Write-Output "$Script_Name" | Yellow
Write-Output "$version , $last_tested" | Yellow
Write-Output "$live , $bmgr" | Yellow
Write-Output "$Description" | Yellow
Write-Output "--------------------"
## END Main Descriptor
#endregion

## Variables
$Destination = "C:\temp"
$Source = "\\sncorp\internal\Corp_Software\ServiceCenter_SNC_Software\7-ZIP-64bit.zip"
$vpn_test = Test-NetConnection -ComputerName "sncorp.intranet.com"
$ping_test = $vpn_test | Select-Object PingSucceeded -Wait




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
Expand-Archive "C:\temp\7-ZIP-64bit.zip" -Destination "C:\temp" -force
## Archive Expansion Completed

## Starting Uninstallation
Start-Process "C:\temp\7-ZIP-64bit\7-Zip-64bit_uninstall.bat" -wait
## Finished Uninstallation

## Starting Installation
Start-Process "C:\temp\7-ZIP-64bit\7-Zip-64bit_install.bat" -wait
## Finished Installation

EXIT}

## Associated resource file "7-ZIP-64bit.zip"
## Author = Seth Burns & Frank Coates
## Last Tested on - 02-21-2023 - Working