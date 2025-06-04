Powershell

#region Script Info
$Script_Name = "Downgrade_Cisco_Anyconnect_4.10_To_4.9.ps1"
$Description = "This script will uninstall 4.10 Cisco any connect and install 4.9"
$Author = "Seth Burns - System Administrator II - Service Center"
$last_tested = "05-27-24"
$version = "1.0.0"
$live = "Retired"
$bmgr = "Retired"
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

## This script will uninstall 4.9 Cisco any connect and install 4.10

Expand-archive %RESOURCE_FILE% c:\Temp -Force

## Expanded archive uninstall path
Start-Process c:\temp\Cisco_AnyConnect_4.10.03104\Cisco_AnyConnect_4.10.03104_uninstall_silent.bat -wait

## Expanded archive install path
Start-Process c:\temp\Cisco_AnyConnect_4.9.06037\Cisco_AnyConnect_4.9.06037_install_silent.bat -wait


EXIT

## Associated resource file "Cisco_AnyConnect_4.9.06037_TO_4.10.03104.zip"