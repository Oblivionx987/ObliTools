## This script will Remove Citrix Reciever & Workspace and Install Citrix workspace

Powershell

## Variables
$Destination = "C:\temp"
$Source = "\\sncorp\internal\Corp_Software\ServiceCenter_SNC_Software\Citrix_Workspace_22.3.2000.2105.zip"
$vpn_test = Test-NetConnection -ComputerName "sncorp.intranet.com"
$ping_test = $vpn_test | Select-Object PingSucceeded -Wait

## Functions
function Red { process { Write-Host $_ -ForegroundColor Red }}
function Green { process { Write-Host $_ -ForegroundColor Green }}
function Yellow { process { Write-Host $_ -ForegroundColor Yellow }}
function DarkRed { process { Write-Host $_ -ForegroundColor DarkRed }}

## Author Info
Write-Output ("Author :Seth Burns - System Administrator II - Service Center
Tested On : 02/05/2025
Associated Resource:
$Source
Associated Destination:
$Destination ") | DarkRed

## Description
Write-Output ("Description:
This script will Uninstall Citrix Reciever & Workspace if it exists then it will Install Citrix Workspace") | Green

read-host "Please read the description, then press ENTER to Continue"

## Checking That Machine Is Online
Write-Output ("Checking that device can connect to file Server") | Green
if ($ping_test -match "False") { Write-Output "Please Connect To Internet & VPN" | Red}
if ($ping_test -match "False") { EXIT }
if ($ping_test -match "True") { Write-Output "Computer Is Connected To Network" | Green}
if ($ping_test -match "True") {
	
## Starting File Transfer
Write-Output ("Starting File Transfer") | Green
$FOF_CREATEPROGRESSDLG = "&H0&"
$objShell = New-Object -ComObject "Shell.Application"
$objFolder = $objShell.NameSpace($Destination) 
$objFolder.CopyHere($Source, $FOF_CREATEPROGRESSDLG)
Write-Output ("Finished File Transfer") | Green
## Finished File Transfer

## Expanding Archive File
Write-Output ("Starting Archive Expansion") | Green
Expand-Archive "C:\temp\Citrix_Workspace_22.3.2000.2105.zip" -Destination "C:\temp" -force
Write-Output ("Finished Archive Expansion") | Green
## Archive Expansion Completed

## Starting Uninstallation
Write-Output ("Starting Uninstallation") | Green
Start-Process "C:\temp\Citrix_Workspace_22.3.2000.2105\Files\ReceiverCleanupUtility.exe" -wait
Start-Process "C:\temp\Citrix_Workspace_22.3.2000.2105\Citrix_Workspaces_22.3.2000.2105_uninstall.bat" -wait
Write-Output ("Finished Uninstallation") | Green
## Finished Uninstallation

## Starting Installation
Write-Output ("Starting Installation") | Green
Start-Process "C:\temp\Citrix_Workspace_22.3.2000.2105\Citrix_Workspaces_22.3.2000.2105_install.bat" -wait
Write-Output ("Finished Installation") | Green
## Finished Installation


EXIT}