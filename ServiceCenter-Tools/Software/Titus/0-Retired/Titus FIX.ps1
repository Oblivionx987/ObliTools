## This script will uninstall Titus and install current version with config file

Powershell
Expand-archive %RESOURCE_FILE% c:\Temp -Force


## Expanded archive uninstall path

Start-Process C:\Temp\TITUS_FIX\Step_1_TITUS_Classification_v18.8.1913.246\TITUS_Classification_v18.8.1913.246_uninstall_silent.bat -wait

## Expanded archive install path

Start-Process C:\Temp\TITUS_FIX\Step_1_TITUS_Classification_v18.8.1913.246\TITUS_Classification_v18.8.1913.246_install_silent.bat -wait

## Expanded archive configuration file path

Start-Process C:\Temp\TITUS_FIX\Step_2_TITUS_Classification_v18.8.1913.246_config_v2.0.7.1EL2\TITUS_Classification_v18.8.1913.246_config_v2.0.7.1EL2_install_silent.bat -wait

EXIT

##Associated resource file "TITUS_FIX.zip"