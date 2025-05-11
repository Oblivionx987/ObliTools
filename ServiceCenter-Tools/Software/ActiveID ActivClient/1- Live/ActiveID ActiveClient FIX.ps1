## This script will install ActiveID Active Client

Powershell

## Variables
$Destination = "C:\temp"
$Source = "\\sncorp\internal\Corp_Software\ServiceCenter_SNC_Software\C1150_Mini_Driver_2.1.0.21_FIXS2302004.zip"
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

## Associated resource file "C1150_Mini_Driver_2.1.0.21_FIXS2302004.zip"
## Author = Seth Burns
## Last Tested on - 11-29-2023 - Working


