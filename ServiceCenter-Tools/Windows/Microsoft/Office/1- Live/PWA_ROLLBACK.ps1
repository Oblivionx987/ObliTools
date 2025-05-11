## This script will remove office 365 / 2019 complete suite - It will then install office 2016 - It will then install Project pro 2016 32 bit pwa - It will then uninstall TITUS and Install 2016 Compatible TITUS

Powershell

## Variables
$Destination = "C:\temp"
$Source = "\\sncorp\internal\Corp_Software\ServiceCenter_SNC_Software\PWA_ROLLBACK.zip"
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
Expand-Archive "C:\temp\PWA_ROLLBACK.zip" -Destination "C:\temp" -force
## Archive Expansion Completed

## Starting Uninstallation of office 365
Write-Host "Starting Uninstallation of Office 365" -ForegroundColor Green
Start-Process "C:\temp\PWA_ROLLBACK\01_Microsoft365_Professional_64bit_v3\z_O365Pro_uninstall_ALL.bat" -wait
## Uninstall Completed

## Starting Software Installation for Office 2016
Write-Host "Starting Installation of Office 2016" -ForegroundColor Green
Start-Process "C:\temp\PWA_ROLLBACK\02_Office2016_Professional_32bit_v5\office_pro_2016_32bit_install_Outlook.bat" -wait
## Software Installation Completed

## Starting Software Installation for Project Pro 2016 32 BIT PWA
Write-Host "Starting Installation of Project Pro 2016 32 BIT PWA " -ForegroundColor Green
Start-Process "C:\temp\PWA_ROLLBACK\03_Project2016_Professional_32bit_PWA\project_2016_professional_32bit_install.bat" -wait
## Software Installation Completed

## Kill Running Titus Services
net stop Titus.Enterprise.Client.Service
net stop Titus.Enterprise.HealthMonitor.Service

taskkill /IM Titus* /F

## Starting Software Uninstallation
Write-Host "Starting Uninstallation of TITUS " -ForegroundColor Green
Start-Process "C:\temp\PWA_ROLLBACK\04_TITUS_Classification_v21.9.2244.2_msi_sync\TITUS_Classification_v21.9.2244.2_uninstall.bat" -wait
## Software Installation Completed

## Starting Software Installation
Write-Host "Starting Installation of TITUS " -ForegroundColor Green
Start-Process "C:\temp\PWA_ROLLBACK\04_TITUS_Classification_v21.9.2244.2_msi_sync\TITUS_Classification_v21.9.2244.2_install.bat" -wait
## Software Installation Completed

## Start Titus Services
net start Titus.Enterprise.Client.Service
net start Titus.Enterprise.HealthMonitor.Service

EXIT}

## Associated resource file "PWA_ROLLBACK.zip"
## Author = Seth Burns
## Last Tested on - 11/02/2023 - Working

