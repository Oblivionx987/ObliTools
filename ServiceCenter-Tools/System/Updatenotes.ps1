Powershell code
## Install the windows update module for powershell
Install-module pswindowsupdate
Y 
A 

## Get and install windows updates - forced
Get-windowsupdate -microsoftupdate -acceptall -install -autoreboot




## change the script execution policy on machine
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope LocalMachine
