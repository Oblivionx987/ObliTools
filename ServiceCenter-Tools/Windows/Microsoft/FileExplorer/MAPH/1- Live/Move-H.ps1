powershell

New-Item -Path "c:\" -Name "Temp" -ItemType "directory" -ErrorAction Ignore
New-Item -Path "c:\Temp" -Name "ServiceCenter" -ItemType "directory" -ErrorAction Ignore
copy-item -path %RESOURCE_FILE% -destination "C:\temp\servicecenter\MapH.ps1"
explorer "c:\temp\servicecenter"



## Last Tested on 02-08-2024
## Author : Seth Burns
## Resource File: MAP-H.ps1