
Powershell

#region Script Info
$Script_Name = "Titus FIX.ps1"
$Description = "This script will uninstall Titus and install current version with config file"
$Author = "Seth Burns - System Administrator II - Service Center"
$last_tested = "05-27-25"
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



Expand-archive %RESOURCE_FILE% c:\Temp -Force


## Expanded archive uninstall path

Start-Process C:\Temp\TITUS_FIX\Step_1_TITUS_Classification_v18.8.1913.246\TITUS_Classification_v18.8.1913.246_uninstall_silent.bat -wait

## Expanded archive install path

Start-Process C:\Temp\TITUS_FIX\Step_1_TITUS_Classification_v18.8.1913.246\TITUS_Classification_v18.8.1913.246_install_silent.bat -wait

## Expanded archive configuration file path

Start-Process C:\Temp\TITUS_FIX\Step_2_TITUS_Classification_v18.8.1913.246_config_v2.0.7.1EL2\TITUS_Classification_v18.8.1913.246_config_v2.0.7.1EL2_install_silent.bat -wait

EXIT

##Associated resource file "TITUS_FIX.zip"