$author = "Seth Burns - System Administrator II - Service Center"
$description = "This script will import the pswindows update module. It will then attempt to force feed the device all misssing windows updates."
$live = "Restriced"
$Version = "1.0.0"
$bmgr = "Restricted"




Install-module pswindowsupdate
Y
Import-module pswindowsupdate


Get-windowsupdate -microsoftupdate -acceptall -install -autoreboot