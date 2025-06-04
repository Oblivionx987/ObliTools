## This Script will install rsa secure id

Powershell

#region Script Info
$Script_Name = ""
$Description = "This Script will install rsa secure id"
$Author = "Seth Burns - System Administrator II - Service Center"
$last_tested = "05-27-25"
$version = "2.0.0 - 5.0.2.440"
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
$Source = "\\sncorp\internal\Corp_Software\ServiceCenter_SNC_Software\RSA_SecurID_Software_Token.zip"
$vpn_test = Test-NetConnection -ComputerName "sncorp.intranet.com"
$ping_test = $vpn_test | Select-Object PingSucceeded -Wait

## Functions
function Red { process { Write-Host $_ -ForegroundColor Red }}
function Green { process { Write-Host $_ -ForegroundColor Green }}

## Checking That Machine Is Online
if ($ping_test -match "False") { Write-Output "Please Connect To Internet & VPN" | Red}
if ($ping_test -match "False") { EXIT }
if ($ping_test -match "True") { Write-Output "Computer Is Connected To Network" | Green}
if ($ping_test -match "True") {
	
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

## Starting File Transfer
$FOF_CREATEPROGRESSDLG = "&H0&"
$objShell = New-Object -ComObject "Shell.Application"
$objFolder = $objShell.NameSpace($Destination) 
$objFolder.CopyHere($Source, $FOF_CREATEPROGRESSDLG)
## Finished File Transfer

## Expanding Archive File
Expand-Archive "C:\temp\RSA_SecurID_Software_Token.zip" -Destination "C:\temp" -Force
## Archive Expansion Completed

## Starting Installation
Start-Process "c:\temp\RSA_SecurID_Software_Token\5.0.2.440\Deploy-Application.exe" -wait
## Installation Started

EXIT}

## Associated resource file "RSA_SecurID_Software_Token.zip"
## Author = Seth Burns & Frank Coates
## Script Last Test Date - 2/9/2023 - Working