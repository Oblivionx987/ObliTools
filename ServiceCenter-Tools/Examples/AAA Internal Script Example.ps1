
Powershell
## Starting File Transfer
Copy-Item "C:\Users\114825\Desktop\Acrobat_2017_Pro.zip" -Destination "C:\temp" -Force
## Finished File Transfer
##Expanding Archive File
Expand-Archive "C:\Users\114825\Desktop\Acrobat_2017_Pro.zip" -Destination "C:\temp" -force
## Starting Expanded Archive uninstallation if Needed
Start-Process "C:\Temp\Acrobat_2017_Pro\acrobat_2017_uninstall.bat" -wait
## Starting Expanded Archile Insallation
Start-Process "C:\Temp\Acrobat_2017_Pro\acrobat_2017_install_STD.bat" -wait




## Author = Seth Burns - 114825-adm