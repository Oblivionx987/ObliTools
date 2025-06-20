
powershell

#region Script Info
$Script_Name = "MoveSetup.ps1"
$Description = "Moves the new machine setup script over to the local device."
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



New-Item -Path "c:\" -Name "Temp" -ItemType "directory" -ErrorAction Ignore
New-Item -Path "c:\Temp" -Name "ServiceCenter" -ItemType "directory" -ErrorAction Ignore
copy-item -path %RESOURCE_FILE% -destination "C:\temp\servicecenter\NewMachineSetup.ps1"
explorer "c:\temp\servicecenter"



## Last Tested on 02-08-2024
## Author : Seth Burns
## Resource File: NewMachineSetup.ps1