$Computer = $env:computername
$UserInput = Read-Host "Please Input User ID" 
gpresult /h C:\Temp\"$Computer"_Policy_Export.html /User snc\"$UserInput"