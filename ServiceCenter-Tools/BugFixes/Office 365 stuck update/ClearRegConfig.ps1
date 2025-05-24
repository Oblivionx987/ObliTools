Powershell



#region Script Info
## NAME
$Script_Name = "Office 365 Stuck Update Fix" | Yellow
##D ESCRIPTION
$Description = "Description: This script will clear registry related to a stuck Office 365 update."
## AUTHOR
$Author = "Author: Seth Burns - System Administrator II - Service Center"
## CREATED
##    D.04-18-25
##
## VERSION
$this_version = "Version: 1.0.0"
#endregion

#region Built in Text Color Functions
function Red        { process { Write-Host $_ -ForegroundColor Red }}
function Green      { process { Write-Host $_ -ForegroundColor Green }}
function Yellow     { process { Write-Host $_ -ForegroundColor Yellow }}
function DarkRed    { process { Write-Host $_ -ForegroundColor DarkRed }}
#endregion

#region Main Descriptor
## START Main Descriptor
Write-Output "--------------------"
Write-Output "$Author" | Yellow
Write-Output "$Script_Name"
Write-Output ("$this_version") | Yellow
Write-Output "$Description" | Yellow
Write-Output "--------------------"
## END Main Descriptor
#endregion


#Region Main Function
Write-Output "Clearing Registry related to updates" | Yellow
Remove-Item "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration" -Recurse
Write-Output "Registry has been cleared. Reboot for changes to take affect." | Green
#endregion 

Exit