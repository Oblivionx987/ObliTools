Powershell
New-Item -Path "c:\" -Name "Temp" -ItemType "directory" -ErrorAction Ignore
New-Item -Path "c:\Temp" -Name "ServiceCenter" -ItemType "directory" -ErrorAction Ignore
copy-item -path %RESOURCE_FILE% -destination "C:\temp\servicecenter\teamscache.ps1"
explorer "c:\temp\servicecenter"
exit