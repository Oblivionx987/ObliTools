## This script will uninstall Citrix Receiver and install Citrix Workspace
powershell
Expand-archive %RESOURCE_FILE% c:\Temp -Force

## Expanded archive uninstall path
Start-Process c:\temp\Citrix_Workspace_Install\ReceiverCleanupUtility.exe -wait

## Expanded archive install path
Start-Process c:\temp\Citrix_Workspace_Install\CitrixWorkspaceApp.exe -wait

EXIT

## Associated resource file "Citrix_Workspace_Install.zip"