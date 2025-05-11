Powershell

$FileName = "C:\Windows\System32\grouppolicy\user\Registry.pol"
$FileName2 = "C:\Windows\System32\grouppolicy\machine\Registry.pol"

if (Test-Path $FileName){
    Remove-Item $FileName -Force
    Write-host "$Filename has been deleted"
}
Else {
    Write-host "$FileName doesnt exist"
    }

if (Test-Path $FileName2){
    Remove-Item $FileName2 -Force
    Write-host "$Filename2 has been deleted"
}
Else {
    Write-host "$FileName2 doesnt exist"
    }

Get-Service CcmExec
Net Stop CcmExec
Get-Service CcmExec
Net Start CcmExec

gpupdate /force




## No Associated files
## Author Seth Burns
## Last Test Date - 7-3-23