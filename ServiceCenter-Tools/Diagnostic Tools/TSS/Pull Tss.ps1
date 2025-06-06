









## This script will run Tss Script
powershell
Expand-Archive -Path \\cmfs01p\SNC_Source\TSS.zip -Destination c:\Temp\TSS -Force


## Expanded archive install path
# Note: Corrected the argument list formatting and added -NoNewWindow to keep it in the same window
cd c:\temp\tss

.\TSS.ps1 -CollectLog MCM_Report -Beta -noUpdate

$vpn_test = Test-NetConnection -ComputerName "sncorp.intranet.com"
$ping_test = $vpn_test | Select-Object PingSucceeded

## Functions
function Red { process { Write-Host $_ -ForegroundColor Red }}
function Green { process { Write-Host $_ -ForegroundColor Green }}

## Ensure the destination directory exists before copying
if (-Not (Test-Path -Path "\\cmfs01p\SNC_Source")) {
    New-Item -Path "\\cmfs01p\SNC_Source" -ItemType Directory
}

Copy-Item -Path C:\MS_DATA\*.zip -Destination \\cmfs01p\SNC_Source -Force
Write-Host "Logs Outputted"


EXIT






## .\TSS.ps1 -CollectLog MCM_Report -Beta -noUpdate