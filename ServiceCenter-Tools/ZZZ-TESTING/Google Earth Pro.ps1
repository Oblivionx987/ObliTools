## This script will Install Google Earth Pro

powershell
## Starting File Transfer
Copy-Item "\\sncorp\internal\Corp_Software\ServiceCenter_SNC_Software\Google_Earth_Pro.zip" -Destination "C:\temp" -Force
## Finished File Transfer

## Expanding Archive File
Expand-Archive "C:\temp\Google_Earth_Pro.zip" -Destination "C:\temp" -force
## Archive Expansion Completed

## Starting Installation
Start-Process "C:\temp\Google_Earth_Pro\GoogleEarthProSetup.exe" -wait
## Finished Installation

EXIT

## Associated resource file "Cisco_AnyConnect_4.9.06037.zip"
## Author = Seth Burns - 114825-adm
## Last Tested on - 02-09-2023 - NW