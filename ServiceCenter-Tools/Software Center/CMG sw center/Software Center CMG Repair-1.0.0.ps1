Powershell

## Variables
$Destination = "C:\temp"
$Source = "\\sncorp\internal\Corp_Software\ServiceCenter_SNC_Software\Client-1.0.0.zip"
$vpn_test = Test-NetConnection -ComputerName "sncorp.intranet.com"
$ping_test = $vpn_test | Select-Object PingSucceeded -Wait

## Functions
function Red { process { Write-Host $_ -ForegroundColor Red }}
function Green { process { Write-Host $_ -ForegroundColor Green }}
function Yellow { process { Write-Host $_ -ForegroundColor Yellow }}
function DarkRed { process { Write-Host $_ -ForegroundColor DarkRed }}


## Author Info
Write-Output ("Author Seth Burns - System Administrator II - Service Center
Tested On : 01-08-2024
This script will remove and reinstall software center for CMG
Associated Resource:
$Source
Associated Path:
$Destination" ) | DarkRed

## Description
Write-Output ("Description
This script will remove and reinstall software center") | Green

read-host "Please read the description, then press ENTER to Continue"


## Checking That Machine Is Online
Write-Output ("Checking that machine is connected to snc network")
if ($ping_test -match "False") { Write-Output "Please Connect To Internet & VPN If Needed" | Red}
if ($ping_test -match "False") { EXIT }
if ($ping_test -match "True") { Write-Output "Computer Is Connected To Network" | Green}
if ($ping_test -match "True") {
	
## Starting File Transfer
Write-Output ("Starting Arhcive File Transfer")
$FOF_CREATEPROGRESSDLG = "&H0&"
$objShell = New-Object -ComObject "Shell.Application"
$objFolder = $objShell.NameSpace($Destination) 
$objFolder.CopyHere($Source, $FOF_CREATEPROGRESSDLG)
Write-Output ("Finsihed Archive File Transfer") | Green
## Finished File Transfer

## Expanding Archive File
Write-Output ("Starting Archive Expansion")
Expand-Archive "C:\temp\Client-1.0.0.zip" -Destination "C:\temp" -force
Write-Output ("Finsished Archive Expansion") | Green
## Archive Expansion Completed


Write-Output ("Removing Previous Software Center")
Start-Process C:/temp/Client-1.0.0/removeswcenter-1.0.0.cmd
Write-Output ("Start 30 second wait")
Sleep 30
Write-Output ("Finished Removal") | Green

Write-Output ("Installing CMG Software Center")
Start-Process C:/temp/Client-1.0.0/addcmgswcenter-1.0.0.cmd
Write-Output ("Start 30 second wait")
Sleep 30
Write-Output ("Finished adding CMG software center") | Green

Start-Process softwarecenter:

Write-Output ("Please note that this can take up to 30 mins for all software to arrive. Opening your software center for you, If the GUI looks odd close it and reopen it. Please let it sit, and report back to your Technician.
") | Red

Exit}