Powershell

#region Script Info
$Script_Name = "Citrix_Workspace_Cache_Clear-1.0.0.ps1"
$Description = "This script will Clear Citrix Workspace Cache"
$Author = "Seth Burns - System Administrator II - Service Center"
$last_tested = "05-27-25"
$version = "1.0.0"
$live = "Test"
$bmgr = "Test"
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

Write-Output "Stopping Running Services" | Cyan
taskkill /im selfserviceplugin* /f
taskkill /im selfservice* /F
Write-Output "Done stopping serives" | Green

## Main Cleanup Call
Write-Output "Starting Cache Clear" | Cyan
Start-Process -FilePath "C:\Program Files (x86)\Citrix\ICA Client\SelfServicePlugin\CleanUp.exe" -ArgumentList "-cleanUser -silent" -Wait
Write-Output "Finished Cache Clear" | Green

#Start Citrix Workspace
Write-Output "Starting Citrix Workspace" | Cyan
Start-Process "C:\Program Files (x86)\Citrix\ICA Client\SelfServicePlugin\SelfService.exe"
Write-Output "Finished Starting Citrix Workspace" | Green

EXIT