##Powershell

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



## Functions
function Red {
    process { Write-Host $_ -ForegroundColor Red }
   }
function Green {
    process { Write-Host $_ -ForegroundColor Green }
   }
function Blue   { 
   process { Write-Host $_ -ForegroundColor Blue}
}

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