powershell

#region Script Info
$Script_Name = "Execution_Restricted-1.0.0.ps1"
$Description = "Sets the powershell execution for scripts to Restricted."
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

Set-ExecutionPolicy -ExecutionPolicy Restricted -Scope LocalMachine -Force