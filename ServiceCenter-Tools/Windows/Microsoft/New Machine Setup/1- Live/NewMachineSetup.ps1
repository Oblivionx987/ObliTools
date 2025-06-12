##Powershell

#region Script Info
$Script_Name = "NewMachineSetup.ps1"
$Description = "Starts the new machine setup script."
$Author = "Seth Burns - System Administrator II - Service Center"
$last_tested = "05-27-25"
$version = "1.0.0"
$live = "Live"
$bmgr = "Live"
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

## TO DO

   ## Set Default PDF Handler - Adobe
   ## Set Default Web Browser - Chrome
   ## Set Default email client - Outlook

   ## MAPPING shortcuts and .exe's will need to be setup in a VB script as windows blocks it via powershell
   ## Map a shortcut to Toolbar - Teams
   $teamslink = "C:\Users\114825\AppData\Local\Microsoft\Teams\Update.exe" -ArgumentList '--processStart "Teams.exe"'
   ## Map a shortcut to Toolbar - Outlook
   $outlooklink = "C:\Program Files\Microsoft Office\root\Office16\OUTLOOK.EXE"
   ## Map a shortcut to Toolbar - Chrome
   $chromelink = "C:\Program Files\Google\Chrome\Application\chrome.exe"
   ## Map a shortcut to Toolbar - Edge
   $edglelink = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe" -ArgumentList '--profile-directory=Default'
   ## Map a shrotcut to Toolbar - OneDrive Folder
   $onedrivelink = "C:\Users\$UserInput\OneDrive - Sierra Nevada Corporation"
   ## Map a shortcut to Toolbar - H Drive Folder
   $hdrivelink = "\\sncorp\homes\$UserInput"




## Variables
$UserInput = Read-Host "Please Input User ID" 
$User = $Env:USERNAME
$Outlook = "C:\Program Files\Microsoft Office\root\Office16\OUTLOOK.EXE"
$Computer = $Env:ComputerName

## Display Input results
Write-Output "User: $UserInput" | Blue
Write-Output "Asset: $Computer" | Blue

## Map H Drive for current User
New-PSDrive -Name "H" -PSProvider "FileSystem" -Root \\sncorp\homes\$UserInput -Persist

## Setup Error handling for a user that does not have an H drive



## Start Outlook for Current User
Start-Process $Outlook

## Start Teams for Current User
Start-Process -File $env:LOCALAPPDATA\Microsoft\Teams\Update.exe -ArgumentList '--processStart "Teams.exe"'


## Enable AutoUpdates in DellCommandUpdates
$dcuenable = "C:\Program Files (x86)\Dell\CommandUpdate\"
Set-Location -Path $dcuenable
.\dcu-cli.exe /configure -ScheduleAuto




Read-Host -Prompt "Press Enter to exit"
EXIT


## Last Tested on 02-08-2024
## Author : Seth Burns
## Resource File: N/A