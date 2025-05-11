cd "C:\Program Files (x86)\Cisco\Cisco AnyConnect Secure Mobility Client"
Copy-Item -Path .\Log\AnyConnect.log | Out-File -FilePath "\\sncorp\internal\Corp_Software\Cisco_LOGS"