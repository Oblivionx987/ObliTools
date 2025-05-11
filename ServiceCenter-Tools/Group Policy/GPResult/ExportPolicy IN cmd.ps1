$Computer = $env:computername
$UserInput = Read-Host "Please Input User ID" 
gpresult /r /user $UserInput