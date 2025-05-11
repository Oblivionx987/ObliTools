Get-WindowsCapability -Name RSAT* -Online
Get-WindowsCapability -Name RSAT* -Online | % {Add-WindowsCapability -online -Name $_.Name}