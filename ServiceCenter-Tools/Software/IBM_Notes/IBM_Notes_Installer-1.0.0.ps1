Powershell

#region Script Info
$Script_Name = "IBM_Notes_Installer-1.0.0.ps1"
$Description = "This script will Install IBM Notes Personal Edition"
$Author = "Seth Burns - System Administrator II - Service Center"
$last_tested = "05-27-25"
$version = "5.0.0"
$live = "WIP"
$bmgr = "WIP"
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
$Source = "\\sncorp\internal\Corp_Software\ServiceCenter_SNC_Software\IBM_Notes_PE_9.0.1.zip"
$vpn_test = Test-NetConnection -ComputerName "sncorp.intranet.com"
$ping_test = $vpn_test | Select-Object PingSucceeded -Wait
$FileName = "C:\Program Files (x86)\IBM\Notes"


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

Stop-Process -Name "nlnotes" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "notes2" -Force -ErrorAction SilentlyContinue

Read-Host -Prompt "Please ensure that you have manually uninstalled IBM Notes then Press any key to continue..."

if (Test-Path $FileName){
    Remove-Item $FileName -Force -Recurse -ErrorAction SilentlyContinue
    Write-host "$Filename has been deleted"
    Stop-Process -Name "nlnotes" -Force -ErrorAction SilentlyContinue
    Stop-Process -Name "notes2" -Force -ErrorAction SilentlyContinue
}
Else {
    Write-host "$FileName doesnt exist"
    }


## Expanding Archive File
Expand-Archive "C:\temp\IBM_Notes_PE_9.0.1.zip" -Destination "C:\temp" -force
## Archive Expansion Completed


## Starting Installation
Start-Process "C:\temp\IBM_Notes_PE_9.0.1\setup.exe" -wait
## Finished Installation

EXIT}

## Associated resource file "IBM_Notes_PE_9.0.1.zip"
## Author = Seth Burns & Frank Coates
## Last Tested on - 02-21-2023 - Working