# NoteManagerGUI.ps1
# A PowerShell GUI for managing notes with features like search, tagging, and dark mode.

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Paths for saving notes and configuration
$notesFilePath = "c:\Users\Oblivion\OneDrive\Seth\Oblivion Vault\Scripts\Templates\noterv2\notes.json"
$configFilePath = "c:\Users\Oblivion\OneDrive\Seth\Oblivion Vault\Scripts\Templates\noterv2\config.json"

# Load existing notes and config
if (Test-Path $notesFilePath) {
    $notes = Get-Content $notesFilePath | ConvertFrom-Json
    if ($notes -isnot [System.Collections.ArrayList] -and $notes -isnot [System.Array]) {
        $notes = @($notes)
    }
} else {
    $notes = @()
}

if (Test-Path $configFilePath) {
    $config = Get-Content $configFilePath | ConvertFrom-Json
} else {
    $config = @{ DarkMode = $false }
}

# Create the form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Note Manager"
$form.Size = New-Object System.Drawing.Size(600, 400)
$form.StartPosition = "CenterScreen"

# Add a TabControl to the form
$tabControl = New-Object System.Windows.Forms.TabControl
$tabControl.Location = New-Object System.Drawing.Point(10, 10)
$tabControl.Size = New-Object System.Drawing.Size(580, 350)
$form.Controls.Add($tabControl)

# Create a tab for the main view
$mainTab = New-Object System.Windows.Forms.TabPage
$mainTab.Text = "Main View"
$tabControl.TabPages.Add($mainTab)

# Create a tab for settings
$settingsTab = New-Object System.Windows.Forms.TabPage
$settingsTab.Text = "Settings"
$tabControl.TabPages.Add($settingsTab)

# Move the dark mode button to the settings tab
$darkModeButton = New-Object System.Windows.Forms.Button
$darkModeButton.Text = "Toggle Dark Mode"
$darkModeButton.Location = New-Object System.Drawing.Point(10, 10)
$darkModeButton.Parent = $settingsTab
$settingsTab.Controls.Add($darkModeButton)

# Notes list view
$notesListView = New-Object System.Windows.Forms.ListView
$notesListView.View = [System.Windows.Forms.View]::Details
$notesListView.FullRowSelect = $true
$notesListView.Location = New-Object System.Drawing.Point(10, 40)
$notesListView.Size = New-Object System.Drawing.Size(560, 200)
$notesListView.Columns.Add("Timestamp", 150)
$notesListView.Columns.Add("Tags", 150)
$notesListView.Columns.Add("Note", 250)
$mainTab.Controls.Add($notesListView)

# Populate the list view with notes
function RefreshNotes {
    $notesListView.Items.Clear()
    foreach ($note in $notes) {
        $item = New-Object System.Windows.Forms.ListViewItem ($note.Timestamp)
        $item.SubItems.Add(($note.Tags -join ", "))
        $item.SubItems.Add($note.Content)
        $notesListView.Items.Add($item)
    }
}
RefreshNotes

# Note input box
$noteInput = New-Object System.Windows.Forms.TextBox
$noteInput.Location = New-Object System.Drawing.Point(10, 250)
$noteInput.Size = New-Object System.Drawing.Size(400, 20)
$mainTab.Controls.Add($noteInput)

# Tags input box
$tagsInput = New-Object System.Windows.Forms.TextBox
$tagsInput.Location = New-Object System.Drawing.Point(420, 250)
$tagsInput.Size = New-Object System.Drawing.Size(150, 20)
$mainTab.Controls.Add($tagsInput)

# Add note button
$addButton = New-Object System.Windows.Forms.Button
$addButton.Text = "Add Note"
$addButton.Location = New-Object System.Drawing.Point(10, 280)
$addButton.Add_Click({
    $newNote = [PSCustomObject]@{
        Timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        Tags = $tagsInput.Text -split ","
        Content = $noteInput.Text
    }
    $notes += $newNote

    # Save notes as an array in JSON format
    $json = $notes | ConvertTo-Json -Depth 10 -Compress
    [System.IO.File]::WriteAllText($notesFilePath, $json)

    RefreshNotes
    $noteInput.Clear()
    $tagsInput.Clear()
})
$mainTab.Controls.Add($addButton)

# Edit note button
$editButton = New-Object System.Windows.Forms.Button
$editButton.Text = "Edit Note"
$editButton.Location = New-Object System.Drawing.Point(100, 280)
$editButton.Add_Click({
    if ($notesListView.SelectedItems.Count -eq 1) {
        $selectedIndex = $notesListView.SelectedItems[0].Index
        $notes[$selectedIndex].Content = $noteInput.Text
        $notes[$selectedIndex].Tags = $tagsInput.Text -split ","

        # Save notes as an array in JSON format
        $json = $notes | ConvertTo-Json -Depth 10 -Compress
        [System.IO.File]::WriteAllText($notesFilePath, $json)

        RefreshNotes
    }
})
$mainTab.Controls.Add($editButton)

# Delete note button
$deleteButton = New-Object System.Windows.Forms.Button
$deleteButton.Text = "Delete Note"
$deleteButton.Location = New-Object System.Drawing.Point(190, 280)
$deleteButton.Add_Click({
    if ($notesListView.SelectedItems.Count -eq 1) {
        $selectedIndex = $notesListView.SelectedItems[0].Index
        $notes = $notes | Where-Object { $_ -ne $notes[$selectedIndex] }

        # Save notes as an array in JSON format
        $json = $notes | ConvertTo-Json -Depth 10 -Compress
        [System.IO.File]::WriteAllText($notesFilePath, $json)

        RefreshNotes
    }
})
$mainTab.Controls.Add($deleteButton)

# Search notes button
$searchButton = New-Object System.Windows.Forms.Button
$searchButton.Text = "Search Notes"
$searchButton.Location = New-Object System.Drawing.Point(280, 280)
$searchButton.Add_Click({
    $searchTerm = $noteInput.Text
    $filteredNotes = $notes | Where-Object {
        $_.Content -like "*$searchTerm*" -or ($_.Tags -join ",") -like "*$searchTerm*"
    }
    $notesListView.Items.Clear()
    foreach ($note in $filteredNotes) {
        $item = New-Object System.Windows.Forms.ListViewItem ($note.Timestamp)
        $item.SubItems.Add(($note.Tags -join ", "))
        $item.SubItems.Add($note.Content)
        $notesListView.Items.Add($item)
    }
})
$mainTab.Controls.Add($searchButton)

# Dark mode toggle functionality
$darkModeButton.Add_Click({
    $config.DarkMode = -not $config.DarkMode
    $config | ConvertTo-Json | Set-Content $configFilePath
    if ($config.DarkMode) {
        $form.BackColor = [System.Drawing.Color]::Black
        $form.ForeColor = [System.Drawing.Color]::White
    } else {
        $form.BackColor = [System.Drawing.Color]::White
        $form.ForeColor = [System.Drawing.Color]::Black
    }
})

# Apply initial dark mode setting
if ($config.DarkMode) {
    $form.BackColor = [System.Drawing.Color]::Black
    $form.ForeColor = [System.Drawing.Color]::White
}

# Show the form
[void]$form.ShowDialog()
