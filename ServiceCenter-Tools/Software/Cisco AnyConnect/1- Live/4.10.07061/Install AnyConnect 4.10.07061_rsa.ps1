powershell

#region Script Info
$Script_Name = "Install AnyConnect 4.10.07061_rsa.ps1"
$Description = "This script will uninstall Cisco any connect and install version 4.10.06079"
$Author = "Seth Burns - System Administrator II - Service Center"
$last_tested = "05-27-25"
$version = "5.0.0 - 4.10.07061_rsa"
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


Expand-archive %RESOURCE_FILE% c:\Temp -Force

## Expanded archive uninstall path
Start-Process "c:\temp\Cisco_AnyConnect_4.10.07061_RSATOKEN\Cisco_AnyConnect_4.10.07061_uninstall.bat" -wait

## Expanded archive install path
Start-Process "c:\temp\Cisco_AnyConnect_4.10.07061_RSATOKEN\Cisco_AnyConnect_4.10.07061_install.bat" -wait

EXIT

## Associated resource file "Cisco_AnyConnect_4.10.07061_RSATOKEN.zip"