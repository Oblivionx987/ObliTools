## This script will Remove Citrix Reciever & Workspace and Install Citrix workspace

Powershell

#region Script Info
$Script_Name = "Citrix_Workspace_AIO-1.0.1.ps1"
$Description = "This script will Uninstall citrix workspace and Install Citrix workspace"
$Author = "Seth Burns - System Administrator II - Service Center"
$last_tested = "05-27-25"
$version = "1.0.1 - 22.3.2000.2105"
$live = "Test"
$bmgr = "Test"
#endregion

## Variables
$Destination = "C:\temp"
$Source = "\\sncorp\internal\Corp_Software\ServiceCenter_SNC_Software\Citrix_Workspace_22.3.2000.2105.zip"
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

Clear-Host

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

## Starting Installation
Write-Output ("Starting Installation") | Green
Start-Process "C:\temp\Citrix_Workspace_22.3.2000.2105\Citrix_Workspaces_22.3.2000.2105_uninstall.bat" -wait
Write-Output ("Finished Installation") | Green
## Finished Installation

## Starting Installation
Write-Output ("Starting Installation") | Green
Start-Process "C:\temp\Citrix_Workspace_22.3.2000.2105\Citrix_Workspaces_22.3.2000.2105_install.bat" -wait
Write-Output ("Finished Installation") | Green
## Finished Installation


EXIT}