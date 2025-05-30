$Version = "4.10.03104"
$live = "Retired"
$bmgr = "Retired"
$description = "This script will uninstall 4.9 Cisco any connect and install 4.10"
$author = "Seth Burns - System Administrator II - Service Center"


## This script will uninstall 4.9 Cisco any connect and install 4.10
powershell
Expand-archive %RESOURCE_FILE% c:\Temp -Force

## Expanded archive uninstall path
Start-Process "c:\temp\Cisco_AnyConnect_4.10.03104\Cisco_AnyConnect_4.10.03104_uninstall_silent.bat" -wait

## Expanded archive install path
Start-Process "c:\temp\Cisco_AnyConnect_4.10.03104\Cisco_AnyConnect_4.10.03104_install_silent.bat" -wait

EXIT

## Associated resource file "Cisco_AnyConnect_4.10.03104.zip"