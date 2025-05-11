## This script is designed to launch the dart tool to pull logs. It will then attempt to transfer the logs to our common drive

## This script currently does not work as it runs as an admin - Adjust to run as user 


$Dartlocation = "C:\Program Files (x86)\Cisco\Cisco AnyConnect Secure Mobility Client\DART\DartOffline.exe"


$Destination = "\\sncorp\internal\Corp_Software\Cisco_LOGS"
$Temp = "C:\Temp"
$DartLog = Get-ChildItem $Temp | Where-Object {$_.Name -match "$ComputerAsset-VPNLOGS.zip"} 
$Source = Get-ChildItem $DesktopPathSource | Where-Object {$_.Name -match "$ComputerAsset"} 


## Grabs Current Machine Asset #
$ComputerAsset = hostname
Write-Output "Computer Name $ComputerAsset"


## Grabs Current User ID #
$CurrentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
Write-Output "User Name $CurrentUser"


Start-Process $Dartlocation -Wait


## Grabs Current Desktop path for Current Signed in User
$DesktopPathSource = "$($env:userprofile)\Desktop"

Get-ChildItem $DesktopPathSource | Where-Object {$_.Name -match "DARTBundle"} | Rename-Item -NewName "$ComputerAsset-VPNLOGS.zip" | Move-Item -Destination $Temp

Get-ChildItem $DesktopPathSource | Where-Object {$_.Name -match "$ComputerAsset-VPNLOGS.zip"} | Copy-Item -Destination $Temp

Get-ChildItem $Temp | Where-Object {$_.Name -match "$ComputerAsset-VPNLOGS.zip"} | Copy-Item -Destination $Destination -Force

Exit

##Move-Item [-Destination $Destination] -Path $DesktopPathSource | Where-Object {$_.Name -match "$ComputerAsset"}
