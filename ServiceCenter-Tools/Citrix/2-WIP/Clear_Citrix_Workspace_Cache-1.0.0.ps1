
## Functions
function Red { process { Write-Host $_ -ForegroundColor Red }}
function Green { process { Write-Host $_ -ForegroundColor Green }}
function Yellow { process { Write-Host $_ -ForegroundColor Yellow }}
function DarkRed { process { Write-Host $_ -ForegroundColor DarkRed }}

## Author Info
Write-Output ("Author Seth Burns - System Administrator II - Service Center
Tested On : 01-08-2024
This script will Clear Citrix Workspace Cache
Associated Resource $File") | DarkRed

## Description
Write-Output ("Description
This script will Clear Citrix Workspace Cache") | Green

read-host "Please read the description, then press ENTER to Continue"

taskkill /im selfserviceplugin* /f
taskkill /im selfservice* /F

## Main Cleanup Call
Write-Output "Starting Cache Clear" | Green
Start-Process -FilePath "C:\Program Files (x86)\Citrix\ICA Client\SelfServicePlugin\CleanUp.exe" -ArgumentList "-cleanUser -silent" -Wait
Write-Output "Finished Cache Clear" | Green

#Start Citrix Workspace
Write-Output "Starting Citrix Workspace" | Green
Start-Process "C:\Program Files (x86)\Citrix\ICA Client\SelfServicePlugin\SelfService.exe"
Write-Output "Finished Starting Citrix Workspace" | Green


EXIT