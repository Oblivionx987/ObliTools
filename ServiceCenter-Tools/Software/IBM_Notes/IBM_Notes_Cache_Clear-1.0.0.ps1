Powershell

#region Script Info
$Script_Name = "IBM_Notes_Cache_Clear-1.0.0.ps1"
$Description = "This script will clear cache files for ibm notes"
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
$Source = "\\sncorp\internal\Corp_Software\ServiceCenter_SNC_Software\Notes_Cache_Fix.zip"
$vpn_test = Test-NetConnection -ComputerName "sncorp.intranet.com"
$ping_test = $vpn_test | Select-Object PingSucceeded -Wait
$FileName = "C:\Program Files (x86)\IBM\Notes\Data\notes.lck"
$FileName1 = "C:\Program Files (x86)\IBM\Notes\Data\Cache.ndk"
$FileName2 = "C:\Program Files (x86)\IBM\Notes\Data\Desktop8.ndk"
$FileName3 = "C:\Program Files (x86)\IBM\Notes\Data\Workspace"
$FileName4 = "C:\Program Files (x86)\IBM\Notes\notes.ini"


## Checking That Machine Is Online
if ($ping_test -match "False") { Write-Output "Please Connect To Internet & VPN" | Red}
if ($ping_test -match "False") { EXIT }
if ($ping_test -match "True") { Write-Output "Computer Is Connected To Network" | Green}
if ($ping_test -match "True") {
	
## Starting File Transfer
$FOF_CREATEPROGRESSDLG = "&H0&"
$objShell = New-Object -ComObject "Shell.Application"
$objFolder = $objShell.NameSpace($Destination) 
$objFolder.CopyHere($Source, $FOF_CREATEPROGRESSDLG)
## Finished File Transfer

## Expanding Archive File
Expand-Archive "C:\temp\Notes_Cache_Fix.zip" -Destination "C:\temp" -force
## Archive Expansion Completed


## Get-Process -name "nlnotes"
## Get-Process -name "notes2"

## Stopping Notes Processes
Stop-Process -Name "nlnotes" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "notes2" -Force -ErrorAction SilentlyContinue

## Remove cache related data
if (Test-Path $FileName){
    Remove-Item $FileName -Force
    Write-host "$Filename has been deleted"
}
Else {
    Write-host "$FileName doesnt exist"
    }

if (Test-Path $FileName1){
    Stop-Process -Name "nlnotes" -Force -ErrorAction SilentlyContinue
    Remove-Item $FileName1 -Force
    Write-host "$Filename1 has been deleted"
}
Else {
    Write-host "$FileName1 doesnt exist"
    }

if (Test-Path $FileName2){
    Remove-Item $FileName2 -Force
    Write-host "$Filename2 has been deleted"
}
Else {
    Write-host "$FileName2 doesnt exist"
    }

if (Test-Path $FileName3){
    Remove-Item $FileName3 -Force -Recurse
    Write-host "$Filename3 has been deleted"
}
Else {
    Write-host "$FileName3 doesnt exist"
    }

## Remove profile related data
if (Test-Path $FileName4){
    Remove-Item $FileName4 -Force
    Write-host "$Filename4 has been deleted"
}
Else {
    Write-host "$FileName4 doesnt exist"
    }

## Copy over new profile
Copy-Item -Path "C:\Temp\Notes_Cache_Fix\notes.ini" -Destination "C:\Program Files (x86)\IBM\Notes\" -Force

## Start IBM Notes
Start-Process "C:\Program Files (x86)\IBM\Notes\notes.exe"
Exit }

## Associated Files
    ## Notes_Cache_Fix
    ## Notes_Cache_Fix.zip
    ## notes.ini 