Add-Type -AssemblyName System.Windows.Forms

# Create a new form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Simple GUI"
$form.Width = 300
$form.Height = 200
$form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen

# Create a label
$label = New-Object System.Windows.Forms.Label
$label.Text = "Hello, World!"
$label.AutoSize = $true
$label.Location = New-Object System.Drawing.Point(100, 50)
$form.Controls.Add($label)

# Create a button
$button = New-Object System.Windows.Forms.Button
$button.Text = "Click Me"
$button.Location = New-Object System.Drawing.Point(100, 100)
$button.AutoSize = $false
$button.Size = New-Object System.Drawing.Size(75, 23)

# Add button click event
$button.Add_Click({
    $label.Text = "Button Clicked!"
})

$form.Controls.Add($button)

# Show the form
$form.Add_Shown({$form.Activate()})
[System.Windows.Forms.Application]::Run($form)
