Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create the form
$form = New-Object System.Windows.Forms.Form
$form.Text = "URL Entry Form"
$form.Size = New-Object System.Drawing.Size(400,300)
$form.StartPosition = "CenterScreen"

# Create labels and textboxes for Name, URL, and Note
$labelName = New-Object System.Windows.Forms.Label
$labelName.Text = "Name:"
$labelName.Location = New-Object System.Drawing.Point(20,20)
$form.Controls.Add($labelName)

$textboxName = New-Object System.Windows.Forms.TextBox
$textboxName.Location = New-Object System.Drawing.Point(120,20)
$textboxName.Width = 200
$form.Controls.Add($textboxName)

$labelUrl = New-Object System.Windows.Forms.Label
$labelUrl.Text = "URL:"
$labelUrl.Location = New-Object System.Drawing.Point(20,60)
$form.Controls.Add($labelUrl)

$textboxUrl = New-Object System.Windows.Forms.TextBox
$textboxUrl.Location = New-Object System.Drawing.Point(120,60)
$textboxUrl.Width = 200
$form.Controls.Add($textboxUrl)

$labelNote = New-Object System.Windows.Forms.Label
$labelNote.Text = "Note:"
$labelNote.Location = New-Object System.Drawing.Point(20,100)
$form.Controls.Add($labelNote)

$textboxNote = New-Object System.Windows.Forms.TextBox
$textboxNote.Location = New-Object System.Drawing.Point(120,100)
$textboxNote.Width = 200
$form.Controls.Add($textboxNote)

# Create a button to save the input
$buttonSave = New-Object System.Windows.Forms.Button
$buttonSave.Text = "Save"
$buttonSave.Location = New-Object System.Drawing.Point(120,140)
$form.Controls.Add($buttonSave)

# Create a panel to hold URL buttons
$panelUrls = New-Object System.Windows.Forms.Panel
$panelUrls.Location = New-Object System.Drawing.Point(20,180)
$panelUrls.Size = New-Object System.Drawing.Size(340,60)
$form.Controls.Add($panelUrls)

# CSV file path
$csvPath = "C:\Temp\url_list.csv"

# Function to create URL buttons
function CreateUrlButtons {
    $panelUrls.Controls.Clear()
    if (Test-Path $csvPath) {
        $urls = Import-Csv -Path $csvPath
        $x = 0
        foreach ($url in $urls) {
            $button = New-Object System.Windows.Forms.Button
            $button.Text = $url.Name
            $button.Location = New-Object System.Drawing.Point($x, 0)
            $button.Width = 100
            $button.Add_Click({
                Start-Process $url.Url
            })
            $panelUrls.Controls.Add($button)
            $x += 110
        }
    }
}

# Initialize URL buttons when form loads
$form.Add_Shown({ CreateUrlButtons })

# Button save click event
$buttonSave.Add_Click({
    $name = $textboxName.Text
    $url = $textboxUrl.Text
    $note = $textboxNote.Text

    if ($name -and $url) {
        $entry = [PSCustomObject]@{
            Name = $name
            URL = $url
            Note = $note
        }}})

        # Debug output
        Write-Output "Entry: $($entry
        )