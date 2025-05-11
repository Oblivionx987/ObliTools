## Set policy to allow the running of powershell scripts
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope LocalMachine

Install-Module pswindowsupdate -Force
Import-Module pswindowsupdate -Force


$WUALog = "C:\Windows\CCM\Logs\WUAHandler.log"
$CMTrace = "C:\Windows\CCM\CMTrace.exe"




## this will auto accept everything
get-windowsupdate -microsoftupdate -acceptall -install -autoreboot


## this will manually require you to accept everything
get-windowsupdate -microsoftupdate -install -autoreboot