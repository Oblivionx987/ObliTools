<#  Note-Manager.ps1  —  revised 2025-05-10  #>

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

#───────────────────────────────────────────────────────────────────────────────
#  Paths & data
#───────────────────────────────────────────────────────────────────────────────
$dataFile = Join-Path $env:USERPROFILE 'NoteManager_Notes.json'
if (Test-Path $dataFile -and (Get-Content $dataFile -Raw).Trim()) {
    try {
        $notes = (Get-Content $dataFile -Raw | ConvertFrom-Json)
    } catch {
        [System.Windows.MessageBox]::Show(
            "Corrupted data file found at $dataFile – starting with an empty list.",
            "Note Manager"
        )
        $notes = @()
    }
} else {
    $notes = @()
}

# ensure we always treat it as an array
if ($notes -isnot [System.Collections.IEnumerable]) { $notes = @($notes) }

#───────────────────────────────────────────────────────────────────────────────
#  XAML  (no PlaceholderText – WPF TextBox has no such property pre-.NET 8)
#───────────────────────────────────────────────────────────────────────────────
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="Note Manager" Height="650" Width="850">
    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto" />
            <RowDefinition Height="*" />
            <RowDefinition Height="Auto" />
        </Grid.RowDefinitions>

        <!-- Input area -->
        <StackPanel Grid.Row="0" Orientation="Vertical" Margin="0,0,0,10">
            <TextBox Name="NoteInput"
                     Height="100"
                     AcceptsReturn="True"
                     TextWrapping="Wrap"
                     VerticalScrollBarVisibility="Auto"/>
            <StackPanel Orientation="Horizontal" Margin="0,5,0,0">
                <TextBox Name="CategoryInput" Width="150" Margin="0,0,5,0"/>
                <TextBox Name="ReminderInput" Width="200" Margin="0,0,5,0"
                         ToolTip="yyyy-MM-dd HH:mm (optional)"/>
                <Button Name="BoldButton"    Content="Bold"    Width="60" Margin="0,0,5,0"/>
                <Button Name="ItalicsButton" Content="Italics" Width="60" Margin="0,0,5,0"/>
                <Button Name="BulletButton"  Content="Bullet"  Width="60"/>
            </StackPanel>
        </StackPanel>

        <!-- Search & list -->
        <StackPanel Grid.Row="1" Orientation="Vertical">
            <TextBox Name="SearchBox" Height="25" ToolTip="Search notes..."/>
            <ListBox Name="NotesList" Height="350"/>
        </StackPanel>

        <!-- Action buttons -->
        <StackPanel Grid.Row="2" Orientation="Horizontal" HorizontalAlignment="Center" Margin="0,10,0,0">
            <Button Name="AddNoteButton"        Content="Add Note"         Width="100" Margin="5"/>
            <Button Name="OrganizeNotesButton"  Content="Organize Notes"   Width="120" Margin="5"/>
            <Button Name="ExportButton"         Content="Export Notes"     Width="120" Margin="5"/>
            <Button Name="ToggleDarkModeButton" Content="Toggle Dark Mode" Width="150" Margin="5"/>
            <Button Name="ShowDashboardButton"  Content="Show Dashboard"   Width="150" Margin="5"/>
        </StackPanel>
    </Grid>
</Window>
"@

#───────────────────────────────────────────────────────────────────────────────
#  Wire-up
#───────────────────────────────────────────────────────────────────────────────
$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)

# Grab controls ---------------------------------------------------------------
$noteInput            = $window.FindName('NoteInput')
$categoryInput        = $window.FindName('CategoryInput')
$reminderInput        = $window.FindName('ReminderInput')
$searchBox            = $window.FindName('SearchBox')
$notesList            = $window.FindName('NotesList')
$addNoteButton        = $window.FindName('AddNoteButton')
$organizeButton       = $window.FindName('OrganizeNotesButton')
$exportButton         = $window.FindName('ExportButton')
$boldButton           = $window.FindName('BoldButton')
$italicsButton        = $window.FindName('ItalicsButton')
$bulletButton         = $window.FindName('BulletButton')
$toggleDarkModeButton = $window.FindName('ToggleDarkModeButton')
$showDashboardButton  = $window.FindName('ShowDashboardButton')

#───────────────────────────────────────────────────────────────────────────────
#  Helper – refresh list
#───────────────────────────────────────────────────────────────────────────────
function Refresh-NotesList {
    $notesList.Items.Clear()
    foreach ($note in $notes) {
        $categoryText = if ($note.Category) { " [$($note.Category)]" } else { '' }
        $reminderText = if ($note.Reminder) { " (Reminder: $($note.Reminder))" } else { '' }
        $notesList.Items.Add("$($note.Timestamp)$categoryText$reminderText – $($note.Content)")
    }
}
Refresh-NotesList

#───────────────────────────────────────────────────────────────────────────────
#  Event handlers
#───────────────────────────────────────────────────────────────────────────────
# Add note
$addNoteButton.Add_Click({
    $noteText     = $noteInput.Text.Trim()
    $categoryText = $categoryInput.Text.Trim()
    $reminderText = $reminderInput.Text.Trim()

    if ($noteText) {
        $noteObj = [pscustomobject]@{
            Timestamp = (Get‑Date -Format 'yyyy-MM-dd HH:mm:ss')
            Content   = $noteText
            Category  = $categoryText
            Reminder  = $reminderText
            Alerted   = $false
        }
        $script:notes += $noteObj
        $script:notes | ConvertTo‑Json -Depth 3 | Set‑Content -LiteralPath $dataFile -Encoding UTF8
        Refresh‑NotesList
        $noteInput.Clear(); $categoryInput.Clear(); $reminderInput.Clear()
    }
})


