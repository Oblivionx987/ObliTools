$Version = "4.9>4.10"
$live = "Retired"
$bmgr = "Retired"
$description = "This script will uninstall 4.9 Cisco any connect and install 4.10"
$author = "Seth Burns - System Administrator II - Service Center"




## This script will uninstall 4.9 Cisco any connect and install 4.10
powershell
Expand-archive %RESOURCE_FILE% c:\Temp -Force

## Expanded archive uninstall path
Start-Process "c:\temp\Cisco_AnyConnect_4.9.06037\Cisco_AnyConnect_4.9.06037_uninstall_silent.bat" -wait

## Expanded archive install path
Start-Process "c:\temp\Cisco_AnyConnect_4.9.06037\Cisco_AnyConnect_4.9.06037_install_silent.bat" -wait

EXIT

## Associated resource file "Cisco_AnyConnect_4.9.06037.zip"