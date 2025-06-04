powershell.exe

#region Script Info
$Script_Name = "PullLogTEMP.ps1"
$Description = "Script for Pulling network connection info for citrix"
$Author = "Seth Burns - System Administrator II - Service Center"
$last_tested = "05-27-25"
$version = "1.0.0"
$live = "WIP"
$bmgr = "WIP"
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

$hostname = $env:COMPUTERNAME
$ipv4Address = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias (Get-NetAdapter | Where-Object {$_.Status -eq 'Up'} | Select-Object -ExpandProperty Name))[0].IPAddress

$networkInfo = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -ne "Loopback Pseudo-Interface 1"} | Select-Object -First 1)
$interfaceIndex = $networkInfo.$interfaceIndex
$dnsSuffix = (Get-DnsClient -InterfaceIndex $interfaceIndex).ConnectionSpecificSuffix

Write-Output "Connection-specific DNS Suffix: $dnsSuffix"
Write-Output "Device Name: $hostname"
Write-Output "IP Address: $ipv4Address"