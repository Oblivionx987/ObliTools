#region Script Info
$Script_Name = "Firspsguis.ps1"
$Description = "powershell gui testing"
$Author = "Seth Burns - System Administrator II - Service Center"
$last_tested = "05-27-25"
$version = "1.0.0"
$live = "Restricted"
$bmgr = "Restricted"
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
Write-Output "--------------------" | Yellow
Write-Output "$Author" | Yellow
Write-Output "$Script_Name" | Yellow
Write-Output "$version , $last_tested" | Yellow
Write-Output "$live , $bmgr" | Yellow
Write-Output "$Description" | Yellow
Write-Output "--------------------" | Yellow
## END Main Descriptor
#endregion

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
