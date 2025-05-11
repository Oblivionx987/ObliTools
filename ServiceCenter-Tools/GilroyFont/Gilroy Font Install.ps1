## This script will Install Gilroy Fonts

Powershell

function Red { process { Write-Host $_ -ForegroundColor Red }}
function Green { process { Write-Host $_ -ForegroundColor Green }}
$vpn_test = Test-NetConnection -ComputerName "sncorp.intranet.com"
$ping_test = $vpn_test | Select-Object PingSucceeded -Wait
if ($ping_test -match "False") { Write-Output "Please Connect To Internet & VPN" | Red}
if ($ping_test -match "False") { EXIT }
if ($ping_test -match "True") { Write-Output "Computer Is Connected To Network" | Green}
if ($ping_test -match "True") {

## Starting File Transfer
$Gilroy = "\\sncorp\internal\Corp_Software\ServiceCenter_SNC_Software\Gilroy_Family.zip"
$Destination = "C:\temp"
Copy-Item $Gilroy -Destination $Destination -Force
## Finished File Transfer
## Expanding Archive File
Expand-Archive "C:\temp\Gilroy_Family.zip" -Destination "C:\temp" -force
## Archive Expansion Completed
}

$SourceDir   = "C:\temp\Gilroy Family"
$Source      = "C:\temp\Gilroy Family\*"
$Destination = (New-Object -ComObject Shell.Application).Namespace(0x14)
$TempFolder  = "C:\Windows\Temp\Fonts"

# Create the source directory if it doesn't already exist
New-Item -ItemType Directory -Force -Path $SourceDir

New-Item $TempFolder -Type Directory -Force | Out-Null

Get-ChildItem -Path $Source -Include '*.ttf','*.ttc','*.otf' -Recurse | ForEach {
    If (-not(Test-Path "C:\Windows\Fonts\$($_.Name)")) {

        $Font = "$TempFolder\$($_.Name)"
        
        # Copy font to local temporary folder
        Copy-Item $($_.FullName) -Destination $TempFolder
        
        # Install font
        $Destination.CopyHere($Font,0x10) -Force

        # Delete temporary copy of font
        Remove-Item $Font -Force
    }
}
Exit
Exit

## Associated resource file "Gilroy_Family.zip"
## Author = Seth Burns - 114825-adm
## Last Tested on -