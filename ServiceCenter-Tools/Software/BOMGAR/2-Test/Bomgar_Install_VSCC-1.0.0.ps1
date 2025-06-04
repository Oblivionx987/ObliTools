powershell

#region Script Info
$Script_Name = "Bomgar_Install_VSCC-1.0.0.ps1"
$Description = "This script will install Virtual Smart Card Customer Drivers"
$Author = "Seth Burns - System Administrator II - Service Center"
$last_tested = "05-27-25"
$version = "1.0.0"
$live = "Test"
$bmgr = "Test"
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

## Variables
$Source = "\\colofs01\Internal\Corp_Software\ServiceCenter_SNC_Software\bomgar-vsccust-win64.zip"
$DestinationFolder = "C:\temp\"
$File = "bomgar-vsccust-win64.zip"
$MainInstaller = "bomgar-vsccust-win64.msi"
$vpn_test = Test-NetConnection -ComputerName "sncorp.intranet.com"
$ping_test = $vpn_test | Select-Object PingSucceeded -Wait
$ZipFilePath = Join-Path -Path $DestinationFolder -ChildPath $File ## DO NOT CHANGE

Clear-Host

#region Main Descriptor
## START Main Descriptor
Write-Output "--------------------" | Yellow
Write-Output "$Author" | Yellow
Write-Output "$Script_Name" | Yellow
Write-Output "$version , $last_tested" | Yellow
Write-Output "$live , $bmgr" | Yellow
Write-Output "$Description" | Yellow
Write-Output "--------------------" | Yellow
## END Main Descriptor
#endregion

## Checking That Machine Is Online
if ($ping_test -match "False") { Write-Output "Please Connect To Internet & VPN" | Red}
if ($ping_test -match "False") { EXIT }
if ($ping_test -match "True") { Write-Output "Computer Is Connected To Network" | Green}
if ($ping_test -match "True") {

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
        Write-Output "The file path '$file' is reachable." | Green
        return $true
    } else {
        Write-Output "The file server is not reachable. Trying again in 10 seconds... If issue persists, check connectivity" | Red
        return $false
    }
}
## Loop until the file path is reachable
while (-not (CheckFilePath -file $filePath)) {
    Start-Sleep -Seconds 10
}
Write-Output "The file server was successfully reached." | Green
## END Built in file server connection check
#endregion

#region Zip File Transfer
## START Zip File Transfer
# Start the process
Write-Output "Starting Zip File Transfer" | Cyan

# Check if the destination folder exists
if (Test-Path -Path $ZipFilePath ) {
    Write-Output "Destination folder exists, removing for a fresh transfer..." | Yellow
    Remove-Item -Path $ZipFilePath -Recurse -Force
} else {
# Create the destination folder if it doesn't exist
    New-Item -ItemType Directory -Path $ZipFilePath
}

# Perform the file transfer
$FOF_CREATEPROGRESSDLG = "&H0&"
$objShell = New-Object -ComObject "Shell.Application"
$objFolder = $objShell.NameSpace($DestinationFolder)
$objFolder.CopyHere($Source, $FOF_CREATEPROGRESSDLG)

# Finish the process
Write-Output "Finished Zip File Transfer" | Green

## Archive Exspansion
Write-Output "Starting Archive Expansion" | Cyan
Expand-Archive "C:\temp\$File" -Destination $DestinationFolder -force
Write-Output "Done Expanding Archive" | Green

## Main Installer Start
Write-Output "Starting $MainInstaller" | Cyan
Start-Process "C:\temp\$MainInstaller"
Write-Output "Finished $maininstaller" | Green
Write-Output "The script will now Exit" | Blue
Start-Sleep 5
Exit}

Exit
Pause & exit
