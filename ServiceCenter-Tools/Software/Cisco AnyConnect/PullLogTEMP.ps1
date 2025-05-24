$hostname = $env:COMPUTERNAME
$ipv4Address = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias (Get-NetAdapter | Where-Object {$_.Status -eq 'Up'} | Select-Object -ExpandProperty Name))[0].IPAddress

$networkInfo = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -ne "Loopback Pseudo-Interface 1"} | Select-Object -First 1)
$interfaceIndex = $networkInfo.$interfaceIndex
$dnsSuffix = (Get-DnsClient -InterfaceIndex $interfaceIndex).ConnectionSpecificSuffix

Write-Output "Connection-specific DNS Suffix: $dnsSuffix"
Write-Output "Device Name: $hostname"
Write-Output "IP Address: $ipv4Address"