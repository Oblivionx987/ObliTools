## This script will uninstall Citrix Receiver and install Citrix Workspace
powershell
Expand-archive %RESOURCE_FILE% c:\Temp -Force

## Expanded archive install path
Start-Process c:\temp\RSA_SecurID_Software_Token\5.0.2.440\Deploy-Application.exe -wait

EXIT

## Associated resource file "RSA_SecurID_Software_Token.zip"