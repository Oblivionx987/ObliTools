#region Script Info
$Script_Name = ""
$Description = ""
$Author = "Seth Burns - System Administrator II - Service Center"
$last_tested = "05-27-25"
$version = "5.0.0"
$live = "Live"
$bmgr = "Live"
#endregion

##      Built in Text Function
##      Built in Server Check
##      Built in Text Color Functions
$Destination = "C:\temp" ## DO NOT CHANGE
$Source = "\\sncorp\internal\Corp_Software\ServiceCenter_SNC_Software\Scripts\Adobe_Acrobat_DC_AIO.ps1" ## Replace with name of source
$SourceFileName = "Adobe_Acrobat_DC_AIO.ps1" ## Replace with name of zip
$ZipFilePath = Join-Path -Path $Destination -ChildPath $zipFileName ## DO NOT CHANGE
$ExpandedFileName = "Acrobat_DC_Std" ## Replace with name of expanded folder
$ExpandedFilePath = Join-Path -Path $Destination -ChildPath $ExpandedFileName ## DO NOT CHANGE
#endregion



#region Text Colors 
function Red     { process { Write-Host $_ -ForegroundColor Red }}
function Green   { process { Write-Host $_ -ForegroundColor Green }}
function Yellow  { process { Write-Host $_ -ForegroundColor Yellow }}
function Blue    { process { Write-Host $_ -ForegroundColor Blue }}
function Cyan    { process { Write-Host $_ -ForegroundColor Cyan }}
function Magenta { process { Write-Host $_ -ForegroundColor Magenta }}
function White   { process { Write-Host $_ -ForegroundColor White }}
function Gray    { process { Write-Host $_ -ForegroundColor Gray }}
#endregion

#region Main Descriptor
## START Main Descriptor
Write-Output "--------------------"
Write-Output "$Author" | Yellow
Write-Output "$Script_Name"
Write-Output "$version , $last_tested" | Yellow
Write-Output "$live , $bmgr"
Write-Output "$Description" | Yellow
Write-Output "--------------------"
## END Main Descriptor
#endregion

#region Online Check 
## START Built in Machine Online Check
$vpn_test = Test-NetConnection -ComputerName "sncorp.intranet.com" ## DO NOT CHANGE
$ping_test = $vpn_test | Select-Object PingSucceeded -Wait ## DO NOT CHANGE
if ($ping_test -match "False") { Write-Output "Please Connect To Internet & VPN" | Red}
if ($ping_test -match "False") { EXIT }
if ($ping_test -match "True") { Write-Output "Computer Is Connected To Network" | Green}
if ($ping_test -match "True") {
## END Built in Machine Online Check
#endregion

#region File Server Check
## START Built in file server connection check
## File server path
$filePath = "\\sncorp\internal\Corp_Software\ServiceCenter_SNC_Software"
## Function to check if the file path is reachable
function CheckFilePath {
    param (
        [string]$file
    )
    
    if (Test-Path -Path $file) {
        Write-Output "The file path '$file' is reachable."
        return $true
    } else {
        Write-Output "The file server is not reachable. Trying again in 10 seconds...
        If issue persists, check connectivity" | Red
        return $false
    }
}
## Loop until the file path is reachable
while (-not (Check-FilePath -file $filePath)) {
    Start-Sleep -Seconds 10
}
Write-Output "The file server was successfully reached." | Green
## END Built in file server connection check
#endregion

#region Zip File Transfer
## START Zip File Transfer
Write-Output "Starting File Transfer" | Yellow
$FOF_CREATEPROGRESSDLG = "&H0&"
$objShell = New-Object -ComObject "Shell.Application"
$objFolder = $objShell.NameSpace($Destination) 
$objFolder.CopyHere($Source, $FOF_CREATEPROGRESSDLG)

if (Test-Path -Path $ZipFilePath -PathType Leaf) {
    Write-Output "File Transfer was successful." | Green
} else {
    Write-Output "File Transfer failed." | Red
EXIT}
## END Zip File Transfer
#endregion



}