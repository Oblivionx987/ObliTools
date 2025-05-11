Add-Type -AssemblyName System.Windows.Forms

# Create the main form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Device Status Checker"
$form.Size = New-Object System.Drawing.Size(400, 300)

# Create a listbox to display the machine names
$listBox = New-Object System.Windows.Forms.ListBox
$listBox.Size = New-Object System.Drawing.Size(250, 200)
$listBox.Location = New-Object System.Drawing.Point(10, 10)
$form.Controls.Add($listBox)

# Create a textbox for inputting new machine names
$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Size = New-Object System.Drawing.Size(180, 20)
$textBox.Location = New-Object System.Drawing.Point(10, 220)
$form.Controls.Add($textBox)

# Create a button to add new machine names
$addButton = New-Object System.Windows.Forms.Button
$addButton.Text = "Add"
$addButton.Size = New-Object System.Drawing.Size(50, 20)
$addButton.Location = New-Object System.Drawing.Point(200, 220)
$form.Controls.Add($addButton)

# Create a button to remove selected machine names
$removeButton = New-Object System.Windows.Forms.Button
$removeButton.Text = "Remove"
$removeButton.Size = New-Object System.Drawing.Size(70, 20)
$removeButton.Location = New-Object System.Drawing.Point(270, 220)
$form.Controls.Add($removeButton)

# Dictionary to store the last known status of each machine
$machineStatus = @{}

# Function to ping machines and update status
function Check-MachineStatus {
    foreach ($machine in $listBox.Items) {
        $pingResult = Test-Connection -ComputerName $machine -Count 1 -Quiet
        if ($machineStatus[$machine] -ne $pingResult) {
            if ($pingResult) {
                [System.Windows.Forms.MessageBox]::Show("$machine is now online!", "Status Change")
            }
            $machineStatus[$machine] = $pingResult
        }
    }
}

# Event handler for adding a new machine name
$addButton.Add_Click({
    if (-not [string]::IsNullOrWhiteSpace($textBox.Text)) {
        $listBox.Items.Add($textBox.Text)
        $machineStatus[$textBox.Text] = $false
        $textBox.Clear()
    }
})

# Event handler for removing a selected machine name
$removeButton.Add_Click({
    if ($listBox.SelectedItem) {
        $machineStatus.Remove($listBox.SelectedItem)
        $listBox.Items.Remove($listBox.SelectedItem)
    }
})

# Timer to periodically check the status of machines
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 300000 # 5 minutes in milliseconds
$timer.Add_Tick({ Check-MachineStatus })
$timer.Start()

# Show the form
[void]$form.ShowDialog()
