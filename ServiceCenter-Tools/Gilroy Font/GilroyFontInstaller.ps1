## Gilroy Font Installer
## Purpose: Installs the Gilroy Font Family
## Author: Seth Burns & Frank Coates
## Date Created: 2.17.2023
## Date Updated: 2.17.2023


## Variables
	## Font store
	$Source = "\\sncorp\internal\Corp_Software\ServiceCenter_SNC_Software\Gilroy_Family.zip"
	## Temp Remote destination
	$Destination = "C:\Temp"
	## Temp Remote Font Store
	$RemFontStore = ("$Destination\Gilroy Family")
	## Windows Font Store
	$FontFolder = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts\"
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
	
# Copy zip to destination and expand
Copy-Item $Source -Destination $Destination -Force
Write-Output "Zip copied."

Expand-Archive "$Destination\Gilroy_Family.zip" -Destination $Destination -Force
Write-Output "Zip expanded."
}
# Assign variables to fonts in Remote Font Store
$FontItem = Get-Item -Path $RemFontStore
$FontList = Get-ChildItem -Path "$FontItem\*" -Include ('*.fon','*.ttf','*.ttc','*.otf')

# Copy each font to Windows Font Store
$Destination = (New-Object -ComObject Shell.Application).Namespace(0x14)

foreach ($Font in $FontList) {
if (Test-Path $FontFolder\$($Font.Name)) {
    Write-Output "$Font already installed."
    }
if (-not(Test-Path $FontFolder\$($Font.Name))) {
    Write-Host "Installing font -" $Font.BaseName
    Copy-Item $Font -Destination $FontFolder -Force
    $Destination.CopyHere("$Font",0x10)
}
}

# Clean up
Write-Output "Cleaning up.."
Remove-Item $RemDes\Gilroy* -Recurse -Force


# Exit script
Read-Host "Press Enter to exit"

EXIT