
Powershell

#region Script Info
$Script_Name = "Titus Office 2016 Fix.ps1"
$Description = "This script will install Titus for Office 2016"
$Author = "Seth Burns - System Administrator II - Service Center"
$last_tested = "05-27-25"
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
Write-Output "--------------------" | Yellow
Write-Output "$Author" | Yellow
Write-Output "$Script_Name" | Yellow
Write-Output "$version , $last_tested" | Yellow
Write-Output "$live , $bmgr" | Yellow
Write-Output "$Description" | Yellow
Write-Output "--------------------" | Yellow
## END Main Descriptor
#endregion


## Variables
$Destination = "C:\temp"
$Source = "\\sncorp\internal\Corp_Software\ServiceCenter_SNC_Software\TITUS_Office2016_FIX.zip"
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
Expand-Archive "C:\temp\TITUS_Office2016_FIX.zip" -Destination "C:\temp" -force
## Archive Expansion Completed

## Kill Running Titus Services
net stop Titus.Enterprise.Client.Service
net stop Titus.Enterprise.HealthMonitor.Service

taskkill /IM Titus* /F

## Starting Uninstallation
Start-Process "C:\temp\TITUS_Office2016_FIX\Step_1_TITUS_Classification_v18.8.1913.246\TITUS_Classification_v18.8.1913.246_uninstall.bat" -wait
## Uninstall Completed

## Starting Software Installation
Start-Process "C:\temp\TITUS_Office2016_FIX\Step_1_TITUS_Classification_v18.8.1913.246\TITUS_Classification_v18.8.1913.246_install.bat" -wait
## Software Installation Completed

## Starting Config Installation
Start-Process "C:\Temp\TITUS_Office2016_FIX\Step_2_TITUS_Classification_v18.8.1913.246_config_v2.0.7.1EL2\TITUS_Classification_v18.8.1913.246_config_v2.0.7.1EL2_install_silent.bat" -wait
##Config Installation Started

## Start Titus Services
net start Titus.Enterprise.Client.Service
net start Titus.Enterprise.HealthMonitor.Service


EXIT}

## Associated resource file "TITUS_Office2016_FIX.zip"
## Author = Seth Burns & Frank Coates
## Last Tested on - 02-21-2023 - Working