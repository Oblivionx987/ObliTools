$Destination = "C:\temp"
$Source = "\\sncorp\internal\Corp_Software\ServiceCenter_SNC_Software\PlantronicsHubInstaller.zip"

$FOF_CREATEPROGRESSDLG = "&H0&"
$objShell = New-Object -ComObject "Shell.Application"
$objFolder = $objShell.NameSpace($Destination) 
$objFolder.CopyHere($Source, $FOF_CREATEPROGRESSDLG)

Expand-Archive "\\sncorp\internal\Corp_Software\ServiceCenter_SNC_Software\PlantronicsHubInstaller.zip" -Destination "c:\temp"

Start-Process "C:\temp\PlantronicsHubInstaller.exe"

EXIT