## This script will install NEW TEAMS Meeting Addin

Powershell

## Functions
function Red { process { Write-Host $_ -ForegroundColor Red }}
function Green { process { Write-Host $_ -ForegroundColor Green }}


$msteams = get-process -name "ms-teams"
Stop-Process -InputObject $msteams -Force
if (Get-Process | Where-Object {$_.HasExited}) {Write-Output "Force Closed New Teams" | Red } else {Write-Output "New Teams is not open" | Red }

$classicteams = get-process -name "teams"
Stop-Process -InputObject $classicteams -Force
if (Get-Process | Where-Object {$_.HasExited}) {Write-Output "Force Closed Classic Teams" | Red } else {Write-Output "Classic Teams is not open" | Red }

$outlook = get-process -name "Outlook"
Stop-Process -InputObject $outlook -Force
if (Get-Process | Where-Object {$_.HasExited}) {Write-Output "Force Closed Outlook" | Red } else {Write-Output "Outlook is not open" | Red }

Write-Output "Starting New Teams Install do not close the command window that pops up" | Red

## Starting Software Installation
start-process "C:\Program Files\WindowsApps\MSTeams_24091.214.2846.1452_x64__8wekyb3d8bbwe\MicrosoftTeamsMeetingAddinInstaller.msi" -Wait
## Software Installation Completed

EXIT

## Associated resource file "x"
## Author = Seth Burns
## Last Tested on - 09-29-2022 - UNK