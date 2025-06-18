#region Script Info
$Script_Name = "Scan-MSI.ps1"
$Description = "This script will scan an MSI file and output all properties."
$Author = "Seth Burns - System Administrator II - Service Center"
$last_tested = "06-17-25"
$version = "1.0.0"
$live = "WIP"
$bmgr = "WIP"
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
Write-Output "$Script_Name" | Yellow
Write-Output "$version , $last_tested" | Yellow
Write-Output "$live , $bmgr" | Yellow
Write-Output "$Description" | Yellow
Write-Output "--------------------"
## END Main Descriptor
#endregion

# Define the path to the MSI file
$msiPath = "C:\path\to\your\file.msi"

# Create the WindowsInstaller.Installer COM object
$installer = New-Object -ComObject WindowsInstaller.Installer

# Open the MSI database
$database = $installer.GetType().InvokeMember("OpenDatabase", "InvokeMethod", $null, $installer, @($msiPath, 0))

# Define the query to fetch all properties
$query = "SELECT * FROM Property"

# Open the view for the query
$view = $database.GetType().InvokeMember("OpenView", "InvokeMethod", $null, $database, @($query))

# Execute the view
$view.GetType().InvokeMember("Execute", "InvokeMethod", $null, $view, $null)

# Fetch all records
$record = $view.GetType().InvokeMember("Fetch", "InvokeMethod", $null, $view, $null)

# Loop through all records and print the properties
while ($record -ne $null) {
    $property = $record.GetType().InvokeMember("StringData", "GetProperty", $null, $record, @(1))
    $value = $record.GetType().InvokeMember("StringData", "GetProperty", $null, $record, @(2))
    Write-Output "$property = $value"
    
    # Fetch the next record
    $record = $view.GetType().InvokeMember("Fetch", "InvokeMethod", $null, $view, $null)
}
