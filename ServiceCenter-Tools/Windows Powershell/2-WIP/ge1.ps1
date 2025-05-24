

$author = "Seth Burns - System Administrator II - Service Center"
$description = "This script will check active directory for expiring accounts"
$live = "Restriced"
$Version = "1.0.0"
$bmgr = "Restricted"



Search-ADAccount -AccountExpired -UsersOnly | Select-Object Name, SamAccountName, DistinguishedName, AccountExpirationDate | export-csv -path c:\temp\passwordexpiration.csv