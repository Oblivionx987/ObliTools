##powershell

$WUALog = "C:\Windows\CCM\Logs\WUAHandler.log"
$CMTrace = "C:\Windows\CCM\CMTrace.exe"

Start-Process $CMTrace $WUALog