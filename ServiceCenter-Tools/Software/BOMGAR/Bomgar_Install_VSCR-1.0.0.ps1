powershell

#region Script Info
$Script_Name = "Bomgar_Install_VSCR-1.0.0.ps1"
$Description = "This script will install Virtual Smart Card Representative Drivers"
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

#region File Server Check
## START Built in file server connection check
## File server path
$filePath = "\\sncorp\internal\Corp_Software\ServiceCenter_SNC_Software"
## Function to check if the file path is reachable
function CheckFilePath {
    param (
        [string]$file
    )
    
    if (Test-Path -Path $file) {
        Write-Output "The file path '$file' is reachable."
        return $true
    } else {
        Write-Output "The file server is not reachable. Trying again in 10 seconds...
        If issue persists, check connectivity" | Red
        return $false
    }
}
## Loop until the file path is reachable
while (-not (CheckFilePath -file $filePath)) {
    Start-Sleep -Seconds 10
}
Write-Output "The file server was successfully reached." | Green
## END Built in file server connection check
#endregion

## Author Info


## Variables
$Source = "\\colofs01\Internal\Corp_Software\ServiceCenter_SNC_Software\"
$DestinationFolder = "C:\temp\"
$File = "bomgar-vscrep-win64.zip"
$MainInstaller = "bomgar-vscrep-win64.msi"
$vpn_test = Test-NetConnection -ComputerName "sncorp.intranet.com"
$ping_test = $vpn_test | Select-Object PingSucceeded -Wait


## Checking That Machine Is Online
if ($ping_test -match "False") { Write-Output "Please Connect To Internet & VPN" | Red}
if ($ping_test -match "False") { EXIT }
if ($ping_test -match "True") { Write-Output "Computer Is Connected To Network" | Green}
if ($ping_test -match "True") {

## File Transfer
Robocopy $Source $DestinationFolder $File /mt:4 /z /e /xo | Green

## Archive Exspansion
Write-Output "Starting Archive Exspansion" | Green
Expand-Archive "C:\temp\$File" -Destination $DestinationFolder -force
Write-Output "Done Expanding Archive" | Green

## Main Installer Start
Write-Output "Starting $MainInstaller Installer" | Green
Start-Process "C:\temp\$MainInstaller"

Exit}