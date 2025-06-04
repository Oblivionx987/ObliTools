powershell

#region Script Info
$Script_Name = "Google_Earth_Pro_Installer-1.0.0.ps1"
$Description = "This script will Install Google Earth Pro"
$Author = "Seth Burns - System Administrator II - Service Center"
$last_tested = "05-27-25"
$version = "1.0.0"
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


## Starting File Transfer
Copy-Item "\\sncorp\internal\Corp_Software\ServiceCenter_SNC_Software\Google_Earth_Pro.zip" -Destination "C:\temp" -Force
## Finished File Transfer

## Expanding Archive File
Expand-Archive "C:\temp\Google_Earth_Pro.zip" -Destination "C:\temp" -force
## Archive Expansion Completed

## Starting Installation
Start-Process "C:\temp\Google_Earth_Pro\GoogleEarthProSetup.exe" -wait
## Finished Installation

EXIT

## Associated resource file "Cisco_AnyConnect_4.9.06037.zip"
## Author = Seth Burns - 114825-adm
## Last Tested on - 02-09-2023 - NW