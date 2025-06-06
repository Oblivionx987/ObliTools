Powershell

#region Script Info
$Script_Name = "Adobe Acrobat DC All in One"
$Description = "This script will copy over files for windows 11 setup diagnostics. It will auto scan C:\$WINDOWS.~BT and outout diag logs to temp folder."
$Author = "Seth Burns - System Administrator II - Service Center"
$last_tested = "05-24-2025"
$version = "2.0.0"
$live = "Test"
$bmgr = "Test"
#endregion


## Variables
$Destination = "C:\temp"
$Source = "\\sncorp\Internal\Corp_Software\ServiceCenter_SNC_Software\SetupDiag.zip"
$vpn_test = Test-NetConnection -ComputerName "sncorp.intranet.com"
$ping_test = $vpn_test | Select-Object PingSucceeded -Wait






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


## Author Info
Write-Output ("Author Seth Burns - System Administrator II - Service Center
Tested On : 01-08-2024
This script will copy over files for windows 11 setup diagnostics. It will auto scan C:\$WINDOWS.~BT and outout diag logs to temp folder. 
If your not familiar with checking this logs reach out to Seth Burns") | DarkRed

## Description
Write-Output ("Description:
This script will copy over files for windows 11 setup diagnostics. It will auto scan C:\$WINDOWS.~BT and outout diag logs to temp folder. 
If your not familiar with checking this logs reach out to Seth Burns") | Green

read-host "Please read the description, then press ENTER to Continue"


## Checking That Machine Is Online
Write-Output "Checking that Machine is connected to SNC"
if ($ping_test -match "False") { Write-Output "Please Connect To Internet & VPN If Needed" | Red}
if ($ping_test -match "False") { EXIT }
if ($ping_test -match "True") { Write-Output "Computer Is Connected To Network" | Green}
if ($ping_test -match "True") {
	
## Starting File Transfer
Write-Output "Starting Archive File Transfer"
$FOF_CREATEPROGRESSDLG = "&H0&"
$objShell = New-Object -ComObject "Shell.Application"
$objFolder = $objShell.NameSpace($Destination) 
$objFolder.CopyHere($Source, $FOF_CREATEPROGRESSDLG)
Write-Output "Finished Archive File Transfer" | Green
## Finished File Transfer

## Expanding Archive File
Write-Output "Expanding Archive File"
Expand-Archive "C:\temp\SetupDiag.zip" -Destination "C:\temp\SetupDiag\" -force
Write-Output "Finished Expanding Archive File" | Green
## Archive Expansion Completed

## Starting Installation
Write-Output "Starting Setup Diagnostics"
Start-Process C:\temp\SetupDiag\LogSetupDiag-1.0.0.cmd
Write-Output "Finished Setup Diagnostics" | Green
## Finished Installation

Exit}