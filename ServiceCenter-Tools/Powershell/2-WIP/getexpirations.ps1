$author = "Seth Burns - System Administrator II - Service Center"
$description = "This script will check active directory for expiring accounts"
$live = "Restricted"
$Version = "1.0.2"
$bmgr = "Restricted"



Get-ADUser -filter {Enabled -eq $True -and PasswordNeverExpires -eq $False} –Properties "DisplayName", "msDS-UserPasswordExpiryTimeComputed" |
Select-Object -Property "Displayname",@{Name="ExpiryDate";Expression={[datetime]::FromFileTime($_."msDS-UserPasswordExpiryTimeComputed")}} | export-csv -path c:\temp\passwordexpiration.csv