Powershell

## Functions
function Red { process { Write-Host $_ -ForegroundColor Red }}
function Green { process { Write-Host $_ -ForegroundColor Green }}
function Yellow { process { Write-Host $_ -ForegroundColor Yellow }}
function DarkRed { process { Write-Host $_ -ForegroundColor DarkRed }}

## Author Info
Write-Output ("
Author Seth Burns - System Administrator II - Service Center
Tested On : 12-20-2024
This script will Output a Battery Report to Temp folder") | DarkRed

## Variables
$Computer = $env:computername

## MAIN
Write-Output "Creating Battery Report for $Computer" | Green
powercfg /batteryreport /output "C:\temp\$Computer-battery-report.html"
Write-Output "Battery Report Output Completed Please See Temp Folder"

Start-Process "C:\temp\$Computer-battery-report.html"

read-host "Press ENTER to Continue"

Exit