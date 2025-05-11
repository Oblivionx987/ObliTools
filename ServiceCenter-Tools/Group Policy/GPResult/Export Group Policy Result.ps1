## Powershell

$Computer = $env:computername
$UserInput = Read-Host "Please Input User ID" 
gpresult /s $Computer /u [snc\]"$UserInput" /f /h C:\temp\"$computer".html


$Computer = $env:computername
gpresult /h C:\temp\"$Computer"_Policy_Export.html











