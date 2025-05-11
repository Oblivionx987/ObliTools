Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Function to load data from CSV
function Load-PrinterData {
    param (
        [string]$csvPath
    )

    $data = Import-Csv -Path $csvPath
    return $data
}

# Load the data
$data = Load-PrinterData -csvPath "C:\Users\114825\OneDrive - Sierra Nevada Corporation\SCRIPTS\Main\Printers\MasterPrinterList.csv"

# Extract unique locations
$locations = $data | Select-Object -ExpandProperty Location -Unique

# Create the form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Printer Installation"
$form.Size = New-Object System.Drawing.Size(400, 400)
$form.StartPosition = "CenterScreen"

# Create the location dropdown
$locationLabel = New-Object System.Windows.Forms.Label
$locationLabel.Text = "Select Location"
$locationLabel.Location = New-Object System.Drawing.Point(10, 25)
$form.Controls.Add($locationLabel)

$locationDropdown = New-Object System.Windows.Forms.ComboBox
$locationDropdown.Location = New-Object System.Drawing.Point(150, 20)
$locationDropdown.Size = New-Object System.Drawing.Size(200, 25)
$locationDropdown.Items.AddRange($locations)
$form.Controls.Add($locationDropdown)

# Create the sublocation dropdown
$sublocationLabel = New-Object System.Windows.Forms.Label
$sublocationLabel.Text = "Select Sublocation"
$sublocationLabel.Location = New-Object System.Drawing.Point(10, 60)
$form.Controls.Add($sublocationLabel)

$sublocationDropdown = New-Object System.Windows.Forms.ComboBox
$sublocationDropdown.Location = New-Object System.Drawing.Point(150, 60)
$sublocationDropdown.Size = New-Object System.Drawing.Size(200, 25)
$form.Controls.Add($sublocationDropdown)

# Create the printer server dropdown
$printerServerLabel = New-Object System.Windows.Forms.Label
$printerServerLabel.Text = "Select Printer Server"
$printerServerLabel.Location = New-Object System.Drawing.Point(10, 100)
$form.Controls.Add($printerServerLabel)

$printerServerDropdown = New-Object System.Windows.Forms.ComboBox
$printerServerDropdown.Location = New-Object System.Drawing.Point(150, 100)
$printerServerDropdown.Size = New-Object System.Drawing.Size(200, 25)
$form.Controls.Add($printerServerDropdown)

# Create the printer dropdown
$printerLabel = New-Object System.Windows.Forms.Label
$printerLabel.Text = "Select Printer"
$printerLabel.Location = New-Object System.Drawing.Point(10, 140)
$form.Controls.Add($printerLabel)

$printerDropdown = New-Object System.Windows.Forms.ComboBox
$printerDropdown.Location = New-Object System.Drawing.Point(150, 140)
$printerDropdown.Size = New-Object System.Drawing.Size(200, 25)
$form.Controls.Add($printerDropdown)

# Create the install button
$installButton = New-Object System.Windows.Forms.Button
$installButton.Text = "Install Printer"
$installButton.Location = New-Object System.Drawing.Point(150, 180)
$form.Controls.Add($installButton)

# Event handlers for dropdown selections
$locationDropdown.add_SelectedIndexChanged({
    $sublocationDropdown.Items.Clear()
    $sublocationDropdown.Text = ""
    $printerServerDropdown.Items.Clear()
    $printerServerDropdown.Text = ""
    $printerDropdown.Items.Clear()
    $printerDropdown.Text = ""
    
    $selectedLocation = $locationDropdown.SelectedItem
    $sublocations = $data | Where-Object { $_.Location -eq $selectedLocation } | Select-Object -ExpandProperty Sublocation -Unique
    $sublocationDropdown.Items.AddRange($sublocations)
})

$sublocationDropdown.add_SelectedIndexChanged({
    $printerServerDropdown.Items.Clear()
    $printerServerDropdown.Text = ""
    $printerDropdown.Items.Clear()
    $printerDropdown.Text = ""
    
    $selectedLocation = $locationDropdown.SelectedItem
    $selectedSublocation = $sublocationDropdown.SelectedItem
    $printerServers = $data | Where-Object { $_.Location -eq $selectedLocation -and $_.Sublocation -eq $selectedSublocation } | Select-Object -ExpandProperty PrinterServer -Unique
    $printerServerDropdown.Items.AddRange($printerServers)
})

$printerServerDropdown.add_SelectedIndexChanged({
    $printerDropdown.Items.Clear()
    $printerDropdown.Text = ""
    
    $selectedLocation = $locationDropdown.SelectedItem
    $selectedSublocation = $sublocationDropdown.SelectedItem
    $selectedPrinterServer = $printerServerDropdown.SelectedItem
    $printers = $data | Where-Object { $_.Location -eq $selectedLocation -and $_.Sublocation -eq $selectedSublocation -and $_.PrinterServer -eq $selectedPrinterServer } | Select-Object -ExpandProperty PrinterName
    $printerDropdown.Items.AddRange($printers)
})

# Event handler for install button click
$installButton.Add_Click({
    $printerServer = $printerServerDropdown.SelectedItem
    $printer = $printerDropdown.SelectedItem
    if ($printerServer -and $printer) {
        $printerPath = "\\$printerServer\$printer"
        $command = @"
        Write-Host "Installing $printer on $printerServer Please wait"
        Add-Printer -ConnectionName '$printerPath'
        rundll32 printui.dll,PrintUIEntry /ga /n"$printerPath"
        Write-Host "Installed $printer on $printerServer This window will auto close"
        Sleep 10
        Exit
"@
        Start-Process powershell -ArgumentList "-NoExit", "-Command", $command         
    } else {
        [System.Windows.Forms.MessageBox]::Show("Please select a printer server and printer.")
    }
})

# Run the form
[void]$form.ShowDialog()