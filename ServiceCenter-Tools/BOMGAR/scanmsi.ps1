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
