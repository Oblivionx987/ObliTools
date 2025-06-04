## "This script will remove activeid active client and replace it with an HID creshendo mini driver as there are incompatability issues with the driver and yubiekys"

Powershell

## Variables
$Destination = "C:\temp"
$Source = "\\sncorp\internal\Corp_Software\ServiceCenter_SNC_Software\C1150_Mini_Driver_2.1.0.21_FIXS2302004.zip"
$vpn_test = Test-NetConnection -ComputerName "sncorp.intranet.com"
$ping_test = $vpn_test | Select-Object PingSucceeded -Wait


#region Script Info
$Script_Name = "ActiveID_ActiveClient_FIX-1.0.0.ps1"
$Description = "This script will remove activeid active client and replace it with an HID creshendo mini driver as there are incompatability issues with the driver and yubiekys"
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
Expand-Archive "C:\temp\C1150_Mini_Driver_2.1.0.21_FIXS2302004.zip" -Destination "C:\temp" -force
## Archive Expansion Completed

$MyApp = Get-WmiObject -Class Win32_Product | Where-Object{$_.Name -eq "ActivID ActivClient x64"}
$MyApp.Uninstall()

$MyApp1 = Get-WmiObject -Class Win32_Product | Where-Object{$_.Name -eq "HID OMNIKEY 3x2x PC/SC Driver"}
$MyApp1.Uninstall()

## Starting Software Installation
Start-Process "C:\temp\C1150_Mini_Driver_2.1.0.21_FIXS2302004\HID_Global_Crescendo_Minidriver_x64_2.1.msi" -wait
## Software Installation Completed

EXIT}
Exit

