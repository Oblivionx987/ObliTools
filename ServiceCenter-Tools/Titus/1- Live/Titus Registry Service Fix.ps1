## Script will inject appropriate server configurations into Windows registry and try to restart the service to resolve the Titus issues.




powershell
Expand-archive %RESOURCE_FILE% c:\temp -Force
regedit /s "c:\temp\titus_server_config.reg"
regedit /s "c:\temp\titus_plugin_config.reg"

net stop Titus.Enterprise.Client.Service
net stop Titus.Enterprise.HealthMonitor.Service

taskkill /IM Titus* /F

net start Titus.Enterprise.Client.Service
net start Titus.Enterprise.HealthMonitor.Service

exit



## Resource File %RESOURCE_FILE% = titus_config.zip