# Search
$searchBox.Add_TextChanged({
    $query = $searchBox.Text.Trim().ToLower()
    $notesList.Items.Clear()
    foreach ($note in $notes) {
        $matchContent  = $note.Content.ToLower() -like "*$query*"
        $matchCategory = ($note.Category) -and ($note.Category.ToLower() -like "*$query*")
        if ($matchContent -or $matchCategory) {
            $categoryText = if ($note.Category) { " [$($note.Category)]" } else { '' }
            $reminderText = if ($note.Reminder) { " (Reminder: $($note.Reminder))" } else { '' }
            $notesList.Items.Add("$($note.Timestamp)$categoryText$reminderText – $($note.Content)")
        }
    }
})

# Organize by Category then Date
$organizeButton.Add_Click({
    $script:notes = $notes | Sort-Object Category, { [datetime]$_.Timestamp }
    Refresh-NotesList
    $notes | ConvertTo-Json -Depth 3 | Set-Content -LiteralPath $dataFile -Encoding UTF8
})

# Export
$exportButton.Add_Click({
    $dlg = New-Object System.Windows.Forms.SaveFileDialog
    $dlg.Filter = 'Markdown (*.md)|*.md|Text (*.txt)|*.txt'
    $dlg.Title  = 'Export Notes'
    if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $sb = [System.Text.StringBuilder]::new()
        foreach ($note in $notes) {
            if ($note.Category) { $null = $sb.AppendLine("**Category:** $($note.Category)") }
            if ($note.Reminder) { $null = $sb.AppendLine("**Reminder:** $($note.Reminder)") }
            $null = $sb.AppendLine("### $($note.Timestamp)")
            $null = $sb.AppendLine($note.Content)
            $null = $sb.AppendLine()
        }
        $sb.ToString() | Set-Content -LiteralPath $dlg.FileName -Encoding UTF8
        [System.Windows.MessageBox]::Show("Notes exported to $($dlg.FileName)", 'Export Complete')
    }
})

# Bold / Italic
$boldButton.Add_Click({
    if ($noteInput.SelectionLength -gt 0) {
        $selStart   = $noteInput.SelectionStart
        $selLength  = $noteInput.SelectionLength
        $noteInput.Text = $noteInput.Text.Insert($selStart + $selLength, '**').Insert($selStart, '**')
        $noteInput.Select($selStart, $selLength + 4)
    }
})
$italicsButton.Add_Click({
    if ($noteInput.SelectionLength -gt 0) {
        $selStart   = $noteInput.SelectionStart
        $selLength  = $noteInput.SelectionLength
        $noteInput.Text = $noteInput.Text.Insert($selStart + $selLength, '_').Insert($selStart, '_')
        $noteInput.Select($selStart, $selLength + 2)
    }
})

# Bullet
$bulletButton.Add_Click({
    $noteInput.Text = "$([char]0x2022) $($noteInput.Text)"
})

# Dark-mode toggle
$dark = $false
function Set-Theme([bool]$isDark) {
    $bg = if ($isDark) { 'Black' } else { 'White' }
    $fg = if ($isDark) { 'White' } else { 'Black' }
    foreach ($ctrl in @($window,
                        $noteInput,$categoryInput,$reminderInput,
                        $searchBox,$notesList)) {
        $ctrl.Background = $bg
        $ctrl.Foreground = $fg
    }
}
$toggleDarkModeButton.Add_Click({
    $script:dark = -not $script:dark
    Set‑Theme $script:dark
})


# Dashboard
$showDashboardButton.Add_Click({
    $total = $notes.Count
    $byCat = $notes | Group-Object Category |
             ForEach-Object { "{0}: {1}" -f ($_.Name ?? '<none>'), $_.Count } |
             Sort-Object
    $byMonth = $notes | Group-Object { $_.Timestamp.Substring(0,7) } |
               ForEach-Object { "{0}: {1}" -f $_.Name, $_.Count } |
               Sort-Object
    $msg = "Total Notes: $total`n`nNotes by Category:`n$($byCat -join "`n")`n`nNotes by Month:`n$($byMonth -join "`n")"
    [System.Windows.MessageBox]::Show($msg, 'Dashboard Analytics')
})

# Reminder timer (60 s)
$timer = New-Object System.Windows.Threading.DispatcherTimer
$timer.Interval = [TimeSpan]::FromSeconds(60)
$timer.Add_Tick({
    $now = Get-Date
    $dirty = $false
    foreach ($note in $notes) {
        if ($note.Reminder -and -not $note.Alerted) {
            $parsed = [datetime]::MinValue
            if ([datetime]::TryParse($note.Reminder, [ref]$parsed) -and $parsed -le $now) {
                [System.Windows.MessageBox]::Show("Reminder Due:`n$($note.Content)", 'Reminder')
                $note.Alerted = $true
                $dirty = $true
            }
        }
    }
    if ($dirty) {
        $notes | ConvertTo-Json -Depth 3 | Set-Content -LiteralPath $dataFile -Encoding UTF8
    }
})
$timer.Start()

#───────────────────────────────────────────────────────────────────────────────
#  Run
#───────────────────────────────────────────────────────────────────────────────
$window.ShowDialog() | Out-Null
