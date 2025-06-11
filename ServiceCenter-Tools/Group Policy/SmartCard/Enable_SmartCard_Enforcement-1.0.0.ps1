$Registrypath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\'
$Name = 'scforceoption'
$Value = '1'
New-ItemProperty -path $Registrypath -Name $Name -Value $Value -PropertyType DWORD -Force
Exit