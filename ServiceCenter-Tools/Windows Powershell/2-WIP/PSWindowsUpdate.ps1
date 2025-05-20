Install-module pswindowsupdate
Y
Import-module pswindowsupdate


Get-windowsupdate -microsoftupdate -acceptall -install -autoreboot