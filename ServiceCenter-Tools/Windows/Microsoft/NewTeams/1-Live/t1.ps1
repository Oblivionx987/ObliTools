## This script will install NEW TEAMS Meeting Addin

Powershell

## Functions
function Red { process { Write-Host $_ -ForegroundColor Red }}
function Green { process { Write-Host $_ -ForegroundColor Green }}

## Stop ms-teams process
try {
    $msteams = Get-Process -Name "ms-teams" -ErrorAction Stop
    Stop-Process -InputObject $msteams -Force
    Write-Output "Stopped ms-teams process" | Green
}
catch {
    Write-Output "ms-teams process not found" | Red
}

## Stop teams process
try {
    $classicteams = Get-Process -Name "teams" -ErrorAction Stop
    Stop-Process -InputObject $classicteams -Force
    Write-Output "Stopped teams process" | Green
}
catch {
    Write-Output "teams process not found" | Red
}

## Stop Outlook process
try {
    $outlook = Get-Process -Name "Outlook" -ErrorAction Stop
    Stop-Process -InputObject $outlook -Force
    Write-Output "Stopped Outlook process" | Green
}
catch {
    Write-Output "Outlook process not found" | Red
}

Write-Output "Starting New Teams Install. Please do not close the command window that pops up." | Red

## Starting Software Installation
Start-Process "C:\Program Files\WindowsApps\MSTeams_24091.214.2846.1452_x64__8wekyb3d8bbwe\MicrosoftTeamsMeetingAddinInstaller.msi" -Wait
## Software Installation Completed

EXIT

## Associated resource file "x"
## Author = Seth Burns
## Last Tested on - 09-29-2022 - UNK