## This script will map the H drive as a persistent Location

## This script will need to be ran as the local user - if ran as adm it will map the location to the adm account

## Powershell

## Variables
$UserInput = Read-Host "Please Input User ID" 

## Map H Drive for current User
New-PSDrive -Name "H" -PSProvider "FileSystem" -Root \\sncorp\homes\$UserInput -Persist

Read-Host -Prompt "Press Enter to exit"
EXIT