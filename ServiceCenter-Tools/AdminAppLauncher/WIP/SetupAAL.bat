


powershell.exe -WindowStyle Hidden winget install --id Microsoft.PowerShell --source winget
powershell.exe -WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -command "Set-ExecutionPolicy -ExecutionPolicy unrestricted -Scope LocalMachine -Force"

Echo Setup Completed