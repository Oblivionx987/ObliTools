Powershell

#region Script Info
$Script_Name = "SW_Center_Repair.ps1"
$Description = "Updates policys and then installs software center."
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

## Variables
$Destination = "C:\temp"
$Source = "\\sncorp\Internal\Corp_Software\ServiceCenter_SNC_Software\SCCM_Client_sncorp_ps.zip"
$vpn_test = Test-NetConnection -ComputerName "sncorp.intranet.com"
$ping_test = $vpn_test | Select-Object PingSucceeded -Wait
$FileName = "C:\Windows\System32\grouppolicy\user\Registry.pol"
$FileName2 = "C:\Windows\System32\grouppolicy\machine\Registry.pol"

## Functions
function Red { process { Write-Host $_ -ForegroundColor Red }}
function Green { process { Write-Host $_ -ForegroundColor Green }}
function Yellow { process { Write-Host $_ -ForegroundColor Yellow }}
function DarkRed { process { Write-Host $_ -ForegroundColor DarkRed }}

if (Test-Path $FileName){
    Remove-Item $FileName -Force
    Write-host "$Filename has been deleted"
}
Else {
    Write-host "$FileName doesnt exist"
    }

if (Test-Path $FileName2){
    Remove-Item $FileName2 -Force
    Write-host "$Filename2 has been deleted"
}
Else {
    Write-host "$FileName2 doesnt exist"
    }


Write-Output ("Stopping Ccm Exec Services - To clear any pending policy changes") | Green
Get-Service CcmExec
Net Stop CcmExec
Write-Output ("Starting Ccm Exec Services - To pull polciy changes") | Green
Get-Service CcmExec
Net Start CcmExec


Write-Output ("Starting GpUpdate /force") | Green
gpupdate /force


## Checking That Machine Is Online
Write-Output "Checking that Machine is connected to SNC"
if ($ping_test -match "False") { Write-Output "Please Connect To Internet & VPN If Needed" | Red}
if ($ping_test -match "False") { EXIT }
if ($ping_test -match "True") { Write-Output "Computer Is Connected To Network" | Green}
if ($ping_test -match "True") {
	
## Starting File Transfer
Write-Output "Starting Archive File Transfer"
$FOF_CREATEPROGRESSDLG = "&H0&"
$objShell = New-Object -ComObject "Shell.Application"
$objFolder = $objShell.NameSpace($Destination) 
$objFolder.CopyHere($Source, $FOF_CREATEPROGRESSDLG)
Write-Output "Finished Archive File Transfer" | Green
## Finished File Transfer

## Expanding Archive File
Write-Output "Expanding Archive File"
Expand-Archive "C:\temp\SCCM_Client_sncorp_ps.zip" -Destination "C:\temp\SCCM_Client_sncorp_ps\" -force
Write-Output "Finished Expanding Archive File" | Green
## Archive Expansion Completed

## Starting Uninstallation
Write-Output "Starting Software Center Removal"
Start-Process "C:\temp\SCCM_Client_sncorp_ps\SCCM_Client_sncorp_ps\SCCM_Client_sncorp_uninstall_silent.bat" -Wait
Write-Output "Finished Software Center Removal" | Green
## Finished Uninstallation

## Starting installation
Write-Output "Starting Software Center Install"
Start-Process "C:\temp\SCCM_Client_sncorp_ps\SCCM_Client_sncorp_ps\SCCM_Client_sncorp_install_silent.bat" -Wait
Write-Output "Finished Software Center Install" | Green
## Finished installation

Write-Output ("Script Closure Notes:
Now that software center is reinstalled it may take up to 30 mins to start seeing software populate in. No additional commands needed - Software center has been instrcuted to pull latest updates.") | Green

read-host "Please read the Script Closure Notes, then press ENTER to Continue"

Exit}