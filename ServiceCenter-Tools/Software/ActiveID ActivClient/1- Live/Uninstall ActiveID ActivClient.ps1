
$version = "1.0.0"
$live = "Live"
$bmgr = "Live"
$description = "This script will unstall activeid active client."


powershell
$MyApp = Get-WmiObject -Class Win32_Product | Where-Object{$_.Name -eq "ActivID ActivClient x64"}
$MyApp.Uninstall()
$MyApp1 = Get-WmiObject -Class Win32_Product | Where-Object{$_.Name -eq "HID OMNIKEY 3x2x PC/SC Driver"}
$MyApp1.Uninstall()

Exit