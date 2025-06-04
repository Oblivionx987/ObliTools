powershell.exe

#region Script Info
$Script_Name = "PullLogs.ps1"
$Description = "This script is designed to launch the dart tool to pull logs. It will then attempt to transfer the logs to our common drive
This script currently does not work as it runs as an admin - Adjust to run as user "
$Author = "Seth Burns - System Administrator II - Service Center"
$last_tested = "05-27-25"
$version = "5.0.0"
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

$Dartlocation = "C:\Program Files (x86)\Cisco\Cisco AnyConnect Secure Mobility Client\DART\DartOffline.exe"


$Destination = "\\sncorp\internal\Corp_Software\Cisco_LOGS"
$Temp = "C:\Temp"
$DartLog = Get-ChildItem $Temp | Where-Object {$_.Name -match "$ComputerAsset-VPNLOGS.zip"} 
$Source = Get-ChildItem $DesktopPathSource | Where-Object {$_.Name -match "$ComputerAsset"} 


## Grabs Current Machine Asset #
$ComputerAsset = hostname
Write-Output "Computer Name $ComputerAsset"


## Grabs Current User ID #
$CurrentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
Write-Output "User Name $CurrentUser"


Start-Process $Dartlocation -Wait


## Grabs Current Desktop path for Current Signed in User
$DesktopPathSource = "$($env:userprofile)\Desktop"

Get-ChildItem $DesktopPathSource | Where-Object {$_.Name -match "DARTBundle"} | Rename-Item -NewName "$ComputerAsset-VPNLOGS.zip" | Move-Item -Destination $Temp

Get-ChildItem $DesktopPathSource | Where-Object {$_.Name -match "$ComputerAsset-VPNLOGS.zip"} | Copy-Item -Destination $Temp

Get-ChildItem $Temp | Where-Object {$_.Name -match "$ComputerAsset-VPNLOGS.zip"} | Copy-Item -Destination $Destination -Force

Exit

##Move-Item [-Destination $Destination] -Path $DesktopPathSource | Where-Object {$_.Name -match "$ComputerAsset"}
