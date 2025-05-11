$ipv4Address = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias (Get-NetAdapter | Where-Object {$_.Status -eq 'Up'} | Select-Object -ExpandProperty Name))[0].IPAddress
Write-Output "Local IPv4 Address: $ipv4Address"
Read-Host -Prompt "Press Enter to exit"