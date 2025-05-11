## This script will Uninstall NEW TEAMS

Powershell

## Variables
$Destination = "C:\temp"
$Source = "\\sncorp\internal\Corp_Software\ServiceCenter_SNC_Software\NewTeams_24091.214.2846.1452.zip"
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
Expand-Archive "C:\temp\NewTeams_24091.214.2846.1452.zip" -Destination "C:\temp" -force
## Archive Expansion Completed

$msteams = get-process -name "ms-teams"
Stop-Process -InputObject $msteams -Force
if (Get-Process | Where-Object {$_.HasExited}) {Write-Output "Force Closed New Teams"}
else {Write-Output "New Teams is not open"}

$classicteams = get-process -name "teams"
Stop-Process -InputObject $classicteams -Force
if (Get-Process | Where-Object {$_.HasExited}) {Write-Output "Force Closed Classic Teams"}
else {Write-Output "Classic Teams is not open"}

$outlook = get-process -name "Outlook"
Stop-Process -InputObject $outlook -Force
if (Get-Process | Where-Object {$_.HasExited}) {Write-Output "Force Closed Outlook"}
else {Write-Output "Outlook is not open"}

Write-Output "Starting New Teams Install do not close the command window that pops up" | Red

## Starting Software Installation
Start-Process "C:\temp\NewTeams_24091.214.2846.1452\teamsbootstrapper.exe" -Args "-x" -wait
## Software Installation Completed

EXIT}

## Associated resource file "x"
## Author = Seth Burns
## Last Tested on - 09-29-2022 - UNK