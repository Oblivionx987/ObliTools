## This script will uninstall Cisco any connect and install version 4.10.06079
powershell
Expand-archive %RESOURCE_FILE% c:\Temp -Force

## Expanded archive uninstall path
Start-Process "c:\temp\Cisco_AnyConnect_4.10.06079_ALWAYSON\Cisco_AnyConnect_4.10.06079_uninstall_silent.bat" -wait

## Expanded archive install path
Start-Process "c:\temp\Cisco_AnyConnect_4.10.06079_ALWAYSON\Cisco_AnyConnect_4.10.06079_install_silent.bat" -wait

EXIT

## Associated resource file "Cisco_AnyConnect_4.10.06079_ALWAYSON.zip"